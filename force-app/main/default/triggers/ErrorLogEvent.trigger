trigger ErrorLogEvent on Account_Portfolio_Error_Log_Event__e (after insert) {
List<BSF_Error_Log__c> logsToInsert = new List<BSF_Error_Log__c>();

    for (Account_Portfolio_Error_Log_Event__e event : Trigger.New) {
        BSF_Error_Log__c log = new BSF_Error_Log__c();
        log.Process_Name__c = event.Process_Name__c;
        log.ApexClass__c = event.ApexClass__c;
        log.Method__c = event.Method__c;
        log.Type__c = event.Type__c;
        log.Error_Description__c = event.Error_Description__c;


        logsToInsert.add(log);
    }

  Database.SaveResult[] insertResult = Database.insert(logsToInsert, false);
               
}