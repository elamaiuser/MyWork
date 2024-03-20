public class skedSiteFeedbackHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
    }
    
    public override void onAfterUpdate() {
        onStatusChanged(this.context.newRecords, (Map<Id, sked_Site_Feedback__c>)this.context.oldMap);
    }
    
    public override void onAfterInsert() {
        submittedFeedback(this.context.newRecords);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onApproved(List<sked_Site_Feedback__c> records) {
        List<sked_Role_Time_Variance__c> roleTimeVariances = new List<sked_Role_Time_Variance__c>();
        
        Date minDate, maxDate;
        Set<Id> locationIds = new Set<Id>();
        for (sked_Site_Feedback__c record : records) {
            locationIds.add(record.sked_Site__c);
            if (minDate == NULL || minDate > record.sked_Effective_Start_Date__c) {
                minDate = record.sked_Effective_Start_Date__c;
            }
            if (maxDate == NULL || maxDate < record.sked_Effective_End_Date__c) {
                maxDate = record.sked_Effective_End_Date__c;
            }
            
            sked_Role_Time_Variance__c roleTimeVariance = new sked_Role_Time_Variance__c(
                sked_Buffer_Type__c = record.sked_Buffer_Type__c,
                sked_Effective_End_Date__c = record.sked_Effective_End_Date__c,
                sked_Effective_Start_Date__c = record.sked_Effective_Start_Date__c,
                sked_Location__c = record.sked_Site__c,
                sked_Resource_Role_Group__c = record.sked_Resource_Role_Group__c,
                sked_Variance_Applies_to__c = record.sked_Variance_Applies_to__c,
                sked_Variation_Amount__c = record.sked_Amount__c,
                sked_Variation_Type__c = record.sked_Variance_Type__c
            );
            roleTimeVariances.add(roleTimeVariance);
        }
        if (!roleTimeVariances.isEmpty()) {
            insert roleTimeVariances;
        }
    }
    
    private void onStatusChanged(List<sked_Site_Feedback__c> newRecords, Map<Id, sked_Site_Feedback__c> oldMap) {
        List<sked_Site_Feedback__c> approvedRecords = new List<sked_Site_Feedback__c>();
        List<sked_Site_Feedback__c> submittedRecords = new List<sked_Site_Feedback__c>();
        for (sked_Site_Feedback__c newRecord : newRecords) {
            sked_Site_Feedback__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.SITE_FEEDBACK_STATUS_APPROVED) {
                    approvedRecords.add(newRecord);
                }
                if (newRecord.sked_Status__c == skedConstants.SITE_FEEDBACK_STATUS_SUBMITTED) {
                    submittedRecords.add(newRecord);
                }
            }
        }
        if (!approvedRecords.isEmpty()) {
            onApproved(approvedRecords);
        }
        if (!submittedRecords.isEmpty()) {
            onSubmitted(submittedRecords);
        }
    }
    
    private void onSubmitted(List<sked_Site_Feedback__c> records) {
        Map<Id, sked_Site_Feedback__c> mapInputRecord = new Map<Id, sked_Site_Feedback__c>(records);
        
        List<sked_Site_Feedback__c> skedSiteFeedbacks = [SELECT Id, sked_Drive__r.sked_Account__c, sked_Status__c,
                                                         sked_Drive__r.sked_Collection_Operation__r.sked_Collections_Manager__c,
                                                         sked_Route_Approval_Request_To__c
                                                        FROM sked_Site_Feedback__c
                                                        WHERE Id IN :records];
        Set<Id> accountIds = new Set<Id>();
        for (sked_Site_Feedback__c skedSiteFeedback : skedSiteFeedbacks) {
            accountIds.add(skedSiteFeedback.sked_Drive__r.sked_Account__c);
        }
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, (SELECT Id, UserId
                                                                       FROM AccountTeamMembers
                                                                       WHERE TeamMemberRole = 'District Manager')
                                                           FROM Account
                                                           WHERE Id IN :accountIds]);
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for (sked_Site_Feedback__c skedSiteFeedback : skedSiteFeedbacks) {
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setComments('Submitting request for Scheduler approval.');
            request.setObjectId(skedSiteFeedback.Id);
            request.setSubmitterId(UserInfo.getUserId()); 
            
            List<Id> dmUserIds = new List<Id>();
            Account account = mapAccount.get(skedSiteFeedback.sked_Drive__r.sked_Account__c);
            if (account.AccountTeamMembers != NULL && !account.AccountTeamMembers.isEmpty()) {
                dmUserIds.add(account.AccountTeamMembers.get(0).UserId);
            }
            if (skedSiteFeedback.sked_Route_Approval_Request_To__c == 'Route to CO Team Supervisor' || dmUserIds.isEmpty()) {
                List<Id> collectionsManagerIds = new List<Id>();
                collectionsManagerIds.add(skedSiteFeedback.sked_Drive__r.sked_Collection_Operation__r.sked_Collections_Manager__c);
                request.setNextApproverIds(collectionsManagerIds);
                skedSiteFeedback.sked_Status__c = 'Waiting for CO Supervisor Approval';
            }
            else {
                request.setNextApproverIds(dmUserIds); 
                skedSiteFeedback.sked_Status__c = 'Waiting for DM Approval';
            }
            request.setProcessDefinitionNameOrId('sked_RTV_Feedback_Approval');
            requests.add(request);
            
        }
        List<Approval.ProcessResult> approvalResults = Approval.process(requests);
        update skedSiteFeedbacks;
    }
    
    private void populateData(List<sked_Site_Feedback__c> records) {
        Set<Id> jobIds = new Set<Id>();
        for (sked_Site_Feedback__c record : records) {
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
    
}