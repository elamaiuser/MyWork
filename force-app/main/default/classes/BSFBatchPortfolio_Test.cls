@isTest
public class BSFBatchPortfolio_Test {
    @isTest
    Public static void TestMethod1()
    {
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        
       // Fetch a RecordType
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
            Status__c = 'Pending',
            Future_Version_Number__c = taxn.Version_Key__c,
            Taxo_Record_Type__c = rt.Name
        );
        insert taxoRun;

        // Create scope for the batch (simulate execution context)
        List<Taxonomy__c> scope = new List<Taxonomy__c>{taxn};

      

        // Assert: Check if status changed to 'Processing'
        Taxonomy_Run__c updatedRun = [SELECT Status__c, Processing_Start__c FROM Taxonomy_Run__c WHERE Id = :taxoRun.Id];
       // System.assertEquals('Processing', updatedRun.Status__c);
       // System.assertNotEquals(null, updatedRun.Processing_Start__c);
       
        
        Date stDate = system.today()-100;
        Date enDate = system.today()+365;
        
        BSF_Batch_BSFPortfolio batch = new BSF_Batch_BSFPortfolio(stDate,True);
        database.executeBatch(batch);
        
        BSF_Batch_BSFPortfolio batchV1 = new BSF_Batch_BSFPortfolio('Bio Sickle Cell Portfolio',1000,stDate,enDate,True);
        database.executeBatch(batchV1);
        
        BSF_Batch_BSFPortfolio batchV2 = new BSF_Batch_BSFPortfolio('Bio Sickle Cell Portfolio',1000,Null,Null,True);
        String chron = '0 0 23 * * ?';        
         String jobid = System.schedule('testScheduledApex', chron, batchV2);
        //database.executeBatch(batchV2);
        //
          BSF_Batch_BSFPortfolio batchV3 = new BSF_Batch_BSFPortfolio(taxoRun.Taxo_Record_Type__c,taxoRun.Future_Version_Number__c,stDate,enDate,True,true);
        database.executeBatch(batchV3);
    }
    
    
     
        @isTest
static void testExecuteMethodWithExceptions() {
    RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' LIMIT 1];
    
    // Insert intentionally bad Taxonomy__c record
    Taxonomy__c badRecord = new Taxonomy__c(
        RecordTypeId = rt.Id,
        Version_Key__c = 9999999.0,
        District_Code__c = '',
        District_Name__c = '',
        ABM_Code__c ='',
        Division_Key__c  = null// this should cause failure
    );
    insert badRecord;
    
 Taxonomy_Run__c run = new Taxonomy_Run__c(
            Run_Date__c = Date.today(),
            Status__c = 'Pending',
            Taxo_Record_Type__c = 'Some_Type',
            Sequence__c = 1,
            Future_Version_Number__c = 9999999.0
        );
        insert run;
    Test.startTest();
     // Fake scope
        List<Taxonomy__c> scope = new List<Taxonomy__c>{ badRecord };

    // Create batch instance with parameters that will cause failure
    BSF_Batch_BSFPortfolio batchV3 = new BSF_Batch_BSFPortfolio(
      null,
      null,
        null, null,
        null, null
    );
    
    // Try-catch not needed here — let the batch handle and go into its internal catch block
  
        // Manually call execute and force error inside it
       batchV3.execute(null, new List<Taxonomy__c>{ badRecord }); // Assuming the test trigger will throw

    
    Test.stopTest();
}
    
    
 @isTest
static void testConstructorException() {
    Test.startTest();

    // Will throw a test-only error and enter catch block
    BSF_Batch_BSFPortfolio batch = new BSF_Batch_BSFPortfolio(
        'TestRecordType',
        -9999999999999999999999.00,
        Date.today(),
        Date.today().addDays(1),
        true
    );

    Test.stopTest();
    
    // Optionally assert that error logs were created if your logging system persists them
}


}