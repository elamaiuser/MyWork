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
 *
 **********************************************************************************************************/
@isTest
public class DeleteExpiredTaxoVersionBatchTest {
    @isTest
    static void testBatchExecution() {
        // Create some test Taxonomy__c records
        List<Taxonomy__c> testRecords = new List<Taxonomy__c>();
        
        // Create records with End_Date__c in the past (to be deleted)
        for (Integer i = 0; i < 10; i++) {
            Taxonomy__c record = new Taxonomy__c(
                Version_Key__c = 1.0, 
                End_Date__c = Date.today().addDays(-1), 
                RecordTypeId = '0125c000001DoljAAC' 
            );
            testRecords.add(record);
        }
        
        for (Integer i = 0; i < 10; i++) {
            Taxonomy__c record = new Taxonomy__c(
                Version_Key__c = 2.0,
                End_Date__c = Date.today().addDays(1), 
                RecordTypeId = '0125c000001DoljAAC' 
            );
            testRecords.add(record);
        }
        
        insert testRecords;

        /* Start the batch */
        Test.startTest();
        BSF_Batch_DeleteExpiredTaxoVersionBatch batch = new BSF_Batch_DeleteExpiredTaxoVersionBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        /* End the batch */

        // Verify the deletion of records
        List<Taxonomy__c> deletedRecords = [SELECT Id FROM Taxonomy__c WHERE Id IN :testRecords];
        System.assertEquals(10, deletedRecords.size());
    }
}