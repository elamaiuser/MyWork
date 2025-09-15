trigger TaxonomyRunUpdateTrigger on TaxonomyRunUpdateEvent__e (after insert) {
    List<Taxonomy_Run__c> recordsToUpdate = new List<Taxonomy_Run__c>();
    for (TaxonomyRunUpdateEvent__e event : Trigger.new) {
        Taxonomy_Run__c txr = new Taxonomy_Run__c();
        txr.Id = event.TaxonomyRunId__c;
        txr.Status__c = event.Status__c;
        
        if (event.ProcessingEndDate__c != null) {
            txr.Processing_End__c = event.ProcessingEndDate__c;
        }
        recordsToUpdate.add(txr);
    }
    if (!recordsToUpdate.isEmpty()) {
        
        Database.SaveResult[] updateResults = Database.update(recordsToUpdate, false);
        Taxo_Utilities.logErrors(updateResults, 'Taxonomy Run', 'TaxonomyRunUpdateTrigger', 'Execute', 'Error',
                                 'Error occurred while updating the Taxonomy Run Record',recordsToUpdate[0].Taxo_Record_Type__c, recordsToUpdate[0].Future_Version_Number__c);
    }
        
    List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
    BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Recruitment',ApexClass__c='BSF_Batch_TaxonomyEndDateHandler',Method__c='finish',Type__c='Success',
                                                     Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
    errorLogList.add(errorLog);
    // insert errorLog;
    Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
    Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_TaxonomyEndDateHandler','Finish','Error',
                             'Error occurred while inserting the error Record',null,null);
    
}