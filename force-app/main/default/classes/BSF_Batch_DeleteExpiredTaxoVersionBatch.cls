/***********************************************************************************************************
* 
* Description:          The batch implemented when the GOATS load should delete any/all versions in [Taxonomy__c] 
*                       with an end-date in the past,except for the most recent expired version of the taxonomy.  
*				         The most recent expired version is the taxonomy version with the most recent end-date.
*                       That is also a past date.  
* 
* 
* Modification Log:    
* --------------------------------------------------------------------------------------------------------
* Date         Author                 Description
* 10/17/23     Ankit Kundu         The batch implemented based on HRP-10998.
* 27/02/2025   Harika  Bolisetti   The batch implemented based on HRP-14313
**********************************************************************************************************/
global class BSF_Batch_DeleteExpiredTaxoVersionBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global Map<Id, List<Decimal>> recordTypeVersionMap = new Map<Id, List<Decimal>>();
    
    //Stateful Variable to store the external Id
    global Set<String> externalIdSet = new Set<String>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            //Fetch the metadata configuration records 
            // Fetch all records from Taxonomy_Run_Config__mdt
            Map<String, Taxonomy_Run_Config__mdt> configRecords = Taxonomy_Run_Config__mdt.getAll();
            Taxonomy_Run_Config__mdt configRecord;
            Integer offsetDays = 0; 
            // Iterate through the records to find the matching one
            for (Taxonomy_Run_Config__mdt record : configRecords.values()) {
                if (record.Category__c == 'Taxo Expiration Offset' && record.Is_Active__c) {
                    configRecord = record;
                    break; // Stop once the first matching record is found
                }
            }
            if (configRecord != null) {
                offsetDays = (configRecord.Taxo_Expiration_Offset__c != null) ? configRecord.Taxo_Expiration_Offset__c.intValue() : 0;
            }
            Date expirationDate = Date.today().addDays(-offsetDays);
            //Fetch Taxonomy records where endDate less than expirationDate
            String query = 'SELECT Id, Version_Key__c,RecordType.Name, RecordTypeId, End_Date__c FROM Taxonomy__c WHERE End_Date__c < :expirationDate ORDER BY End_Date__c DESC, RecordTypeId';
            return Database.getQueryLocator(query);
            
        } catch (Exception e) {  Taxo_Utilities.logErrorForException( e,'BSF_Batch_DeleteExpiredTaxoVersionBatch','Start Method', e.getMessage(),e.getMessage(),'Taxonomy__c',null,null );
        return null;
        }
    }
    global void execute(Database.BatchableContext bc, List<Taxonomy__c> scope) {
        List<Taxonomy__c> recordIdsToDelete = new List<Taxonomy__c>();   
        try {
            //Store the externalId 
            for (Taxonomy__c taxo : scope) {
                externalIdSet.add(taxo.RecordType.Name + '_' + taxo.Version_Key__c);
                recordIdsToDelete.add(taxo);
            }
            if (!recordIdsToDelete.isEmpty()) {
                Database.DeleteResult[] deleteResults = Database.delete(recordIdsToDelete, false);
                Taxo_Utilities.logErrorsDeletion(deleteResults, 'Taxonomy Run', 'BSF_Batch_DeleteExpiredTaxoVersionBatch', 'Execute', 'Error', 'Error occurred while deleting the Taxonomy Run Record');
            }  
        } catch (Exception e) {
            Taxo_Utilities.logErrorForException( e, 'BSF_Batch_DeleteExpiredTaxoVersionBatch', 'Execute Method',e.getMessage(),e.getMessage(),'Taxonomy_Run__c', null,null);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
        List<Taxonomy_Run__c> updateStatus = new List<Taxonomy_Run__c>();
        try {
            // Updates Status of Corresponding Taxo version Entries in Taxo Run Object to Deleted if avaliable.
            if (externalIdSet != null && !externalIdSet.isEmpty()) {
                for (Taxonomy_Run__c taxo : [ SELECT Id, Deleted_On__c,External_Id__c,Taxo_Record_Type__c, Status__c, Future_Version_Number__c, Name 
                                             FROM Taxonomy_Run__c WHERE External_Id__c IN :externalIdSet]) {
                                                 
                                                 taxo.Status__c = 'Deleted';
                                                 taxo.Deleted_On__c = System.now();
                                                 updateStatus.add(taxo);
                                             }
                if (!updateStatus.isEmpty()) {
                    Database.SaveResult[] statusResults = Database.update(updateStatus, false);
                    Taxo_Utilities.logErrors(statusResults, 'Taxonomy Run', 'BSF_Batch_DeleteExpiredTaxoVersionBatch', 'Finish', 'Error', 'Error occurred while updating the status of the Taxonomy Record',
                                             updateStatus[0].Taxo_Record_Type__c,updateStatus[0].Future_Version_Number__c);
                } 
            }
            //Chain the taxo run batch
            if (!Test.isRunningTest()) {
                Database.executeBatch(new BSF_Batch_TaxoRunControlBatch(), 1);
            }
        } catch (Exception e) {
            Taxo_Utilities.logErrorForException( e, 'BSF_Batch_DeleteExpiredTaxoVersionBatch', 'Finish Method',e.getMessage(),e.getMessage(),'Taxonomy_Run__c', null,null);
        }
        
        
    } 
}