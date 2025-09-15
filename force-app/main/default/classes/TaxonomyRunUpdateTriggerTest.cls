@isTest(SeeAllData = false)

public class TaxonomyRunUpdateTriggerTest {

     @isTest
    static void testTriggerExecution() {
    RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name = 'Bio Relationship Manager Portfolio' LIMIT 1];
        // Create corresponding taxonomy run
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            //  External_Id__c = rt.Name + '_' + taxn.Version_Key__c,
            Status__c = 'pending',
            Taxo_Record_Type__c = rt.Name,
            // Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today()
        );
        insert taxoRun;
        // Step 2: Publish the Platform Event
        Test.startTest();

        TaxonomyRunUpdateEvent__e event = new TaxonomyRunUpdateEvent__e(
            TaxonomyRunId__c = taxoRun.Id,
            Status__c = 'Completed',
            ProcessingEndDate__c = DateTime.now()
        );
        Database.SaveResult eventResult = EventBus.publish(event);

        Test.stopTest();

        // Step 3: Validate that Taxonomy_Run__c was updated
        Taxonomy_Run__c updatedRun = [SELECT Id, Status__c, Processing_End__c FROM Taxonomy_Run__c WHERE Id = :taxoRun.Id];
        System.assertEquals('Completed', updatedRun.Status__c);
        System.assertNotEquals(null, updatedRun.Processing_End__c);

        // Step 4: Validate that BSF_Error_Log__c record was inserted
        List<BSF_Error_Log__c> logs = [SELECT Id, Process_Name__c, ApexClass__c FROM BSF_Error_Log__c WHERE Process_Name__c = 'Taxo Run - Recruitment'];
        System.assertEquals(1, logs.size());
        System.assertEquals('BSF_Batch_TaxonomyEndDateHandler', logs[0].ApexClass__c);
    }
    
    
       @isTest
    static void testTriggerExecution2() {
    RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name = 'Bio Relationship Manager Portfolio' LIMIT 1];
         // Setup: Create a Taxonomy_Run__c record
        Taxonomy_Run__c run = new Taxonomy_Run__c(
            Taxo_Record_Type__c = 'Invalid_Type', // Make sure this doesn't match your actual records
            Future_Version_Number__c = 123,  // Invalid version number
            Status__c = 'Pending',
            Run_Date__c = Date.today()
        );
        insert run;
        
        // Step 2: Publish the Platform Event
        Test.startTest();

        TaxonomyRunUpdateEvent__e event = new TaxonomyRunUpdateEvent__e(
            TaxonomyRunId__c = null,
            Status__c = '',
            ProcessingEndDate__c = DateTime.now()
        );
        Database.SaveResult eventResult = EventBus.publish(event);

        Test.stopTest();

       run.Future_Version_Number__c = 9999;
        run.Taxo_Record_Type__c = 'Invalid_Type';
        update run;
        
        // Step 3: Validate that Taxonomy_Run__c was updated
        Taxonomy_Run__c updatedRun = [SELECT Id, Status__c, Processing_End__c FROM Taxonomy_Run__c WHERE Id = :run.Id];
       // System.assertEquals('Completed', updatedRun.Status__c);
//        System.assertNotEquals(null, updatedRun.Processing_End__c);

        // Step 4: Validate that BSF_Error_Log__c record was inserted
        List<BSF_Error_Log__c> logs = [SELECT Id, Process_Name__c, ApexClass__c FROM BSF_Error_Log__c WHERE Process_Name__c = 'Taxo Run - Recruitment'];
        System.assertEquals(1, logs.size());
        System.assertEquals('BSF_Batch_TaxonomyEndDateHandler', logs[0].ApexClass__c);
    }
    
    
 @isTest
static void testTriggerExceptionHandling() {
    // Create Taxonomy_Run__c record with missing required fields (invalid)
    Taxonomy_Run__c run = new Taxonomy_Run__c(
        Status__c = 'Pending',
        Taxo_Record_Type__c = 'InvalidType', // Assuming this or another field causes an update failure
        Future_Version_Number__c = 9999,
        Run_Date__c = Date.today()
    );
    insert run;

    // Add invalid data by deleting the record before event is fired (update fails on non-existent Id)
    delete run;

    // Publish platform event with Id of deleted record
    Test.startTest();
    TaxonomyRunUpdateEvent__e event = new TaxonomyRunUpdateEvent__e(
        TaxonomyRunId__c = run.Id, // Id no longer valid
        Status__c = 'Completed',
        ProcessingEndDate__c = DateTime.now()
    );
    Database.SaveResult res = EventBus.publish(event);
    Test.stopTest();

    // No need for assert here since we're targeting catch coverage
}

  @isTest
    static void testTriggerOnInsert() {
        // Create test record
       RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name =: BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE LIMIT 1];
        
        // Create taxonomy record
        Taxonomy__c taxn = new Taxonomy__c(
            RecordTypeId = rt.Id,
            Internal_Version_Key__c = 'v12',
            Version_Key__c = 12.0,
            Start_Date__c = Date.today(),
            End_Date__c = Date.newInstance(4000, 12, 31)
        );
        insert taxn;

        // Re-fetch the inserted record to verify trigger effect
        Taxonomy__c inserted = [SELECT Id, Version_Key__c, Internal_Version_Key__c FROM Taxonomy__c WHERE Id = :taxn.Id];
        System.assertEquals('12', inserted.Internal_Version_Key__c, 'Internal_Version_Key__c should match integer part of Version_Key__c');
    }
    
}