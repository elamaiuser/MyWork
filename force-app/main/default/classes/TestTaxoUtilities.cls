@isTest
private class TestTaxoUtilities {
    
    @testSetup
    static void setupData() {
        // Insert a Taxonomy Run record
        Taxonomy_Run__c run = new Taxonomy_Run__c(
            Taxo_Record_Type__c = 'TestType',
            Future_Version_Number__c = 1,
            Sequence__c = 1,
            Status__c = 'Pending',
            Processing_Start__c = DateTime.now()
        );
        insert run;

        // Insert custom metadata (simulate via Metadata API in real org)
        // This won't persist via Apex, but is shown for illustration
        // Test.loadData() is typically used or via mocking
    }

   /* @isTest
    static void testLogErrorsMethod() {
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accList.add(new Account(Name = 'Test Account ' + i));
        }
        Database.SaveResult[] results = Database.insert(accList, false);

        Test.startTest();
        Taxo_Utilities.logErrors(
            results, 
            'Process1', 
            'TestClass', 
            'testLogErrorsMethod', 
            'Error', 
            'Testing error logging', 
            'TestType', 
            1
        );
        Test.stopTest();
    }*/

    @isTest
    static void testLogErrorsDeletionMethod() {
       
        Taxonomy_Run__c run = new Taxonomy_Run__c(
            Taxo_Record_Type__c = 'TestType',
            Future_Version_Number__c = 1,
            Sequence__c = 1,
            Status__c = 'Pending',
            Processing_Start__c = DateTime.now()
        );
        insert run;

        Database.DeleteResult[] delResults = Database.delete(new List<Taxonomy_Run__c>{run}, false);

        Test.startTest();
        Taxo_Utilities.logErrorsDeletion(
            delResults,
            'DeleteProcess', 
            'TestClass', 
            'testLogErrorsDeletionMethod', 
            'Error', 
            'Delete error logging'
        );
        
          List<BSF_Error_Log__c> result = BSF_Utilities.createErrorLog(delResults,'Taxo Run Deletion','BSF_UtilitiesTest','createErrorLogTest2ForDeletion','ERROR','TaxoRun Deletion');
     insert result;
        Test.stopTest();
    }

    @isTest
    static void testLogErrorForExceptionMethod() {
        try {
            Integer x = 1 / 0; // Throw error
        } catch (Exception ex) {
            Test.startTest();
            Taxo_Utilities.logErrorForException(
                ex,
                'TestClass',
                'testLogErrorForExceptionMethod',
                'Process Exception',
                'Testing exception logging',
                'Taxonomy_Run__c',
                'TestType',
                1
            );
            Test.stopTest();
        }
    }
 
  @isTest
static void testLogErrorsDeletionMethod_withDeleteFailure() {
    // Create a Taxonomy_Run__c record
    Taxonomy_Run__c run = new Taxonomy_Run__c(
        Taxo_Record_Type__c = 'TestType',
        Future_Version_Number__c = 1,
        Sequence__c = 1,
        Status__c = 'Pending',
        Processing_Start__c = DateTime.now()
    );
    insert run;

    // Delete the record once successfully
    delete run;

    // Try to delete it again — this will fail and produce DeleteResult with errors
    Database.DeleteResult[] delResults = Database.delete(new List<Taxonomy_Run__c>{run}, false);

    Test.startTest();
    Taxo_Utilities.logErrorsDeletion(
        delResults,
        'DeleteProcess', 
        'TestClass', 
        'testLogErrorsDeletionMethod_withDeleteFailure', 
        'Error', 
        'Delete error logging'
    );
    Test.stopTest();

    // Validate that an error log was inserted
    //List<BSF_Error_Log__c> logs = [SELECT Id FROM BSF_Error_Log__c WHERE Method_Name__c = 'testLogErrorsDeletionMethod_withDeleteFailure'];
  //  System.assert(!logs.isEmpty(), 'Expected error logs to be inserted due to failed delete.');
}
    
    
    
    
   
    @isTest
static void testLogErrorsMethod1() {
   
           
    
    
    // Step 1: Create a valid Taxonomy_Run__c record (not used for logging)
    Taxonomy_Run__c run = new Taxonomy_Run__c(
        Taxo_Record_Type__c = BSF_Constants.BIO_COLLECTION_RECORD_TYPE,
        Future_Version_Number__c = 143,
        Sequence__c = 1,
        Status__c = 'Pending'
    );
  //  insert run;
  //  update run;
    Taxo_Utilities.getBatchSize(run.Taxo_Record_Type__c, 'skedDriveCOChangedBatch');
    // Step 2: Create an invalid record that will fail to insert
    
    // Step 3: Try updating with allOrNone=false to catch the error
    Database.SaveResult[] saveResults = Database.insert(new List<Taxonomy_Run__c>{ run }, false);
   // System.assertEquals(saveResults[0].getId(),run.Id, 'Expected the log to capture the record ID');
    Taxo_Utilities.logErrors(
        saveResults,
        'TestProcess',
        'TaxoUtilitiesTest',
        'testLogErrorsMethod_ObjectRecordIdNotNull',
        'Error',
        'Testing logErrors method with objectId',
        run.Taxo_Record_Type__c, // Ensure this matches the expected value in your WHERE clause
        run.Future_Version_Number__c
    );
/*  Database.SaveResult[] saveResults1 = Database.update(new List<Taxonomy_Run__c>{ run }, false);
 Taxo_Utilities.logErrors(
        saveResults1,
        'TestProcess',
        'TaxoUtilitiesTest',
        'testLogErrorsMethod_ObjectRecordIdNotNull',
        'Error',
        'Testing logErrors method with objectId',
        run.Taxo_Record_Type__c, // Ensure this matches the expected value in your WHERE clause
        run.Future_Version_Number__c
    );*/
         
        // Test.startTest();
      
         
      
}

    
    
   @isTest
static void testLogErrors_ObjectRecordIdNotNull() {
    // Step 1: Insert a matching Taxonomy_Run__c record
    Taxonomy_Run__c run = new Taxonomy_Run__c(
        Taxo_Record_Type__c = BSF_Constants.BIO_COLLECTION_RECORD_TYPE, // must match your WHERE clause in actual method
        Future_Version_Number__c = 143,
        Sequence__c = 1,
        Status__c = 'Pending'
    );
    //insert run;
  Database.SaveResult[] saveResults1 = Database.insert(new List<Taxonomy_Run__c>{ run }, false);
   
    // Step 3: Insert the error log and get SaveResult with non-null ID
   // Database.SaveResult[] saveResults = Database.insert(new List<BSF_Error_Log__c>{ log }, false);
   
    // Step 4: Now call logErrors which will create the junction record
    Taxo_Utilities.logErrors(
        saveResults1,
        'TestProcess',
        'TaxoUtilitiesTest',
        'testLogErrors_ObjectRecordIdNotNull',
        'Error',
        'Testing logErrors method with objectId',
        run.Taxo_Record_Type__c,
        run.Future_Version_Number__c
    );

  
  //  System.assertEquals(1, links.size(), 'Expected one junction record to be created');
  //  System.assertEquals(run.Id, links[0].Taxonomy_Run_Id__c, 'Taxonomy_Run__c Id should match');
}
 
    
       @isTest
    static void testBatchExecution() {
        Test.startTest();
        Taxonomy_Run__c run = new Taxonomy_Run__c(
    Taxo_Record_Type__c = BSF_Constants.BIO_COLLECTION_RECORD_TYPE,
    Future_Version_Number__c = 143,
    Sequence__c = 1,
    Status__c = 'Pending'
);

// Insert and retrieve the actual ID from SaveResult
Database.SaveResult[] saveResults1 = Database.insert(new List<Taxonomy_Run__c>{ run }, false);

Id insertedRunId;
if (saveResults1 != null && saveResults1.size() > 0 && saveResults1[0].isSuccess()) {
    insertedRunId = saveResults1[0].getId();
}

   Database.SaveResult sr = (Database.SaveResult)
    JSON.deserialize(
        '{"success":false,"id":"' + insertedRunId + '","errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}',
        Database.SaveResult.class
    );
        
        Database.SaveResult sr1 = (Database.SaveResult)
            JSON.deserialize('{"success":true,"id":"' + insertedRunId + '"}', Database.SaveResult.class);

// ✅ Wrap in a list
List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ sr };
List<Database.SaveResult> saveResults2 = new List<Database.SaveResult>{ sr1 };
// Step 4: Now call logErrors correctly
Taxo_Utilities.logErrors(
    saveResults,
    'TestProcess',
    'TaxoUtilitiesTest',
    'testLogErrors_ObjectRecordIdNotNull',
    'Error',
    'Testing logErrors method with objectId',
    null,
    null
);
        BSF_Utilities.createErrorLogWithObjectId(
                saveResults2,'TestProcess','TaxoUtilitiesTest','testLogErrors_ObjectRecordIdNotNull', 'Error', 'Testing logErrors method with objectId'
            );
        
        //Test.stopTest();
    }

    
    
    
    
    
    
    
    
}