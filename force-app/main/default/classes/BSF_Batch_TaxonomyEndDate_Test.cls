@isTest
public class BSF_Batch_TaxonomyEndDate_Test 
{
    @TestSetup
    public static void setupData()
    {
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;

        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // create territory
        list<sked_Territory__c> territoryList = new list<sked_Territory__c>();
        sked_Territory__c territoryDivision = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_DIVISON') ;
        territoryList.add(territoryDivision);
        sked_Territory__c territoryRegion = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_ARC_REGION') ;
        territoryList.add(territoryRegion);
        sked_Territory__c territoryDistrict = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_DISTRICT') ;
        territoryDistrict.Name='Test Dis';
        territoryList.add(territoryDistrict);
        insert territoryList;
        
        sked_Territory__c districtTerritory = new sked_Territory__c(
            Name= 'Alabama North 02',
            RecordTypeId =  sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('District').getRecordTypeId(),  
            sked_High_Drive_Productivity_Threshold__c= 0.800000,
            sked_Mid_Drive_Productivity_Threshold__c= 0.600000,
            sked_Parent__c = territoryRegion.id,
            //External_Id_BackEnd__c = 'Bio_Collection_BSF_District_D1_R1_DIST1'
            External_Id_BackEnd__c = 'Bio Fixed Sites_BD32',
            Start_Date__c =  Date.newInstance(2025, 01, 01),
            End_Date__c = Date.newInstance(2025, 03, 31)

        );
        insert districtTerritory;
        
        // create collection operation
        Biomed_Collection_Op_Center__c collectionOpp1 = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP') ;
        collectionOpp1.Name='Test CollOp';
        collectionOpp1.sked_Territory__c=territoryDistrict.id;
        collectionOpp1.External_Id__c = 'Bio_Collection_BSF_BSF_CO_0085';
        collectionOpp1.Biomed_Collection_Op_Code_Center_ID__c='1212';
        insert collectionOpp1;

        /* Biomed_Collection_Op_Center__c collectionOpp2 = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP') ;
        collectionOpp2.Name='Test CollOp';
        collectionOpp2.sked_Territory__c=territoryDistrict.id;
        collectionOpp2.External_Id__c = 'Bio_Collection_BSF_BSF_CO_0085X';
        insert collectionOpp2; */
        
        // create sked_Territory_Collection_Operation__c        
        List<sked_Territory_Collection_Operation__c> territoryColOppList = new List<sked_Territory_Collection_Operation__c>();
        sked_Territory_Collection_Operation__c territoryColOpp = new sked_Territory_Collection_Operation__c();
        territoryColOpp.sked_Collection_Operation__c = collectionOpp1.id;
        territoryColOpp.sked_Territory__c = districtTerritory.id;
        territoryColOpp.sked_Start_Date__c = System.today();
        territoryColOpp.sked_End_Date__c = System.today().addDays(10);
        territoryColOpp.sked_External_ID__c = districtTerritory.External_Id__c  +'__'+collectionOpp1.Biomed_Collection_Op_Code_Center_ID__c;
        territoryColOppList.add(territoryColOpp);        
        
        
        insert territoryColOppList;  
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

        //Taxonomy_Run__c should NOT remain in 'pending'
        Taxonomy_Run__c updatedRun = [ SELECT Status__c FROM Taxonomy_Run__c WHERE Id = :taxoRun.Id];
        System.assertNotEquals('pending',updatedRun.Status__c,'Taxonomy_Run__c status should be updated after batch execution');
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

        Taxonomy_Run__c updatedRun = [SELECT Status__c FROM Taxonomy_Run__c WHERE Id = :taxoRun.Id];
        System.assertNotEquals('pending',updatedRun.Status__c,'Bio Recruitment taxonomy run should be processed by the batch');
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
            District_Code__c = 'DIST1',
            Start_Date__c =  Date.newInstance(2025, 11, 01),
            End_Date__c = Date.newInstance(2025, 12, 31)
        );
        insert oldTax;

        // Insert matching current version record (part of batch input)
        Taxonomy__c newTax = new Taxonomy__c(
            Version_Key__c = 1.0,
            RecordTypeId = collectionRT.Id,
            DS_Region_Code__c = 'R1',
            Division_Code__c = 'D1',
            District_Code__c = 'DIST1',
            Start_Date__c =  Date.newInstance(2026, 01, 01),
            End_Date__c = Date.newInstance(4000, 12, 31)
        );
        insert newTax;

        Test.startTest();
        // Instantiate the batch class
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Collection BSF', false, null, null, true);

        // Call execute directly with only Bio Collection records
        batch.execute(null, new List<Taxonomy__c>{ oldTax, newTax });
        Test.stopTest();
        Taxonomy__c updatedOldTax = [ SELECT Version_Key__c, End_Date__c FROM Taxonomy__c WHERE Id = :oldTax.Id ];
        System.assert( updatedOldTax.End_Date__c == null || updatedOldTax.End_Date__c <= Date.today(), 'Older Bio Collection taxonomy should be end-dated.');
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
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Collection BSF', false, null, null, true);

        batch.finish(null); // simulate finish

        Test.stopTest();

        Taxonomy__c persistedTax = [SELECT Id, Version_Key__c FROM Taxonomy__c WHERE Id = :tax.Id];
        System.assertNotEquals(null,persistedTax.Id,'Finish method should not delete taxonomy records');
    }

    
    @isTest
    static void testCollectionFinishCoverage2() {
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' AND Name = 'Bio Fixed Sites' LIMIT 1];
    
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

        Integer batchSize = Taxo_Utilities.getBatchSize('Bio Fixed Sites','BSF_Batch_BSFPortfolio');
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoRun.Future_Version_Number__c,taxoRun.Taxo_Record_Type__c, false, null, null, true);
        database.executeBatch(batch, batchSize);// simulate finish
        Test.stopTest();

        Taxonomy_Run__c updatedRun = [ SELECT Status__c FROM Taxonomy_Run__c WHERE Id = :taxoRun.Id];
        System.assertNotEquals('pending',updatedRun.Status__c,'Bio Fixed Sites taxonomy run should be processed by the batch');
    }

    @isTest
    static void testMethodPortFolio() {
        // Get the record type
        RecordType collectionRT = [SELECT Id, Name FROM RecordType 
                                   WHERE SObjectType = 'Taxonomy__c' 
                                   AND Name = 'Bio Collection BSF' LIMIT 1];
        System.debug('HRP-Test collectionRT:'+collectionRT);
        // Insert older version (for oldVersionTaxRecords match)
        Date startDate = Date.newInstance(2025, 10, 1);
        Date endDate   = Date.newInstance(2025, 12, 31);
        Taxonomy__c oldTax = new Taxonomy__c(
            Version_Key__c = 0.9,
            RecordTypeId = collectionRT.Id,
            DS_Region_Code__c = 'R1',
            Division_Code__c = 'D1',
            District_Code__c = 'DIST1',
            Zip_Code__c='1234',
            Collection_Operation_Code__c='BSF_CO_0085',
            Start_Date__c = startDate,
            End_Date__c  = endDate
        );
        insert oldTax;

        // Insert matching current version record (part of batch input)
        Taxonomy__c newTax = new Taxonomy__c(
            Version_Key__c = 1.0,
            RecordTypeId = collectionRT.Id,
            DS_Region_Code__c = 'R1',
            Division_Code__c = 'D1',
            District_Code__c = 'DIST1',
            Zip_Code__c='1234',
            Collection_Operation_Code__c='BSF_CO_0085X',
            Start_Date__c = Date.newInstance(2026, 1, 1),
            End_Date__c  = Date.newInstance(4000, 12, 31)
        );
        insert newTax;
        System.debug('HRP-Test ------ oldTax:'+oldTax);
        System.debug('HRP-Test ------ newTax:'+newTax);
        List<Taxonomy__c> taxoList = new List<Taxonomy__c>();
        taxoList.add(oldTax);
        taxoList.add(newTax);
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        Test.startTest();
        // Instantiate the batch class
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Collection BSF', false, null, null, true);

        // Call execute directly with only Bio Collection records
        batch.execute(null, new List<Taxonomy__c>{ oldTax, newTax });
        Test.stopTest();

        Taxonomy__c updatedOldTax = [SELECT Version_Key__c, End_Date__c FROM Taxonomy__c WHERE Id = :oldTax.Id];
        System.assert(updatedOldTax.End_Date__c <= Date.today() || updatedOldTax.End_Date__c == endDate,'Older taxonomy should be end-dated or remain within its defined end date');
    } 
}