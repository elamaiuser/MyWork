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
* Date         Author                 Description                              Covering Class Name
* 10/17/23     Ankit Kundu         The batch implemented based on HRP-10998.   BSF_Batch_DeleteExpiredTaxoVersionBatch.apxc
*04/29/25      Harika Bolisetti    The batch implemented based on HRP-14313.   BSF_Batch_DeleteExpiredTaxoVersionBatch.apxc
**********************************************************************************************************/
@isTest(SeeAllData = false)
public class DeleteExpiredTaxoVersionBatchTest {
    @testSetup
    public static void prepareDataSetup() {
        
        // Setup: insert required Taxonomy__c record
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' LIMIT 1];
        
        Taxonomy__c taxn = new Taxonomy__c();
        taxn.Version_Key__c = 1.0;
        taxn.End_Date__c = Date.today().addDays(-5);
        //taxn.End_Date__c = 31-09-009;
        taxn.RecordTypeId = rt.Id;
        insert taxn;
     
        // Insert corresponding Taxonomy_Run__c record to match in finish()
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            
            External_Id__c = rt.Name + '_' + taxn.Version_Key__c,  // Matching the version key
            Status__c = 'Completed',
            Future_Version_Number__c = taxn.Version_Key__c
        );
        insert taxoRun;
        system.debug(' Future_Version_Number__c'+ taxoRun.External_Id__c);
        // Now simulate existing record update
        taxoRun.Status__c = 'Deleted';  // Setting up initial value to test if it gets updated in batch
        update taxoRun;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        BSF_Batch_DeleteExpiredTaxoVersionBatch batch = new BSF_Batch_DeleteExpiredTaxoVersionBatch();
        Database.executeBatch(batch, 200);
        // Execute start and execute methods
        Database.QueryLocator ql = batch.start(null);
        List<Taxonomy__c> scope = [SELECT Id, Version_Key__c, RecordType.Name, RecordTypeId, End_Date__c FROM Taxonomy__c];
        batch.execute(null, scope);
        
        // Execute start and execute methods
        
        Taxonomy_Run__c insertedRun = [SELECT Id, External_Id__c FROM Taxonomy_Run__c LIMIT 1];
        batch.externalIdSet = new Set<String>{ insertedRun.External_Id__c };
            // Call finish
            batch.finish(null);
        
        // Setup
        BSF_Batch_DeleteExpiredTaxoVersionBatch batch1 = new BSF_Batch_DeleteExpiredTaxoVersionBatch();
        // Force updateStatus to remain null/empty but still enter the try block
        batch1.externalIdSet = new Set<String>{''};
            batch1.finish(null);
        Test.stopTest();
        
        
        //Test.stopTest();
    }
    
    
    
    @isTest
    static void testExecuteMethodWithExceptions() {
        // Create test data
        List<Taxonomy__c> scope = new List<Taxonomy__c>();
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' LIMIT 1];
        
        // Add valid record
        Taxonomy__c validTaxo = new Taxonomy__c(RecordTypeId = rt.Id, Version_Key__c = -009);
        scope.add(validTaxo);
        
        // Add invalid record (null RecordType and Version_Key__c)
        Taxonomy__c invalidTaxo = new Taxonomy__c(RecordTypeId = rt.Id, Version_Key__c = null);
        scope.add(invalidTaxo);
        
        Test.startTest();
        
        // Simulate the execute method
        BSF_Batch_DeleteExpiredTaxoVersionBatch batch = new BSF_Batch_DeleteExpiredTaxoVersionBatch();
        batch.execute(null, scope);  // Call the execute method with mock data
        
        Test.stopTest();
    }
    
   /* @isTest
    static void testStartMethodCatchesException() {
        
        Test.startTest();
        
        Taxonomy_Run_Config__mdt metadataRecord = Taxonomy_Run_Config__mdt.getInstance('null');     
        // Create the batch instance
        BSF_Batch_DeleteExpiredTaxoVersionBatch batch = new BSF_Batch_DeleteExpiredTaxoVersionBatch();
        Taxonomy__c taxo = new Taxonomy__c(
            End_Date__c = Date.today().addDays(-9999) // Way in past to match expiration
        );
        // Bypass recordtype logic by assigning directly (not needed if query fails otherwise)
        insert taxo;
        // Call the start method - we expect it to return null due to exception
        Database.QueryLocator result = batch.start(null);
        
        Test.stopTest();
        
        
    }*/
}