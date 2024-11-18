global class slwcApprovalService implements Callable {
    
    @AuraEnabled
    public static slwcAuraResult getApprovalHistoryList(Id recordId) {
        slwcAuraResult result = new slwcAuraResult();
        
        List<approvalItemModel> items = new  List<approvalItemModel>();
        
        List<ProcessInstanceWorkItem> workItems = [SELECT Id, Actor.Name, OriginalActor.Name, ProcessInstance.Status, ProcessInstance.TargetObjectId, CreatedDate
                                                   FROM ProcessInstanceWorkItem 
                                                   WHERE ProcessInstance.TargetObjectId = :recordId
                                                   ORDER BY CreatedDate DESC];
        for (ProcessInstanceWorkItem workItem : workItems) {
            approvalItemModel item = new approvalItemModel();
            item.id = workItem.Id;
            item.createdDate = workItem.CreatedDate;
            item.status = workItem.ProcessInstance.Status;
            item.assignedTo = workItem.Actor.Name;
            item.actualApprover = workItem.OriginalActor.Name;
            items.add(item);
        }
        
        List<ProcessInstanceStep> steps = [SELECT Id, Actor.Name, OriginalActor.Name, StepStatus, ProcessInstance.Status, ProcessInstance.TargetObjectId, 
                                           StepNodeId, Comments, CreatedDate
                                           FROM ProcessInstanceStep
                                           WHERE ProcessInstance.TargetObjectId = :recordId
                                           ORDER BY CreatedDate DESC];
        Set<Id> stepNodeIds = new Set<Id>();
        for (ProcessInstanceStep step : steps) {
            if (!string.isBlank(step.StepNodeId)) {
                stepNodeIds.add(step.StepNodeId);
            }
        }
        Map<Id, ProcessNode> mapProcessNode = new Map<Id, ProcessNode>();
        if (!stepNodeIds.isEmpty()) {
            mapProcessNode = new Map<Id, ProcessNode>([SELECT Id, Name
                                                       FROM ProcessNode
                                                       WHERE Id IN :stepNodeIds]);
        }
        
        for (ProcessInstanceStep step : steps) {
            approvalItemModel item = new approvalItemModel();
            item.id = step.Id;
            if (!string.isBlank(step.StepNodeId)) {
                ProcessNode node = mapProcessNode.get(step.StepNodeId);
                item.step = node.Name;
            }
            item.createdDate = step.CreatedDate;
            item.status = step.StepStatus;
            item.assignedTo = step.Actor.Name;
            item.actualApprover = step.OriginalActor.Name;
            item.comments = step.Comments;
            items.add(item);
        }
        result.returnedData = items;
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult getCurrentApprovalData(getCurrentApprovalDataRequestModel request) {
        slwcAuraResult result = new slwcAuraResult();
        
        List<approvalItemModel> items = new  List<approvalItemModel>();
        List<ProcessInstanceWorkItem> workItems = [SELECT Id, Actor.Name, OriginalActor.Name, ProcessInstance.Status, ProcessInstance.TargetObjectId, CreatedDate
                                                   FROM ProcessInstanceWorkitem 
                                                   WHERE ProcessInstance.targetObjectId IN :request.recordIds
                                                   AND ProcessInstance.Status = 'Pending'];
        for (ProcessInstanceWorkItem workItem : workItems) {
            approvalItemModel item = new approvalItemModel();
            item.id = workItem.Id;
            item.recordId = workItem.ProcessInstance.TargetObjectId;
            item.createdDate = workItem.CreatedDate;
            item.status = workItem.ProcessInstance.Status;
            item.assignedTo = workItem.Actor.Name;
            item.actualApprover = workItem.OriginalActor.Name;
            items.add(item);
        }
        
        result.returnedData = items;
        result.success = true;
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult approveReject(approveRejectRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        slwcAuraResult result = new slwcAuraResult();
        
        List<ProcessInstanceWorkItem> workItems = [SELECT Id, ProcessInstance.ProcessDefinition.DeveloperName
                                                   FROM ProcessInstanceWorkItem 
                                                   WHERE ProcessInstance.TargetObjectId = :request.recordId
                                                   ORDER BY CreatedDate DESC];
        
        if (!workItems.isEmpty()) {
            Id recordId = Id.valueOf(request.recordId);
            string recordObjApiName = recordId.getSobjectType().getDescribe().getName();

            if (request.sObj != NULL) {
                if (recordObjApiName == sked_Site_Feedback__c.getSobjectType().getDescribe().getName()) {
                    populateAdditionalDataForSiteFeedback(request);
                }
                update request.sObj;
            }
            
            Approval.ProcessWorkitemRequest workItemRequest = new Approval.ProcessWorkitemRequest();
            workItemRequest.setComments(request.comments);
            workItemRequest.setAction(request.action);
            workItemRequest.setWorkitemId(workItems.get(0).Id);
            
            if (recordObjApiName == sked_Site_Feedback__c.getSobjectType().getDescribe().getName()) {
                processSiteFeedbackApproval(recordId, workItemRequest, workItems[0], request);
            }
            else if (recordObjApiName == sked_Drive_Change_Request__c.getSobjectType().getDescribe().getName()) {
                processDriveChangeRequestApproval(recordId, workItemRequest, request);
            }
            else if (recordObjApiName == sked_Drive__c.getSobjectType().getDescribe().getName()) {
                processDriveApproval(recordId, workItemRequest, request);
            }
            
            Approval.ProcessResult processResult;
            processResult = Approval.process(workItemRequest);
        }
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult withdraw(withdrawRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        slwcAuraResult result = new slwcAuraResult();
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(request.recordId);
        
        List<Approval.ProcessResult> removeProcessResults = removeWorkItems(recordIds);
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult saveDesignatedApprover(saveDesignatedApproverRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        slwcAuraResult result = new slwcAuraResult();

        Id recordId = Id.valueOf(request.recordId);
        sObject sObj = recordId.getSObjectType().newSObject(recordId);
        sObj.put('sked_Designated_Approver__c', request.approverId);
        update sObj;
        
        return result;
    }

    @AuraEnabled
    public static slwcAuraResult isPendingApproval(Id recordId) {
    	slwcAuraResult result = new slwcAuraResult();
        
        boolean hasPendingApproval = FALSE;
        List<ProcessInstanceWorkItem> workItems = [SELECT Id, ActorId, ProcessInstance.Status, ProcessInstance.TargetObjectId, CreatedDate
                                                   FROM ProcessInstanceWorkItem 
                                                   WHERE ProcessInstance.TargetObjectId = :recordId
                                                   AND ProcessInstance.Status = 'Pending'];
        hasPendingApproval = !workItems.isEmpty();
        result.returnedData = hasPendingApproval;
        
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult canApprove(Id recordId) {
        slwcAuraResult result = new slwcAuraResult();
        
        boolean canApprove = false;
        Id userId = UserInfo.getUserId();
        List<ProcessInstanceWorkItem> workItems = [SELECT Id, ActorId, ProcessInstance.Status, ProcessInstance.TargetObjectId, CreatedDate
                                                   FROM ProcessInstanceWorkItem 
                                                   WHERE ProcessInstance.TargetObjectId = :recordId
                                                   AND ProcessInstance.Status = 'Pending'];
        if (!workItems.isEmpty()) {
            Set<Id> actorIds = new Set<Id>();
            for (ProcessInstanceWorkItem workItem : workItems) {
                actorIds.add(workItem.ActorId);
                canApprove = actorIds.contains(userId);
                
                if (!canApprove) {
                    List<GroupMember> groupMembers = [SELECT GroupId
                                                      FROM GroupMember
                                                      WHERE UserOrGroupId = :userId
                                                      AND GroupId IN :actorIds
                                                      AND Group.Type = 'Queue'];
                    canApprove = !groupMembers.isEmpty();
                }
            }
        }
        
        result.returnedData = canApprove;
        return result;
    }
    
    public static List<Approval.ProcessResult> removeWorkItems(Set<Id> recordIds) {
        List<Approval.ProcessResult> results = new List<Approval.ProcessResult>();
        
        Map<Id, ProcessInstance> mapProcessInstance = New Map<Id, ProcessInstance>([SELECT Id 
                                                                                    FROM ProcessInstance 
                                                                                    WHERE TargetObjectId IN :recordIds]);
        List<ProcessInstanceWorkItem> workItems = [SELECT Id, ProcessInstance.Status
                                                   FROM ProcessInstanceWorkItem 
                                                   WHERE ProcessInstanceId IN :mapProcessInstance.keySet()];
        if (!workItems.isEmpty()) {
            List<Approval.ProcessWorkitemRequest> requestsToRemoved = new List<Approval.ProcessWorkitemRequest> ();
            for (ProcessInstanceWorkItem workItem : workItems) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setAction('Removed');
                req.setWorkitemId(workItem.Id);
                requestsToRemoved.add(req);
            }
            results = Approval.process(requestsToRemoved, true);
        }
        return results;
    }
    
    public static Group getApprovalQueue(string collectionOperationName, string queueTarget) {
        Group approvalQueue;
        string queueName = collectionOperationName + ': ' + queueTarget;
        List<Group> queueQuery = [SELECT Id, Name
                                  FROM Group
                                  WHERE Name = :queueName
                                  AND Type = :skedConstants.GROUP_TYPE_QUEUE];
        if (!queueQuery.isEmpty()) {
            approvalQueue = queueQuery.get(0);
        }
        return approvalQueue;
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private static void processSiteFeedbackApproval(Id recordId, Approval.ProcessWorkitemRequest workItemRequest, ProcessInstanceWorkItem workItem, approveRejectRequestModel request) {
        sked_Site_Feedback__c record = [SELECT Id, sked_Route_Approval_Request_To__c, sked_Status__c, sked_Site__c,
                                               sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Days_Of_Week__c, sked_Current_Submitter__c
                                        FROM sked_Site_Feedback__c
                                        WHERE Id = :recordId];
        Date effectiveStartDate = skedDateTimeUtils.getValueOrMinDate(record.sked_Effective_Start_Date__c);
        Date effectiveEndDate = skedDateTimeUtils.getValueOrMaxDate(record.sked_Effective_End_Date__c);
        sked_Site_Collection_Operation__c siteCO = [
            SELECT sked_Collection_Operation__r.Name
            FROM sked_Site_Collection_Operation__c
            WHERE sked_Site__c = :record.sked_Site__c
            AND sked_Start_Date__c <= :effectiveEndDate
            AND sked_End_Date__c >= :effectiveStartDate
            ORDER BY sked_Start_Date__c DESC
        ];
        String approvalProcessName = workItem.ProcessInstance.ProcessDefinition.DeveloperName;
        if (request.action == 'Approve') {
            String profileQueueTarget;
            if (record.sked_Route_Approval_Request_To__c == skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_CM && record.sked_Status__c == skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_CM_APPROVAL) {
                if (approvalProcessName == skedConstants.RTV_CM_DM_APS_APPROVAL_PROCESS) {
                    profileQueueTarget = skedConstants.PROFILE_QUEUE_DM_ROLE_TIME_VARIANCES;
                    record.sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_DM;
                } else if (isAffectingDriveWithAPSApprovalWindow(record)) {
                    profileQueueTarget = skedConstants.PROFILE_QUEUE_ROLE_TIME_VARIANCES;
                    record.sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_APS;
                    record.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_APS_APPROVAL;
                } else {
                    record.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_APPROVED;
                }
            } else if (record.sked_Route_Approval_Request_To__c == skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_DM && record.sked_Status__c == skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_DM_APPROVAL) {
                if (approvalProcessName == skedConstants.RTV_DM_CM_APS_APPROVAL_PROCESS) {
                    profileQueueTarget = skedConstants.PROFILE_QUEUE_CM_ROLE_TIME_VARIANCES;
                    record.sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_CM;
                } else if (isAffectingDriveWithAPSApprovalWindow(record)) {
                    profileQueueTarget = skedConstants.PROFILE_QUEUE_ROLE_TIME_VARIANCES;
                    record.sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_APS;
                    record.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_APS_APPROVAL;
                } else {
                    record.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_APPROVED;
                }
            }

            if (profileQueueTarget != null) {
                Group approvalQueue = getApprovalQueue(siteCO.sked_Collection_Operation__r.Name, profileQueueTarget);
                if (approvalQueue == null) {
                    throw new skedException('Approval Queue ' + siteCO.sked_Collection_Operation__r.Name + ': ' + profileQueueTarget + ' does not exist');
                }

                workItemRequest.setNextApproverIds(new List<string> {approvalQueue.Id});
                record.sked_Designated_Approver__c = NULL;
            }
        }
        
        update record;
    }

    private static void populateAdditionalDataForSiteFeedback(approveRejectRequestModel request) {
        Id recordId = Id.valueOf(request.recordId);
        sked_Site_Feedback__c record = [SELECT Id, sked_Route_Approval_Request_To__c, sked_Status__c, sked_Site__c,
                                               sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Days_Of_Week__c, sked_Current_Submitter__c
                                        FROM sked_Site_Feedback__c
                                        WHERE Id = :recordId];
        request.sObj.put('sked_Current_Submitter__c', UserInfo.getUserId());
    }

    private static Boolean isAffectingDriveWithAPSApprovalWindow(sked_Site_Feedback__c record) {
        List<String> execludedStatuses = new List<String> {
            skedConstants.DRIVE_STATUS_COMPLETE,
            skedConstants.DRIVE_STATUS_CANCEL
        };
        Integer apsApprovalWindow = skedSetting.instance.Admin.rtvAPSApprovalWindow;

        for (sked_Drive__c affectedDrive : [
            SELECT sked_Drive_Date__c, sked_Start_Time__c, sked_Timezone__c
            FROM sked_Drive__c
            WHERE sked_Drive_Site__c = :record.sked_Site__c
            AND sked_Drive_Date__c >= TODAY
            AND sked_Drive_Date__c <= :System.today().addDays(apsApprovalWindow)
            AND sked_Drive_Date__c >= :record.sked_Effective_Start_Date__c
            AND sked_Drive_Date__c <= :record.sked_Effective_End_Date__c
            AND sked_Status__c NOT IN :execludedStatuses
        ]) {
            DateTime driveDate = DateTime.newInstance(affectedDrive.sked_Drive_Date__c, affectedDrive.sked_Start_Time__c);
            driveDate = skedDateTimeUtils.toTimezone(driveDate, affectedDrive.sked_Timezone__c);
            string driveWeekday = driveDate.format('EEEE');
            if (record.sked_Days_of_Week__c != NULL && record.sked_Days_of_Week__c.contains(driveWeekday)) {
                return true;
            }
        }

        return false;
    }
    
    private static void processDriveChangeRequestApproval(Id recordId, Approval.ProcessWorkitemRequest workItemRequest, approveRejectRequestModel request) {
        sked_Drive_Change_Request__c record = [SELECT Id, sked_Route_Approval_Request_To__c, sked_Status__c,
                                               sked_Drive__r.sked_Collection_Operation__r.Name, sked_New_Collection_Operation__r.Name,
                                               sked_Designated_Approver__c
                                               FROM sked_Drive_Change_Request__c
                                               WHERE Id = :recordId];
        if (request.action == 'Approve') {
            if (record.sked_Route_Approval_Request_To__c == 'Request DM evaluation' && record.sked_Status__c == 'Waiting for DM Approval') {
                string coName = record.sked_New_Collection_Operation__c != NULL 
                    ? record.sked_New_Collection_Operation__r.Name : record.sked_Drive__r.sked_Collection_Operation__r.Name;
                Group approvalQueue = getApprovalQueue(coName, skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS);
                workItemRequest.setNextApproverIds(new List<string> {approvalQueue.Id});
                
                record.sked_Designated_Approver__c = NULL;
            }
        }
        else if (request.action == 'Reject') {
            record.sked_Comments__c = request.comments;
        }
        
        update record;
    }
    
    private static void processDriveApproval(Id recordId, Approval.ProcessWorkitemRequest workItemRequest, approveRejectRequestModel request) {
        sked_Drive__c record = [SELECT Id, sked_Route_Approval_Request_To__c, sked_Approval_Status__c,
                                sked_Pending_Action__c, sked_Collection_Operation__r.Name,
                                sked_Designated_Approver__c
                                FROM sked_Drive__c
                                WHERE Id = :recordId];
        if (request.action == 'Approve') {
            if (record.sked_Pending_Action__c == skedConstants.DRIVE_PENDING_ACTION_DRIVE_SUBMISSION) {
                if (record.sked_Route_Approval_Request_To__c == 'Request DM evaluation' && record.sked_Approval_Status__c == 'Waiting for DM Approval') {
                    Group approvalQueue = getApprovalQueue(record.sked_Collection_Operation__r.Name, skedConstants.PROFILE_QUEUE_PENDING_ACTIONS);
                    workItemRequest.setNextApproverIds(new List<string> {approvalQueue.Id});
                    
                    record.sked_Designated_Approver__c = NULL;
                    update record;
                }
            }
        }
    }

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'removeWorkItems' {
                    removeWorkItems((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));

                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + slwcApprovalService.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    
    /*********************************************************** Nested Classes ***********************************************************/
    public class approvalItemModel {
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string recordId {get;set;}
        @AuraEnabled public string step {get;set;}
        @AuraEnabled public DateTime createdDate {get;set;}
        @AuraEnabled public string status {get;set;}
        @AuraEnabled public string assignedTo {get;set;}
        @AuraEnabled public string actualApprover {get;set;}
        @AuraEnabled public string comments {get;set;}
    }
    
    public class approveRejectRequestModel {
        @AuraEnabled public string action {get;set;}
        @AuraEnabled public string recordId {get;set;}
        @AuraEnabled public string comments {get;set;}
        @AuraEnabled public sObject sObj {get;set;}
        @AuraEnabled public Map<string, string> additionalFields {get;set;}
    }
    
    public class withdrawRequestModel {
        @AuraEnabled public string recordId {get;set;}
        @AuraEnabled public string comments {get;set;}
    }

    public class saveDesignatedApproverRequestModel {
        @AuraEnabled public string recordId {get;set;}
        @AuraEnabled public string approverId {get;set;}
    }
    
    public class getCurrentApprovalDataRequestModel {
        @AuraEnabled public List<string> recordIds {get;set;}
    }

}