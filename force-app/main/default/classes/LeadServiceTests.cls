/*
* This Test class covering the following Classes
* LeadService
* LeadTriggerHandler 
*  
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 10/20/2023                  Krapy Tuli                To increase Code coverage for HRP-10880
* 09/17/2024				  Priti Jana			    Increase code coverage
* 12/11/2024				  Priti Jana				Added test method for HRP-13602
*****************************************************************************
*/

@isTest
public class LeadServiceTests {

    static testMethod void newLeadHasChapterAssignedTest(){     
        String testZipCode = '27560';      
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region');
        insert(testChapter);
        
        Chapter_Blood_Region_Zip_Match__c zipMatch = new Chapter_Blood_Region_Zip_Match__c(
            Name='ZZZZ',
            Blood_Region__c=testChapter.Id, 
            Chapter__c=testChapter.Id,
            Zip__c=testZipCode);
        insert(zipMatch);
        
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=testZipCode,
            CountryCode='US');
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Email='test@test.com';
        
        Test.startTest();
        insert(testLead);
        Test.stopTest();
        
        // Test: did the lead get a Chapter and Blood Region assigned?
        Lead leadResult = [select Chapter__c, Blood_Region__c from Lead where Id = :testLead.Id];
        //System.assertEquals(testChapter.Id, leadResult.Chapter__c);
        
    }
    
    static testMethod void updatedLeadChapterUpdatedTest(){
        String testZipCode1 = '27560';
        String testZipCode2 = '28201';
        
        Chapter__c testChapter1 = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Raleigh',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Raleigh Region');
        insert(testChapter1);
        
        Chapter_Blood_Region_Zip_Match__c zipMatch1 = new Chapter_Blood_Region_Zip_Match__c(
            Name='ZZZZ',
            Blood_Region__c=testChapter1.Id, 
            Chapter__c=testChapter1.Id,
            Zip__c=testZipCode1);
        insert(zipMatch1);

        Chapter__c testChapter2 = new Chapter__c(
            Chapter_Code__c='AB222',
            Division_Code__c='D22',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F43',
            Type__c='Chapter',
            Region_Name__c='Charlotte Region');
        insert(testChapter2);
        
        Chapter_Blood_Region_Zip_Match__c zipMatch2 = new Chapter_Blood_Region_Zip_Match__c(
            Name='ZZZ2',
            Blood_Region__c=testChapter2.Id, 
            Chapter__c=testChapter2.Id,
            Zip__c=testZipCode2);
        insert(zipMatch2);
 
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=testZipCode1,
            CountryCode='US');
         testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Email='test@test.com';
        insert(testLead);
        
        Lead leadResultBEFORE = [select Chapter__c, Blood_Region__c from Lead where Id = :testLead.Id];
        
        // Now update the Lead's zipcode so we can see if the Chapter is updated by the trigger
        Test.startTest();
        testLead.PostalCode = testZipCode2;
        update(testLead);
        Test.stopTest();
 
    }
    
    static testMethod void leadWithoutZipCanBeInsertedTest(){
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=null,
            CountryCode='US',
            Parent_Campaign__c = null,
            Campaign_member_status__c = null,
            Email='test@test.com');
        
        try {
         insert(testLead);
         System.assert(false,'Error should have been thrown for not having zip code');
        }
        catch(Exception e){}
    }
    
    static testMethod void leadWithBadZipTest(){
        // Attempt to insert a lead with an unknown zipcode, it should be allowed and the lead record should save successfully.
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode='99999',
            CountryCode='US');
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Email='test@test.com';
        insert(testLead);
    }

    // Bulk test
    static testMethod void bulkLeadInsertTest(){
        String testZipCode = '27560';
        
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region');
        insert(testChapter);
        
        Chapter_Blood_Region_Zip_Match__c zipMatch = new Chapter_Blood_Region_Zip_Match__c(
            Name='ZZZZ',
            Blood_Region__c=testChapter.Id, 
            Chapter__c=testChapter.Id,
            Zip__c=testZipCode);
        insert(zipMatch);

        // Insert mass leads
        List<Lead> newLeads = new List<Lead>();
        for(Integer i=0;i<10;i++){
            newLeads.add(
                new Lead(
                    FirstName = 'Testingly', 
                    LastName='Lead' + i,
                    Company='TestComany' + i,
                    City='Raleigh',
                    StateCode='NC',
                    PostalCode=testZipCode,
                    CountryCode='US',
                    Parent_Campaign__c = null,
        			Campaign_member_status__c = null,
        			Email='test@test.com'
                )
            );
        }
        
        Test.startTest();
        insert(newLeads);
        Test.stopTest();
    }
    
    static testMethod void tempLeadCreationTest(){
         Lead tempLead =LeadService.createTempLead('test@test.com');
         System.assert(tempLead.Id !=null);
    }

    static testMethod void leadCreatedGeneratesEventTest(){
        
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            CountryCode = 'US',
            StateCode='NC',
            LeadSource = 'Redcrossblood.org',
            Parent_Campaign__c = null,
        	Campaign_member_status__c = null,
            Email='test@test.com',
            PostalCode='27560'
        );
        
        Test.startTest();
        insert(testLead);
        Test.stopTest();
    }

    static testMethod void newLeadHasTerritoryAssignedTest(){        
        String testZipCode = '36310'; // Alabama Region
        
        Profile p = [select id, name from profile where name = 'Standard User'];
        User testBDM = TestUtil.createUser('test.bdm@redcrossblood.org',p.Id,true, null, 'lastname', 'firstname');
        System.assert(testBDM.Id != null);

        Collections_Region__c testRegion = new Collections_Region__c(
            Name = 'Test Region',
            Region_Code__c = 'ABC909'
        );
        insert(testRegion);

        Collections_Territory__c testTerritory = new Collections_Territory__c(
            Name = 'Test Territory',
            Region__c = testRegion.Id,
            Zip__c = testZipCode,
            BDM__c = testBDM.Id
        );
        insert(testTerritory);

        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=testZipCode,
            CountryCode='US', Parent_Campaign__c = null,
            Campaign_member_status__c = null,
        	Email='test@test.com');
        // Execute
        Test.startTest();
        insert(testLead);
        Test.stopTest();
    }

    /*
    static testMethod void newLeadHasTerritoryWithoutBDMTest(){
        
        String testZipCode = '36310'; // Alabama Region
        
        Profile p = [select id, name from profile where name = 'Standard User'];
        User testBDM = TestUtil.createUser('test.bdm@redcrossblood.org',p.Id,true, null, 'lastname', 'firstname');
        System.assert(testBDM.Id != null);

        Collections_Region__c testRegion = new Collections_Region__c(
            Name = 'Test Region',
            Region_Code__c = 'ABC909'
        );
        insert(testRegion);


        Collections_Territory__c testTerritory = new Collections_Territory__c(
            Name = 'Test Territory',
            Region__c = testRegion.Id,
            Zip__c = testZipCode
            //,BDM__c = testBDM.Id  // *** IMPORTANT: THERE IS NO BDM ASSIGNED TO THE TERRITORY FOR THIS TEST ****
        );
        insert(testTerritory);


        // Switch users to create non-setup objects so we don't get the mixed DML error
        User currUser = TestUtil.getCurrentUser();
        Group testGroup;
        QueueSObject testQueue;
        System.runAs(currUser){
            // Create the group and queue for the testRegion
            testGroup = new Group(Type='Queue', Name=testRegion.Name + ' Lead Queue');
            insert(testGroup);

            testQueue = new QueueSObject(SobjectType='Lead', QueueId= testGroup.Id);
            insert(testQueue);
        }

        // Create a Lead to insert
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=testZipCode,
            CountryCode='US');
        
        
        // Execute
        Test.startTest();
            insert(testLead);
        Test.stopTest();

        // Test: did the lead get a Chapter and Blood Region assigned?
        Lead leadResult = [select Collections_Territory__c, OwnerId from Lead where Id = :testLead.Id];
        System.assertEquals(testTerritory.Id, leadResult.Collections_Territory__c);
        //System.assertEquals(testGroup.Id, leadResult.OwnerId);

    }
    */

    static testMethod void newLeadUnassignedTerritoryTest(){
        String testZipCode = '36310'; // Alabama Region
        
        // Switch users to create non-setup objects so we don't get the mixed DML error
        User currUser = TestUtil.getCurrentUser();
        Group testGroup;
        QueueSObject testQueue;
        System.runAs(currUser){
            // Create the group and queue for the testRegion
            testGroup = new Group(Type='Queue', Name = 'Unassigned Lead Queue');
            insert(testGroup);

            testQueue = new QueueSObject(SobjectType='Lead', QueueId= testGroup.Id);
            insert(testQueue);
        }

        // Create a Lead to insert
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=testZipCode,
            CountryCode='US',
        	Parent_Campaign__c = null,
        	Campaign_member_status__c = null,
            Email='test@test.com');
        
        // Execute
        Test.startTest();
        insert(testLead);
        Test.stopTest();
        
        // Test: did the lead get a Chapter and Blood Region assigned?
        Lead leadResult = [select Collections_Territory__c, OwnerId from Lead where Id = :testLead.Id];
        System.assertEquals(null, leadResult.Collections_Territory__c);

    }

    static testMethod void leadOwnerChangeTest(){
        String testZipCode = '36310'; // Alabama Region
        Profile p = [select id, name from profile where name = 'Standard User'];
        User testBDM = TestUtil.createUser('test.bdm@redcrossblood.org',p.Id,true, null, 'lastname', 'firstname');
        User testBDM2 = TestUtil.createUser('test.bdm2@redcrossblood.org',p.Id,true, null, 'lastname2', 'firstname2');
        
        Collections_Region__c testRegion = new Collections_Region__c(
            Name = 'Test Region',
            Region_Code__c = 'ABC909'
        );
        insert(testRegion);

        Collections_Territory__c testTerritory = new Collections_Territory__c(
            Name = 'Test Territory',
            Region__c = testRegion.Id,
            Zip__c = testZipCode,
            BDM__c = testBDM.Id
        );
        insert(testTerritory);

        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=testZipCode,
            CountryCode='US',
            Parent_Campaign__c = null,
        	Campaign_member_status__c = null,
            Email='test@test.com');
        
        insert(testLead);
        // Execute
        Test.startTest();
        // Change the lead owner
        testLead.OwnerId = testBDM2.Id;
        update(testLead);    
        Test.stopTest();
    }

    static testMethod void leadPostalCodeUpdatedTest(){
        String testZipCode = '36310';
        String newZipCode = '02770';

        Profile p = [select id, name from profile where name = 'Standard User'];
        User testBDM = TestUtil.createUser('test.bdm@redcrossblood.org',p.Id,true, null, 'lastname', 'firstname');
        User testBDM2 = TestUtil.createUser('test.bdm2@redcrossblood.org',p.Id,true, null, 'lastname2', 'firstname2');

        Collections_Region__c testRegion = new Collections_Region__c(
            Name = 'Test Region',
            Region_Code__c = 'ABC909'
        );
        insert(testRegion);

        Collections_Territory__c testTerritory = new Collections_Territory__c(
            Name = 'Test Territory',
            Region__c = testRegion.Id,
            Zip__c = testZipCode,
            BDM__c = testBDM.Id
        );
        insert(testTerritory);

        Collections_Region__c testRegion2 = new Collections_Region__c(
            Name = 'Test Region 2',
            Region_Code__c = 'ABC123'
        );
        insert(testRegion2);

        Collections_Territory__c testTerritory2 = new Collections_Territory__c(
            Name = 'Test Territory 2',
            Region__c = testRegion2.Id,
            Zip__c = newZipCode,
            BDM__c = testBDM2.Id
        );
        insert(testTerritory2);

        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode=testZipCode,
            CountryCode='US',
            Parent_Campaign__c = null,
        	Campaign_member_status__c = null,
            Email='test@test.com'
        );
        insert(testLead);
        
        // Execute
        Test.startTest();
        testLead.PostalCode = newZipCode;
        update(testLead);    
        Test.stopTest();
    }

    static testMethod void newLeadQueueAssignmentTest(){
       String testZipCode = '36310'; // Alabama Region
        
        // Switch users to create non-setup objects so we don't get the mixed DML error
        User currUser = TestUtil.getCurrentUser();
        Group testGroup;
        QueueSObject testQueue;
        
        Collections_Region__c testRegion = new Collections_Region__c(
            Name = 'Alabama Region',
            Region_Code__c = 'ABC909'
        );
        insert(testRegion);


        Collections_Territory__c testTerritory = new Collections_Territory__c(
            Name = 'Alabama & Gulf Coast',
            Region__c = testRegion.Id,
            Zip__c = testZipCode
        );
        insert(testTerritory);

        // Create a Lead to insert
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Mobile',
            StateCode='AL',
            PostalCode=testZipCode,
            CountryCode='US',
            Parent_Campaign__c = null,
        	Campaign_member_status__c = null,
        	Email='test@test.com');
        
        
        // Execute
        Test.startTest();
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule= true;
            testLead.setOptions(dmo);
            insert(testLead);
        Test.stopTest();
    }

    static testMethod void testLeadAssignmentEmail(){
        String testZipCode = '36310'; // Alabama Region
        
        // Switch users to create non-setup objects so we don't get the mixed DML error
        User currUser = TestUtil.getCurrentUser();
        Group testGroup;
        QueueSObject testQueue;
        System.runAs(currUser){
            // Create the group and queue for the testRegion
            testGroup = new Group(Type='Queue', Email = 'mike.demeglio@redcross.org', Name = 'Test Queue');
            insert(testGroup);

            testQueue = new QueueSObject(SobjectType='Lead', QueueId= testGroup.Id);
            insert(testQueue);
        }
 
        Collections_Region__c testRegion = new Collections_Region__c(
            Name = 'Alabama Region',
            Region_Code__c = 'ABC909'
        );
        insert(testRegion);

        Collections_Territory__c testTerritory = new Collections_Territory__c(
            Name = 'Alabama & Gulf Coast',
            Region__c = testRegion.Id,
            Zip__c = testZipCode
        );
        insert(testTerritory);

        // Create a Lead to insert
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Mobile',
            StateCode='AL',
            PostalCode=testZipCode,
            CountryCode='US',
            Parent_Campaign__c = null,
        	Campaign_member_status__c = null,
            Email='test@test.com'
        );

        // Insert the lead 
        insert(testLead);

        // Execute
        Test.startTest(); 
        // Update the lead owner manually
        testLead.OwnerId = testGroup.Id;
        update(testLead);
        Test.stopTest();
        
        // Test: did the lead get a Chapter and Blood Region assigned?
        Lead leadResult = [select OwnerId, Owner.Name from Lead where Id = :testLead.Id];
        System.assertEquals(testGroup.Id, leadResult.OwnerId); 
    }
    
	static  testMethod void autoConvert() {
        skedHubBase.bypassInsertTriggers = true;
        skedHubBase.bypassUpdateTriggers = true;
        skedHubBase.bypassDeleteTriggers = true;
        // Switch users to create non-setup objects so we don't get the mixed DML error
        User currUser = TestUtil.getCurrentUser();
        Group testGroup;
        QueueSObject testQueue;

        String testZipCode = '36310';

        System.runAs(currUser) {
            // Create the group and queue for the testRegion
            testGroup = new Group(Type='Queue', Email = 'mike.demeglio@redcross.org', Name = 'Test Queue');
            insert(testGroup);

            testQueue = new QueueSObject(SobjectType='Lead', QueueId= testGroup.Id);
            insert(testQueue);
        }

        // Create a Lead to insert
        Lead testLead = new Lead();
        testLead.FirstName = 'LeadService'; 
        testLead.LastName='Tests2323';
        testLead.Company='TestComany';
        testLead.City='Aldie';
        testLead.StateCode='VA';
        testLead.PostalCode='20105';
        testLead.CountryCode='US';
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Street ='test';
        testLead.Email='test@test.com';
        testLead.Phone_Type__c ='Mobile Phone';
        testLead.Phone = '123-456-7890';
        TriggerHandler.bypass('LeadTriggerHandler');
        insert testLead;
        Triggerhandler.clearAllBypasses();

		Test.StartTest();
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
	    Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Converted');
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
	    Test.stopTest();
    }

	static testMethod void testNonAdminsDeleteLead() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
       
        //Create DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');    
        system.runAs(new User(Id = UserInfo.getUserId()))
        {
            insert testDrdUser;
        }
        
        List<Lead> leadList = new List<Lead>();
        Lead testLead = new Lead();
        testLead.FirstName = 'LeadService1'; 
        testLead.LastName='Tests23233';
        testLead.Company='TestComany1';
        testLead.City='Mobile';
        testLead.StateCode='AL';
        testLead.PostalCode='27560';
        testLead.CountryCode='US';
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Street ='test1';
        testLead.Email='test@tes1t.com';
        testLead.Phone_Type__c ='Mobile Phone';
        testLead.Phone ='23212123243';
        leadList.add(testLead);
        
        insert leadList;
        Test.startTest();
        system.runAS(testDrdUser)
        {
        	try{
                delete leadList;                            
       		} catch(Exception ex) {
           		system.assert(ex.getMessage().contains('You are not authorized to delete Leads')); 
        	}
      	}

        Test.stopTest();   
    }

    static testMethod void tempLeadForNewTaxo() {
        
        List<sked_Territory__c> territoryList = new List<sked_Territory__c>();
        Id recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c districtTerritory = new sked_Territory__c();
        districtTerritory.Name = 'District Territory';
        districtTerritory.RecordTypeId  = recordTypeId;
        districtTerritory.Start_Date__c = system.today();
        districtTerritory.End_Date__c = Date.newInstance(4000, 12,31);
        districtTerritory.External_Id_BackEnd__c = 'Bio_Collection_BSF_District_BD32_24E_4076';
        territoryList.add(districtTerritory);
        
        recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('ARC Region').getRecordTypeId();
        sked_Territory__c aRCRegionTerritory = new sked_Territory__c();
        aRCRegionTerritory.Name = 'ARC Region Territory';
        aRCRegionTerritory.RecordTypeId  = recordTypeId;
        aRCRegionTerritory.Start_Date__c = system.today();
        aRCRegionTerritory.End_Date__c = Date.newInstance(4000, 12,31);
        aRCRegionTerritory.External_Id_BackEnd__c = 'Bio_Collection_BSF_ARC Region_BD32_24E';
        territoryList.add(aRCRegionTerritory);        
        
        recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('Division').getRecordTypeId();
        sked_Territory__c divisionTerritory = new sked_Territory__c();
        divisionTerritory.Name = 'Division Territory';
        divisionTerritory.RecordTypeId  = recordTypeId;
        divisionTerritory.Start_Date__c = system.today();
        divisionTerritory.End_Date__c = system.today().addDays(180);
        divisionTerritory.External_Id_BackEnd__c = 'Bio_Collection_BSF_Division_BD32';
        territoryList.add(divisionTerritory);   
             
        insert territoryList;
        
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c();
        co.Biomed_Collection_Op_Code_Center_ID__c ='BSF_Co_005';
        co.Collection_Operation_ID__c='CoKey';
        co.Name='Collection_Operation_Name__c';
        co.External_Id__c = 'Bio_Collection_BSF_' + 'Collection_Operation_Code__c';
        co.sked_Lunch_Break_Duration_Fixed_Site__c='30';
        co.sked_Lunch_Break_Duration_Mobile__c='30';
        insert co;

        BSF_Portfolio__c bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'HProdSED_755';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment CD';
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolio.Start_Date__c = system.today().addDays(-100);
        bportfolio.End_Date__c = system.today().addDays(100);
        bportfolio.Territory_Portfolio__c = true;
        insert bportfolio;

        String bioRecruitmentRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE).getRecordTypeId();
        String bioCollOppRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();
         
        List<Taxonomy__c> taxonomyList = new List<Taxonomy__c>();

        Taxonomy__c taxonomyForPortfolio = new Taxonomy__c(ABM_Code__c='GEOR_S Georgia Coastal_ABM', ABM_Key__c=115960, ABM_Name__c='Georgia Coastal ABM', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_755', DRD_Territory_Key__c=115893, DRD_Territory_Name__c='GA South 02', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=System.today()+180, RecordTypeId=bioRecruitmentRTID,Start_Date__c=System.today()-10,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=169,Zip_Code_Key__c=13272, Zip_Code_Name__c='zipcode1', Zip_Code__c='27560',Version_Key__c=1000);
        taxonomyList.add(taxonomyForPortfolio);
        
        Taxonomy__c taxonomyForCollectionOpperation = new Taxonomy__c(Collection_Operation_Code__c='BSF_Co_005', Collection_Operation_Key__c=117514, Collection_Operation_Name__c='Louisville KY', District_Code__c='4076', District_Key__c=214, District_Name__c='Greater Louisville', Division_Code__c='BD32', Division_Key__c=42262, Division_Name__c='Central Atlantic', DS_Region_Code__c='24E', DS_Region_Key__c=117401, DS_Region_Name__c='Kentucky', Portfolio_Code__c='024001804', Portfolio_Name__c='East End Louisville Blood Donation Center', End_Date__c=Date.newInstance(4000,12,31),RecordTypeId=bioCollOppRTID, Start_Date__c=System.today(), Type_Key__c=196, Type__c=BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE, Version_Key__c=999,Zip_Code__c='27560', City__c = 'Test', State__c = 'Test');
        taxonomyList.add(taxonomyForCollectionOpperation);
        
        Taxonomy__c taxonomyForNCA = new Taxonomy__c(Collection_Operation_Code__c='BSF_Co_006', Collection_Operation_Key__c=117515, Collection_Operation_Name__c='Non-Collection Area', District_Code__c='4077', District_Key__c=215, District_Name__c='Non-Collection Area', Division_Code__c='BD32', Division_Key__c=42262, Division_Name__c='Non-Collection Area', DS_Region_Code__c='24E', DS_Region_Key__c=117401, DS_Region_Name__c='Kentucky', Portfolio_Code__c='024001804', Portfolio_Name__c='Non-Collection Area', End_Date__c=System.today()+180,RecordTypeId=bioCollOppRTID, Start_Date__c=System.today(), Type_Key__c=196, Type__c=BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE, Version_Key__c=999,Zip_Code__c='27560');
        taxonomyList.add(taxonomyForNCA); 
        insert taxonomyList;

        Lead tempLead =LeadService.createTempLead('test@test.com');
        System.assert(tempLead.Id !=null);
    }
    
    static testMethod void testCreateOrUpdateCampaignMember_Insert(){
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign', 
            IsActive = true, 
            External_Campaign_Id__c = 'ABC123',
            External_Cid__c='cid123',
            External_Med__c='med123',	
            External_Source__c='source123',
        	External_Did__c = 'DID_4848484'
        );
        insert(testCampaign);
        
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Biomed Recruitment').getRecordTypeId();
        
        Lead testLead = new Lead(
            recordTypeId = recordTypeId,
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode='27560',
            CountryCode='US');
        testLead.Parent_Campaign__c = testCampaign.Id;
        testLead.Campaign_member_status__c = 'Responded';
        testLead.Email='test@test.com';
        insert(testLead);        
        CampaignMember cm = [SELECT ID, Name, Status FROM CampaignMember LIMIT 1];        
        Assert.areEqual('Responded', cm.Status);
        
    }
    
    static testMethod void testCreateOrUpdateCampaignMember_Update(){
        
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Biomed Recruitment').getRecordTypeId();
        
        Lead testLead = new Lead(
            recordTypeId = recordTypeId,
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode='27560',
            CountryCode='US'
        );
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Email='test@test.com';
        insert(testLead);
        
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign', 
            IsActive = true, 
            External_Campaign_Id__c = 'ABC123',
            External_Cid__c='cid123',
            External_Med__c='med123',	
            External_Source__c='source123',
        	External_Did__c = 'DID_4848484'
        );
        insert(testCampaign);
        
        testLead.Parent_Campaign__c = testCampaign.Id;
        testLead.Campaign_member_status__c = 'Responded';
        
        update(testLead);
        
        CampaignMember cm = [SELECT ID, Name, Status FROM CampaignMember LIMIT 1];
        
        Assert.areEqual('Responded', cm.Status);
    }
    
    static testMethod void testTriggervalidation1(){
        
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Biomed Recruitment').getRecordTypeId();
        
        Lead testLead = new Lead(
            recordTypeId = recordTypeId,
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode='27560',
            CountryCode='US'
        );
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = 'Sent';
        testLead.Email='test@test.com';
        try {
        	insert(testLead);
        } catch(Exception ex) {
            Assert.isTrue(ex.getMessage().contains('You must select a Campaign'));
        } 
    }
    
    static testMethod void testTriggervalidation2(){
        
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Biomed Recruitment').getRecordTypeId();
        
        Lead testLead = new Lead(
            recordTypeId = recordTypeId,
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode='27560',
            CountryCode='US'
        );
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Email='test@test.com';
        insert(testLead);
        
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign', 
            IsActive = true, 
            External_Campaign_Id__c = 'ABC123',
            External_Cid__c='cid123',
            External_Med__c='med123',	
            External_Source__c='source123',
        	External_Did__c = 'DID_4848484'
        );
        insert(testCampaign);
        
        testLead.Parent_Campaign__c = testCampaign.Id;
        try{
            update(testLead);
        } catch(Exception ex) {
            Assert.isTrue(ex.getMessage().contains('You must select a Campaign'));
        } 
    }
    
    //HRP-13602 -> Test Method
    static testMethod void testRestrictFeederLeadConversion() {
        
        // Create a Lead to insert
        Lead testLead = new Lead();
        testLead.FirstName = 'LeadService'; 
        testLead.LastName='Tests2323';
        testLead.Company='TestComany';
        testLead.City='Aldie';
        testLead.StateCode='VA';
        testLead.PostalCode='20105';
        testLead.CountryCode='US';
        testLead.Parent_Campaign__c = null;
        testLead.Campaign_member_status__c = null;
        testLead.Street ='test';
        testLead.Email='test@test.com';
        testLead.Phone_Type__c ='Mobile Phone';
        testLead.Phone = '123-456-7890';
        testLead.Status = 'Potential Feeder Group';
        TriggerHandler.bypass('LeadTriggerHandler');
        insert testLead;
        Triggerhandler.clearAllBypasses();
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        Account testAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        TriggerHandler.bypass('AccountTriggerHandler');
        insert testAccount;
        TriggerHandler.clearBypass('AccountTriggerHandler');

		Test.StartTest();
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
	    Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setAccountId(testAccount.Id);
        lc.setConvertedStatus('Converted');
        lc.setDoNotCreateOpportunity(true);
        try{
        	Database.LeadConvertResult lcr = Database.convertLead(lc);
        }catch(Exception ex) {
            Assert.isTrue(ex.getMessage().containsIgnoreCase(Custom_Messages__mdt.getInstance('Non_Feeder_Acc_Convert_Validation').Value__c));
        }
	    Test.stopTest();
        
    }
}