@isTest
private class BSFPopulateSiteChapterBatchTest {
    
	@testSetup
     public static void prepareDataSetup()
     {        
         BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
         Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
         skedHubBase.BypassInsertTriggers = true;
         // insert Mobile Account
         List<Account> accListToInsert = new List<Account>();
         Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
         testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
         
         accListToInsert.add(testMobileAccount);
         
         // insert Fixed Site Account
         Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
         testFixedSiteAccount.Internal_Name__c = 'TEST FIXED SITE ACC 1';
         accListToInsert.add(testFixedSiteAccount);
         Triggerhandler.bypass('AccountTriggerhandler');
         insert accListToInsert;
         
         TriggerHandler.bypass('SiteTriggerHandler');
         // insert mobile site
         List<sked__Location__c> siteListToInsert = new List<sked__Location__c>();
         sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
         testMobileSite.sked_Active__c = true;
         testMobileSite.sked_Start_Date__c = system.today().addDays(-30);
         testMobileSite.sked_End_Date__c = system.today().addDays(30);
         testMobileSite.National_Name_Status__c = 'Second Review Pending';
         
         testMobileSite.sked_Zip_Code__c = '12344';
         siteListToInsert.add(testMobileSite);
         
         // insert Fixed Site
         sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
         testFixedSite.sked_Active__c = true;
         testFixedSite.sked_Start_Date__c = system.today().addDays(-30);
         testFixedSite.sked_End_Date__c = system.today().addDays(30);
         testFixedSite.sked_Zip_Code__c = '12344';
         siteListToInsert.add(testFixedSite);
         insert siteListToInsert;
         
         // insert Fixed Site Opportunity
         List<Opportunity> oppList = new List<Opportunity>();
         Opportunity testFixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
         testFixedSiteOpp.AccountId = testFixedSiteAccount.Id;
         testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
         oppList.add(testFixedSiteOpp);
         //insert testFixedSiteOpp;
         
         // insert Mobile Opportunity
         Opportunity optyObj = new Opportunity();
         optyObj.accountId = testMobileAccount.Id;
         optyObj.Drive_Site__c = testMobileSite.Id;
         optyObj.Drive_Date__c = system.today().addDays(-1);
         optyObj.CloseDate = system.today().addDays(-20);
         optyObj.Is_Template__c = true;
         optyObj.Name = 'Test Drive';
         optyObj.StageName = 'Discovery'; 
         optyObj.Drive_Status__c = 'Draft';
         optyObj.WB_Projected_Procedures__c = 1;
         optyObj.X2RBC_Projected_Procedures__c = 1;
         optyObj.Anticipated_Registered_Donors__c = 1;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('OpportunityTriggerHandler');
         oppList.add(optyObj);
         //insert optyObj;
 
         Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
         testMobileOpp.accountId = testMobileAccount.Id;
         testMobileOpp.Drive_Site__c = testMobileSite.Id;
         testMobileOpp.Drive_Date__c = system.today().addDays(-1);
         testMobileOpp.CloseDate = system.today().addDays(-20);
         testMobileOpp.Parent_Template_Id__c = optyObj.id;
         oppList.add(testMobileOpp);
         Triggerhandler.bypass('OpportunityTriggerHandler');
         insert oppList;
 
         Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                         sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                         sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                         sked_Hold_Threshold__c = 100,
                                                                                                         Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                         Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                         sked_Work_Week_First_Day__c = 'Sunday');
         insert testCollectionOperation1;
 
         sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                         sked_Collection_Operation__c = testCollectionOperation1.Id,
                                                         sked_Drive_Date__c = System.today().addDays(-1),
                                                         sked_Drive_Site__c = testFixedSite.Id,
                                                         sked_Opportunity__c = testFixedSiteOpp.Id,
                                                         sked_Type_of_Drive__c = 'Fixed Site',
                                                         sked_Account__c = testFixedSiteAccount.Id,
                                                         sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                         sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                         sked_Drive_Productivity_Planned__c = 0.8,
                                                         sked_Projected_Registered_Donors__c = 100,
                                                      	 sked_2RBC_Projected_Procedures__c = 20,
                                                      	 sked_WB_Projected_Procedures__c = 20,
                                                         sked_Status__c = BSF_Constants.DOC_STATUS_DRAFT);
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('DriveTriggerHandler');
         insert testDrive1;
         
         Chapter__c ojdih = new Chapter__c();
         ojdih.Name = 'ARC';
         ojdih.Type__c = 'Chapter';
         insert ojdih;
         Chapter_Blood_Region_Zip_Match__c dededf = new Chapter_Blood_Region_Zip_Match__c();
         dededf.Chapter__c = ojdih.Id;
         dededf.Zip__c = '12344';
         insert dededf;
         
     }
    @isTest
    static void testmethod1() {
        Test.startTest();
        Database.executeBatch(new BSFPopulateSiteChapterBatch(system.today().addDays(-30),system.today().addDays(30)),200);
        Test.stopTest();
    }
}