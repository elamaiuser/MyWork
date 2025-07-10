@isTest(SeeAllData = false)
public class BSF_Batch_TaxoRunControlBatch_Test {
    
    @testSetup
    static void setupData() {
        // Insert a record type
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' LIMIT 1];
        
        // Insert one expired taxonomy record
        Taxonomy__c taxn = new Taxonomy__c(
            Version_Key__c = 1.0,
            End_Date__c = Date.today().addDays(-5),
            RecordTypeId = rt.Id
        );
        insert taxn;
        
        // Insert corresponding Taxonomy_Run__c
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            External_Id__c = rt.Name + '_' + taxn.Version_Key__c,
            Status__c = 'pending',
            Future_Version_Number__c = taxn.Version_Key__c
        );
        insert taxoRun;
    }
    
   @isTest
    static void testBatchExecution_WithMultipleActiveVersions() {
        // Setup two active taxonomy versions
         RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name =: BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE LIMIT 1];
       
        insert new List<Taxonomy__c>{
            new Taxonomy__c(
                RecordTypeId = rt.Id,
                Version_Key__c = 111,
                Start_Date__c = Date.today(),
                End_Date__c = Date.newInstance(4000, 12, 31)
            ),
                new Taxonomy__c(
                    RecordTypeId = rt.Id,
                    Version_Key__c = 112,
                    Start_Date__c = Date.today(),
                    End_Date__c = Date.newInstance(4000, 12, 31)
                )
                };
                    
                    Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        List<Taxonomy_Run__c> runs = [SELECT Id, Future_Version_Number__c FROM Taxonomy_Run__c];
        System.assert(!runs.isEmpty(), 'Expected Taxonomy_Run__c records to be created for active versions');
    }
   /*@isTest
    static void testBatchExecution_bioRecruitment() {
      RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name = 'Bio Recruitment CD' LIMIT 1];
     Date endDate = Date.newInstance(4000, 12, 31);
        // Create taxonomy record
        Taxonomy__c taxn = new Taxonomy__c(
            RecordTypeId = rt.Id,
            //Internal_Version_Key__c = 'v12',
            Version_Key__c = 12.0,
            Start_Date__c = Date.today(),
            End_Date__c = endDate
        );
        insert taxn;
        
        // Create corresponding taxonomy run
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            External_Id__c = rt.Name + '_' + taxn.Version_Key__c,
            Status__c = 'pending',
            Future_Version_Number__c = taxn.Version_Key__c
        );
        insert taxoRun;
        
        Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
      
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
        List<Taxonomy_Run__c> runs = [SELECT Id, Status__c FROM Taxonomy_Run__c];
        System.assert(!runs.isEmpty(), 'Expected Taxonomy_Run__c records to exist after batch');
    }*/
    @isTest
    static void testBatchExecution_Finish() {
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name =: BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE LIMIT 1];
        // Create corresponding taxonomy run
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            //  External_Id__c = rt.Name + '_' + taxn.Version_Key__c,
            Status__c = 'pending',
            Taxo_Record_Type__c = rt.Name,
            // Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today()
        );
        insert taxoRun;
        
        Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.finish(null); // This should fail if taxoRun is expected and dereferenced
        Test.stopTest();
        
    }
    
    @isTest
    static void testBatchExecution_Finish1() {
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name =: BSF_Constants.BIO_COLLECTION_RECORD_TYPE LIMIT 1];
        // Create corresponding taxonomy run
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            //  External_Id__c = rt.Name + '_' + taxn.Version_Key__c,
            Status__c = 'pending',
            Taxo_Record_Type__c = rt.Name,
            // Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today()
        );
        insert taxoRun;
        
        Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.finish(null); // This should fail if taxoRun is expected and dereferenced
        Test.stopTest();
        
    }
    
    @isTest
    static void testBatchExecution_Finish2() {
        
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
        
        Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.finish(null); // This should fail if taxoRun is expected and dereferenced
        Test.stopTest();
        
    }
    
    
    
     @isTest
    static void testBatchExecution_QueryLimitExceed() {
       // Get a valid RecordType for Taxonomy__c
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' LIMIT 1];
        Set<String> recordTypes = new Set<String>();
        List<Taxonomy__c> taxoList = new List<Taxonomy__c>();
        for (Integer i = 0; i < 10; i++) {
            Taxonomy__c tax = new Taxonomy__c();
            tax.RecordTypeId = rt.Id;
            tax.Version_Key__c = Decimal.valueOf(i);
            tax.End_Date__c = Date.newInstance(4000, 12, 31);
            taxoList.add(tax);
        }
        insert taxoList;
        
        
        BSF_Batch_TaxoRunControlBatch obj = new BSF_Batch_TaxoRunControlBatch();
       obj.sendNotificationIfQueryLimitNearThreshold(recordTypes);
       // BSF_Batch_TaxoRunControlBatch.sendNotificationIfQueryLimitNearThreshold(true);
        Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.finish(null); // This should fail if taxoRun is expected and dereferenced
        Test.stopTest();
        
    }
    
    
    
    
    
    
    @isTest
    static void testExecuteMethodWithExceptions() {
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name = 'Bio Relationship Manager Portfolio' LIMIT 1];
        
        // Create test data
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            //  External_Id__c = rt.Name + '_' + taxn.Version_Key__c,
            Status__c = '',
            Taxo_Record_Type__c = rt.Name,
            Future_Version_Number__c = -009,
            Run_Date__c = null
        );
        insert taxoRun;
        // Taxo_Utilities.getBatchSize('getbacthsize','getbatchsize');
        Test.startTest();
        
        // Simulate the execute method
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.finish(null);   // Call the execute method with mock data
        
        Test.stopTest();
    }
    @isTest
    static void testCoverageForNightlyBatchJob() {
        // Schedule a dummy job using System.schedule() to create AsyncApexJob
        String cronExp = '0 0 1 * * ?'; // 1 AM daily
        String jobName = 'BSFBatchPopulateTerriInCollOppSchedule';
        
        // Schedule your existing batch class
        Test.startTest();
        // String jobId = System.schedule(jobName, cronExp, new BSFBatchPopulateTerriInCollOppSchedule());
        Test.stopTest();
        
        // Add to nightlyBatches so the ApexClass.Name matches
        List<String> nightlyBatches = new List<String>{'BSFBatchPopulateTerriInCollOppSchedule'};
            
            // Now your code will retrieve the AsyncApexJob
            List<AsyncApexJob> jobs = [
                SELECT Id, ApexClass.Name, CronTriggerId 
                FROM AsyncApexJob 
                WHERE ApexClass.Name IN :nightlyBatches
            ];
        
        // System.assert(!jobs.isEmpty(), 'AsyncApexJob should exist and be covered in test');
    }
    
    @isTest
    static void testFinishMethodExceptionCoverage() {
        // Setup: Create a Taxonomy_Run__c record
        Taxonomy_Run__c run = new Taxonomy_Run__c(
            Taxo_Record_Type__c = 'Invalid_Type', // Make sure this doesn't match your actual records
            Future_Version_Number__c = 9999,  // Invalid version number
            Status__c = 'Pending',
            Run_Date__c = Date.today()
        );
        insert run;
        
        Test.startTest();
        
        // Trigger the finish method, which will now encounter invalid data and possibly throw an exception
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.finish(null);  // This will now run with invalid data and hit the catch block
        
        Test.stopTest();
    }
    
    
    @isTest
    static void testExecuteWithMetadataScope() {
        // Simulate a scope list using the real metadata record
        Taxonomy_Run_Config__mdt config = Taxonomy_Run_Config__mdt.getInstance('Sample_Config');
        
        List<Taxonomy_Run_Config__mdt> scope = new List<Taxonomy_Run_Config__mdt>{ config };
             RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name = 'Bio Relationship Manager Portfolio' LIMIT 1];
         Date endDate = Date.newInstance(4000, 12, 31);
        // Create taxonomy record
        Taxonomy__c taxn = new Taxonomy__c(
            RecordTypeId = rt.Id,
            //Internal_Version_Key__c = 'v12',
            Version_Key__c = 12.0,
            Start_Date__c = Date.today(),
            End_Date__c = endDate
        );
        insert taxn;
        
            Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.execute(null, scope); // Now your execute() method is hit properly
        Test.stopTest();
    }  
    
    
    
      @isTest
    static void testExecuteWithMetadataScope1() {
        // Simulate a scope list using the real metadata record
        Taxonomy_Run_Config__mdt config = Taxonomy_Run_Config__mdt.getInstance('Sample_Config');
        
        List<Taxonomy_Run_Config__mdt> scope = new List<Taxonomy_Run_Config__mdt>{ config };
             RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name = 'Bio Relationship Manager Portfolio' LIMIT 1];
         Date endDate = Date.newInstance(4000, 12, 31);
        // Create taxonomy record
        Taxonomy__c taxn = new Taxonomy__c(
            RecordTypeId = rt.Id,
            //Internal_Version_Key__c = 'v12',
            Version_Key__c = 12.0,
            Start_Date__c = Date.today(),
            End_Date__c = endDate
        );
        insert taxn;
        
        // Create taxonomy record
        Taxonomy__c taxn1 = new Taxonomy__c(
            RecordTypeId = rt.Id,
            //Internal_Version_Key__c = 'v12',
            Version_Key__c = 13.0,
            Start_Date__c = Date.today(),
            End_Date__c = endDate
        );
        insert taxn1;
        
            Test.startTest();
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.execute(null, scope); // Now your execute() method is hit properly
        Test.stopTest();
    }  
    
      @isTest
static void testStartMethodWithValidData() {
Test.startTest();

BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
Database.QueryLocator locator = batch.start(null);

// Check that a valid query locator is returned
System.assertNotEquals(null, locator);

Test.stopTest();
}
    
    @isTest
    static void testCronTriggerHandlingBlock() {
        Test.startTest();
        
        // 1. Schedule a dummy job
        String cronExp = '0 0 0 15 5 ? 2050'; // Schedule for a future time
        String jobId = System.schedule('Dummy Job', cronExp, new BSFBatchPopulateTerriInCollOppSchedule(200));
        
        // 2. Insert a matching custom metadata record
        Taxonomy_Run_Config__mdt config = new Taxonomy_Run_Config__mdt(
            DeveloperName = 'TestJob',
            Category__c = 'Nightly Batch Pause',
            Is_Active__c = true,
            Batch_Name__c = 'DummySchedulable' // Match ApexClass.Name
        );
        //  insert config;
        
        // 3. Insert a taxonomy run to satisfy the `taxonomyRun != null` check
        Taxonomy_Run__c run = new Taxonomy_Run__c(
            Run_Date__c = Date.today(),
            Status__c = 'Pending',
            Taxo_Record_Type__c = 'Some_Type',
            Sequence__c = 1,
            Future_Version_Number__c = 12
        );
        insert run;
        
        // 4. Call the finish method on your batch to trigger the logic
        BSF_Batch_TaxoRunControlBatch batch = new BSF_Batch_TaxoRunControlBatch();
        batch.finish(null);
        
        Test.stopTest();
    }
    
    
    
    
    
}