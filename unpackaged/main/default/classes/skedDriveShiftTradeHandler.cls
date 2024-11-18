public class skedDriveShiftTradeHandler extends skedTriggerHub {
	
    public override void onBeforeInsert() {
        populateTradeDetails(this.context.newRecords);
        cancelDuplicateTrades(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        populateTradeDetails(this.context.newRecords, (Map<Id, sked_Drive_Shift_Trade__c>)this.context.oldMap);
        populateData(this.context.newRecords, (Map<Id, sked_Drive_Shift_Trade__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        onStatusChanged(this.context.newRecords, (Map<Id, sked_Drive_Shift_Trade__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void cancelDuplicateTrades(List<sked_Drive_Shift_Trade__c> newRecords) {
        List<string> uniqueKeys = new List<string>();
        for (sked_Drive_Shift_Trade__c newRecord : newRecords) {
            uniqueKeys.add(newRecord.sked_UniqueKey__c);
        }
        
        List<sked_Drive_Shift_Trade__c> duplicateTrades = [SELECT Id, sked_Status__c, sked_Denied_Reason__c
                                                           FROM sked_Drive_Shift_Trade__c
                                                           WHERE sked_UniqueKey__c IN :uniqueKeys
                                                           AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED
                                                           AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED];
        if (!duplicateTrades.isEmpty()) {
            for (sked_Drive_Shift_Trade__c duplicateTrade : duplicateTrades) {
                duplicateTrade.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED;
                duplicateTrade.sked_Denied_Reason__c = skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_CANCELLED;
            }
            update duplicateTrades;
        }
    }
    
    private void onStatusChanged(List<sked_Drive_Shift_Trade__c> newRecords, Map<Id, sked_Drive_Shift_Trade__c> oldMap) {
        Set<Id> approvedRecordIds = new Set<Id>();
        List<sked_Drive_Shift_Trade__c> pendingApprovalRecords = new List<sked_Drive_Shift_Trade__c>();
        List<sked_Drive_Shift_Trade__c> submittedRecords = new List<sked_Drive_Shift_Trade__c>();
        for (sked_Drive_Shift_Trade__c newRecord : newRecords) {
            if (newRecord.sked_Auto_process_Complete__c) {
                sked_Drive_Shift_Trade__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                    if (newRecord.sked_Status__c == skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED) {
                        approvedRecordIds.add(newRecord.Id);
                    }
                    else if (newRecord.sked_Status__c == skedConstants.DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL) {
                        pendingApprovalRecords.add(newRecord);
                    }
                }
            }
        }
        if (!approvedRecordIds.isEmpty()) {
            performShiftTrades(approvedRecordIds);
            createShiftTradeAPIData(approvedRecordIds);
        }
        if (!pendingApprovalRecords.isEmpty()) {
            onPendingApproval(pendingApprovalRecords);
        }
    }

    private void createShiftTradeAPIData(Set<Id> recordIds) {
        skedFutureCallEventHandler.publishFutureCallEvent(
            'slwcDriveShiftTradeService',
            'createShiftTradeAPIData',
            recordIds,
            UserInfo.getUserEmail()
        );
    }
    
    private void performShiftTrades(Set<Id> recordIds) {
        skedFutureCallEventHandler.publishFutureCallEvent(
                'slwcDriveShiftTradeService',
                'performShiftTrades',
                recordIds);
    }
    
    private void onPendingApproval(List<sked_Drive_Shift_Trade__c> records) {
        List<sked_Drive_Shift_Trade__c> driveShiftTrades = [SELECT Id, sked_Collection_Operation__r.Name
                                                            FROM sked_Drive_Shift_Trade__c
                                                            WHERE Id IN :records];
        Set<string> queueNames = new Set<string>();
        for (sked_Drive_Shift_Trade__c driveShiftTrade : driveShiftTrades) {
            queueNames.add(driveShiftTrade.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_SHIFT_TRADES);
        }
        List<Group> approvalQueues = [SELECT Id, Name
                                      FROM Group
                                      WHERE Name IN :queueNames
                                      AND Type = :skedConstants.GROUP_TYPE_QUEUE];
        Map<string, Group> mapQueueByName = new Map<string, Group>();
        for (Group approvalQueue : approvalQueues) {
            mapQueueByName.put(approvalQueue.Name, approvalQueue);
        }
        
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for (sked_Drive_Shift_Trade__c driveShiftTrade : driveShiftTrades) {
            string approvalQueueName = driveShiftTrade.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_SHIFT_TRADES;
            if (mapQueueByName.containsKey(approvalQueueName)) {
                Group approvalQueue = mapQueueByName.get(approvalQueueName);
                
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setComments('Submitting request for Scheduler approval.');
                request.setObjectId(driveShiftTrade.Id);
                request.setSubmitterId(UserInfo.getUserId());
                request.setNextApproverIds(new List<string> {approvalQueue.Id});
                request.setProcessDefinitionNameOrId('sked_Drive_Shift_Trade_Approval');
                requests.add(request);
            }
        }
        if (!requests.isEmpty()) {
            Approval.process(requests);
        }
    }
    
    private void populateTradeDetails(List<sked_Drive_Shift_Trade__c> records) {
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> jobAllocationIds = new Set<Id>();
        Set<Id> activityIds = new Set<Id>();
        for (sked_Drive_Shift_Trade__c record : records) {
            resourceIds.add(record.sked_Requesting_Staff__c);
            resourceIds.add(record.sked_Trading_Staff__c);
            
            if (record.sked_Requesting_Staff_Job_Allocation__c != NULL) {
                jobAllocationIds.add(record.sked_Requesting_Staff_Job_Allocation__c);
            }
            if (record.sked_Trading_Staff_Job_Allocation__c != NULL) {
                jobAllocationIds.add(record.sked_Trading_Staff_Job_Allocation__c);
            }
            
            if (record.sked_Requesting_Staff_NCE__c != NULL) {
                activityIds.add(record.sked_Requesting_Staff_NCE__c);
            }
            if (record.sked_Trading_Staff_NCE__c != NULL) {
                activityIds.add(record.sked_Trading_Staff_NCE__c);
            }
        }
        Map<Id, sked__Job_Allocation__c> mapAllocation = new Map<Id, sked__Job_Allocation__c>();
        if (!jobAllocationIds.isEmpty()) {
            mapAllocation = new Map<Id, sked__Job_Allocation__c>([SELECT Id, sked__Job__c, sked__Resource__c, sked_Resource_Role__c,
                                                                  sked__Job__r.sked_Drive_Shift__c, 
                                                                  sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive__r.Name,
                                                                  sked__Job__r.sked_Drive__r.sked_District__c,
                                                                  sked__Job__r.sked_Drive__r.sked_Collection_Operation__c,
                                                                  sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_Timezone__c,
                                                                  sked__Job__r.sked_Drive__r.sked_UFID__c,
                                                                  sked__Job__r.sked_Drive__r.sked_Drive_Date__c
                                                                  FROM sked__Job_Allocation__c
                                                                  WHERE Id IN :jobAllocationIds]);
        }
        Map<Id, sked__Activity__c> mapActivity = new Map<Id, sked__Activity__c>();
        if (!activityIds.isEmpty()) {
            mapActivity = new Map<Id, sked__Activity__c>([SELECT Id, sked_District__c, sked_Collection_Operation__c
                                                          FROM sked__Activity__c
                                                          WHERE Id IN :activityIds]);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                                                                 sked_Timezone__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        
        List<sked_Drive_Shift_Trade__c> recordsDistrictFromRequestingStaffCO = new List<sked_Drive_Shift_Trade__c>();
        for (sked_Drive_Shift_Trade__c record : records) {
            if (mapAllocation.containsKey(record.sked_Requesting_Staff_Job_Allocation__c)) {
                sked__Job_Allocation__c requestingStaffJobAllocation = mapAllocation.get(record.sked_Requesting_Staff_Job_Allocation__c);
                record.sked_District__c = requestingStaffJobAllocation.sked__Job__r.sked_Drive__r.sked_District__c;
                record.sked_Collection_Operation__c = requestingStaffJobAllocation.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c;
                record.sked_Requesting_Staff__c = requestingStaffJobAllocation.sked__Resource__c;
                record.sked_Requesting_Staff_Drive__c = requestingStaffJobAllocation.sked__Job__r.sked_Drive__c;
                record.sked_Requesting_Staff_Drive_Shift__c = requestingStaffJobAllocation.sked__Job__r.sked_Drive_Shift__c;
                record.sked_Requesting_Staff_Drive_Date__c = requestingStaffJobAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
                record.sked_Requesting_Staff_Drive_Name__c = requestingStaffJobAllocation.sked__Job__r.sked_Drive__r.Name;
                record.sked_Requesting_Staff_Job__c = requestingStaffJobAllocation.sked__Job__c;
                record.sked_Requesting_Staff_Role_on_Drive__c = requestingStaffJobAllocation.sked_Resource_Role__c;
            }
            if (mapAllocation.containsKey(record.sked_Trading_Staff_Job_Allocation__c)) {
                sked__Job_Allocation__c tradingStaffJobAllocation = mapAllocation.get(record.sked_Trading_Staff_Job_Allocation__c);
                record.sked_Trading_Staff__c = tradingStaffJobAllocation.sked__Resource__c;
                record.sked_Trading_Staff_Drive__c = tradingStaffJobAllocation.sked__Job__r.sked_Drive__c;
                record.sked_Trading_Staff_Drive_Shift__c = tradingStaffJobAllocation.sked__Job__r.sked_Drive_Shift__c;
                record.sked_Trading_Staff_Drive_Date__c = tradingStaffJobAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
                record.sked_Trading_Staff_Drive_Name__c = tradingStaffJobAllocation.sked__Job__r.sked_Drive__r.Name;
                record.sked_Trading_Staff_Job__c = tradingStaffJobAllocation.sked__Job__c;
                record.sked_Trading_Staff_Role_on_Drive__c = tradingStaffJobAllocation.sked_Resource_Role__c;
            }
            if (mapActivity.containsKey(record.sked_Requesting_Staff_NCE__c)) {
                sked__Activity__c tradingStaffNce = mapActivity.get(record.sked_Requesting_Staff_NCE__c);
                record.sked_District__c = tradingStaffNce.sked_District__c;
                record.sked_Collection_Operation__c = tradingStaffNce.sked_Collection_Operation__c;
            }
            if (record.sked_Collection_Operation__c == NULL) {
                if (mapResource.containsKey(record.sked_Requesting_Staff__c)) {
                    sked__Resource__c requestingStaff = mapResource.get(record.sked_Requesting_Staff__c);
                    record.sked_Collection_Operation__c = requestingStaff.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
                    recordsDistrictFromRequestingStaffCO.add(record);
                }
            }

            populateDistrictFromRequestingStaffCO(recordsDistrictFromRequestingStaffCO, mapResource);

            string requestingRecordId;
            if (record.sked_Requesting_Staff_Trading_Type__c == 'Drive Shift') {
                requestingRecordId = record.sked_Requesting_Staff_Job_Allocation__c;
            }
            else if (record.sked_Requesting_Staff_Trading_Type__c == 'Activity') {
                requestingRecordId = record.sked_Requesting_Staff_NCE__c;
            }
            
            string tradingRecordId;
            if (record.sked_Trading_Staff_Trading_Type__c == 'Drive Shift') {
                tradingRecordId = record.sked_Trading_Staff_Job_Allocation__c;
            }
            else if (record.sked_Trading_Staff_Trading_Type__c == 'Activity') {
                tradingRecordId = record.sked_Trading_Staff_NCE__c;
            }
            record.sked_UniqueKey__c = requestingRecordId + ':' + tradingRecordId;
            
            string timezoneSidId = UserInfo.getTimeZone().getID();
            if (mapResource.containsKey(record.sked_Requesting_Staff__c)) {
                sked__Resource__c requestingStaff = mapResource.get(record.sked_Requesting_Staff__c);
                timezoneSidId = !string.isBlank(requestingStaff.sked_Timezone__c) ? requestingStaff.sked_Timezone__c : timezoneSidId;
            }
            if (record.sked_Date_Trade_Approved__c != NULL) {
                record.sked_Date_Trade_Approved_Text__c = record.sked_Date_Trade_Approved__c.format(skedDateTimeUtils.DATE_FORMAT, timezoneSidId);
            }
            record.sked_Date_Trade_Submitted_Text__c = system.now().format(skedDateTimeUtils.DATE_FORMAT, timezoneSidId);
        }
    }

    private void populateTradeDetails(List<sked_Drive_Shift_Trade__c> newRecords, Map<Id, sked_Drive_Shift_Trade__c> oldMap) {
        List<sked_Drive_Shift_Trade__c> recordsToPopulate = new List<sked_Drive_Shift_Trade__c>();
        for (sked_Drive_Shift_Trade__c newRecord : newRecords) {
            sked_Drive_Shift_Trade__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Trading_Staff__c != oldData.sked_Trading_Staff__c && newRecord.sked_Trading_Staff__c != NULL) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateTradeDetails(recordsToPopulate);
        }
    }

    private void populateDistrictFromRequestingStaffCO(List<sked_Drive_Shift_Trade__c> records, Map<Id, sked__Resource__c> mapResource) {
        Set<Id> requestingStaffCOIds = new Set<Id>();
        for (sked_Drive_Shift_Trade__c record : records) {
            requestingStaffCOIds.add(mapResource.get(record.sked_Requesting_Staff__c).sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c);
        }

        Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([
            SELECT Id,
                (SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Territory__c
            FROM sked_Territory_Collection_Operations__r)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id IN :requestingStaffCOIds
        ]);

        for (sked_Drive_Shift_Trade__c record : records) {
            Id requestingStaffCOId = mapResource.get(record.sked_Requesting_Staff__c).sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
            if (mapCO.containsKey(requestingStaffCOId)) {
                Biomed_Collection_Op_Center__c co = mapCO.get(requestingStaffCOId);
                for (sked_Territory_Collection_Operation__c territoryCO : co.sked_Territory_Collection_Operations__r) {
                    boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= record.sked_Requesting_Staff_Trading_Event_Date__c;
                    boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= record.sked_Requesting_Staff_Trading_Event_Date__c;
                    if (isStartDateMatched && isEndDateMatched) {
                        record.sked_District__c = territoryCO.sked_Territory__c;
                        break;
                    }
                }
            }
        }
    }
    
    private void populateData(List<sked_Drive_Shift_Trade__c> newRecords, Map<Id, sked_Drive_Shift_Trade__c> oldMap) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked_Drive_Shift_Trade__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked_Requesting_Staff__c);
        }
        
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                                                                 sked_Timezone__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        
        Map<string, string> map_deniedReason_apsNotes = new Map<string, string>();
        map_deniedReason_apsNotes.put(skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_CUTOFF_DAYS, 'Your Trade Request has been denied due to Drive Date falls outside the cutoff period for Shift Trades.');
        map_deniedReason_apsNotes.put(skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_HOURS, 'Your Trade Request has been denied due to a difference in drive assignment hours.');
        map_deniedReason_apsNotes.put(skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_ROLE, 'Your Trade Request has been denied due to a difference in role for drive assignments.');
        map_deniedReason_apsNotes.put(skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_TRAVEL_DISTANCE, 'Your Trade Request has been denied due to a difference in drive assignment travel distance.');
        map_deniedReason_apsNotes.put(skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_CANCELLED, 'Your Trade Request has been cancelled per your request.');
        
        for (sked_Drive_Shift_Trade__c newRecord : newRecords) {
            sked_Drive_Shift_Trade__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Denied_Reason__c != oldData.sked_Denied_Reason__c) {
                newRecord.sked_APS_Notes__c = map_deniedReason_apsNotes.get(newRecord.sked_Denied_Reason__c);
            }
            if (newRecord.sked_Reason_Approval_Required__c != oldData.sked_Reason_Approval_Required__c) {
                newRecord.sked_TAT_Time_Traded_Into_Requester__c = newRecord.sked_Reason_Approval_Required__c.contains(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION);
                newRecord.sked_TAT_Time_Traded_Into_Trading__c = newRecord.sked_Reason_Approval_Required__c.contains(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_TAT_CONTENTION);
            }
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED || newRecord.sked_Status__c == skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED) {
                    newRecord.sked_Date_Trade_Approved__c = system.now();
                }
            }
            
            if (newRecord.sked_Date_Trade_Approved__c != oldData.sked_Date_Trade_Approved__c) {
                newRecord.sked_Date_Trade_Approved_Text__c = NULL;
                if (newRecord.sked_Date_Trade_Approved__c != NULL) {
                    string timezoneSidId = UserInfo.getTimeZone().getID();
                    if (mapResource.containsKey(newRecord.sked_Requesting_Staff__c)) {
                        sked__Resource__c requestingStaff = mapResource.get(newRecord.sked_Requesting_Staff__c);
                        timezoneSidId = !string.isBlank(requestingStaff.sked_Timezone__c) ? requestingStaff.sked_Timezone__c : timezoneSidId;
                    }
                    newRecord.sked_Date_Trade_Approved_Text__c = newRecord.sked_Date_Trade_Approved__c.format(skedDateTimeUtils.DATE_FORMAT, timezoneSidId);
                }
            }
        }
    }
    
}