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
 *
 **********************************************************************************************************/
global class BSF_Batch_DeleteExpiredTaxoVersionBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Version_Key__c,RecordtypeId,End_Date__c FROM Taxonomy__c WHERE End_Date__c < Today ORDER BY END_Date__C DESC,recordtypeId';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Taxonomy__c> scope) {
        
        delete scope;
    }
    

    global void finish(Database.BatchableContext BC) {

    }
    
    
    
}