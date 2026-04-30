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
            External_Id_BackEnd__c = 'Bio_Collection_BSF_District_D1_R1_DIST1'
        );
        insert districtTerritory;
        
        // create collection operation
        Biomed_Collection_Op_Center__c collectionOpp1 = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP') ;
        collectionOpp1.Name='Test CollOp';
        collectionOpp1.sked_Territory__c=territoryDistrict.id;
        collectionOpp1.External_Id__c = 'Bio_Collection_BSF_BSF_CO_0085';
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
        territoryColOppList.add(territoryColOpp);        
        
        
        insert territoryColOppList;  
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
            
  //map<String,taxonomy__c> taxIdExternalKeysMap = getexternalKeyTaxonomyMap (oldVerTax);
        //system.debug('taxIdExternalKeysMap '+taxIdExternalKeysMap);
        List<Taxonomy__c> oldTaxList = new List<Taxonomy__c>();
      Date startDate = Date.newInstance(2025, 10, 1);
        Date endDate   = Date.newInstance(2025, 12, 31);
        Taxonomy__c oldTax = new Taxonomy__c(
            Version_Key__c = 0.9,
            RecordTypeId = rt.Id,
            DS_Region_Code__c = 'R1Testing',
            Division_Code__c = 'D1Testing',
            District_Code__c = 'DIST1Testing',
            Zip_Code__c='1234',
            Collection_Operation_Code__c='BSF_CO_0088',
            Start_Date__c = startDate,
            End_Date__c  = endDate
        );
        insert oldTax;
        System.debug('oldTaxexternalKey'+oldTax);
        oldTaxList.add(oldTax);
        map<String,taxonomy__c> taxIdExternalKeysMap = BSF_Batch_TaxonomyEndDateHelper.getexternalKeyTaxonomyMap(oldTaxList);
         set<string> externalKeySetNew = new set<string>();
        externalKeySetNew.addAll(taxIdExternalKeysMap.keyset());
         Bsf_portfolio__c bsf = new Bsf_Portfolio__c();
        bsf.Account_Based_Portfolio__c=true;
        bsf.Portfolio_Type__c='Account Manager';
        bsf.Taxonomy_Type__c='Bio Recruitment CD';
        bsf.Start_Date__c = system.today()-1;
        bsf.End_Date__c = system.today()+3;
     bsf.External_Key_BackEnd__c = 'Bio Recruitment CD_'+oldTax.Division_Code__c+'_'+oldTax.District_Code__c+'_'+oldTax.DS_Region_Code__c;
        
        insert bsf;
        
        sked_Territory__c territory = new sked_Territory__c();
        territory.Start_Date__c = System.today();
        territory.End_Date__c = System.today().addDays(1);
        
        territory.External_Id_BackEnd__c = 'Bio Recruitment CD_BD33_'+oldTax.Division_Code__c+oldTax.District_Code__c+oldTax.DS_Region_Code__c;
              //'Bio_Collection_BSF_District_'+oldTax.Division_Code__c+oldTax.District_Code__c+oldTax.DS_Region_Code__c;
        insert territory;
        
        
        
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
           Date startDate = Date.newInstance(2025, 10, 1);
        Date endDate   = system.today().addDays(30);
    
        Taxonomy__c oldTax = new Taxonomy__c(
            Version_Key__c = 0.9,
            Start_Date__c = startDate,
            End_Date__c  = endDate,
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
  
         Id recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_'+'District_'+oldTax.Division_Code__c+'_'+oldTax.District_Code__c+'_'+oldTax.DS_Region_Code__c;
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_'+'District'+'_'+oldTax.Division_Code__c+'_'+oldTax.District_Code__c+'_'+oldTax.DS_Region_Code__c;
        territory.Name = 'name';
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = system.today();
        territory.End_Date__c = system.today().addDays(100);
        
        
        insert territory;
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
  
        Test.startTest();

       // BSF_Batch_TaxonomyEndDateHandler.isTestOverride = true; // Force block to run
        Integer batchSize = Taxo_Utilities.getBatchSize('Bio Fixed Sites','BSF_Batch_BSFPortfolio');
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoRun.Future_Version_Number__c,taxoRun.Taxo_Record_Type__c, false, null, null, true);
        database.executeBatch(batch, batchSize);// simulate finish
        Test.stopTest();
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
          Id recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_'+'District_'+oldTax.Division_Code__c+'_'+oldTax.District_Code__c+'_'+oldTax.DS_Region_Code__c;
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_'+'District'+'_'+oldTax.Division_Code__c+'_'+oldTax.District_Code__c+'_'+oldTax.DS_Region_Code__c;
        territory.Name = 'name';
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = system.today();
        territory.End_Date__c = system.today().addDays(100);
        
        
        insert territory;
        // Instantiate the batch class
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Collection BSF', false, null, null, true);

        // Call execute directly with only Bio Collection records
        batch.execute(null, new List<Taxonomy__c>{ oldTax, newTax });
        Test.stopTest();
    }    
    //to cover the helper class
    //
    //
    //

 @isTest
    static void testMethodEndDateHelper() {
        Map<String, Taxonomy__c> oldKeyToTaxMap = new  Map<String, Taxonomy__c>();
        Set<Id> terrIdSet = new Set<Id>();
        Set<String> allNewTaxoVerTcoKeySet = new Set<String>();
        List<Taxonomy__c> oldTaxList = new List<Taxonomy__c>();
         Set<id> territoryIdSetToBeUsedInTCOsEnding = new Set<id>();
          set<string> externalKeySet = new set<string>();
      //  set<string> externalKeySetNew = new set<string>();
        // Get the record type
        RecordType collectionRT = [SELECT Id, Name FROM RecordType 
                                   WHERE SObjectType = 'Taxonomy__c' 
                                   AND Name = 'Bio Collection BSF' LIMIT 1];
        System.debug('HRP-Test collectionRT:'+collectionRT);
        // Insert older version (for oldVersionTaxRecords match)
        Date startDate = system.today().addDays(5);
        Date endDate   = system.today().addDays(30);
        Taxonomy__c oldTax = new Taxonomy__c(
            Version_Key__c = 0.9,
            RecordTypeId = collectionRT.Id,
            DS_Region_Code__c = 'R1Test',
            Division_Code__c = 'D1Test',
            District_Code__c = 'DIST1Test',
            Zip_Code__c='1234',
            Collection_Operation_Code__c='BSF_CO_0085',
            Start_Date__c = startDate,
            End_Date__c  = endDate
        );
        insert oldTax;
        oldTaxList.add(oldTax);
        map<String,taxonomy__c> taxIdExternalKeysMap = BSF_Batch_TaxonomyEndDateHelper.getexternalKeyTaxonomyMap(oldTaxList);
      
        // Insert matching current version record (part of batch input)
        Taxonomy__c newTax = new Taxonomy__c(
            Version_Key__c = 1.0,
            RecordTypeId = collectionRT.Id,
            DS_Region_Code__c = 'R2',
            Division_Code__c = 'D2',
            District_Code__c = 'DIST2',
            Zip_Code__c='1234',
            Collection_Operation_Code__c='BSF_CO_0085X',
            Start_Date__c = Date.newInstance(2026, 1, 1),
            End_Date__c  = Date.newInstance(4000, 12, 31)
        );
        insert newTax;
        Bsf_portfolio__c bsf = new Bsf_Portfolio__c();
        bsf.Account_Based_Portfolio__c=true;
        bsf.Portfolio_Type__c='Account Manager';
        bsf.Taxonomy_Type__c='Bio Recruitment CD';
        bsf.Start_Date__c = system.today()-1;
        bsf.End_Date__c = system.today()+3;
        bsf.External_Key_BackEnd__c =  'Bio_Collection_BSF_District_D1Test_R1Test_DIST1Test';
        
        insert bsf;
        
        Id recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_District_D1Test_R1Test_DIST1Test';
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_District_D1Test_R1Test_DIST1Test';
        territory.Name = 'name';
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = system.today();
        territory.End_Date__c = system.today().addDays(100);
        
        
        insert territory;
        sked_Territory__c updatedTerr = [
            SELECT End_Date__c,Start_Date__c
            FROM sked_Territory__c
            WHERE Id = :territory.Id
        ];
        
        System.assert(
            oldTax.End_Date__c > updatedTerr.Start_Date__c,
            'Expected oldTax End Date to be greater than updatedTerr Start Date'
        );
        system.debug('yes insert'+updatedTerr);
        /* sked_Territory__c territory = new sked_Territory__c();
        territory.Start_Date__c = System.today();
          territory.End_Date__c = System.today().addDays(1);
        
          territory.External_Id_BackEnd__c = 'Bio_Collection_BSF_District_'+oldTax.Division_Code__c+oldTax.District_Code__c+oldTax.DS_Region_Code__c;
        insert territory;*/
        
           Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c();
        co.Biomed_Collection_Op_Code_Center_ID__c ='C-OP3';
        //co.Collection_Operation_ID__c='CoKey';
        co.Name='Collection_Operation_Name__c';
        co.External_Id__c = 'Bio_Collection_BSF_' + 'Collection_Operation_Code__c';
        co.sked_Territory__c=territory.id;
        co.sked_Lunch_Break_Duration_Fixed_Site__c='30';
        co.sked_Lunch_Break_Duration_Mobile__c='30';
        insert co;
        territoryIdSetToBeUsedInTCOsEnding.add(territory.Id);
        sked_Territory_Collection_Operation__c tco = new sked_Territory_Collection_Operation__c();
        tco.sked_Territory__c = territory.Id;
        tco.sked_Start_Date__c = System.today();
        tco.sked_End_Date__c = System.today().addDays(2);
        tco.sked_Collection_Operation__c = CO.Id; 
        tco.sked_External_ID__c = tco.sked_Territory__r.External_Id_BackEnd__c+'_' + tco.sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c ;
        insert tco;
        
        
                
        System.debug('HRP-Test ------ oldTax:'+oldTax);
        System.debug('HRP-Test ------ newTax:'+newTax);
        List<Taxonomy__c> taxoList = new List<Taxonomy__c>();
        //taxoList.add(oldTax);
        taxoList.add(newTax);
           BSF_Batch_TaxonomyEndDateHelper taxonomyHelper = new BSF_Batch_TaxonomyEndDateHelper();
        
         map<String,taxonomy__c> newTaxIdExternalKeysMap = BSF_Batch_TaxonomyEndDateHelper.getexternalKeyTaxonomyMap(taxoList);
        set<string> externalKeySetNew = new set<string>();
        externalKeySetNew.addAll(newTaxIdExternalKeysMap.keyset());

      
       // BSF_Batch_TaxonomyEndDateHelper.endDateTCOsBatchSafe(taxIdExternalKeysMap,territoryIdSetToBeUsedInTCOsEnding,externalKeySetNew);
        Test.startTest();
        // Instantiate the batch class
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(1.0, 'Bio Collection BSF', false, null, null, true);
      // database.executeBatch(batch,25);
        
        // Call execute directly with only Bio Collection records
        batch.execute(null, new List<Taxonomy__c>{ oldTax, newTax });
        Test.stopTest();
    }    



    
}