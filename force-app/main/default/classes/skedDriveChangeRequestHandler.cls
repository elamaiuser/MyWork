public class skedDriveChangeRequestHandler extends skedTriggerHub {
    
    private static final Map<String, String> genDriveFieldByOppFieldMap = new Map<String, String>{
        'Drive_Date__c' => 'sked_Drive_Date__c',
        'Drive_Status__c' => 'sked_Status__c',
        'Start_Time__c' => 'sked_Start_Time__c',
        'End_Time__c' => 'sked_End_Time__c',
        'Drive_Site__c' => 'sked_Drive_Site__c',
        'sked_Replacement_Drive__c' => 'sked_Replacement_Drive__c',
        'Anticipated_Registered_Donors__c' => 'sked_Projected_Registered_Donors__c',
        'WB_Projected_Procedures__c' => 'sked_WB_Projected_Procedures__c',
        'X2RBC_Projected_Procedures__c' => 'sked_2RBC_Projected_Procedures__c',
        'Platelet_Projected_Procedures__c' => 'sked_Platelet_Projected_Procedures__c',
        'Plasma_Pheresis_Projected_Procedures__c' => 'sked_Plasma_Projected_Procedures__c',
        'Number_of_2RBC_Assets__c' => 'sked_Number_of_2RBC_Assets__c',
        'Number_of_Plasma_Assets__c' => 'sked_Number_of_Plasma_Assets__c',
        'Number_of_Platelet_Assets__c' => 'sked_Number_of_Platelet_Assets__c',
        'sked_Cancellation_Reason__c' => 'sked_Cancellation_Reason__c',
        'Initiated_By__c' => 'sked_Initiated_By__c'
    };

    public override void onBeforeInsert() {
        populateNewCollectionOperationData(this.context.newRecords);
    }

    public override void onAfterInsert() {
        updateNumDCRsForRelatedDrives(this.context.newRecords);
    }
    
	public override void onBeforeUpdate() {
        populateNewCollectionOperationData(this.context.newRecords, (Map<Id, sked_Drive_Change_Request__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        updateNumDCRsForRelatedDrives(this.context.newRecords, (Map<Id, sked_Drive_Change_Request__c>)this.context.oldMap);
        if (!skedSetting.instance.Admin.migrationMode) {
            onSubmitted(this.context.newRecords, (Map<Id, sked_Drive_Change_Request__c>)this.context.oldMap);
            onCancelledRejected(this.context.newRecords, (Map<Id, sked_Drive_Change_Request__c>)this.context.oldMap);
            onBackToPending(this.context.newRecords, (Map<Id, sked_Drive_Change_Request__c>)this.context.oldMap);
            createRequestToSyncOppsWithDrives(this.context.newRecords, (Map<Id, sked_Drive_Change_Request__c>)this.context.oldMap);
        }
    }

    public override void onAfterDelete() {
        updateNumDCRsForRelatedDrives(this.context.oldRecords);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void updateNumDCRsForRelatedDrives(List<sked_Drive_Change_Request__c> records) {
        Set<Id> driveIds = new Set<Id>();
        for (sked_Drive_Change_Request__c record : records) { 
            if (record.sked_Drive__c != null) {
                driveIds.add(record.sked_Drive__c);
            }
        }

        if (!driveIds.isEmpty()) {
            Set<String> nonPendingStatuses = new Set<String>{'Approved', 'Rejected', 'Cancelled', 'Approved by System'};
            List<sked_Drive__c> drives = [
                SELECT Id, sked_Num_Of_Pending_DCRs__c, 
                    (SELECT Id FROM sked_Drive_Change_Requests__r WHERE sked_Status__c NOT IN :nonPendingStatuses)
                FROM sked_Drive__c
                WHERE Id IN :driveIds
            ];

            List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
            for (sked_Drive__c drive : drives) {
                if (drive.sked_Drive_Change_Requests__r.size() != drive.sked_Num_Of_Pending_DCRs__c) {
                    drive.sked_Num_Of_Pending_DCRs__c = drive.sked_Drive_Change_Requests__r.size();
                    drivesToUpdate.add(drive);
                }
            }

            if (!drivesToUpdate.isEmpty()) {
                skedHubBase.BypassUpdateTriggers = true;
                update drivesToUpdate;
                skedHubBase.BypassUpdateTriggers = false;
            }
        }
    }

    private void updateNumDCRsForRelatedDrives(List<sked_Drive_Change_Request__c> newRecords, Map<Id, sked_Drive_Change_Request__c> oldMap) {
        List<sked_Drive_Change_Request__c> dcrsRequiringDriveUpdate = new List<sked_Drive_Change_Request__c>();
        for (sked_Drive_Change_Request__c newRecord : newRecords) {
            sked_Drive_Change_Request__c oldRecord = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldRecord.sked_Status__c) {
                dcrsRequiringDriveUpdate.add(newRecord);
            }
        }

        if (!dcrsRequiringDriveUpdate.isEmpty()) {
            updateNumDCRsForRelatedDrives(newRecords);
        }
    }

    private void onSubmitted(List<sked_Drive_Change_Request__c> newRecords, Map<Id, sked_Drive_Change_Request__c> oldMap) {
        Map<Id, sked_Drive_Change_Request__c> mapSubmittedDcr = new Map<Id, sked_Drive_Change_Request__c>();
        Boolean hasRouteApprovalRequestChanged = false;
        for (sked_Drive_Change_Request__c newRecord : newRecords) {
            sked_Drive_Change_Request__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c && newRecord.sked_Status__c == 'Submitted') {
                mapSubmittedDcr.put(newRecord.Id, newRecord);
                if(newRecord.sked_Route_Approval_Request_To__c != oldData.sked_Route_Approval_Request_To__c || (newRecord.sked_Status__c == 'Submitted' && oldData.sked_Status__c == 'Waiting for APS Approval')) {//HRP-14627
                    hasRouteApprovalRequestChanged = true;
                }
            }
        }
        if (!mapSubmittedDcr.isEmpty()) {
            doSubmission(mapSubmittedDcr, hasRouteApprovalRequestChanged);
        }
    }
    
    private void doSubmission(Map<Id, sked_Drive_Change_Request__c> mapSubmittedDcr, Boolean hasRouteApprovalRequestChanged) {
        List<sked_Drive_Change_Request__c> submittedDcrs = [SELECT Id, sked_Drive__c, sked_Route_Approval_Request_To__c, sked_Status__c,
                                                            sked_New_Collection_Operation__c, sked_New_Collection_Operation__r.Name 
                                                            FROM sked_Drive_Change_Request__c
                                                            WHERE Id IN :mapSubmittedDcr.keySet()
                                                            FOR UPDATE];
        List<Approval.ProcessWorkitemRequest> activeApprovalProcesses = new List<Approval.ProcessWorkitemRequest>();
        if(hasRouteApprovalRequestChanged) {
            List<ProcessInstanceWorkitem> activeWorkItems = [SELECT Id, ProcessInstanceId 
                                                             FROM ProcessInstanceWorkitem 
                                                             WHERE ProcessInstance.TargetObjectId IN :mapSubmittedDcr.keySet()
                                                             AND ProcessInstance.Status = 'Pending'];
            for (ProcessInstanceWorkitem workItem : activeWorkItems) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                req.setAction('Removed');  // Remove the existing pending approval process
                activeApprovalProcesses.add(req);
            }
        }

        Set<Id> accountIds = new Set<Id>();
        Set<string> queueNames = new Set<string>();
        
        Set<Id> driveIds = new Set<Id>();
        for (sked_Drive_Change_Request__c submittedDcr : submittedDcrs) {
            driveIds.add(submittedDcr.sked_Drive__c);
            if (submittedDcr.sked_New_Collection_Operation__c != NULL) {
                queueNames.add(submittedDcr.sked_New_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS);
                queueNames.add(submittedDcr.sked_New_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DM_DRIVE_CHANGE_REQUESTS);
            }
        }
        
        Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>([
            SELECT Id, sked_Account__c, sked_Pending_Action__c, sked_Collection_Operation__r.Name
            FROM sked_Drive__c
            WHERE Id IN :driveIds
            FOR UPDATE
        ]);
        for (sked_Drive__c skedDrive : mapDrive.values()) {
            accountIds.add(skedDrive.sked_Account__c);
            queueNames.add(skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS);
            queueNames.add(skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DM_DRIVE_CHANGE_REQUESTS);
        }

        List<Group> approvalQueues = [
            SELECT Id, Name
            FROM Group
            WHERE Name IN :queueNames
            AND Type = :skedConstants.GROUP_TYPE_QUEUE
        ];

        Map<string, Group> mapQueueByName = new Map<string, Group>();
        for (Group approvalQueue : approvalQueues) {
            mapQueueByName.put(approvalQueue.Name, approvalQueue);
        }
        
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        List<sked_Drive_Change_Request__c> recordsToUpdate = new List<sked_Drive_Change_Request__c>();
        
        for (sked_Drive_Change_Request__c submittedDcr : submittedDcrs) {
            sked_Drive__c skedDrive = mapDrive.get(submittedDcr.sked_Drive__c);
            skedDrive.sked_Pending_Action__c = 'Drive Change Request';
            drivesToUpdate.add(skedDrive);
            
            Id submitterId = UserInfo.getUserId();
            submittedDcr.sked_Submitted_By__c = submitterId;
            
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setComments('Submitting change request for approval.');
            request.setObjectId(submittedDcr.Id);
            request.setSubmitterId(submitterId); 
            
            string coName = submittedDcr.sked_New_Collection_Operation__c != NULL 
                ? submittedDcr.sked_New_Collection_Operation__r.Name : skedDrive.sked_Collection_Operation__r.Name;
            
            String approvalQueueName;
            
            if (submittedDcr.sked_Route_Approval_Request_To__c == 'Request DM evaluation')  {
                request.setProcessDefinitionNameOrId('sked_DCR_DM_APS_Approval');
                approvalQueueName = coName + ': ' + skedConstants.PROFILE_QUEUE_DM_DRIVE_CHANGE_REQUESTS;
                
                submittedDcr.sked_Status__c = 'Waiting for DM Approval';
            }
            if (submittedDcr.sked_Route_Approval_Request_To__c == 'Request APS exception') {
                request.setProcessDefinitionNameOrId('sked_DCR_APS_Approval');
                approvalQueueName = coName + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS;
                
                submittedDcr.sked_Status__c = 'Waiting for APS Approval';
            }
            
            system.debug('#mapQueueByName#' + mapQueueByName);
            system.debug('#approvalQueueName#' + approvalQueueName);
            
            if (approvalQueueName != null && mapQueueByName.containsKey(approvalQueueName)) {
                Group approvalQueue = mapQueueByName.get(approvalQueueName);
                request.setNextApproverIds(new List<string> {approvalQueue.Id});
                if(hasRouteApprovalRequestChanged) {
                	approvalRequests.add(request);
                }
                recordsToUpdate.add(submittedDcr);
            }
            else {
                sked_Drive_Change_Request__c newRecord = mapSubmittedDcr.get(submittedDcr.Id);
                if (!Test.isRunningTest()) {
                    newRecord.addError(approvalQueueName + ' does not exist.');
                }
            }
        }

        if (!drivesToUpdate.isEmpty()) {
            update drivesToUpdate;
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
        
        if(!activeApprovalProcesses.isEmpty()) {
            Approval.process(activeApprovalProcesses);
        }

        if (!approvalRequests.isEmpty()) {
            Approval.process(approvalRequests);
        }
    }
    
    private void onBackToPending(List<sked_Drive_Change_Request__c> newRecords, Map<Id, sked_Drive_Change_Request__c> oldMap) {
        Set<String> nonPendingStatuses = new Set<String>{'Approved', 'Pending', 'Rejected', 'Cancelled', 'Approved by System'};
        
        Set<Id> backToPendingDcrIds = new Set<Id>();
        for (sked_Drive_Change_Request__c newRecord : newRecords) {
            sked_Drive_Change_Request__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c 
                && newRecord.sked_Status__c == 'Pending' 
                && !nonPendingStatuses.contains(oldData.sked_Status__c)) 
            {
                backToPendingDcrIds.add(newRecord.Id);
            }
        }
        
        if (!backToPendingDcrIds.isEmpty()) {
            List<sked_Drive_Change_Request_Item__c> impactedDcrItems = [SELECT Id
                                                                        FROM sked_Drive_Change_Request_Item__c
                                                                        WHERE sked_Drive_Change_Request__c IN :backToPendingDcrIds
                                                                        AND sked_Type__c = 'Impact'];
            if (!impactedDcrItems.isEmpty()) {
                delete impactedDcrItems;
            }
            
            skedFutureCallEventHandler.publishFutureCallEvent(
                slwcApprovalService.class.getName(),
                'removeWorkItems',
                backToPendingDcrIds);
        }
    }

    private void onCancelledRejected(List<sked_Drive_Change_Request__c> newRecords, Map<Id, sked_Drive_Change_Request__c> oldMap) {
        Set<Id> rejectedDriveChangeRequestIds = new Set<Id>();
        for (sked_Drive_Change_Request__c newRecord : newRecords) {
            sked_Drive_Change_Request__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED || newRecord.sked_Status__c == skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED) {
                    rejectedDriveChangeRequestIds.add(newRecord.Id);
                }
            }
        }
        if (!rejectedDriveChangeRequestIds.isEmpty()) {
            List<sked_Drive_Change_Request__c> rejectedDCRs = [SELECT Id, sked_Drive__c, sked_Opportunity_Id__c,
                                                               (SELECT Id, sked_Field_API_Name__c, sked_Field_Type__c, 
                                                                sked_Old_Value__c
                                                                FROM sked_Drive_Change_Request_Items__r
                                                                WHERE sked_Object_API_Name__c = 'Opportunity')
                                                               FROM sked_Drive_Change_Request__c
                                                               WHERE Id IN :rejectedDriveChangeRequestIds];
            Map<String, Schema.SObjectField> mapSObjectOptyField = Schema.SObjectType.Opportunity.fields.getMap();
            List<Opportunity> oppLst = new List<Opportunity>();
            Set<Id> driveIds = new Set<Id>();
            for (sked_Drive_Change_Request__c rejectedDCR : rejectedDCRs) {
                driveIds.add(rejectedDCR.sked_Drive__c);
                
                if (rejectedDCR.sked_Drive_Change_Request_Items__r != NULL && !rejectedDCR.sked_Drive_Change_Request_Items__r.isEmpty()) {
					Opportunity oppRec = new Opportunity(Id = rejectedDCR.sked_Opportunity_Id__c);
                    for (sked_Drive_Change_Request_Item__c item : rejectedDCR.sked_Drive_Change_Request_Items__r) {
                        string oppDataField = item.sked_Field_API_Name__c;
                        object fieldVal = skedUtils.getFieldValue(item.sked_Old_Value__c, item.sked_Field_Type__c);
                        
						oppRec.put(oppDataField, fieldVal);
                        
                        if (skedDriveHandler.mapReasonFields.containsKey(oppDataField)) {
                            string reasonField = skedDriveHandler.mapReasonFields.get(oppDataField);
                            string reason = 'Drive Change Requested is rejected. ' + system.now();
                            oppRec.put(reasonField, reason);
                        }
                    }
                    oppRec.Is_Recursion_On__c = TRUE;
                    oppLst.add(oppRec);
                    system.debug('#DCR oppRec# ' + oppRec);
                }
            }
            
            if (!oppLst.isEmpty()){
                opportunityService.syncOppsWithDrives(oppLst);
            }
            
            if (!driveIds.isEmpty()) {
                List<sked_Drive__c> skedDrives = [SELECT Id, sked_Pending_Action__c
                                                  FROM sked_Drive__c
                                                  WHERE Id IN :driveIds];
                List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
                for (sked_Drive__c skedDrive : skedDrives) {
                    if (skedDrive.sked_Pending_Action__c != NULL) {
                        List<string> pendingActions = skedDrive.sked_Pending_Action__c.split(';');
                        for (integer i = pendingActions.size() - 1; i >= 0; i--) {
                            string pendingAction = pendingActions.get(i);
                            if (pendingAction == skedConstants.DRIVE_PENDING_ACTION_DRIVE_CHANGE_REQUEST) {
                                pendingActions.remove(i);
                                skedDrive.sked_Pending_Action__c = string.join(pendingActions, ';');
                                drivesToUpdate.add(skedDrive);
                                break;
                            }   
                        }
                    }
                }
                if (!drivesToUpdate.isEmpty()) {
                    update drivesToUpdate;
                }
            }
        }
    }
    
    private void populateNewCollectionOperationData(List<sked_Drive_Change_Request__c> newRecords, Map<Id, sked_Drive_Change_Request__c> oldMap) {
        List<sked_Drive_Change_Request__c> recordsToPopulate = new List<sked_Drive_Change_Request__c>();
        for (sked_Drive_Change_Request__c newRecord : newRecords) {
            sked_Drive_Change_Request__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_New_Collection_Operation__c != oldData.sked_New_Collection_Operation__c && newRecord.sked_New_Collection_Operation__c != NULL) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateNewCollectionOperationData(recordsToPopulate);
        }
    }
    
    private void populateNewCollectionOperationData(List<sked_Drive_Change_Request__c> newRecords) {
        List<sked_Drive_Change_Request__c> recordsToPopulate = new List<sked_Drive_Change_Request__c>();
        Set<Id> newCoIds = new Set<Id>();
        for (sked_Drive_Change_Request__c newRecord : newRecords) {
            if (newRecord.sked_New_Collection_Operation__c != NULL) {
                newCoIds.add(newRecord.sked_New_Collection_Operation__c);
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>();
            if (!newCoIds.isEmpty()) {
                mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id,
                                                                     (SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Territory__c
                                                                      FROM sked_Territory_Collection_Operations__r)
                                                                     FROM Biomed_Collection_Op_Center__c
                                                                     WHERE Id IN :newCoIds]);
            }
            
            for (sked_Drive_Change_Request__c recordToPopulate : recordsToPopulate) {
                if (mapCO.containsKey(recordToPopulate.sked_New_Collection_Operation__c)) {
                    Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(recordToPopulate.sked_New_Collection_Operation__c);
                    
                    for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                        boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= recordToPopulate.sked_Drive_Date__c;
                        boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= recordToPopulate.sked_Drive_Date__c;
                        if (isStartDateMatched && isEndDateMatched) {
                            recordToPopulate.sked_New_District__c = territoryCO.sked_Territory__c;
                            break;
                        }
                    }
                }
            }
        }
    }

    private void createRequestToSyncOppsWithDrives(List<sked_Drive_Change_Request__c> newRecords, Map<Id, sked_Drive_Change_Request__c> oldMap) {
        Set<Id> approvedDriveChangeRequestIds = new Set<Id>();
        Set<Id> driveIds = new Set<Id>();
        for (sked_Drive_Change_Request__c newRecord : newRecords) {
            sked_Drive_Change_Request__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED) {
                    approvedDriveChangeRequestIds.add(newRecord.Id);
                    driveIds.add(newRecord.sked_Drive__c);
                }
            }
        }
        if (!approvedDriveChangeRequestIds.isEmpty()) {
            Map<Id, sked_Drive__c> mapOfDoc = new Map<Id, sked_Drive__c>([SELECT Id, sked_Drive_Date__c,sked_Status__c,sked_Start_Time__c,sked_End_Time__c,sked_Drive_Site__c,sked_Replacement_Drive__c,
                                                                        sked_Projected_Registered_Donors__c,sked_WB_Projected_Procedures__c,sked_2RBC_Projected_Procedures__c,sked_Platelet_Projected_Procedures__c,
                                                                        sked_Plasma_Projected_Procedures__c,sked_Number_of_2RBC_Assets__c,sked_Number_of_Plasma_Assets__c,sked_Number_of_Platelet_Assets__c,
                                                                        sked_Cancellation_Reason__c,sked_Opportunity__c FROM sked_Drive__c 
                                                                        WHERE Id in : driveIds]);
            List<Opportunity> oppLst = new List<Opportunity>();
            for (sked_Drive_Change_Request__c approvedDCR : [SELECT Id, sked_Drive__c, sked_Opportunity_Id__c, (SELECT Id, sked_Field_API_Name__c, sked_Field_Type__c,
                                                            sked_Old_Value__c, sked_New_Value__c FROM sked_Drive_Change_Request_Items__r 
                                                            WHERE sked_Object_API_Name__c = 'Opportunity' AND sked_Type__c = 'Change') 
                                                            FROM sked_Drive_Change_Request__c 
                                                            WHERE Id IN :approvedDriveChangeRequestIds]) {
                if (approvedDCR.sked_Drive_Change_Request_Items__r != NULL && !approvedDCR.sked_Drive_Change_Request_Items__r.isEmpty()) {
                    Opportunity oppRec = new Opportunity(Id = approvedDCR.sked_Opportunity_Id__c);
                    boolean isOpportunityNeedToUpdate = FALSE;
                    for (sked_Drive_Change_Request_Item__c item : approvedDCR.sked_Drive_Change_Request_Items__r) {
                        string getDriveFieldNameFromOppField = genDriveFieldByOppFieldMap.get(item.sked_Field_API_Name__c);
                        if(mapOfDoc.get(approvedDCR.sked_Drive__c) != null && getDriveFieldNameFromOppField != null && string.valueOf(mapOfDoc.get(approvedDCR.sked_Drive__c).get(getDriveFieldNameFromOppField)).toLowerCase() == item.sked_Old_Value__c.toLowerCase()){
                            string oppDataField = item.sked_Field_API_Name__c;
                            object fieldVal = skedUtils.getFieldValue(item.sked_Old_Value__c, item.sked_Field_Type__c);
                            oppRec.put(oppDataField, fieldVal);
                            isOpportunityNeedToUpdate = TRUE;
                            if (skedDriveHandler.mapReasonFields.containsKey(oppDataField)) {
                                string reasonField = skedDriveHandler.mapReasonFields.get(oppDataField);
                                string reason = 'Changed from Drive record. ' + system.now();
                                oppRec.put(reasonField, reason);
                            }
                            oppRec.Is_Recursion_On__c = TRUE;
                        }
                    }
                    if(isOpportunityNeedToUpdate){
                        oppLst.add(oppRec);
                    }
                }
            }
            
            if (!oppLst.isEmpty()){
                OpportunityService.syncOppsWithDrives(oppLst);
            }
        }
    }
    
    /*********************************************************** Nested Class ***********************************************************/
    public class UpdateEventDataModel {
        public string objectName;
        public List<Map<string, object>> objectFields;
    }

}