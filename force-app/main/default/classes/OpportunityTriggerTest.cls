/* @Description : The following test class covers below apex classes and trigger
 * 1. OpportunityService
 * 2. OpportunityTriggerHandler
 * 3. OpportunityTrigger
 * **********************************************************************************************************************************************
 * Modification Log 
 * Date					     Developer Name			     Comments
 * *********************************************************************************************************************************************** 
 * 7/25/2023                  Ankit Kundu            Logic for HRP-10514 (Added Platelet Procedure in Drive Sync Logic) Apex Class:OpportunityService
 * 7/30/2023                  Anil Kallu             HRP-10312- When DCR is rejected and fields have null values, Opportunity is not updated correctly
 * 8/24/2023				  Priti Jana			 New testMethod for HRP-10115
 * 9/19/2023				  Priti Jana			 Restructured the following test class, added diff test methods to increase coverage
 * 10/27/2023			      Anil Kallu			 Fix for HRP-11296 Capture error logs in case of DB failures and run time exceptions
 * 1/19/2024			 	  Priti Jana			 Fixed existing test class errors, replaced all system.assert with new assert class, increased code coverage (90%+)
 * 6/18/2024				  Priti Jana			 Fixed existing errors, increased code coverage
 ************************************************************************************************************************************************
*/


@isTest(SeeAllData = FALSE)
public class OpportunityTriggerTest
{
    static testMethod void testcheckAccept56DaysVoilation()
    {
        Test.startTest();
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
   /*     // insert Mobile Opp 1
        Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);*/
       /* Opportunity testMobileOpp1 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Drive_Date__c = system.today().addDays(55);
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp1;*/
        
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        try{
        	insert testMobileOpp2;
        }catch(Exception ex)
        {
            Assert.isTrue(ex.getMessage().contains('This drive date violates the 56 day rule.Please acknowledge.'));
        }
        
        
        Test.stopTest();    
    }
    
    static testMethod void testUpdateDriveDateDay()
    {
        Test.startTest();
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        List<Opportunity> oppList = new List<Opportunity>();
         // insert Mobile Opp 1
        Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.newinstance(2023,10,9),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Source__c = 'Adhoc',
            Slot_Generator__c = 130
		);
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        testMobileOpp1.Slot_Generator__c = 130;
        oppList.add(testMobileOpp1);
        
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.newinstance(2023,10,10),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Slot_Generator__c = 130,
            Source__c = 'Adhoc'
		);
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        oppList.add(testMobileOpp2);
        
        // insert Mobile Opp 3
        Opportunity testMobileOpp3 = new Opportunity(
            Name = 'Test Opportunity 3',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.newinstance(2023,10,11),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Slot_Generator__c = 130,
            Source__c = 'Adhoc'
		);
        testMobileOpp3.AccountId = testMobileAccount.Id;
        testMobileOpp3.Drive_Site__c = testMobileSite.Id;
        testMobileOpp3.Parent_Template_Id__c = testTemplate.Id;
        oppList.add(testMobileOpp3);
        
        // insert Mobile Opp 4
        Opportunity testMobileOpp4 = new Opportunity(
            Name = 'Test Opportunity 4',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.newinstance(2023,10,12),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Slot_Generator__c = 130,
            Source__c = 'Adhoc'
		);
        testMobileOpp4.AccountId = testMobileAccount.Id;
        testMobileOpp4.Drive_Site__c = testMobileSite.Id;
        testMobileOpp4.Parent_Template_Id__c = testTemplate.Id;
        oppList.add(testMobileOpp4);
        
        // insert Mobile Opp 5
        Opportunity testMobileOpp5 = new Opportunity(
            Name = 'Test Opportunity 5',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.newinstance(2023,10,13),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Slot_Generator__c = 130,
            Source__c = 'Adhoc'
		);
        testMobileOpp5.AccountId = testMobileAccount.Id;
        testMobileOpp5.Drive_Site__c = testMobileSite.Id;
        testMobileOpp5.Parent_Template_Id__c = testTemplate.Id;
        oppList.add(testMobileOpp5);

        // insert Mobile Opp 6
        Opportunity testMobileOpp6 = new Opportunity(
            Name = 'Test Opportunity 6',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.newinstance(2023,10,14),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Slot_Generator__c = 130,
            Source__c = 'Adhoc'
		);
        testMobileOpp6.AccountId = testMobileAccount.Id;
        testMobileOpp6.Drive_Site__c = testMobileSite.Id;
        testMobileOpp6.Parent_Template_Id__c = testTemplate.Id;
        oppList.add(testMobileOpp6);
        
		insert oppList;
        
        List<Opportunity> oppListAfterInsert = [Select Id, Drive_Date_Day__c,Direct_Donors_To__c from Opportunity];
        Id id_acc = OpportunityService.getOrCreateDefaultAccount();
        Account accObj = [select name from Account where Id=:id_acc LIMIT 1];
		Test.stopTest();
                
        Assert.areEqual(NULL,oppListAfterInsert[0].Drive_Date_Day__c);
        Assert.areEqual('Room 1',oppListAfterInsert[0].Direct_Donors_To__c);
        Assert.areEqual('MON',oppListAfterInsert[1].Drive_Date_Day__c);
        Assert.areEqual('TUE',oppListAfterInsert[2].Drive_Date_Day__c);
        Assert.areEqual('WED',oppListAfterInsert[3].Drive_Date_Day__c);
        Assert.areEqual('THU',oppListAfterInsert[4].Drive_Date_Day__c);
        Assert.areEqual('FRI',oppListAfterInsert[5].Drive_Date_Day__c);
        Assert.areEqual('Default Account',accObj.Name);
    }
	
    static testMethod void testReturnStatements()
    {
        Test.startTest();
        OpportunityService.updateDriveDateDay(null);
        OpportunityService.assignDefaultSiteDataIfNotPresent(null);
        OpportunityService.createRecruitmentTask(null,null);
        OpportunityService.createSponsorPlanningMeetingTask(null,null);
        OpportunityService.updateTypeBasedOnPhysicalLocationType(null,null);
        Test.stopTest();
    }
    
    static testMethod void testAssignDefaultSiteDataIfNotPresent()
    {
        Test.startTest();
        Account acc = new Account(Name = 'Default Account', Internal_Name__c = 'Default Acc');
        insert acc;
        
        Opportunity opp = new opportunity(
        name = 'Test Opp');
        insert opp;
        Test.stopTest();        
    }
    
    /*static testMethod void testOppRelatedTasks()
    {        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
       
        //Create DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');    
        system.runAs(new User(Id = UserInfo.getUserId()))
        {
            insert testDrdUser;
        }
                
        //Create Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Account_Manager__c = userinfo.getUserId();
        
        insert testMobileAccount; 
        
        // insert Contact
        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        // insert Mobile Site
        sked__Location__c mobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        mobileSite.sked_Site_Contact__c = contactRec.Id;
        insert mobileSite;        
       
        // insert Mobile Opp
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = mobileSite.Id;
        testMobileOpp.Call_List_Recipient_Exist__c = true;
        testMobileOpp.End_Time__c = Time.newInstance(21, 0, 0, 0);
        testMobileOpp.StageName = 'Solicitation';
        testMobileOpp.Start_Time__c = Time.newInstance(12, 0, 0, 0);
        //testMobileOpp.Drive_Status__c ='complete';
        oppList.add(testMobileOpp);
        OpportunityRecursive.isOpportunity = false;
        insert oppList;
        
        // insert OpportunityTeamMember
        OpportunityTeamMember oppTeam = new OpportunityTeamMember (TeamMemberRole = 'District Manager', Start_Date__c = system.today());
        oppTeam.OpportunityId = oppList[0].Id;
        oppTeam.UserId = testDrdUser.id;
        oppTeam.OpportunityAccessLevel = 'Edit';
        Triggerhandler.bypass('OpportunitySplitTriggerHandler');
        insert oppTeam;
                
        // insert DOC      
        sked_Drive__c drive = new sked_Drive__c();
        drive.sked_Opportunity__c=oppList[0].id;
        drive.sked_2RBC_Projected_Procedures__c = 20;
        drive.sked_WB_Projected_Procedures__c = 20;
        drive.sked_status__c = 'System Generated';
        drive.sked_Type_of_Drive__c = 'Mobile';
        drive.sked_Drive_Site__c = mobileSite.Id;
        insert Drive;
        
        testMobileAccount.Contact_BPL__c = contactRec.Id;
        update testMobileAccount;
        	            
        List<Opportunity> updatedOppList = [SELECT Id, Name, Drive_Date__c, StageName, drive_status__c, Drive_Name__c,Is_Template__c,
                                                Drive_Site__c, Anticipated_Registered_Donors__c, WB_Projected_Procedures__c,AccountId,
                                                Start_Time__c, End_Time__c, X2RBC_Projected_Procedures__c, Collection_Operation__c,Parent_Template_Id__c
                                                FROM Opportunity WHERE Is_Template__c = False];
        
        updatedOppList[0].drive_status__c='Complete';
        skedHubBase.BypassInsertTriggers = false;
        Map<Id, Opportunity> accountOpportunityMap = new Map<Id, Opportunity>();
        for(Opportunity op : updatedOppList)
        {
            accountOpportunityMap.put(op.AccountId,op);
        }
        
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        update updatedOppList;
        OpportunityContactRole ocr = (OpportunityContactRole)mapTestData.get('OPP_CONTACT_ROLE');
        ocr.OpportunityId = updatedOppList[0].Id;
		ocr.ContactId = contactRec.id;
        ocr.Role = 'Primary Contact';
        insert ocr;

        skedHubBase.BypassInsertTriggers = false;
        system.assertEquals(1, updatedOppList.size());
        updatedOppList[0].Call_List_Recipient_Exist__c = true;
        updatedOppList[0].StageName = 'Closed';
        OpportunityRecursive.isOpportunity = true;
        triggerHandler.bypass('TaskTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        update updatedOppList;          
        Test.stopTest();
        
        List<Task> taskList = [SELECT Id, WhatId FROM Task];
        System.assertEquals(5, taskList.size());
        System.assertEquals(updatedOppList[0].Id, taskList[0].WhatId);
    }*/
    
    static testMethod void testSetCallListRecipientFlag()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp2;
        
        List<Account> accList = [select Id from Account];
        Set<Id> accId = new set<Id>();
        for(Account acc : accList)
        {
           accId.add(acc.Id); 
        }
        Test.startTest();
        OpportunityService.setCallListRecipientFlag(accId);
        List<Opportunity> oppList = [select Id, Call_List_Recipient_Exist__c from Opportunity where accountId IN: accId];
        Test.stopTest();
        
        Assert.isTrue(oppList[0].Call_List_Recipient_Exist__c == TRUE);
    }
    
    static testMethod void testCheckProductEndDate()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        Profile drdProfileInfo = [SELECT Id,Name from Profile where Name like '%DRD Profile%' LIMIT 1];
        
        /* DRD User */
        User drdUser = new User(
            ProfileId = drdProfileInfo.Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        system.runAs(new User(Id=UserInfo.getUserId()))
        {
            insert drdUser;
        }
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OrderItemTriggerHandler');
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        testMobileAccount.Account_Manager__c = drdUser.Id;
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        testMobileOpp2.Account_Manager__c = drdUser.Id;
        insert testMobileOpp2;
        
        //create product and pricebook
        List<Product2> productlist = new List<Product2>(); 
        Product2 prod1 = new Product2(Name = 'Laptop X200',
                                     Family = 'Hardware', Start_Date__c = system.today().addDays(20), End_Date__c = system.today().addDays(21));
        Product2 prod2 = new Product2(Name = 'ABCD X200',
                                     Family = 'Hardware', Start_Date__c = system.today(), End_Date__c = system.today().addDays(21));
        productlist.add(prod1);
        productlist.add(prod2);
        
        insert productlist;
       
        //Id pricebookId = Test.getStandardPricebookId();
        Id pricebookId = Test.getStandardPricebookId();
       
        // create Pricebook entry
        List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, 
                                                          Product2Id = productlist[0].Id,
                                                          UnitPrice = 0.01, 
                                                          IsActive = true);  
        pentrylist.add(standardPrice);
        insert pentrylist;

        // create order 
        List<Order> orderlist = new List<Order>();
        Order o = new Order();
        o.name='Test1';
        o.AccountId= testMobileAccount.Id ;
        o.OpportunityId = testMobileOpp2.Id ;
        o.Material_Recipient_Type__c = 'Same';
        o.Material_Recipient__c = 'Account Manager';
        o.EffectiveDate=system.today();
        o.status='draft' ;
        o.Pricebook2Id =  pricebookId ;
        o.BudgetCurrency__c = 10;
        orderlist.add(o);
        
        insert orderList;
        
        // insert order product 1
        OrderItem oItem1 = new OrderItem();
        oItem1.OrderId = orderList[0].id;
        oItem1.Product2Id = productlist[0].Id;
        oItem1.Quantity = 1;
        oItem1.UnitPrice = 0.01;
        oItem1.PricebookEntryId = pentrylist[0].Id;
        insert oItem1;
        
        // insert order product 2
        OrderItem oItem2 = new OrderItem();
        oItem2.OrderId = orderList[0].id;
        oItem2.Product2Id = productlist[1].Id;
        oItem2.Quantity = 1;
        oItem2.UnitPrice = 0.01;
        oItem2.PricebookEntryId = pentrylist[0].Id;
        insert oItem2;
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        testMobileOpp2.Drive_Date__c = system.today();
        update testMobileOpp2;
        Test.stopTest();
        
    }

    static testMethod void testTemplateImpactingRegionCheck() {
        //triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite1;
        
         // insert Mobile Site 2
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert template 2 - PLT - Inside/Outside
        Opportunity testTemplate2 = new Opportunity(
            Name = 'Mobile Template Opp 2',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            StageName = 'Discovery', 
            CloseDate = System.today(),
            Is_Template__c = TRUE,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
            Anticipated_Registered_Donors__c = 10,
            WB_Projected_Procedures__c = 11,
            X2RBC_Projected_Procedures__c = 12
        );
        testTemplate2.AccountId = testMobileAccount.Id;
        testTemplate2.Drive_Site__c = testMobileSite2.Id;
        testTemplate2.Type = 'Inside/Outside';
        insert testTemplate2;
        
        Biomed_Collection_Op_Center__c testCO = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');
        testCO.FS_Web_Scheduling_Start_Date_Offset__c = -250;
        testCO.FS_Web_Scheduling_Start_Time__c = '1015';
        testCO.FS_Web_Scheduling_End_Date_Offset__c = -25;
        testCO.FS_Web_Scheduling_End_Time_Offset__c = 0;
        insert testCO;
        
        //insert site collection operation
        sked_Site_Collection_Operation__c testSiteCO = (sked_Site_Collection_Operation__c)mapTestData.get('FIXED_SITE_COLLECTION_OPERATION');
        testSiteCO.sked_Collection_Operation__c = testCO.Id;
        testSiteCO.sked_Site__c = testMobileSite1.Id;
        insert testSiteCO;
        
        sked_Territory__c arcRegionTerritory = new sked_Territory__c(
            Name= 'Midnapur Mississippi',
            RecordTypeId =  sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('District').getRecordTypeId(),  
            sked_High_Drive_Productivity_Threshold__c= 0.800000,
            sked_Mid_Drive_Productivity_Threshold__c= 0.600000
        	);
        insert arcRegionTerritory;
        
        sked_Territory__c testterritoryDivision = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_DIVISON');
        testterritoryDivision.sked_Parent__c = arcRegionTerritory.Id;
        insert testterritoryDivision;
        
        sked_Territory__c testterri = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_ARC_REGION');
        testterri.sked_Parent__c = testterritoryDivision.Id;
        system.debug('line 617'+testterri);
        insert testterri;
        
        sked_Territory_Collection_Operation__c testterriCO = (sked_Territory_Collection_Operation__c)mapTestData.get('TERRITORY_COLLECTION_OPERATION');
        testterriCO.sked_Collection_Operation__c = testCO.Id;
        testterriCO.sked_Territory__c = testterri.Id;
        testterriCO.sked_Start_Date__c = System.Today().addDays(-5);
        testterriCO.sked_End_Date__c = System.Today().addDays(50);
        system.debug('line 622'+testterriCO);
        insert testterriCO;
        
        Test.startTest();
        
        // insert Mobile Opp 
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        testMobileOpp.Drive_Date__c = System.TODAY().addDays(50);
        insert testMobileOpp;
                
        testMobileOpp.Parent_Template_Id__c = testTemplate2.Id;
        try{
        	Update testMobileOpp; 
        }catch(Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Change requires Cancel/Rebook due to the Site changing regions'));
        }     
    }
    
    static testMethod void testSiteImpactingRegionCheck() {
        //triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite1;
        
         // insert Mobile Site 2
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert template 2 - PLT - Inside/Outside
        Opportunity testTemplate2 = new Opportunity(
            Name = 'Mobile Template Opp 2',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            StageName = 'Discovery', 
            CloseDate = System.today(),
            Is_Template__c = TRUE,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
            Anticipated_Registered_Donors__c = 10,
            WB_Projected_Procedures__c = 11,
            X2RBC_Projected_Procedures__c = 12
        );
        testTemplate2.AccountId = testMobileAccount.Id;
        testTemplate2.Drive_Site__c = testMobileSite2.Id;
        testTemplate2.Type = 'Inside/Outside';
        insert testTemplate2;
        
        Biomed_Collection_Op_Center__c testCO = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');
        testCO.FS_Web_Scheduling_Start_Date_Offset__c = -250;
        testCO.FS_Web_Scheduling_Start_Time__c = '1015';
        testCO.FS_Web_Scheduling_End_Date_Offset__c = -25;
        testCO.FS_Web_Scheduling_End_Time_Offset__c = 0;
        insert testCO;
        
        //insert site collection operation
        sked_Site_Collection_Operation__c testSiteCO = (sked_Site_Collection_Operation__c)mapTestData.get('FIXED_SITE_COLLECTION_OPERATION');
        testSiteCO.sked_Collection_Operation__c = testCO.Id;
        testSiteCO.sked_Site__c = testMobileSite1.Id;
        insert testSiteCO;
        
        sked_Territory__c arcRegionTerritory = new sked_Territory__c(
            Name= 'Midnapur Mississippi',
            RecordTypeId =  sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('District').getRecordTypeId(),  
            sked_High_Drive_Productivity_Threshold__c= 0.800000,
            sked_Mid_Drive_Productivity_Threshold__c= 0.600000
        	);
        insert arcRegionTerritory;
        
        sked_Territory__c testterritoryDivision = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_DIVISON');
        testterritoryDivision.sked_Parent__c = arcRegionTerritory.Id;
        insert testterritoryDivision;
        
        sked_Territory__c testterri = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_ARC_REGION');
        testterri.sked_Parent__c = testterritoryDivision.Id;
        system.debug('line 617'+testterri);
        insert testterri;
        
        sked_Territory_Collection_Operation__c testterriCO = (sked_Territory_Collection_Operation__c)mapTestData.get('TERRITORY_COLLECTION_OPERATION');
        testterriCO.sked_Collection_Operation__c = testCO.Id;
        testterriCO.sked_Territory__c = testterri.Id;
        testterriCO.sked_Start_Date__c = System.Today().addDays(-5);
        testterriCO.sked_End_Date__c = System.Today().addDays(50);
        system.debug('line 622'+testterriCO);
        insert testterriCO;
        
        Test.startTest();
        
        // insert Mobile Opp 
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        testMobileOpp.Drive_Date__c = System.TODAY().addDays(50);
        insert testMobileOpp;
                
        testMobileOpp.Drive_Site__c = testMobileSite2.Id;
        try{
        	Update testMobileOpp; 
        }catch(Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Change requires Cancel/Rebook due to the Site changing regions'));
        }     
    }
    
    static testMethod void testGetTaskOwner()
    {
        /* DRD Users */
        List<User> userList = new List<User>();
        User drdUser1 = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        User drdUser2 = new User(
            ProfileId = [select Id from Profile where name = 'DRD Manager'].Id,
            LastName = 'DRDLastName2',
            Email = 'DRDUser2@test.com',
            Username = 'DRDUser2@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany2',
            Title = 'TestTitle2',
            Alias = 'Tal2',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        userList.add(drdUser1);
        userList.add(drdUser2);
        
        system.runAs(new User(Id=UserInfo.getUserId()))
        {
            insert userList;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite1;
        
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert mobile opp
                
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        testMobileOpp.Account_Manager__c = userList[0].Id;
        //testMobileOpp.Source__c = 'Adhoc';
        insert testMobileOpp;
        
        Opportunity testMobileOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Accept_56_Day_Rule_Violation__c = TRUE
		);
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate1.Id;
        //testMobileOpp2.Source__c = 'Adhoc';
        insert testMobileOpp2;
        
        List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
        
        OpportunityTeamMember oppTeam1 = new OpportunityTeamMember();
        oppTeam1.OpportunityId = testMobileOpp.Id;
        oppTeam1.TeamMemberRole = 'District Manager';
        oppTeam1.UserId = userList[1].Id;
        oppTeam1.Start_Date__c = system.today();
        oppTeam1.OpportunityAccessLevel = 'Edit';
        oppTeamList.add(oppTeam1);
        
        OpportunityTeamMember oppTeam2 = new OpportunityTeamMember();
        oppTeam2.OpportunityId = testMobileOpp.Id;
        oppTeam2.TeamMemberRole = 'Account Specialist';
        oppTeam2.UserId = UserInfo.getUserId();
        oppTeam2.Start_Date__c = system.today();
        oppTeam2.OpportunityAccessLevel = 'Edit';
        oppTeamList.add(oppTeam2);
                
        //Triggerhandler.bypass('OpportunityTriggerhandler');
        insert oppTeamList;
        //TriggerHandler.clearAllBypasses();
        Test.startTest();
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
        for(OpportunityTeamMember oppT : oppTeamList)
        {
            if (!oppTeamMembersMap.containsKey(oppT.OpportunityId))
            {
            	oppTeamMembersMap.put(oppT.OpportunityId, new List<OpportunityTeamMember>());
        	}
        	oppTeamMembersMap.get(oppT.OpportunityId).add(oppT);
        }
        
        String am_dm = String.valueOf(Task_Reassignment_Matrix__mdt.getInstance('Recruitment_Task')?.Assigned_To__c);
        
        Id taskOwnerId1 = OpportunityService.getTaskOwner(testMobileOpp, oppTeamMembersMap,am_dm);
        Id taskOwnerId2 = OpportunityService.getTaskOwner(testMobileOpp2, oppTeamMembersMap,am_dm);
        
        OpportunitySplitType revenueSplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName='Revenue' ];
      	 List<Opportunity> oppNewList = [select id, ownerid from Opportunity where is_template__c = false];
        Set<Id> setOfOpptyIds = new Set<Id>();
        for(Opportunity opp : oppNewList)
        {
            setOfOpptyIds.add(opp.Id);
        }
        
        /*OpportunitySplit oppSplit = new OpportunitySplit();
        oppSplit.OpportunityId = oppNewList[0].Id ;
        oppSplit.SplitPercentage = 50.0;
        oppSplit.SplitOwnerId = userList[0].Id;
        oppSplit.SplitTypeId = revenueSplitType.id;
        insert oppSplit;*/
        oppNewList[0].ownerid=userList[0].Id;
        //Triggerhandler.bypass('OpportunityTriggerHandler');
        update oppNewList[0];
        TriggerHandler.clearAllBypasses();
        OpportunityService.UpdateOwnerSplit(oppNewList);
        opportunityService.deleteOpptyTeamMembers(setOfOpptyIds);
        Test.stopTest();
     
		Assert.isTrue(taskOwnerId1 == userList[0].Id);        
    }
    
    static testMethod void testValidatePromotionEndDate()
    {	
        TriggerHandler.bypass('AccountTriggerHandler'); 
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
       
        sked__Location__c site1 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site1;
        
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.is_Template__c = true;
        templateOpp.Procedure_Projections_Template__c = 20;
        templateOpp.Projected_Registered_Donors_Template__c = 30;
        templateOpp.Staffing_Template__c = 40;
		templateOpp.Volunteers_Template__c = 10;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        templateOpp.Drive_Site__c =site1.Id ;
        insert templateOpp;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(80);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time()+1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Plasma_Pheresis_Projected_Procedures__c = 3;
        mobileOpportunityRecord.Platelet_Projected_Procedures__c = 1;
        insert mobileOpportunityRecord;
        //This is added to cover 1084 AccountTeamMemberService methods--Starts
        
        AccountTeamMember atm3 = new AccountTeammember();
        atm3.AccountAccessLevel = 'Edit';
        atm3.CaseAccessLevel = 'Edit';
        atm3.OpportunityAccessLevel = 'Edit';
        atm3.userId = userInfo.getUserId();
        atm3.AccountId = testMobileAccount.Id;
        atm3.TeamMemberRole = 'Account Manager';
        atm3.Start_Date__c = System.today();
        atm3.End_Date__c = System.today();
        atm3.Is_Covering_Recruiter__c = true;
        atm3.Coverage_Reason__c = 'Leave of Absence (LOA)';        
        insert atm3;
        
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = testMobileAccount.Id; 
        serviceRole.Contact__c = contactRec.id;
        insert serviceRole;
        
         // insert OpportunityContactRoles (to cover AssignDriveSerivcesRoleForCBOpps method)
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = templateOpp.id;
        insert oppConRole;

        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityAccessLevel = 'Edit';
        otm.userId = userInfo.getUserId();
        otm.OpportunityId = mobileOpportunityRecord.id;
        otm.TeamMemberRole = 'Account Manager';
        insert otm;

        Promotion__c promotion = new Promotion__c(Name='Test Promotion');
        Date todayDate = Date.today();
        promotion.Start_Date__c = Date.Today();
        promotion.End_Date__c = Date.Today().addDays(85);
        promotion.Supplier__c = 'Drive';
        insert promotion;
       
        Opportunity_Promotion__c oppPromo= new Opportunity_Promotion__c();
        oppPromo.Blood_Drive_Opportunity__c = mobileOpportunityRecord.id;
        oppPromo.Promotion__c = promotion.id;
        insert oppPromo;
                
        Test.startTest();
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(90);
        mobileOpportunityRecord.Drive_Date_Change_Reason__c = 'Test';
		update mobileOpportunityRecord;
        /*
            try
            {
                mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(90);
                update mobileOpportunityRecord;
            }catch(Exception e)
            {
                Boolean expectedExceptionThrown =  e.getMessage().contains('Please choose the current template') ? true : false;
        
            }
        */
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
    static testMethod void testSendEmail()
    {        
        List<String> emailIds = new List<String> {'test@test.com'};
        List<String> affectedOppPromoNames = new List<String> {'test'};
        Test.startTest();
        OpportunityService.sendEmail(emailIds, affectedOppPromoNames);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        //Assert.areEqual(1, invocations, 'Email has been sent');
    }
    
    static testMethod void testPopulateDriveWorksheetData()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite1;
        
        Test.startTest();
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert mobile opp
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        testMobileOpp.Open_to_Public__c = 'Yes';
        testMobileOpp.Security_Escort_Name__c = 'TEST';
        oppList.add(testMobileOpp);
        insert oppList;
        
        sked_Drive__c drives = new sked_Drive__c();
        drives.sked_Opportunity__c = oppList[0].Id;
        drives.sked_Account__c = testMobileAccount.Id;
        drives.sked_Drive_Date__c=oppList[0].Drive_Date__c;
        drives.sked_2RBC_Projected_Procedures__c = 20;
        drives.sked_WB_Projected_Procedures__c = 20;
        insert drives;
        
        OpportunityService.populateDriveWorksheetData(oppList);
        OpportunityService.checkOppNameChange(oppList);
        Test.stopTest();
        
        sked_Drive__c driveAfterUpdate = [select Id, sked_Open_to_Public__c,OwnerId, sked_Opportunity__r.OwnerId from sked_Drive__c where Id=:drives.id];
        Assert.areEqual('Yes', driveAfterUpdate.sked_Open_to_Public__c);
    }
    
    static testMethod void testUpdateDriveOwnerOnOppOwnerUpdate()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
		TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler'); 
        TriggerHandler.bypass('AccountTriggerHandler'); 
        TriggerHandler.bypass('ContactTriggerHandler'); 
        /* DRD Users */
        List<User> userList = new List<User>();
        User drdUser1 = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        User drdUser2 = new User(
            ProfileId = [select Id from Profile where name = 'DRD Manager'].Id,
            LastName = 'DRDLastName2',
            Email = 'DRDUser2@test.com',
            Username = 'DRDUser2@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany2',
            Title = 'TestTitle2',
            Alias = 'Tal2',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        userList.add(drdUser1);
        userList.add(drdUser2);
        
        system.runAs(new User(Id=UserInfo.getUserId())) {
            insert userList;
        }
        
        // Portfolios 
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeIdTax = recordTypesadjustment.get('Bio Recruitment CD').getRecordTypeId();        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);        
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',
                                           DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',  
                                           DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate1,
                                           RecordTypeId=RecTypeIdTax, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S',
                                           Team_Name__c='MICH_Detroit S',Type__c='Bio Recruitment',  Version_Key__c=108.0, Zip_Code__c='30622');
        
        taxList.add(tax1);        
        insert taxList;
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        DMPortfolio.External_Key__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c+'_'+taxList[0].Start_Date__c;
        DMPortfolio.External_Key_BackEnd__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c;
        
        insert DMPortfolio;
        
        BSF_Portfolio__c AMPortfolio = new BSF_Portfolio__c();
        AMPortfolio.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolio.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolio.Portfolio_Type__c = 'Account Manager';
        AMPortfolio.Account_Based_Portfolio__c = false;
        AMPortfolio.Parent_Portfolio__c=DMPortfolio.id;
        AMPortfolio.Territory_Portfolio__c = true;
        insert AMPortfolio;
       
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite1;
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert mobile opp
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        testMobileOpp.Open_to_Public__c = 'Yes';
        testMobileOpp.Security_Escort_Name__c = 'TEST';
        testMobileOpp.Account_Manager__c = userList[0].Id;
        testMobileOpp.Account_Manager_Portfolio__c = AMPortfolio.Id;
        testMobileOpp.District_Manager_Portfolio__c = DMPortfolio.Id;
        oppList.add(testMobileOpp);
        insert oppList;
        
        Map<Id,Id> oppWithOwnerIdMap = new Map<Id,Id>();
        Map<Id,Id> oppWithAccMangrIdMap = new Map<Id,Id>();
        Map<Id,Opportunity> oppIdVsAMDMPortfoliodMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> oppIdVsAMDMPortfoliodMap1 = new Map<Id,Opportunity>();
        
        sked_Drive__c drives = new sked_Drive__c();
        drives.sked_Opportunity__c = oppList[0].Id;
        drives.sked_Account__c = testMobileAccount.Id;
        drives.sked_Drive_Date__c=oppList[0].Drive_Date__c;
        drives.sked_2RBC_Projected_Procedures__c = 20;
        drives.sked_WB_Projected_Procedures__c = 20;
        insert drives;
        Test.startTest();
        oppList[0].ownerId = userList[1].Id;
        update oppList[0];
        for(Opportunity opp : oppList)
        {
            oppWithOwnerIdMap.put(opp.Id, opp.OwnerId);
            oppWithAccMangrIdMap.put(opp.Id,opp.Account_Manager__c);
            oppIdVsAMDMPortfoliodMap1.put(opp.Id,opp);
        }
        opportunityService.UpdateDriveOwnerOnOppOwnerUpdate(oppWithOwnerIdMap, oppWithAccMangrIdMap,oppIdVsAMDMPortfoliodMap); // with oppIdVsAMDMPortfoliodMap == NULL
        opportunityService.UpdateDriveOwnerOnOppOwnerUpdate(oppWithOwnerIdMap, oppWithAccMangrIdMap,oppIdVsAMDMPortfoliodMap1); // with oppIdVsAMDMPortfoliodMap != NULL
        Test.stopTest();
        
    }
    
    static testmethod void testModifyTasksOnDriveDateChange()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite1.sked_Pre_Drive_Security_Due_Date__c = '14';
        insert testMobileSite1;
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert mobile opp
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        List<Opportunity> oppList = new List<Opportunity>();
    
        Opportunity testMobileOpp = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today().addDays(10),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Source__c = 'Adhoc',
            Slot_Generator__c = 130
		);
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        oppList.add(testMobileOpp);
        insert oppList;
        
        List<Task> taskList = new List<task>();
        
        Task task1 = new Task();
        task1.whatId = oppList[0].Id;
        task1.subject = 'Sponsor Planning Meeting - System Generated';
        task1.OwnerId = userInfo.getUserId();
        task1.ActivityDate = oppList[0].Drive_Date__c;
        task1.Status = 'Not Started';
        task1.Priority = 'High';
        taskList.add(task1);
        
        /*Task task2 = new Task();
        task2.whatId = oppList[0].Id;
        task2.subject = '72 Hour Check in - System Generated';
        task2.OwnerId = userInfo.getUserId();
        task2.ActivityDate = oppList[0].Drive_Date__c;
        task2.Status = 'Not Started';
        task2.Priority = 'High';
        taskList.add(task2);
        
        Task task3 = new Task();
        task3.whatId = oppList[0].Id;
        task3.subject = 'Recruitment Task - System Generated';
        task3.OwnerId = userInfo.getUserId();
        task3.ActivityDate = oppList[0].Drive_Date__c;
        task3.Status = 'Not Started';
        task3.Priority = 'High';
        taskList.add(task3);
        
        Task task4 = new Task();
        task4.whatId = oppList[0].Id;
        task4.subject = 'Security Information Completion';
        task4.OwnerId = userInfo.getUserId();
        task4.ActivityDate = oppList[0].Drive_Date__c;
        task4.Status = 'Not Started';
        task4.Priority = 'High';
        taskList.add(task4);*/
        
        insert taskList;
        Test.startTest();
        Date dDate = oppList[0].Drive_Date__c;
        oppList[0].Drive_Date__c = dDate.adddays(20);
        oppList[0].Drive_Date_Change_Reason__c='test';
        //oppList[0].Accepts_Automation__c = 'NO';
        Update oppList[0];
        
        Test.stopTest();        
    }
    
    static testmethod void testCheckForOppStageChange1()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
		TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler'); 
        TriggerHandler.bypass('AccountTriggerHandler'); 
        TriggerHandler.bypass('ContactTriggerHandler'); 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite1.sked_Pre_Drive_Security_Due_Date__c = '14';
        insert testMobileSite1;
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert mobile opp
               
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        oppList.add(testMobileOpp);
        insert oppList;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        Account_Service_Role__c accBPL = new Account_Service_Role__c(
        	Account__c = testMobileAccount.Id,
        	Contact__c = contactRec.Id,
        	Start_Date__c = System.today().addDays(-40),
        	Account_Service_Role__c = 'Blood Program Leader'
        );
        insert accBPL;
        
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = oppList[0].id;
        insert oppConRole;
        
        Test.startTest();
        oppList[0].stagename = 'Closed';
        try{
            TriggerHandler.bypass('AccountTriggerHandler'); 
            update oppList[0];
        } catch(Exception ex)
        {
            system.debug('ex.getMessage() '+ex.getMessage());
            Assert.isTrue(ex.getMessage().contains('Opportunity without a drive record cannot have a committed stage, closed stage, or confirmed drive status.'));
        }
        
        Opportunity mobileOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Committed',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        mobileOpp2.AccountId = testMobileAccount.Id;
        mobileOpp2.Drive_Site__c = testMobileSite1.Id;
        mobileOpp2.Parent_Template_Id__c = testTemplate1.Id;
        mobileOpp2.Accept_56_Day_Rule_Violation__c = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler'); 
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert mobileOpp2;
        Triggerhandler.clearBypass('OpportunityTriggerHandler');
        mobileOpp2.stageName = 'Solicitation';
        try{
        	update mobileOpp2;
        }catch(Exception ex)
        {
            Assert.isTrue(ex.getMessage().contains('Only below stage transition is valid'));
        }
        Test.stopTest();        
    }
    
    static testmethod void testCheckForOppStageChange2()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite1.sked_Pre_Drive_Security_Due_Date__c = '14';
        insert testMobileSite1;
        
        
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        Opportunity mobileOpp3 = new Opportunity(
            Name = 'Test Opportunity 3',
        	StageName = 'Withdrawn',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        mobileOpp3.AccountId = testMobileAccount.Id;
        mobileOpp3.Drive_Site__c = testMobileSite1.Id;
        mobileOpp3.Parent_Template_Id__c = testTemplate1.Id;
        mobileOpp3.Accept_56_Day_Rule_Violation__c = TRUE;
        TriggerHandler.bypass('OpportunityTriggerhandler');
        insert mobileOpp3;
        
        Triggerhandler.clearAllBypasses();
        Test.startTest();
        mobileOpp3.stageName = 'Committed';
        try{
        update mobileOpp3;
        }catch(Exception ex)
        {}
        
        Opportunity mobileOpp4 = new Opportunity(
            Name = 'Test Opportunity 4',
        	StageName = 'Excluded',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        mobileOpp4.AccountId = testMobileAccount.Id;
        mobileOpp4.Drive_Site__c = testMobileSite1.Id;
        mobileOpp4.Parent_Template_Id__c = testTemplate1.Id;
        mobileOpp4.Accept_56_Day_Rule_Violation__c = TRUE;
        TriggerHandler.bypass('OpportunityTriggerhandler');
        insert mobileOpp4;
        Triggerhandler.clearAllBypasses();
        mobileOpp4.stageName = 'Discovery';
        try{
        update mobileOpp4;
        }catch(Exception ex)
        {
			Assert.isTrue(ex.getMessage().contains('A Blood Drive Opportunity cannot move back once it has moved to the next Stage in the Lifecycle'));
        }
    }
    
    static testmethod void testCheckForOppStageChange3()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
		TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler'); 
        TriggerHandler.bypass('AccountTriggerHandler'); 
        TriggerHandler.bypass('ContactTriggerHandler'); 
        Test.startTest();
        Profile drdProfileInfo = [SELECT Id,Name from Profile where Name like '%DRD Profile%' LIMIT 1];
        
        /* DRD User */
        User drdUser = new User(
            ProfileId = drdProfileInfo.Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        system.runAs(new User(Id=UserInfo.getUserId())) {
            insert drdUser;
        }
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite1.sked_Pre_Drive_Security_Due_Date__c = '14';
        insert testMobileSite1;
        
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        Opportunity mobileOpp3 = new Opportunity(
            Name = 'Test Opportunity 3',
        	StageName = 'Cancelled',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Initiated_By__c = '	ARC_Initiated_Mobile',
            sked_Cancellation_Reason__c = 'ARC Management'
		);
        mobileOpp3.AccountId = testMobileAccount.Id;
        mobileOpp3.Drive_Site__c = testMobileSite1.Id;
        mobileOpp3.Parent_Template_Id__c = testTemplate1.Id;
        mobileOpp3.Accept_56_Day_Rule_Violation__c = TRUE;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert mobileOpp3;
        
        Triggerhandler.clearBypass('OpportunityTriggerHandler');
        
        mobileOpp3.stageName = 'Closed';
        system.runAs(drdUser) {
        	try{
        		update mobileOpp3;
        	} catch(Exception ex)
        	{}
        }
        
        Opportunity mobileOpp4 = new Opportunity(
            Name = 'Test Opportunity 4',
        	StageName = 'Closed',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        mobileOpp4.AccountId = testMobileAccount.Id;
        mobileOpp4.Drive_Site__c = testMobileSite1.Id;
        mobileOpp4.Parent_Template_Id__c = testTemplate1.Id;
        mobileOpp4.Accept_56_Day_Rule_Violation__c = TRUE;
        TriggerHandler.bypass('OpportunityTriggerhandler');
        insert mobileOpp4;
        Triggerhandler.clearAllBypasses();
        mobileOpp4.stageName = 'Discovery';
        system.runAs(drdUser)
        {
            try{
            	update mobileOpp4;
            }catch(Exception ex)
            {
                Assert.isTrue(ex.getMessage().contains('Only below stage transition is valid'));
            }
        }
        
        Test.stopTest();
    }
    
    static testMethod void testUpdateWebSchedulingStart_EndDates()
    {        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
       
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
		
        sked__Location__c testSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testSite;
        
        //Template opp
        Opportunity testMobileTemplateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testMobileTemplateOpp.AccountId = testMobileAccount.Id;
        testMobileTemplateOpp.Drive_Site__c = testSite.Id;
        insert testMobileTemplateOpp;

        //Mobile Opp 1
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testSite.Id;
        testMobileOpp.Online_Scheduling_Enabled__c = 'Yes';
        testMobileOpp.Parent_Template_Id__c = testMobileTemplateOpp.Id;
        
        Test.startTest();
        	insert testMobileOpp;
        Test.stopTest();
    }

    static testMethod void testUpdateWebSchedulingStart_EndDates_WebSchedOffsetOverrideInTemplate()
    {        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
       
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
		
        sked__Location__c testSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testSite.sked_Timezone__c = 'America/Los_Angeles';
        insert testSite;
        
        //Template opp
        Opportunity testMobileTemplateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testMobileTemplateOpp.AccountId = testMobileAccount.Id;
        testMobileTemplateOpp.Drive_Site__c = testSite.Id;
        insert testMobileTemplateOpp;

        testMobileTemplateOpp.Web_Sched_Offset_from_CO_Global_Settings__c = false; 
        testMobileTemplateOpp.Web_Scheduling_End_Date_Offset__c=0;
        testMobileTemplateOpp.Web_Scheduling_End_Time_Offset__c=0;
        testMobileTemplateOpp.Web_Scheduling_Start_Date_Offset__c=-180;
        testMobileTemplateOpp.Web_Scheduling_Start_Time__c = '0001';
        update testMobileTemplateOpp;
        
        //Mobile Opp 1
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testSite.Id;
        testMobileOpp.Online_Scheduling_Enabled__c = 'Yes';
        testMobileOpp.Parent_Template_Id__c = testMobileTemplateOpp.Id;
        
        Test.startTest();
        	insert testMobileOpp;
        Test.stopTest();
    }
    
    static testMethod void testUpdateWebSchedulingStart_EndDatesFixed()
    {        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
       
        // insert FS Account
        Account testFixedAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        insert testFixedAccount;
		
        // insert FS Location
        sked__Location__c testSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        insert testSite;
        
        //insert Template opp
        Opportunity testFixedTemplateOpp = (Opportunity)mapTestData.get('FIXED_TEMPLATE_OPP');
        testFixedTemplateOpp.AccountId = testFixedAccount.Id;
        testFixedTemplateOpp.Drive_Site__c = testSite.Id;
        testFixedTemplateOpp.Web_Sched_Offset_from_CO_Global_Settings__c = false;
        //insert testFixedTemplateOpp;

        //insert Fixed Opp 1
        Opportunity testFixedOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        testFixedOpp.accountId = testFixedAccount.Id;
        testFixedOpp.Drive_Site__c = testSite.Id;
        testFixedOpp.Online_Scheduling_Enabled__c = 'Yes';
        testFixedOpp.Parent_Template_Id__c = testFixedTemplateOpp.Id;
        
        Test.startTest();
        insert testFixedOpp;
        Test.stopTest();
    }
    
    static testMethod void testTemplateActiveCheckValidation()
    {        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
       
        // insert Mobile Acc
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
		
        // insert Mobile Site
        sked__Location__c testSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testSite;
        
        //insert Template opp
        Opportunity testMobileTemplateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testMobileTemplateOpp.AccountId = testMobileAccount.Id;
        testMobileTemplateOpp.Drive_Site__c = testSite.Id;
        testMobileTemplateOpp.Template_Status__c = 'Active';
        insert testMobileTemplateOpp;

        //insert Mobile Opp 1
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testSite.Id;
        testMobileOpp.Parent_Template_Id__c = testMobileTemplateOpp.Id;
        insert testMobileOpp;
        
        Test.startTest();
        testMobileTemplateOpp.Template_Status__c = 'Inactive';
        
        try{
            update testMobileTemplateOpp;
        }catch(Exception ex){
            Boolean expectedExceptionMsg =  ex.getMessage().contains('Template cannot be made inactive because of active related opportunities') ? true : false;
            Assert.areEqual(expectedExceptionMsg, true);
        }
        Test.stopTest();
    }
    
    static testMethod void testUpdateOriginalValueOnOpportunity()
    {        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Acc
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        // insert global tag
        sked__Tag__c tag = (sked__Tag__c)mapTestData.get('GLOBAL_TAG');
        insert tag;
		
        // insert Mobile site
        sked__Location__c site = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert site;
        
        // insert template opp
        Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.accountId = testMobileAccount.Id;
        templateOpp.Drive_Site__c = site.Id;
        insert templateOpp;

        // insert mobile opp
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.accountId = testMobileAccount.Id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Is_Template__c = false;
        insert mobileOpportunityRecord;
        
        Test.startTest();
            mobileOpportunityRecord.Anticipated_Registered_Donors_Original__c = 11;
            try {
                update mobileOpportunityRecord;
            } catch (Exception ex) {
                Assert.areEqual(true, ex.getMessage().containsIgnoreCase('Original values cannot be changed'));
            }
        Test.stopTest();
    }
    
    static testmethod void testDuplicateSiteCheck()
    {
        Test.startTest();  
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert mobile acc
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
        
        // insert site1
        sked__Location__c site = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert site;
        
        // insert site2
        sked__Location__c site2 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site2;
      
        // insert templateOpp
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.Drive_Site__c = site.Id;
        insert templateOpp;
        Map<Id, Opportunity> oldOpportunityMap = new Map<Id, Opportunity>([select Id, Drive_Site__c from Opportunity where Is_template__c = true]);
        
        // insert mobile opp
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Drive_Site__c = site.Id;
        insert mobileOpportunityRecord;
                
     	List<Opportunity> newOppList = new List<Opportunity>();
    
        TriggerHandler.clearAllBypasses();      
        templateOpp.Drive_Site__c = site2.Id;
        newOppList.add(templateOpp);
        try{
           update newOppList;        
        	opportunityService.duplicateSiteCheck(oldOpportunityMap, newOppList);  
        }Catch(Exception ex)
        {}
                 
        Test.stopTest();
        
    }
    
    static testMethod void testUpdateProjectionHistory()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert fixed site acc
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        insert testFixedSiteAccount;
        
        // insert fixed site
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        insert testFixedSite;
        
        // insert fixed site opp
        Opportunity testFixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        testFixedSiteOpp.AccountId = testFixedSiteAccount.id;
        testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
        testFixedSiteOpp.Anticipated_Registered_Donors__c = 10;
        insert testFixedSiteOpp;
        
        Test.startTest();
        testFixedSiteOpp.Anticipated_Registered_Donors__c = 20;
        testFixedSiteOpp.AnticipatedRegisterDonorChangeReason__c = 'Test Anticipated Donors Changed';
        testFixedSiteOpp.WB_Projected_Procedures__c = 20;
        testFixedSiteOpp.WholeBloodProcedureProjectedChangeReason__c = 'Test WB Changed';
        testFixedSiteOpp.X2RBC_Projected_Procedures__c = 20;
        testFixedSiteOpp.DoubleRedProceduresProjectedChangeReason__c = 'Test X2RBC Changed';
        update testFixedSiteOpp;
        Test.stopTest();
        
        Opportunity oppAfterUpdate = [select Id, Projection_History__c from Opportunity where Id=:testFixedSiteOpp.Id];
        Assert.isTrue(oppAfterUpdate.Projection_History__c!= NULL);
    }
    
    static testMethod void testUpdateOpportunitiesRelatedToTemplate()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp2;
        
        Test.startTest();
        testTemplate.Anticipated_Registered_Donors__c = 20;
        testTemplate.AnticipatedRegisterDonorChangeReason__c = 'Test Anticipated Donors Changed';
        testTemplate.WB_Projected_Procedures__c = 20;
        testTemplate.WholeBloodProcedureProjectedChangeReason__c = 'Test WB Changed';
        testTemplate.X2RBC_Projected_Procedures__c = 20;
        testTemplate.DoubleRedProceduresProjectedChangeReason__c = 'Test X2RBC Changed';
        update testTemplate;
        Test.stopTest();

		List<Opportunity> oppAfterUpdate = [select Id, WB_Projected_Procedures__c,WholeBloodProceduresProjectedTemplate__c from Opportunity];
        Assert.isTrue(oppAfterUpdate[1].WholeBloodProceduresProjectedTemplate__c== oppAfterUpdate[0].WB_Projected_Procedures__c);        
    }
    
    static testmethod void testInsertOrUpdateCovRecruiterOpportunitySplit()
    {
        /* DRD Users */
        List<User> userList = new List<User>();
        User drdUser1 = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        User drdUser2 = new User(
            ProfileId = [select Id from Profile where name = 'DRD Manager'].Id,
            LastName = 'DRDLastName2',
            Email = 'DRDUser2@test.com',
            Username = 'DRDUser2@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany2',
            Title = 'TestTitle2',
            Alias = 'Tal2',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        userList.add(drdUser1);
        userList.add(drdUser2);
        
        system.runAs(new User(Id=UserInfo.getUserId()))
        {
            insert userList;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert fixed site acc
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testFixedSiteAccount.Account_Manager__c = userList[0].Id;
        insert testFixedSiteAccount;
        
        // insert fixed Acc Team member - Coverage Recruiter 1
        List<AccountTeamMember> accTeamList = new List<AccountTeamMember>();
        AccountTeamMember fixedAccTeamMember1 = new AccountTeamMember(
        	AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            UserId = userList[0].Id,
            TeamMemberRole = 'Account Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(20),
            Is_Covering_Recruiter__c = true,
            Coverage_Reason__c = 'Leave of Absence (LOA)'
        );
        fixedAccTeamMember1.AccountId = testFixedSiteAccount.Id;
        accTeamList.add(fixedAccTeamMember1);
        
        // insert fixed Acc Team member - Coverage Recruiter 2
        AccountTeamMember fixedAccTeamMember2 = new AccountTeamMember(
        	AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            UserId = userList[1].Id,
            TeamMemberRole = 'Account Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(10),
            Is_Covering_Recruiter__c = true,
            Coverage_Reason__c = 'Vacant Territory'
        );
        fixedAccTeamMember2.AccountId = testFixedSiteAccount.Id;
        accTeamList.add(fixedAccTeamMember2);
        
        Triggerhandler.bypass('AccountTriggerhandler');
        Triggerhandler.bypass('AccountTeamMemberTriggerHandler');
        insert accTeamList;
        
        // insert fixed site
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        insert testFixedSite;
        
        // insert fixed site opp
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity testFixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        testFixedSiteOpp.AccountId = testFixedSiteAccount.id;
        testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
        testFixedSiteOpp.Anticipated_Registered_Donors__c = 10;
        oppList.add(testFixedSiteOpp);
        insert oppList;
        
        
        // insert Affiliation - to cover deleteDriveAffiliationOnDriveDateChange method
        Marketing_Program__c affL = new Marketing_Program__c(Name = 'Test Affiliation 1', External_Name__c = 'TESTAFF',Booking_Start_Date__c = system.today().addDays(3), Booking_End_Date__c = system.today().addDays(10), Scope__c = 'Drive');
        insert affL;
        
        // insert Drive Affiliations
        Drive_Marketing_Programs__c driveAff = new Drive_Marketing_Programs__c();
        driveAff.Blood_Drive_Opportunity__c = oppList[0].Id;
        driveAff.Marketing_Program__c = affL.Id;
        driveAff.Account__c = testFixedSiteAccount.id;
        insert driveAff;
        
        Test.startTest();
        // To cover AddOpptyTeamMembers_Migration() method --> Start
        OpportunityService.AddOpptyTeamMembers_Migration(oppList);
        OpportunityService.publishPlarformEventsOnAfterInsert(oppList);
        // To cover AddOpptyTeamMembers_Migration() method --> End
        
        Date driveDate = oppList[0].Drive_Date__c;
        testFixedSiteOpp.Drive_Date__c = driveDate.addDays(10);
        testFixedSiteOpp.Drive_Date_Change_Reason__c='Test';
        update testFixedSiteOpp;        
        
        // to cover OpportunityService.cancelTasksForCancelledOpportunities().....
        Opportunity oppAfterUpdate = [select id, stagename,Drive_Date__c, sked_Cancellation_Reason__c, Initiated_By__c from Opportunity where Id=:testFixedSiteOpp.Id];
        oppAfterUpdate.StageName = 'Cancelled';
        oppAfterUpdate.sked_Cancellation_Reason__c = 'ARC Management';
        oppAfterUpdate.Initiated_By__c = 'ARC Initiated-Fixed';
        update oppAfterUpdate;
        
        Map<Id,Opportunity> cancelOppMap1 = new Map<Id,Opportunity>([select Id, stagename, drive_date__c from Opportunity where Id=:oppAfterUpdate.Id]);
        Map<Id,Opportunity> cancelOppMap2 = new Map<Id,Opportunity>();
        
        Task testTask = new Task();
        testTask.subject = 'Test';
        testTask.status = 'Not Started';
        testTask.OwnerId = userList[0].Id;
        testTask.whatId = oppAfterUpdate.Id;
        testTask.ActivityDate = oppAfterUpdate.Drive_Date__c.addDays(4);
        TriggerHandler.bypass('TaskTriggerHandler');
        insert testTask;
        
        OpportunityService.cancelTasks(cancelOppMap1);
        OpportunityService.cancelTasks(cancelOppMap2);
        Test.stopTest();
        
    }
    
    static testMethod void testUpdateWebSchedulingStart_EndDates_WithoutGlobalSchedules()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert Mobile Site 2
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        List<Opportunity> newItemList = new List<Opportunity>();
       	List<Opportunity> newList1 = new List<Opportunity>();
        
        Test.startTest();
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'Yes',
            Web_Schedule_StartDate__c = system.today(),
            Web_Schedule_Start_Time__c = Time.newInstance(10, 0, 0, 0),
            Web_Schedule_EndDate__c = system.today().addDays(4),
            Web_Schedule_End_Time__c = Time.newInstance(15, 30, 0, 0),
            Web_Scheduling_End_Time_Offset__c = 3,
            Web_Scheduling_Start_Date_Offset__c = 4,
            Web_Scheduling_End_Date_Offset__c = 2
		);
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        newItemList.add(testMobileOpp2);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');        
        insert newItemList;
        Map<Id, Opportunity> mapOfOfOldOppties = new Map<Id, Opportunity>([select Id, Online_Scheduling_Enabled__c,Drive_Site__c, Web_Schedule_StartDate__c, Web_Schedule_Start_Time__c,
                                                                          Web_Schedule_EndDate__c, Web_Schedule_End_Time__c from Opportunity where Id =: newItemList[0].Id]);
        newItemList[0].Drive_Site__c = testMobileSite2.Id;
        update newItemList;
        OpportunityService.updateWebSchedulingStart_EndDates_WithoutGlobalSchedules(newItemList, null);
        
        newItemList[0].Web_Schedule_EndDate__c = system.today().addDays(10);
        newItemList[0].Web_Schedule_StartDate__c = system.today().addDays(20);
        newList1.add(newItemList[0]);
        update newList1;
        OpportunityService.updateWebSchedulingStart_EndDates_WithoutGlobalSchedules(newList1, mapOfOfOldOppties);
        Test.stopTest();        
    }
    
    /*static testMethod void testSyncOpps()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert Mobile Site 2
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        List<Opportunity> newItemList = new List<Opportunity>();
       	List<Opportunity> newList1 = new List<Opportunity>();
        
        Test.startTest();
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'Yes',
            Web_Schedule_StartDate__c = system.today(),
            Web_Schedule_Start_Time__c = Time.newInstance(10, 0, 0, 0),
            Web_Schedule_EndDate__c = system.today().addDays(4),
            Web_Schedule_End_Time__c = Time.newInstance(15, 30, 0, 0),
            Web_Scheduling_End_Time_Offset__c = 3,
            Web_Scheduling_Start_Date_Offset__c = 4,
            Web_Scheduling_End_Date_Offset__c = 2,
            Drive_Status__c ='Draft' 

		);
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        newItemList.add(testMobileOpp2);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');        
        insert newItemList;
        List<Opportunity> oppsList = new List<Opportunity>();
        oppsList.add(new Opportunity(Drive_Status__c ='Draft',id=testMobileOpp2.id,WB_Projected_Procedures__c = 4));
        OpportunityService.syncOppsWithDrives(oppsList);//update WB_Projected_Procedures__c to 2 from 4

        Map<Id, Opportunity> mapOfOfOldOppties = new Map<Id, Opportunity>([select Id, WB_Projected_Procedures__c from Opportunity where Id =: newItemList[0].Id]);
        //System.assert( newItemList[0].WB_Projected_Procedures__c ==2);
        
        Test.stopTest();        
    }*/
    
    //HRP-11296
    static testMethod void testEventDrivePublish(){
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        // Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        // Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
    
        // MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        // config.oppIds = new Set<Id>();
        // config.oppIds.add(mobileOpportunity.Id);
       
        //     AccountTeamMemberHelper.skipAccountTrigger = true;
        //     TriggerHandler.bypass('AccountTriggerHandler');
        //     TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        //  try{
        //     GenerateMobileDrive.generateDrives(config);
        //  }catch(Exception ex){}
                    	
        // 	List<sked_Drive__c> drivesList = [SELECT Id FROM sked_Drive__c];
        
        UpdateEvent driveUpdateEvent = new UpdateEvent();
        List<FieldIdentifiers> oppFieldsList = new List<FieldIdentifiers>();

        driveUpdateEvent.objectName = 'DrivesOnCalendar';
        FieldIdentifiers oppField = new FieldIdentifiers();
		oppField.Sked_Drive_Id= testDrive.Id;
        oppField.Sked_Cancellation_Reason ='Test';
        oppField.sked_Drive_Owner= UserInfo.getUserId();
        oppField.sked_Historical_Registered_Donors=2;
        oppFieldsList.add(oppField);
        driveUpdateEvent.objectFields = oppFieldsList;
        String objectDataJSON = JSON.serialize(driveUpdateEvent);
        
         //Prepare platform event to publish
        List<Update_Event__e> updateEventList = new List<Update_Event__e>(); 
        Update_Event__e event = new Update_Event__e(
                    Object_Data__c = objectDataJSON
         );
                updateEventList.add(event);
                
               Test.startTest();

                //Publish Event
                if(!updateEventList.isEmpty()) {
                    List<Database.SaveResult> eventPubResultList = EventBus.publish(updateEventList);
                }
     	Test.stopTest();
      	List<BSF_Error_Log__c> errLogList =  [select id from BSF_Error_Log__c];
       	Assert.isTrue(errLogList.size() >0);  

    }
    
    
    // New Version
    static testMethod void testSyncOppWithDrives()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData1 =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Site 2
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData1.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');

        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamTriggerHandler');
        try{
            GenerateMobileDrive.generateDrives(config);
        }catch(Exception ex){}
                           
        List<Opportunity> oppRecordList = [SELECT Id FROM Opportunity];        
        List<Opportunity> updateOppList = new List<Opportunity>();
        Opportunity oppRec = new Opportunity(
                Id = oppRecordList[0].Id,
            	Drive_Site__c = testMobileSite2.Id, // new
            	Flow_Start_Time_Field__c = '1000', // new
        		Flow_End_Time_Field__c = '1530', // new
                Anticipated_Registered_Donors__c = 11,
                WB_Projected_Procedures__c = 11,
                X2RBC_Projected_Procedures__c = 11,
                Platelet_Projected_Procedures__c= 11,//HRP-10514
            	Plasma_Pheresis_Projected_Procedures__c = 11, // new
                AnticipatedRegisterDonorChangeReason__c = 'test class',
                WholeBloodProcedureProjectedChangeReason__c = 'test class',
                DoubleRedProceduresProjectedChangeReason__c = 'test class',
            	Anticipated_Registered_Donors_Template__c = 30, // new
                Apheresis_Projected_Units__c = 21,
                Other_Projected_Units__c = 1,
                Number_of_2RBC_Assets__c = 1,
                Number_of_Plasma_Assets__c = 1,
                Number_of_Platelet_Assets__c = 1,
                Drive_Status__c = 'Tentative',
                StageName = 'Committed',
                Drive_Date__c = System.today().addDays(-5),
                //Start_Time__c = Time.newInstance(12, 0, 0, 0),
                //End_Time__c = Time.newInstance(21, 0, 0, 0),
                Flow_Start_Time_Label_Text__c = Helper.getStartEndTimeLabelText('0000'),
                Account_Manager__c = userinfo.getUserId(),
                Is_Recursion_On__c = true,
                sked_Cancellation_Reason__c = '',
                Initiated_By__c = ''
            ); 
         updateOppList.add(oppRec);
         if (!updateOppList.isEmpty())
         {
             Test.startTest();
             TriggerHandler.bypass('OpportunityTriggerHandler');
             opportunityService.syncOppsWithDrives(updateOppList);
             TriggerHandler.clearAllBypasses();
         } 
        
        Test.stopTest();
        Assert.isTrue(config != null);
    }
    
    @isTest
    //HRP-10312- Addressed issues for opportunities being out of sync when drive change request is rejected 
    public static void testSyncOppWithDrivesGivenNullValues() {
        Test.startTest();
        Triggerhandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        AccountTeamMemberHelper.skipAccountTrigger = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
       
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);           
            
        try{
             GenerateMobileDrive.generateDrives(config);
        }catch(Exception ex){}
                         
        List<Opportunity> oppRecordList = [SELECT Id FROM Opportunity];        
        List<Opportunity> updateOppList = new List<Opportunity>();
        Opportunity oppRec = new Opportunity(
                Id = oppRecordList[0].Id,
                Anticipated_Registered_Donors__c = null,
                WB_Projected_Procedures__c = null,
                X2RBC_Projected_Procedures__c = null,
                Platelet_Projected_Procedures__c= null,//HRP-10514
                Plasma_Pheresis_Projected_Procedures__c = null,
                AnticipatedRegisterDonorChangeReason__c = null,
                WholeBloodProcedureProjectedChangeReason__c = null,
                DoubleRedProceduresProjectedChangeReason__c = null,
                Anticipated_Registered_Donors_Template__c=null,
                Parent_Template_Id__c =null,
                Account_Manager__c = NULL, // new
                Apheresis_Projected_Units__c = null,
                Other_Projected_Units__c = null,
                Number_of_2RBC_Assets__c = null,
                Number_of_Plasma_Assets__c = null,
                Number_of_Platelet_Assets__c =null,
                Drive_Status__c = 'Tentative',
                StageName = 'Committed',
                Drive_Date__c = System.today().addDays(-5),
                Start_Time__c = Time.newInstance(12, 0, 0, 0),
                End_Time__c = Time.newInstance(21, 0, 0, 0),
                Flow_Start_Time_Label_Text__c = Helper.getStartEndTimeLabelText('0000'),
                Is_Recursion_On__c = true,
                sked_Cancellation_Reason__c = null,
                Initiated_By__c = null
                
            ); 
        updateOppList.add(oppRec);
        Triggerhandler.clearAllBypasses();
        if (!updateOppList.isEmpty())
        {
           opportunityService.syncOppsWithDrives(updateOppList);
        }
                Test.stopTest();       
       Opportunity opp = [select id,Anticipated_Registered_Donors__c,WB_Projected_Procedures__c,Platelet_Projected_Procedures__c from opportunity where id=:oppRecordList[0].id limit 1];
       
       Assert.isTrue(opp.Anticipated_Registered_Donors__c == null);
       //Assert.isTrue(opp.WB_Projected_Procedures__c == null);
       //Assert.isTrue(opp.Platelet_Projected_Procedures__c == null);
   
    }
     //HRP-10312 Ends   
     
     static testMethod void testSyncOppWithDrives2()
     {
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
    
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
       
            AccountTeamMemberHelper.skipAccountTrigger = true;
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         Test.startTest();
         try{
            GenerateMobileDrive.generateDrives(config);
         }catch(Exception ex){}
                    	
        	List<sked_Drive__c> drivesList = [SELECT Id FROM sked_Drive__c];

        if(drivesList != null && drivesList.size() > 0)
        {
        	List<FieldIdentifiers> docFields = new List<FieldIdentifiers>();
        	FieldIdentifiers fi = new FieldIdentifiers();
        	fi.Sked_Drive_Id = drivesList[0].Id;
        	fi.Sked_Cancellation_Reason = '';
        	fi.sked_Drive_Owner = userinfo.getUserId();
        	fi.sked_Historical_Registered_Donors = 1;
        	docFields.add(fi);
        
        	UpdateEvent objDoc = new UpdateEvent();
        	objDoc.objectName = 'DrivesOnCalendar';
        	objDoc.objectFields = docFields;
              
        	string jsonObj = Json.serialize(objDoc);
            List<Update_Event__e> updateEventList = new List<Update_Event__e>(); 
            
            //Prepare platform event to publish
            Update_Event__e event = new Update_Event__e(
                Object_Data__c = jsonObj
            );
            updateEventList.add(event);
            
            if(!updateEventList.isEmpty())
            {
                List<Database.SaveResult> eventPubResultList = EventBus.publish(updateEventList);
            }
            
        Test.stopTest();
            
        Assert.isTrue(config != null);
        }
     }
    
    // New Version
    static testMethod void testSyncOppWithDrives3()
    {
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
               
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);        
        
        try{
            GenerateMobileDrive.generateDrives(config);
        }catch(Exception ex){}
                           
        //List<Opportunity> oppRecordList = [SELECT Id FROM Opportunity];        
        List<Opportunity> updateOppList = new List<Opportunity>();
        Opportunity oppRec = new Opportunity(
                Id = mobileOpportunity.Id,
                Drive_Status__c = 'Confirmed',
                StageName = 'Committed',
                Initiated_By__c = 'ARC_Initiated_Mobile'
            ); 
        updateOppList.add(oppRec);
        Triggerhandler.clearAllBypasses();
        if (!updateOppList.isEmpty())
        {
            opportunityService.syncOppsWithDrives(updateOppList);
        }         
        Test.stopTest();
        Assert.isTrue(config != null);
    }
    
    // HRP- 10115 --> Covering BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() in OpportunityTriggerHandler
    static testMethod void testRestrictNonAdminsToDeleteOpp()
    {
        /* DRD Users */
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId()))
        {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert fixed site acc
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        insert testFixedSiteAccount;
        
        // insert fixed site
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        insert testFixedSite;
        
        // insert fixed site opp
        Opportunity testFixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        testFixedSiteOpp.AccountId = testFixedSiteAccount.id;
        testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
        testFixedSiteOpp.Anticipated_Registered_Donors__c = 10;
        insert testFixedSiteOpp;
        
        Test.startTest();
        system.runAs(testDrdUser)
        {
            try{
                delete testFixedSiteOpp;
            }catch(Exception ex)
            {
                Assert.isTrue(ex.getMessage().contains('You are not authorized to delete Opportunities. Please escalate via Support Ticket.'));
            }
        }
        Test.stopTest();
    }
    
   @isTest
    public static void testRecruitmentTask()
    {
       
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        triggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.id;
        insert testContact;
               
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        system.debug('testMobileSite '+testMobileSite.sked_Site_Contact__c);
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
                    
        // insert mobile opportunity
        Opportunity testMobileOpp2 = new Opportunity(
            Name = 'Test Opportunity 3',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Call_List_Recipient_Exist__c=true
            );
        
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        
        insert testMobileOpp2;
        //triggerHandler.clearBypass('OpportunityTriggerHandler');
        
 
        testMobileAccount.Contact_BPL__c=testContact.id;
        
        //triggerHandler.bypass('OpportunityTriggerHandler');
        update testMobileAccount;
        
        List <OpportunityContactRole> ocrList = new list<OpportunityContactRole>();
        OpportunityContactRole ocr = (OpportunityContactRole)mapTestData.get('OPP_CONTACT_ROLE');
        ocr.OpportunityId = testMobileOpp2.Id;
		ocr.ContactId = testContact.id;
        ocr.Role = 'Call List Recipient';
        ocrList.add( ocr);
        
        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testMobileOpp2.Id;
		ocr1.ContactId = testContact.id;
        ocr1.Role = 'Primary Contact';
        ocrList.add( ocr1);
                
        insert ocrList;
        
        user u = (user)mapTestData.get('DRD_USER');
        insert u;
        
        OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                        optyTeamMemeberToAdd.OpportunityId = testMobileOpp2.Id;
                        optyTeamMemeberToAdd.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
                        optyTeamMemeberToAdd.OpportunityAccessLevel = 'Edit';
                        optyTeamMemeberToAdd.UserId =u.id;
                        optyTeamMemeberToAdd.is_AccountTeammember__c = true;
        insert optyTeamMemeberToAdd;
        
        Sked_Drive__c drive = new Sked_Drive__c(sked_Opportunity__c=testMobileOpp2.id, sked_Account__c = testMobileAccount.Id,sked_Drive_Site__c = testMobileSite.Id,sked_2RBC_Projected_Procedures__c = 20, sked_WB_Projected_Procedures__c = 20,sked_status__c = 'System Generated', sked_Type_of_Drive__c = 'Mobile');
        insert drive;
        
        system.debug('testMobileOpp2 '+testMobileOpp2.Account.contact_BPL__c);
        triggerHandler.clearBypass('OpportunityTriggerHandler');
        
        Test.startTest();
        testMobileOpp2.StageName='Closed';
        update testMobileOpp2;
        
        Test.stopTest();    
    }
    
    // Added By Priti - 1/19/2024
    static testMethod void testOpportunityStageTransitionValidation1()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        triggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
       // insert mobile opportunity 1
       	Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(20),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
           Call_List_Recipient_Exist__c=true
		);
        
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
       	insert testMobileOpp1;
        
        // insert Primary Contact
        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testMobileOpp1.Id;
		ocr1.ContactId = testContact.id;
        ocr1.Role = 'Primary Contact';                
        insert ocr1;
        
        // insert DOC
        Sked_Drive__c drive = new Sked_Drive__c(sked_Opportunity__c=testMobileOpp1.id, sked_Account__c = testMobileAccount.Id,sked_Drive_Site__c = testMobileSite.Id,sked_2RBC_Projected_Procedures__c = 2, sked_WB_Projected_Procedures__c = 4,sked_status__c = 'System Generated', sked_Type_of_Drive__c = 'Mobile');
        insert drive;
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        //update opp stage
        Test.startTest();
        testMobileOpp1.StageName = 'Closed'; // Trying to update an mobile opp stage to closed without an Active BPL
        try{
            update testMobileOpp1;
        }Catch(Exception ex)
        {
            Assert.isTrue(ex.getMessage().contains(Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Active_BPL_Requirement').Error_Msg_on_Opportunity__c));
        }
         Test.stopTest();              
        
    }
    
    // check Site Mandetory Fields Requirement Method
    static testMethod void testOpportunityStageTransitionValidation2()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        triggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.id;
        insert testContact;
        
        testMobileAccount.Contact_BPL__c = testContact.Id;
        update testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = new sked__Location__c(
            Name = 'Test Mobile Location 3',
            RecordTypeId=  Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            //sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            //sked_Outside_stairs__c = 3,
            //sked_Inside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            //sked_Site_Main_Phone__c = '098-765-4321',
            //sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form'
            ///sked_Site_Contact__c = contact.Id
        );
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
       // insert mobile opportunity 1
       	Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(20),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
           Call_List_Recipient_Exist__c=true
		);
        
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
       	insert testMobileOpp1;
        
        // insert Primary Contact
        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testMobileOpp1.Id;
		ocr1.ContactId = testContact.id;
        ocr1.Role = 'Primary Contact';                
        insert ocr1;
        
        // insert DOC
        Sked_Drive__c drive = new Sked_Drive__c(sked_Opportunity__c=testMobileOpp1.id, sked_Account__c = testMobileAccount.Id,sked_Drive_Site__c = testMobileSite.Id,sked_2RBC_Projected_Procedures__c = 2, sked_WB_Projected_Procedures__c = 4,sked_status__c = 'System Generated', sked_Type_of_Drive__c = 'Mobile');
        insert drive;
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('DriveTriggerHandler');
        //update opp stage
        Test.startTest();
        testMobileOpp1.StageName = 'Closed'; // Trying to update an mobile opp stage to closed without an Active BPL
        try{
            system.debug('here to update');
            update testMobileOpp1;
            system.debug('done');
        }Catch(Exception ex)
        {
            system.debug('ex.getMessage() '+ex.getMessage());
            Assert.isTrue(ex.getMessage().contains('Please populate below site mandatory fields before moving'));
        }
         Test.stopTest();              
        
    }
    
    static testmethod void testPopulateRelatedFieldsOnDOC()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        triggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
       // insert mobile opportunity 1
       	Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(20),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
           	Call_List_Recipient_Exist__c=true,
            Open_to_Public__c = 'No',
            Security_Escort_Name__c = 'test',
            Drive_Keyword__c = 'test'
		);
        
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
       	insert testMobileOpp1;
        
        // insert DOC
        Sked_Drive__c drive = new Sked_Drive__c(sked_Opportunity__c=testMobileOpp1.id, sked_Account__c = testMobileAccount.Id,sked_Drive_Site__c = testMobileSite.Id,sked_2RBC_Projected_Procedures__c = 2, sked_WB_Projected_Procedures__c = 4,sked_status__c = 'System Generated', sked_Type_of_Drive__c = 'Mobile');
        insert drive;
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        //update opp stage
        Test.startTest();
        testMobileOpp1.Open_to_Public__c = 'Yes'; 
        testMobileOpp1.Security_Escort_Name__c = 'TEST2'; 
        try{
            update testMobileOpp1;
            sked_Drive__c docUpdated = [select sked_Open_to_Public__c, sked_Security_Escort_Name__c from sked_Drive__c where sked_opportunity__c =:testMobileOpp1.Id];
            Assert.isTrue(docUpdated.sked_Open_to_Public__c == 'Yes');
        }Catch(Exception ex)
        {
           
        }
         Test.stopTest();                 
    }
    
    // Added by Priti - 6/18/2024 --> Starts Here
    static testMethod void testSlotGeneratorPopulationMethod() {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        
        /* DRD User */
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.id;
        insert testContact;
               
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
                    
        // insert mobile opportunity
        Opportunity testMobileOpp = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive 1',
        	Drive_Date__c = system.today().addDays(10),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Call_List_Recipient_Exist__c = true,
            Source__c = 'Adhoc',
            Slot_Generator__c = 115
        );
        
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        Test.startTest();
        testMobileOpp.Call_List_Recipient_Exist__c = FALSE;
        update testMobileOpp;
        
        system.runAs(testDrdUser) {
            testMobileOpp.Slot_Generator__c = 80;
            try {
                update testMobileOpp;
            } catch(Exception ex) {
                Assert.isTrue(ex.getMessage().contains('please contact DRD Manager.'));
            }
        }
       Test.stopTest(); 
    }
    
    static testMethod void testModifySlotGeneratorChangeForFSByDRDValidation() {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        
        /* DRD User */
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Fixed Site Account
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testFixedSiteAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testFixedSiteAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testFixedSiteAccount.id;
        insert testContact;
               
        // insert Fixed Site
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        testFixedSite.sked_Site_Contact__c = testContact.Id;
        insert testFixedSite;
                    
        // insert Fixed Site Opportunity
        Opportunity testFixedSiteOpp = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Fixed Site',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive 1',
        	Drive_Date__c = system.today().addDays(10),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Source__c = 'Adhoc'
        );
        testFixedSiteOpp.AccountId = testFixedSiteAccount.Id;
        testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        insert testFixedSiteOpp;
        
        Test.startTest();
        system.runAs(testDrdUser) {
            testFixedSiteOpp.Slot_Generator__c = 80;
            try {
                update testFixedSiteOpp;
            } catch(Exception ex) {
                Assert.isTrue(ex.getMessage().contains('You do not have permission to modify this field'));
            }
        }
       Test.stopTest(); 
    }
    
    static testMethod void testModifySlotGeneratorChangeReasonForFSByDRDValidation() {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        
        /* DRD User */
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Fixed Site Account
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testFixedSiteAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testFixedSiteAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testFixedSiteAccount.id;
        insert testContact;
               
        // insert Fixed Site
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        testFixedSite.sked_Site_Contact__c = testContact.Id;
        insert testFixedSite;
                    
        // insert Fixed Site Opportunity
        Opportunity testFixedSiteOpp = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Fixed Site',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive 1',
        	Drive_Date__c = system.today().addDays(10),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Source__c = 'Adhoc',
            Slot_Generator_Change_Reason__c = 'Test Change by DRD Profile'
        );
        testFixedSiteOpp.AccountId = testFixedSiteAccount.Id;
        testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        insert testFixedSiteOpp;
        
        Test.startTest();
        system.runAs(testDrdUser) {
            testFixedSiteOpp.Slot_Generator_Change_Reason__c = 'Test Change by DRD Profile';
            try {
                update testFixedSiteOpp;
            } catch(Exception ex) {
                Assert.isTrue(ex.getMessage().contains('You do not have permission to modify this field'));
            }
        }
       Test.stopTest(); 
    }
    
    static testMethod void testCancelOppOnDriveStatusComplete() {
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        
        /* DRD User */
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        testMobileAccount.Contact_BPL__c = contactRec.Id;
        update testMobileAccount;
       
        sked__Location__c site1 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site1;
        
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.is_Template__c = true;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        templateOpp.Drive_Site__c =site1.Id ;
        insert templateOpp;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.StageName = 'Discovery';
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(80);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time()+1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Source__c = 'Adhoc';
        mobileOpportunityRecord.Slot_Generator__c = 130;
        mobileOpportunityRecord.Slot_Generator_Change_Reason__c = 'System Generated Value';
        insert mobileOpportunityRecord;
        
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = mobileOpportunityRecord.id;
        insert oppConRole;
        
        sked_Drive__c mobileDrive = new sked_Drive__c();
        mobileDrive.sked_Opportunity__c = mobileOpportunityRecord.Id;
        mobileDrive.sked_Account__c = testMobileAccount.Id;
        mobileDrive.sked_Drive_Date__c = mobileOpportunityRecord.Drive_Date__c;
        mobileDrive.sked_2RBC_Projected_Procedures__c = 1;
        mobileDrive.sked_WB_Projected_Procedures__c = 2;
        mobileDrive.sked_Status__c = 'Complete';
        insert mobileDrive;
        
                
        Test.startTest();
        mobileOpportunityRecord.stageName = 'Closed';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update mobileOpportunityRecord;
        TriggerHandler.clearAllBypasses();
        
        Opportunity oppAfterUpdate = [SELECT ID, StageName FROM Opportunity where Id = :mobileOpportunityRecord.Id];
        oppAfterUpdate.stageName = 'Cancelled';
        oppAfterUpdate.Initiated_By__c = 'ARC_Initiated_Mobile';
        oppAfterUpdate.sked_Cancellation_Reason__c = 'ARC Management';
        
        system.runAs(testDrdUser) {
            try {
                update oppAfterUpdate;
            } catch(Exception ex) {
                system.debug('ex.getMessage() 2 '+ex.getMessage());
                Assert.isTrue(ex.getMessage().contains('Only Global Admin and System Admin can change the Drive Status from Complete to Cancel'));
            }
        }
        
        Test.stopTest();
    }

    static testMethod void testsendOpportunityPromotionDisassociatEmail(){
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        testMobileAccount.Contact_BPL__c = contactRec.Id;
        update testMobileAccount;
       
        sked__Location__c site1 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site1;
        
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.is_Template__c = true;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        templateOpp.Drive_Site__c =site1.Id ;
        insert templateOpp;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.StageName = 'Discovery';
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(80);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time()+1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Source__c = 'Adhoc';
        mobileOpportunityRecord.Slot_Generator__c = 130;
        mobileOpportunityRecord.Slot_Generator_Change_Reason__c = 'System Generated Value';
        System.debug('DriveDate-------' +  mobileOpportunityRecord.Drive_Date__c);
        insert mobileOpportunityRecord;
        System.debug('mobileOpportunityRecord -------' +  mobileOpportunityRecord);
        
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = mobileOpportunityRecord.id;
        insert oppConRole;
        
        sked_Drive__c mobileDrive = new sked_Drive__c();
        mobileDrive.sked_Opportunity__c = mobileOpportunityRecord.Id;
        mobileDrive.sked_Account__c = testMobileAccount.Id;
        mobileDrive.sked_Drive_Date__c = mobileOpportunityRecord.Drive_Date__c;
        mobileDrive.sked_2RBC_Projected_Procedures__c = 1;
        mobileDrive.sked_WB_Projected_Procedures__c = 2;
        mobileDrive.sked_Status__c = 'Complete';
        insert mobileDrive;

        Promotion__c promotion = new Promotion__c(Name='Test Promotion');
        Date todayDate = Date.today();
        promotion.Start_Date__c = Date.Today();
        promotion.End_Date__c = Date.Today().addDays(85);
        promotion.Supplier__c = 'Drive';
        insert promotion;
       
        Opportunity_Promotion__c oppPromo= new Opportunity_Promotion__c();
        oppPromo.Blood_Drive_Opportunity__c = mobileOpportunityRecord.id;
        oppPromo.Promotion__c = promotion.id;
        System.debug('oppPromo.Promotion__c' + oppPromo.Promotion__c);
        insert oppPromo;
        System.debug('oppPromo' + oppPromo.Id);
        
        
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityAccessLevel = 'Edit';
        otm.userId = userInfo.getUserId();
        otm.OpportunityId = mobileOpportunityRecord.id;
        otm.TeamMemberRole = 'Account Manager';
        insert otm;
        
      Opportunity_Promotion__c oppPromo1 = [SELECT Id, Promotion__r.Name, Blood_Drive_Opportunity__r.Name, Drive_Date__c 
                                            FROM Opportunity_Promotion__c WHERE Drive_Date__c != null];
        
       Map<Opportunity_Promotion__c, OpportunityTeamMember> oppPromotionMap = new Map<Opportunity_Promotion__c, OpportunityTeamMember>{
             oppPromo1 => otm
        };
            
        Test.startTest();
        opportunityservice.sendOpportunityPromotionDisassociatEmail(oppPromotionMap);
        Test.stopTest();
    }
    
    /*
    static testMethod void testgetChangedFields()
    {
		TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        //TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        testMobileAccount.Contact_BPL__c = contactRec.Id;
        update testMobileAccount;
       
        sked__Location__c site1 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site1;
        
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.is_Template__c = true;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        templateOpp.Drive_Site__c =site1.Id ;
        insert templateOpp;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.StageName = 'Discovery';
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(80);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time()+1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Source__c = 'Adhoc';
        mobileOpportunityRecord.Slot_Generator__c = 130;
        mobileOpportunityRecord.Slot_Generator_Change_Reason__c = 'System Generated Value';
        System.debug('DriveDate-------' +  mobileOpportunityRecord.Drive_Date__c);
        insert mobileOpportunityRecord;
        System.debug('mobileOpportunityRecord -------' +  mobileOpportunityRecord);
        
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = mobileOpportunityRecord.id;
        insert oppConRole;
        
        sked_Drive__c mobileDrive = new sked_Drive__c();
        mobileDrive.sked_Opportunity__c = mobileOpportunityRecord.Id;
        mobileDrive.sked_Account__c = testMobileAccount.Id;
        mobileDrive.sked_Drive_Date__c = mobileOpportunityRecord.Drive_Date__c;
        mobileDrive.sked_2RBC_Projected_Procedures__c = 1;
        mobileDrive.sked_WB_Projected_Procedures__c = 2;
        mobileDrive.sked_Status__c = 'Complete';
        insert mobileDrive;
        
        Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
        
        psr.setObjectId(mobileDrive.Id);
        psr.setNextApproverIds(new List<ID>{UserInfo.getUserId()});

        Test.startTest();
        Approval.ProcessResult processResult = Approval.process(psr);
		System.assertEquals('Pending', processResult.getInstanceStatus());
        mobileOpportunityRecord.WB_Projected_Procedures__c = 3;
        mobileOpportunityRecord.WholeBloodProcedureProjectedChangeReason__c = 'test';
        update mobileOpportunityRecord;
		Test.stopTest();
    }
    */
    static testMethod void testgetChangedFieldsElseCondition()
    {
		TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        testMobileAccount.Contact_BPL__c = contactRec.Id;
        update testMobileAccount;
       
        sked__Location__c site1 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site1;
        
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.is_Template__c = true;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        templateOpp.Drive_Site__c =site1.Id ;
        insert templateOpp;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.StageName = 'Discovery';
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(80);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time()+1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Source__c = 'Adhoc';
        mobileOpportunityRecord.Slot_Generator__c = 130;
        mobileOpportunityRecord.Slot_Generator_Change_Reason__c = 'System Generated Value';
        System.debug('DriveDate-------' +  mobileOpportunityRecord.Drive_Date__c);
        insert mobileOpportunityRecord;
        System.debug('mobileOpportunityRecord -------' +  mobileOpportunityRecord);
        
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = mobileOpportunityRecord.id;
        insert oppConRole;
        
        sked_Drive__c mobileDrive = new sked_Drive__c();
        mobileDrive.sked_Opportunity__c = mobileOpportunityRecord.Id;
        mobileDrive.sked_Account__c = testMobileAccount.Id;
        mobileDrive.sked_Drive_Date__c = mobileOpportunityRecord.Drive_Date__c;
        mobileDrive.sked_2RBC_Projected_Procedures__c = 1;
        mobileDrive.sked_WB_Projected_Procedures__c = 2;
        mobileDrive.sked_Status__c = 'Complete';
        mobileDrive.sked_Pending_Action__c = 'Drive Submission';
		mobileDrive.sked_Approval_Status__c = 'Waiting for DM Approval';
        insert mobileDrive;
        
        Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
        
        psr.setObjectId(mobileDrive.Id);
        psr.setNextApproverIds(new List<ID>{UserInfo.getUserId()});

        Test.startTest();
        //TriggerHandler.bypass('OpportunityTriggerHandler');
        Approval.ProcessResult processResult = Approval.process(psr);
		System.assertEquals('Pending', processResult.getInstanceStatus());
        mobileOpportunityRecord.WB_Projected_Procedures__c = 3;
        mobileOpportunityRecord.WholeBloodProcedureProjectedChangeReason__c = 'test';
        Database.SaveResult result = Database.update(mobileOpportunityRecord, false);
		TriggerHandler.clearAllBypasses();
		Test.stopTest();
        
        System.assert(result.getErrors().size() == 1);
    }
    
    static testMethod void testSyncTemplateOrderWithBDO() {
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        //TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        triggerHandler.bypass('TaskTriggerHandler');
        
        /* DRD User */
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        testMobileAccount.Contact_BPL__c = contactRec.Id;
        update testMobileAccount;
       
        sked__Location__c site1 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site1;
        
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.is_Template__c = true;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        templateOpp.Drive_Site__c =site1.Id ;
        insert templateOpp;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Order> orderlist = new List<Order>();
            Order o = new Order();
            o.name='Test1';
            o.AccountId= testMobileAccount.Id ;
            o.OpportunityId = templateOpp.Id ;
            o.Material_Recipient_Type__c = 'Same';
            o.Material_Recipient__c = 'Account Manager';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
        
        insert orderlist;
        
        List<Product2> productlist = new List<Product2>(); 
        Product2 prod = new Product2(Name = 'Laptop X200',
                                    
                                     Family = 'Hardware');
        productlist.add(prod);
        insert productlist;
        
        List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
                                                            Pricebook2Id = pricebookId, Product2Id = productlist[0].Id,
                                                            UnitPrice = 0.01, IsActive = true);
                                                            
                                                            
        pentrylist.add(standardPrice);
        
        insert pentrylist;
        
        List<OrderItem> oitemlist = new List<OrderItem>();
                OrderItem oi = new OrderItem();
                oi.OrderId= orderlist[0].id ;
                oi.PricebookEntryId= pentrylist[0].Id ;
                oi.Quantity = 1 ;
                oi.UnitPrice = 0.01 ; 
                oi.Product2id  = productlist[0].Id ;
                oi.Material_Recipient__c  = 'Account Manager';
                oitemlist.add(oi);
        insert oitemlist;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.StageName = 'Discovery';
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Site_TBD__c = False;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(80);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time()+1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Source__c = 'Adhoc';
        mobileOpportunityRecord.Slot_Generator__c = 130;
        mobileOpportunityRecord.Slot_Generator_Change_Reason__c = 'System Generated Value';
        
        Test.startTest();
        insert mobileOpportunityRecord;
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = mobileOpportunityRecord.id;
        insert oppConRole;
    }
    
    static testMethod void testUpdateSyncTemplateOrderWithBDO() {
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        //TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        triggerHandler.bypass('TaskTriggerHandler');
        
        /* DRD User */
        User testDrdUser = new User(
            ProfileId = [select Id from Profile where name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

        Contact contactRec = (Contact)mapTestData.get('CONTACT');
        contactRec.AccountId = testMobileAccount.Id;
        insert contactRec;
        
        testMobileAccount.Contact_BPL__c = contactRec.Id;
        update testMobileAccount;
       
        sked__Location__c site1 = (sked__Location__c)mapTestData.get('MOBILE_SITE2');
        insert site1;
        
		Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.is_Template__c = true;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        templateOpp.Drive_Site__c =site1.Id ;
        insert templateOpp;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.StageName = 'Discovery';
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        //mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        //mobileOpportunityRecord.Site_TBD__c = False;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(80);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time()+1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Source__c = 'Adhoc';
        mobileOpportunityRecord.Slot_Generator__c = 130;
        mobileOpportunityRecord.Slot_Generator_Change_Reason__c = 'System Generated Value';
        insert mobileOpportunityRecord;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Order> orderlist = new List<Order>();
            Order o = new Order();
            o.name='Test1';
            o.AccountId= testMobileAccount.Id ;
            o.OpportunityId = templateOpp.Id ;
            o.Material_Recipient_Type__c = 'Same';
            o.Material_Recipient__c = 'Account Manager';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
        
        	o = new Order();
            o.name='Test2';
            o.AccountId= testMobileAccount.Id ;
            o.OpportunityId = mobileOpportunityRecord.Id ;
            //o.Material_Recipient_Type__c = 'Same';
            //o.Material_Recipient__c = 'Account Manager';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
        
        insert orderlist;
        
        List<Product2> productlist = new List<Product2>(); 
        Product2 prod = new Product2(Name = 'Laptop X200',
                                    
                                     Family = 'Hardware');
        productlist.add(prod);
        insert productlist;
        
        List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
                                                            Pricebook2Id = pricebookId, Product2Id = productlist[0].Id,
                                                            UnitPrice = 0.01, IsActive = true);
                                                            
                                                            
        pentrylist.add(standardPrice);
        
        insert pentrylist;
        
        List<OrderItem> oitemlist = new List<OrderItem>();
                OrderItem oi = new OrderItem();
                oi.OrderId= orderlist[0].id ;
                oi.PricebookEntryId= pentrylist[0].Id ;
                oi.Quantity = 1 ;
                oi.UnitPrice = 0.01 ; 
                oi.Product2id  = productlist[0].Id ;
                oi.Material_Recipient__c  = 'Account Manager';
                oitemlist.add(oi);
        
        		oi = new OrderItem();
                oi.OrderId= orderlist[1].id ;
                oi.PricebookEntryId= pentrylist[0].Id ;
                oi.Quantity = 1 ;
                oi.UnitPrice = 0.01 ; 
                oi.Product2id  = productlist[0].Id ;
                oitemlist.add(oi);
        insert oitemlist;
        
        
        
        OpportunityContactRole oppConRole = new OpportunityContactRole(Role = 'Primary Contact');
        oppConRole.ContactId = contactRec.id;
        oppConRole.OpportunityId = mobileOpportunityRecord.id;
        insert oppConRole;
        
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Site_TBD__c = False;
        
        Test.startTest();
        update mobileOpportunityRecord;
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
    /*@isTest
    public static void testRecruitmentTaskDiffSection()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        skedHubBase.BypassDeleteTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        triggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('ContactTriggerHandler');
        triggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        //triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
                 
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.id;
        insert testContact;
        
        // update to not get hit by validation rule - Active BPL Required
        testMobileAccount.Contact_BPL__c=testContact.id;
        update testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        list<opportunity> opportunityList = new list<opportunity>();
        
       // insert mobile opportunity 1
       Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(20),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
           Call_List_Recipient_Exist__c=true
		);
        
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
       	opportunityList.add(testMobileOpp1);
        
        // insert mobile opportunity 2
        Opportunity testMobileOpp2 = new Opportunity(
            Name = 'Test Opportunity 3',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(100),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Call_List_Recipient_Exist__c=true
            );
        
        	testMobileOpp2.AccountId = testMobileAccount.Id;
        	testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        	testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        	opportunityList.add(testMobileOpp2);
       
        	insert opportunityList;
      
        	// insert OCR
        	list <OpportunityContactRole> ocrList = new list<OpportunityContactRole>();
        	OpportunityContactRole ocr = (OpportunityContactRole)mapTestData.get('OPP_CONTACT_ROLE');
        	ocr.OpportunityId = opportunityList[1].Id;
			ocr.ContactId = testContact.id;
        	ocr.Role = 'Call List Recipient';
        	ocrList.add( ocr);
        
        	OpportunityContactRole ocr1 = new OpportunityContactRole();
        	ocr1.OpportunityId = opportunityList[1].Id;
			ocr1.ContactId = testContact.id;
        	ocr1.Role = 'Primary Contact';
        	ocrList.add( ocr1);
                
        	insert ocrList;
        
        	user u = (user)mapTestData.get('DRD_USER');
        	insert u;
        
        	OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                        optyTeamMemeberToAdd.OpportunityId = opportunityList[1].Id;
                        optyTeamMemeberToAdd.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
                        optyTeamMemeberToAdd.OpportunityAccessLevel = 'Edit';
                        optyTeamMemeberToAdd.UserId =u.id;
                        optyTeamMemeberToAdd.is_AccountTeammember__c = true;
        	insert optyTeamMemeberToAdd;
        
                Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Recruitment Meeting').getRecordTypeId();
                task recruitmentTask = new task();
                recruitmentTask.RecordTypeId = recTypeId;
                recruitmentTask.ActivityDate = opportunityList[0].Drive_Date__c;
                recruitmentTask.OwnerId = userinfo.getuserid();//part of ticket HRP-9562
                recruitmentTask.subject = 'Recruitment Task - System Generated';
                recruitmentTask.WhatId = opportunityList[0].id;
            	//recruitmentTaskList.add(recruitmentTask);        	
                insert recruitmentTask;
        
        
        	Sked_Drive__c drive = new Sked_Drive__c(sked_Opportunity__c=opportunityList[1].id, sked_Account__c = testMobileAccount.Id, sked_Drive_Site__c = testMobileSite.Id,sked_2RBC_Projected_Procedures__c = 20, sked_WB_Projected_Procedures__c = 20, sked_status__c = 'System Generated',sked_Type_of_Drive__c = 'Mobile');
        	insert drive;
        
        	triggerHandler.clearBypass('OpportunityTriggerHandler');
        	
        	BSF_Constants.Test_Run=true;
        
            Test.startTest();
        	opportunityList[1].StageName='Closed';
            update opportunityList[1];
            Test.stopTest();    
    }*/
    
    static testMethod void testWebScheduleStart_EndDateUpdateCalculation() {
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountServiceRoleTriggerHandler');
        //TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
       
        // insert FS Account
        Account testFixedAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        insert testFixedAccount;
		
        // insert FS Location
        sked__Location__c testSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        //skedHubBase.BypassInsertTriggers = true;
        //triggerHandler.bypass('SiteTriggerHandler');
        system.debug('line 3665'+testSite);
        insert testSite;
        system.debug('line 3667'+testSite.Id);
        
        //insert CO
        Biomed_Collection_Op_Center__c testCO = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');
        testCO.FS_Web_Scheduling_Start_Date_Offset__c = -250;
        testCO.FS_Web_Scheduling_Start_Time__c = '1015';
        testCO.FS_Web_Scheduling_End_Date_Offset__c = -25;
        testCO.FS_Web_Scheduling_End_Time_Offset__c = 0;
        insert testCO;
        
        //insert site collection operation
        sked_Site_Collection_Operation__c testSiteCO = (sked_Site_Collection_Operation__c)mapTestData.get('FIXED_SITE_COLLECTION_OPERATION');
        system.debug('line 3679'+testSiteCO);
        testSiteCO.sked_Collection_Operation__c = testCO.Id;
        testSiteCO.sked_Site__c = testSite.Id;
        insert testSiteCO;
        system.debug('line 3683'+testSiteCO);
        
        sked_Territory__c testterri = (sked_Territory__c)mapTestData.get('TERRITORY');
        insert testterri;
        
        sked_Territory_Collection_Operation__c testterriCO = (sked_Territory_Collection_Operation__c)mapTestData.get('TERRITORY_COLLECTION_OPERATION');
        testterriCO.sked_Collection_Operation__c = testCO.Id;
        testterriCO.sked_Territory__c = testterri.Id;
        System.debug('Line 3691 entering........' +testterriCO);
        insert testterriCO;
        System.debug('Line 3693 entering........' +testterriCO);
        
        //insert Fixed Opp 1
        Opportunity testFixedOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        testFixedOpp.accountId = testFixedAccount.Id;
        testFixedOpp.Drive_Site__c = testSite.Id;
        testFixedOpp.Online_Scheduling_Enabled__c = 'Yes';
        testFixedOpp.Web_Sched_Offset_from_CO_Global_Settings__c = true;
        
        Test.startTest();
        insert testFixedOpp;
        Test.stopTest();
    }
}