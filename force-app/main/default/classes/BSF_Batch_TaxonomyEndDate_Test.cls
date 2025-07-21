@isTest
public class BSF_Batch_TaxonomyEndDate_Test 
{
    @TestSetup
    public static void setupData()
    {
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
    }
    
    @isTest
    public static void testMethod1()
    {
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                      Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
                                      RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c,Version_Key__c
                                      FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE]; 
        Test.startTest();
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoList[0].version_Key__c,'Bio Recruitment CD',true,null,null);
        database.executeBatch(batch,25);
        Test.StopTest();
    }
    
    
    @isTest
    public static void testMethod_BioRecruitment()
    {
        
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
            Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today(),
            Taxo_Record_Type__c = rt.Name
        );
        insert taxoRun;
        
        Test.startTest();
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoRun.Future_Version_Number__c,taxoRun.Taxo_Record_Type__c,true,null,null,true);
        database.executeBatch(batch,25);
        
        
        
     
        Test.StopTest();
    }
    
     @isTest
    public static void testMethod_BioCollection()
    {
        
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c'  and Name = 'Bio Collection BSF' LIMIT 1];
        
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
            Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today(),
            Taxo_Record_Type__c = rt.Name
        );
        insert taxoRun;
        
        Test.startTest();
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoRun.Future_Version_Number__c,taxoRun.Taxo_Record_Type__c,true,null,null,true);
        database.executeBatch(batch,25);
        
        
        
     
        Test.StopTest();
    }
   
    
   
     @isTest
    public static void testMethod_BioRecruitment1()
    {
        
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name =: BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE LIMIT 1];
        
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
            Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today(),
            Taxo_Record_Type__c = rt.Name
        );
        insert taxoRun;
        
        Test.startTest();
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoRun.Future_Version_Number__c,taxoRun.Taxo_Record_Type__c,true,null,null,true);
        database.executeBatch(batch,25);
        
        
        
     
        Test.StopTest();
    }
   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    @isTest
    public static void testMethod_Fixed()
    {
        
        RecordType collectionRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Taxonomy__c' AND Name = 'Bio Collection BSF' LIMIT 1];
        
        Taxonomy__c taxnCollection = new Taxonomy__c(
            Version_Key__c = 1.0,
            End_Date__c = Date.today().addDays(-5),
            RecordTypeId = collectionRT.Id
        );
        insert taxnCollection;
        
        RecordType collectionRT1 = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Taxonomy__c' AND Name = 'Bio Collection BSF' 
            LIMIT 1
        ];
        
        Taxonomy__c collectionTax = new Taxonomy__c(
            Version_Key__c = 1.0,
            End_Date__c = Date.today().addDays(-5),
            RecordTypeId = collectionRT1.Id,
            DS_Region_Code__c = 'ARC1',
            Division_Code__c = 'DIV1',
            District_Code__c = 'DIST1'
        );
        insert collectionTax;
        
        Taxonomy_Run__c taxoRunCollection = new Taxonomy_Run__c(
            External_Id__c = 'Bio Collection BSF_1.0',
            Status__c = 'pending',
            Future_Version_Number__c = collectionTax.Version_Key__c
        );
        insert taxoRunCollection;  
        Test.startTest();
        BSF_Batch_TaxonomyEndDateHandler batchCollection = new BSF_Batch_TaxonomyEndDateHandler(taxoRunCollection.Future_Version_Number__c, 'Bio Collection BSF', false, null, null, true);
        database.executeBatch(batchCollection, 25);
        Test.stopTest();
        
    }
    
    
    

    @isTest
    static void testExecuteForBioCollection() {
        // Get the record type
        RecordType collectionRT = [SELECT Id, Name FROM RecordType 
                                   WHERE SObjectType = 'Taxonomy__c' 
                                   AND Name = 'Bio Collection BSF' LIMIT 1];

        // Insert older version (for oldVersionTaxRecords match)
        Taxonomy__c oldTax = new Taxonomy__c(
            Version_Key__c = 0.9,
            RecordTypeId = collectionRT.Id,
            DS_Region_Code__c = 'R1',
            Division_Code__c = 'D1',
            District_Code__c = 'DIST1'
        );
        insert oldTax;

        // Insert matching current version record (part of batch input)
        Taxonomy__c newTax = new Taxonomy__c(
            Version_Key__c = 1.0,
            RecordTypeId = collectionRT.Id,
            DS_Region_Code__c = 'R1',
            Division_Code__c = 'D1',
            District_Code__c = 'DIST1'
        );
        insert newTax;

        Test.startTest();
        // Instantiate the batch class
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Collection BSF', false, null, null, true);

        // Call execute directly with only Bio Collection records
        batch.execute(null, new List<Taxonomy__c>{ oldTax, newTax });
        Test.stopTest();
    }
  @isTest
    static void testCollectionFinishCoverage() {
        // Insert a sample Taxonomy__c record with BIO_COLLECTION_RECORD_TYPE
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Taxonomy__c' AND Name = 'Bio Collection BSF' LIMIT 1];

        Taxonomy__c tax = new Taxonomy__c(
           // Name = 'Test Tax',
            RecordTypeId = rt.Id,
            Version_Key__c = 1.0,
            DS_Region_Code__c = 'ARC',
            District_Code__c = 'D123',
            Division_Code__c = 'DIV'
        );
        insert tax;

        Test.startTest();

       // BSF_Batch_TaxonomyEndDateHandler.isTestOverride = true; // Force block to run

        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Collection BSF', false, null, null, true);

        batch.finish(null); // simulate finish

        Test.stopTest();
    }

   /*@isTest
    static void testCollectionFinishCoverage1() {
        // Insert a sample Taxonomy__c record with BIO_COLLECTION_RECORD_TYPE
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' AND Name = 'Bio Fixed Sites' LIMIT 1];
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
            Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today()
        );
        insert taxoRun;
        Test.startTest();
        // BSF_Batch_TaxonomyEndDateHandler.isTestOverride = true; // Force block to run
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Fixed Sites', false, null, null, true);
        batch.finish(null); // simulate finish
        Test.stopTest();
    } */ 
    
    @isTest
    static void testCollectionFinishCoverage2() {
        // Insert a sample Taxonomy__c record with BIO_COLLECTION_RECORD_TYPE
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' AND Name = 'Bio Fixed Sites' LIMIT 1];
    // Insert one expired taxonomy record
        Taxonomy__c taxn = new Taxonomy__c(
            Version_Key__c = 1.0,
            End_Date__c = Date.today().addDays(-5),
            RecordTypeId = rt.Id
        );
        insert taxn;
        String externalId = rt.Name + '_' + Integer.valueOf(taxn.Version_Key__c);
        // Insert corresponding Taxonomy_Run__c
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            External_Id__c = externalId,
            Status__c = 'pending',
            Future_Version_Number__c = taxn.Version_Key__c,
            Run_Date__c = System.today(),
            Taxo_Record_Type__c = rt.Name
        );
        insert taxoRun;

        Test.startTest();

       // BSF_Batch_TaxonomyEndDateHandler.isTestOverride = true; // Force block to run
        Integer batchSize = Taxo_Utilities.getBatchSize('Bio Fixed Sites','BSF_Batch_BSFPortfolio');
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoRun.Future_Version_Number__c,taxoRun.Taxo_Record_Type__c, false, null, null, true);
        
        database.executeBatch(batch, batchSize);// simulate finish

        Test.stopTest();
    } 
    
    
}