global class skedOperationRecordExternalDataBatch implements System.Schedulable, Database.Batchable<sked_Operation_Record__c>,Database.Stateful {

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedOperationRecordExternalDataBatch(), 200);
    }
    
    global List<sked_Operation_Record__c> start(Database.BatchableContext BC) {
        return [SELECT Id
                FROM sked_Operation_Record__c
                WHERE sked_Drive__r.sked_Drive_Date__c = TODAY
                AND (sked_Drive_External_ID__c = NULL OR sked_Account_External_ID__c = NULL OR sked_Site_External_ID__c = NULL)];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Operation_Record__c> records) {
        Set<Id> operationRecordIds = new Set<Id>();
        for (sked_Operation_Record__c record : records) {
            operationRecordIds.add(record.Id);
        }
        
        Set<Id> oprIds = new Set<Id>();
        for (sked_Operation_Record__c record : skedOperationRecordService.populateExternalIds(operationRecordIds)){
            oprIds.add(record.Id);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        //Check whether there is any record that still not have the external ids >>> send an email
        List<sked_Operation_Record__c> anyRecordWithoutExternalIds = [SELECT Id
                                                                      FROM sked_Operation_Record__c
                                                                      WHERE sked_Drive__r.sked_Drive_Date__c = TODAY
                                                                      AND (sked_Drive_External_ID__c = NULL 
                                                                           OR sked_Account_External_ID__c = NULL 
                                                                           OR sked_Site_External_ID__c = NULL)
                                                                     LIMIT 1];
        if (!anyRecordWithoutExternalIds.isEmpty()) {
            sendEmailToSupport();
        }
    }
    
    public void sendEmailToSupport(){
        List<skedEmailService.emailModel> models = new List<skedEmailService.emailModel>();
        List<string> toList = new List<string>();
        toList.add(skedSetting.instance.Admin.bsfSupportEmail);
        
        skedEmailService.emailModel model = new skedEmailService.emailModel();
        model.templateApiName = 'sked_Missing_ExternalIds_Email';
        model.toList = toList;
        models.add(model);
        if (!models.isEmpty()) {
            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(models);
        }
    }
    
}