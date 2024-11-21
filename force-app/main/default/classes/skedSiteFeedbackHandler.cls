public class skedSiteFeedbackHandler extends skedTriggerHub implements Callable {
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW);
        populateData(this.context.newRecords);
        correctData(this.context.newRecords);
    }

    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW);
        correctData(this.context.newRecords);
    }
    
    public override void onAfterUpdate() {
        onStatusChanged(this.context.newRecords, (Map<Id, sked_Site_Feedback__c>)this.context.oldMap);
        checkToNotifyOriginalSubmitter(this.context.newRecords, (Map<Id, sked_Site_Feedback__c>)this.context.oldMap);
    }
    
    public override void onAfterInsert() {
        submittedFeedback(this.context.newRecords);
    }

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'processApprovedSiteFeedbacks' {
                    processApprovedSiteFeedbacks(
                        (List<sked_Site_Feedback__c>) JSON.deserialize((String) params.get('param1'), List<sked_Site_Feedback__c>.class)
                    );
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedBiomedCollectionOpHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    public static void processApprovedSiteFeedbacks(List<sked_Site_Feedback__c> records) {
        List<sked_Role_Time_Variance__c> roleTimeVariances = new List<sked_Role_Time_Variance__c>();
        
        for (sked_Site_Feedback__c record : records) {
            sked_Role_Time_Variance__c roleTimeVariance = new sked_Role_Time_Variance__c(
                sked_Buffer_Type__c = record.sked_Buffer_Type__c,
                sked_Effective_End_Date__c = record.sked_Effective_End_Date__c,
                sked_Effective_Start_Date__c = record.sked_Effective_Start_Date__c,
                sked_Location__c = record.sked_Site__c,
                sked_Resource_Role_Group__c = record.sked_Resource_Role_Group__c,
                sked_Variance_Applies_to__c = record.sked_Variance_Applies_to__c,
                sked_Variation_Amount__c = record.sked_Amount__c,
                sked_Variation_Type__c = record.sked_Variance_Type__c,
                sked_Variation_Type_Other__c = record.sked_Variance_Type_Other__c,
                sked_Days_Of_Week__c = record.sked_Days_Of_Week__c,
                sked_Note__c = record.sked_Reason__c,
                Id = record.sked_Role_Time_Variance__c
            );
            roleTimeVariances.add(roleTimeVariance);
        }
        if (!roleTimeVariances.isEmpty()) {
            upsert roleTimeVariances;
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onApproved(List<sked_Site_Feedback__c> records) {
        skedFutureCallEventHandler.publishFutureCallEvent(
            skedSiteFeedbackHandler.class.getName(), 
            'processApprovedSiteFeedbacks', 
            records
        );
    }

    private void onExpired(List<sked_Site_Feedback__c> records) {
        sendExpiredNotifications(records);
    }
    
    private void onStatusChanged(List<sked_Site_Feedback__c> newRecords, Map<Id, sked_Site_Feedback__c> oldMap) {
        List<sked_Site_Feedback__c> approvedRecords = new List<sked_Site_Feedback__c>();
        List<sked_Site_Feedback__c> submittedRecords = new List<sked_Site_Feedback__c>();
        List<sked_Site_Feedback__c> expiredRecords = new List<sked_Site_Feedback__c>();
        for (sked_Site_Feedback__c newRecord : newRecords) {
            sked_Site_Feedback__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.SITE_FEEDBACK_STATUS_APPROVED) {
                    approvedRecords.add(newRecord);
                }
                if (newRecord.sked_Status__c == skedConstants.SITE_FEEDBACK_STATUS_SUBMITTED) {
                    submittedRecords.add(newRecord);
                }
                if (newRecord.sked_Status__c == skedConstants.RTV_FEEDBACK_STATUS_EXPIRED) {
                    expiredRecords.add(newRecord);
                }
            }
        }
        if (!approvedRecords.isEmpty()) {
            onApproved(approvedRecords);
        }
        if (!submittedRecords.isEmpty()) {
            onSubmitted(submittedRecords);
        }
        if (!expiredRecords.isEmpty()) {
            onExpired(expiredRecords);
        }
    }

    private void sendExpiredNotifications(List<sked_Site_Feedback__c> records) {
        Set<Id> submitterIds = new Set<Id>();
        for (sked_Site_Feedback__c record : records) {
            submitterIds.add(record.CreatedById);
        }

        Map<Id, User> mapIdUser = new Map<Id, User>([
            SELECT Id, Profile.Name
            FROM User
            WHERE Id IN :submitterIds
        ]);

        List<sked_Site_Feedback__c> submittedByCMFeedbacks = new List<sked_Site_Feedback__c>();
        List<sked_site_Feedback__c> submittedByDMFeedbacks = new List<sked_Site_Feedback__c>();
        List<String> CMProfiles = new List<String>{'Collections', 'Collection Management'};
        List<String> DMProfiles = new List<String>{'DRD Manager', 'DRD Profile'};

        for (sked_Site_Feedback__c record : records) {
            User submitter = mapIdUser.get(record.CreatedById);
            if (submitter != null) {
                if (CMProfiles.contains(submitter.Profile.Name)) {
                    submittedByCMFeedbacks.add(record);
                }
                if (DMProfiles.contains(submitter.Profile.Name)) {
                    submittedByDMFeedbacks.add(record);
                }
            }
        }

        if (!submittedByCMFeedbacks.isEmpty()) {
            new skedCustomNotificationService(new List<String>{'sked_CM_RTV_Feedback_Expired'}).generateNotifications(submittedByCMFeedbacks);
        }

        if (!submittedByDMFeedbacks.isEmpty()) {
            new skedCustomNotificationService(new List<String>{'sked_DM_RTV_Feedback_Expired'}).generateNotifications(submittedByDMFeedbacks);
        }
    }

    private void checkToNotifyOriginalSubmitter(List<sked_Site_Feedback__c> newRecords, Map<Id, sked_Site_Feedback__c> oldMap) {
        List<sked_Site_Feedback__c> changedNewRecords = new List<sked_Site_Feedback__c>();
        Map<Id, sked_Site_Feedback__c> changedOldMap = new Map<Id, sked_Site_Feedback__c>();
        List<String> fieldsToCheck = new List<String> {
            'sked_Effective_Start_Date__c',
            'sked_Effective_End_Date__c',
            'sked_Buffer_Type__c',
            'sked_Variance_Type__c',
            'sked_Variance_Type_Other__c',
            'sked_Amount__c',
            'sked_Variance_Applies_to__c',
            'sked_Days_Of_Week__c',
            'sked_Resource_Role_Group__c'
        };
        for (sked_Site_Feedback__c newRecord : newRecords) {
            sked_Site_Feedback__c oldData = oldMap.get(newRecord.Id);
            if (oldData != null && newRecord.sked_Current_Submitter__c != oldData.sked_Current_Submitter__c) {
                for (String fieldToCheck : fieldsToCheck) {
                    if (newRecord.get(fieldToCheck) != oldData.get(fieldToCheck)) {
                        changedNewRecords.add(newRecord);
                        changedOldMap.put(newRecord.Id, oldData);
                        break;
                    }
                }
            }
        }
        if (!changedNewRecords.isEmpty()) {
            new skedCustomNotificationService(new List<String>{'sked_RTV_Notify_Submitter'}).generateNotifications(changedNewRecords, changedOldMap);
        }
    }
    
    private void onSubmitted(List<sked_Site_Feedback__c> newRecords) {
        Map<Id, sked_Site_Feedback__c> map_id_newRecord = new Map<Id, sked_Site_Feedback__c>(newRecords);
        Map<Id, String> map_siteFeedbackId_COName = getMapSiteFeedbackIdCOName(newRecords);
        Set<string> queueNames = new Set<string>();
        for (string coName : map_siteFeedbackId_COName.values()) {
            queueNames.add(coName + ': ' + skedConstants.PROFILE_QUEUE_CM_ROLE_TIME_VARIANCES);
            queueNames.add(coName + ': ' + skedConstants.PROFILE_QUEUE_DM_ROLE_TIME_VARIANCES);
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

        List<sked_Site_Feedback__c> skedSiteFeedbacks = [
            SELECT Id, sked_Site__c, sked_Effective_Start_Date__c, sked_Effective_End_Date__c
            FROM sked_Site_Feedback__c
            WHERE Id IN :map_id_newRecord.keySet()
        ];
        
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        Map<Id, sked_Site_Feedback__c> map_id_siteFeedbackToUpdate = new Map<Id, sked_Site_Feedback__c>();
        for (sked_Site_Feedback__c skedSiteFeedback : skedSiteFeedbacks) {
            sked_Site_Feedback__c newRecord = map_id_newRecord.get(skedSiteFeedback.Id);
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setComments('Submitting request for Role Time Variance Feedback approval.');
            request.setObjectId(newRecord.Id);
            request.setSubmitterId(UserInfo.getUserId()); 
            
            string approvalQueueName;
            if (newRecord.sked_Route_Approval_Request_To__c == skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_CM) {
                request.setProcessDefinitionNameOrId(skedConstants.RTV_CM_DM_APS_APPROVAL_PROCESS);
                approvalQueueName = map_siteFeedbackId_COName.get(newRecord.Id) + ': ' + skedConstants.PROFILE_QUEUE_CM_ROLE_TIME_VARIANCES;
                skedSiteFeedback.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_CM_APPROVAL;
            }
            else if (newRecord.sked_Route_Approval_Request_To__c == skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_DM && skedTriggerUtils.userBelongsToProfile('DRD Manager')) {
                request.setProcessDefinitionNameOrId(skedConstants.RTV_CM_APS_APPROVAL_PROCESS);
                approvalQueueName = map_siteFeedbackId_COName.get(newRecord.Id) + ': ' + skedConstants.PROFILE_QUEUE_CM_ROLE_TIME_VARIANCES;
                skedSiteFeedback.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_CM_APPROVAL;
                skedSiteFeedback.sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_CM;
            } else {
                request.setProcessDefinitionNameOrId(skedConstants.RTV_DM_CM_APS_APPROVAL_PROCESS);
                approvalQueueName = map_siteFeedbackId_COName.get(newRecord.Id) + ': ' + skedConstants.PROFILE_QUEUE_DM_ROLE_TIME_VARIANCES;
                skedSiteFeedback.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_DM_APPROVAL;
            }
            
            if (mapQueueByName.containsKey(approvalQueueName)) {
                Group approvalQueue = mapQueueByName.get(approvalQueueName);
                request.setNextApproverIds(new List<Id>{approvalQueue.Id});
                requests.add(request);

                map_id_siteFeedbackToUpdate.put(skedSiteFeedback.Id, skedSiteFeedback);
            }
            else {
                if (!Test.isRunningTest()) {
                    newRecord.addError(approvalQueueName + ' does not exist.');
                }
            }
            
        }

        skedHubBase.setBypassAllTriggers(true);
        update map_id_siteFeedbackToUpdate.values();
        skedHubBase.setBypassAllTriggers(false);

        Approval.process(requests);
    }

    private Map<Id, String> getMapSiteFeedbackIdCOName(List<sked_Site_Feedback__c> skedSiteFeedbacks) {
        Map<Id, String> map_siteFeedbackId_COName = new Map<Id, String>();
        Date minEffectiveStartDate = null;
        Date maxEffectiveEndDate = null;
        Set<Id> siteIds = new Set<Id>();
        
        for (sked_Site_Feedback__c skedSiteFeedback : skedSiteFeedbacks) {
            Date effectiveStartDate = skedDateTimeUtils.getValueOrMinDate(skedSiteFeedback.sked_Effective_Start_Date__c);
            Date effectiveEndDate = skedDateTimeUtils.getValueOrMaxDate(skedSiteFeedback.sked_Effective_End_Date__c);
            if (minEffectiveStartDate == null || effectiveStartDate < minEffectiveStartDate) {
                minEffectiveStartDate = effectiveStartDate;
            }
            if (maxEffectiveEndDate == null || effectiveEndDate > maxEffectiveEndDate) {
                maxEffectiveEndDate = effectiveEndDate;
            }

            siteIds.add(skedSiteFeedback.sked_Site__c);
        }

        Map<Id, List<sked_Site_Collection_Operation__c>> map_siteId_siteCOs = new Map<Id, List<sked_Site_Collection_Operation__c>>();
        for (sked_Site_Collection_Operation__c siteCO : [
            SELECT sked_Site__c, sked_Collection_Operation__r.Name, sked_Start_Date__c, sked_End_Date__c
            FROM sked_Site_Collection_Operation__c
            WHERE sked_Site__c IN :siteIds
            AND sked_Start_Date__c <= :maxEffectiveEndDate
            AND sked_End_Date__c >= :minEffectiveStartDate
            ORDER BY sked_Start_Date__c DESC
        ]) {
            if (!map_siteId_siteCOs.containsKey(siteCO.sked_Site__c)) {
                map_siteId_siteCOs.put(siteCO.sked_Site__c, new List<sked_Site_Collection_Operation__c>());
            }
            map_siteId_siteCOs.get(siteCO.sked_Site__c).add(siteCO);
        }

        for (sked_Site_Feedback__c skedSiteFeedback : skedSiteFeedbacks) {
            List<sked_Site_Collection_Operation__c> siteCOs = map_siteId_siteCOs.get(skedSiteFeedback.sked_Site__c);
            if (siteCOs != null) {
                for (sked_Site_Collection_Operation__c siteCO : siteCOs) {
                    Date effectiveStartDate = skedDateTimeUtils.getValueOrMinDate(skedSiteFeedback.sked_Effective_Start_Date__c);
                    Date effectiveEndDate = skedDateTimeUtils.getValueOrMaxDate(skedSiteFeedback.sked_Effective_End_Date__c);
                    if (siteCO.sked_Start_Date__c <= effectiveEndDate
                        && siteCO.sked_End_Date__c >= effectiveStartDate) {
                        map_siteFeedbackId_COName.put(skedSiteFeedback.Id, siteCO.sked_Collection_Operation__r.Name);
                        break;
                    }
                }
            }
        }

        return map_siteFeedbackId_COName;
    }
    
    private void populateData(List<sked_Site_Feedback__c> records) {
        Set<Id> jobIds = new Set<Id>();
        for (sked_Site_Feedback__c record : records) {
            record.sked_Current_Submitter__c = UserInfo.getUserId();
            if (record.sked_Job__c != NULL) {
                jobIds.add(record.sked_Job__c);
            }
        }
        if (!jobIds.isEmpty()) {
            Map<Id, sked__Job__c> mapJob = new Map<Id, sked__Job__c>([SELECT Id, sked_Drive__c
                                                                      FROM sked__Job__c
                                                                      WHERE Id IN :jobIds]);
            for (sked_Site_Feedback__c record : records) {
                if (record.sked_Drive__c == NULL) {
                    if (record.sked_Job__c != NULL) {
                        sked__Job__c skedJob = mapJob.get(record.sked_Job__c);
                        record.sked_Drive__c = skedJob.sked_Drive__c;
                    }
                }
            }
        } 
    }
    
    private void submittedFeedback(List<sked_Site_Feedback__c> newRecords) {
        List<sked_Site_Feedback__c> submittedRecords = new List<sked_Site_Feedback__c>();
        for (sked_Site_Feedback__c newRecord : newRecords) {
            if (newRecord.sked_Status__c == skedConstants.SITE_FEEDBACK_STATUS_SUBMITTED) {
                submittedRecords.add(newRecord);
            }
        }
        if (!submittedRecords.isEmpty()) {
            onSubmitted(submittedRecords);
        }
    }
    
    private void correctData(List<sked_Site_Feedback__c> records) {
        for (sked_Site_Feedback__c record : records) {
            if (record.sked_Variance_Type__c != skedConstants.ROLE_TIME_VARIANCE_VARIANCE_TYPE_OTHER) {
                record.sked_Variance_Type_Other__c = NULL;
            }
        }
    }
}