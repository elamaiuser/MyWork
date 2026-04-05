/* The following test class is covering the below apex classes and trigger
 * SiteService
 * SiteTriggerHandlerr
 * SiteTrigger
 * **************************************************************************************************
 * Modification Log 
 * Date					      Developer Name			            Comments
 * **********************************************************************************************
 * 1/19/2024				   Priti Jana			Replaced all System.Assert with new Assert class
 * *************************************************************************************************/

 @isTest(SeeAllData = false)
 private class SiteServiceTest {
     
     @testSetup
     static void prepareDataSetup() {        
         BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
         Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
         
         //insert DRD User
         User testDRDUser = (User)mapTestData.get('DRD_USER');
         testDRDUser.IsActive = true;
         system.runAs(new User(Id = UserInfo.getUserId())) {
             insert testDRDUser;
         }
         
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
         
         // insert template
         Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
         testTemplate.accountId = testMobileAccount.Id;
         testTemplate.Drive_Site__c = testMobileSite.Id;
         insert testTemplate;
         
         // insert Fixed Site Opportunity
         List<Opportunity> oppList = new List<Opportunity>();
         Opportunity testFixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
         testFixedSiteOpp.AccountId = testFixedSiteAccount.Id;
         testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
         oppList.add(testFixedSiteOpp);

         Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
         testMobileOpp.accountId = testMobileAccount.Id;
         testMobileOpp.Drive_Site__c = testMobileSite.Id;
         testMobileOpp.Drive_Date__c = system.today().addDays(-1);
         testMobileOpp.CloseDate = system.today().addDays(-20);
         testMobileOpp.Parent_Template_Id__c = testTemplate.id;
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
 
         List<sked_Drive__c> testDriveList = new List<sked_Drive__c>();
         
         sked_Drive__c testDrive;
         testDrive = new sked_Drive__c(Name = 'Test Mobile Drive',
                                       sked_Collection_Operation__c = testCollectionOperation1.Id,
                                       sked_Drive_Date__c = System.today().addDays(-1),
                                       sked_Drive_Site__c = testMobileSite.Id,
                                       sked_Opportunity__c = testMobileOpp.Id,
                                       sked_Type_of_Drive__c = 'Mobile',
                                       sked_Account__c = testMobileAccount.Id,
                                       sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                       sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                       sked_Drive_Productivity_Planned__c = 0.8,
                                       sked_Projected_Registered_Donors__c = 100,
                                       sked_2RBC_Projected_Procedures__c = 20,
                                       sked_WB_Projected_Procedures__c = 20,
                                       sked_Status__c = BSF_Constants.DOC_STATUS_DRAFT);
         testDriveList.add(testDrive);
         
         testDrive = new sked_Drive__c(Name = 'Test Fixed Site Drive',
                                       sked_Collection_Operation__c = testCollectionOperation1.Id,
                                       sked_Drive_Date__c = System.today().addDays(-1),
                                       sked_Drive_Site__c = testFixedSite.Id,
                                       sked_Opportunity__c = testFixedSiteOpp.Id,
                                       sked_Type_of_Drive__c = 'Fixed Site',
                                       sked_Account__c = testFixedSiteAccount.Id,
                                       sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                       sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                       sked_Drive_Productivity_Planned__c = 0.8,
                                       sked_2RBC_Projected_Procedures__c = 20,
                                       sked_WB_Projected_Procedures__c = 20,
                                       sked_Status__c = BSF_Constants.DOC_STATUS_DRAFT);
         testDriveList.add(testDrive);
         
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('DriveTriggerHandler');
         insert testDriveList;
         Triggerhandler.clearAllBypasses();
         
     }
 
     static testMethod void testSiteInactiveOnEndDateChange() { 
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
         Test.startTest();
         sked__Location__c siteObj = [select Id ,sked_Active__c,sked_Start_Date__c,sked_End_Date__c from sked__Location__c where Operation_Type__c = null limit 1];
         
         
         siteObj.sked_End_Date__c = system.today();
         update siteObj;
                 
         sked__Location__c updatedSiteObj1 = [select Id ,sked_Active__c,sked_Start_Date__c,sked_End_Date__c from sked__Location__c where Id =: siteObj.Id];
         Assert.areEqual(false, updatedSiteObj1.sked_Active__c);
         Assert.areEqual(system.today(), updatedSiteObj1.sked_End_Date__c);
         
         updatedSiteObj1.sked_End_Date__c = system.today().addYears(30);
         
         try {
             update updatedSiteObj1;
         } catch(Exception ex) {}
              
         sked__Location__c updatedSiteObj2 = [
             SELECT Id ,sked_Active__c, sked_End_Date__c 
             FROM sked__Location__c 
             WHERE Id = :updatedSiteObj1.Id
         ];
         
         TriggerHandler.clearAllBypasses();
         
         Assert.areEqual(true, updatedSiteObj2.sked_Active__c);
         Assert.areEqual(system.today().addYears(30), updatedSiteObj2.sked_End_Date__c);
         
         Test.stopTest();
     }
     
     static testMethod void testUpdateTemplatesForSiteBuildingNameOrRoomNameChange() {
         Test.startTest();
         
         sked__Location__c testSiteObj = [
             SELECT Id, sked_Site_Building_Name__c 
             FROM sked__Location__c 
             WHERE sked_Zip_Code__c = '12344' 
             LIMIT 1
         ];
         
         testSiteObj.sked_Site_Building_Name__c = 'Test Building 1';
         testSiteObj.sked_Room_Name__c = 'Test Room 1';
         update testSiteObj;
         
         Test.stopTest();
         
         sked__Location__c testUpdatedSiteObj = [
             SELECT Id, sked_Site_Building_Name__c 
             FROM sked__Location__c 
             WHERE Id = :testSiteObj.Id 
             LIMIT 1
         ];
         
         Opportunity testUpdatedTemplate = [
             SELECT Id, Name, Is_Template__c
             FROM Opportunity
             WHERE Drive_Site__c = :testUpdatedSiteObj.Id
             AND Is_Template__c = true
             LIMIT 1
         ];
         
         Assert.isTrue(testUpdatedTemplate.Name.contains('Test Building 1 - Test Room 1'));
     }  
     
     static testMethod void testUpdateDrivesForSiteBuidlingNameChange() {
         
         Test.startTest();
         
         sked__Location__c testSiteObj = [
             SELECT Id, sked_Site_Building_Name__c 
             FROM sked__Location__c 
             WHERE sked_Zip_Code__c = '12344' 
             LIMIT 1
         ];
         
         testSiteObj.sked_Site_Building_Name__c = 'Test Building 1';
         testSiteObj.sked_Room_Name__c = 'Test Room 1';
         update testSiteObj;
         
         Test.stopTest();
         
         sked__Location__c testUpdatedSiteObj = [
             SELECT Id, sked_Site_Building_Name__c 
             FROM sked__Location__c 
             WHERE Id = :testSiteObj.Id 
             LIMIT 1
         ];
         
         sked_Drive__c testDrive = [
             SELECT Id, Name
             FROM sked_Drive__c
             WHERE sked_Drive_Site__c = :testUpdatedSiteObj.Id
             LIMIT 1
         ];
         
         Assert.isTrue(testDrive.Name.contains('Test Building 1 - Test Room 1'));
     }

     static testMethod void testUpdateInitialReviewer() {         
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
         
         Test.startTest();
         sked__Location__c siteObj = [select Id , sked_National_Name__c, National_Name_Status__c, Initial_Reviewer__c, National_Name_Initial_Review_Date__c from sked__Location__c limit 1];
                  
         siteObj.National_Name_Status__c = 'Second Review Pending';
         siteObj.sked_National_Name__c = 'TESTUSA';
         update siteObj;         
         
         sked__Location__c updatedSiteObj = [select Id , sked_National_Name__c, National_Name_Status__c, Initial_Reviewer__c, National_Name_Initial_Review_Date__c from sked__Location__c where Id = :siteObj.Id];
         TriggerHandler.clearAllBypasses();
         
         Assert.areEqual(UserInfo.getUserId(), updatedSiteObj.Initial_Reviewer__c);
         Assert.areEqual('Initial Review Pending', updatedSiteObj.National_Name_Status__c);
         Assert.areEqual(null, updatedSiteObj.National_Name_Initial_Review_Date__c);
         Test.stopTest();
     }
     
     static testMethod void testErrorInUpdateInitialReviewer() {
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
        
         Test.startTest();
         
         User testDRDUser = [SELECT Id FROM User WHERE LastName = 'DRDLastName' AND IsActive = true LIMIT 1];
         sked__Location__c testSiteObj = [select Id , sked_National_Name__c, National_Name_Status__c, Initial_Reviewer__c, National_Name_Initial_Review_Date__c from sked__Location__c limit 1];
        
         testSiteObj.National_Name_Status__c = 'Review Completed';
         testSiteObj.sked_National_Name__c = 'TESTUSA1';
         
         system.runAs(testDRDUser) {
             try {
         		update testSiteObj;
         	} catch(exception ex) {             
             	Boolean expectedException = ex.getMessage().contains('You cannot update the National name once Review is completed')?true:false;
             	Assert.areEqual(expectedException, true);             
         	}             
         }
         
         TriggerHandler.clearAllBypasses();
         Test.stopTest();
     }
     
     static testMethod void testValidateEndDateChange() {
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
         
         Test.startTest();
         sked__Location__c siteObj = [select Id ,sked_Active__c,sked_Start_Date__c,sked_End_Date__c from sked__Location__c limit 1];
         
         siteObj.sked_End_Date__c = system.today().addDays(-2);
         try {
             update siteObj;
         } catch(Exception ex) {
             Boolean expectedException = ex.getMessage().contains('Please make sure you cancel all drives on or after the designated site end date.') ? true : false;
             Assert.areEqual(expectedException, true);  
         }
         
         TriggerHandler.clearAllBypasses();
         Test.stopTest(); 
     }
     
     static testMethod void testValidateOperationTypeChange() {
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
         
         Test.startTest();
         sked__Location__c siteObj = [select Id ,Name,Operation_Type__c from sked__Location__c where Operation_Type__c = 'Integrated' limit 1];
         sked_Drive__c driveObj = [Select Id , sked_Status__c,sked_Drive_Site__c from sked_Drive__c where sked_Drive_Site__c =:siteObj.Id];
         
         siteObj.Operation_Type__c = 'Non Integrated APH';
         
         try {
             update siteObj;
         } catch(Exception ex) {
             Boolean expectedException = ex.getMessage().contains('change operation type as drives have already been generated.') ? true : false;
             Assert.areEqual(expectedException, true);  
         }
         
         TriggerHandler.clearAllBypasses();
         Test.stopTest();
     }
       
     static testMethod void testOnlyAdmincanDeleteSite() {
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
         
         Test.startTest();
         List<sked__Location__c> testSiteList = [
             SELECT Id ,Name, Operation_Type__c 
             FROM sked__Location__c 
             WHERE Operation_Type__c = 'Integrated'
         ];
         
         Database.DeleteResult[] results = Database.delete(testSiteList, false);
         Test.stopTest();
         
         for (Database.DeleteResult dr : results) {
             if (!dr.isSuccess()) {
                 Assert.areEqual(System.Label.CannotDeleteRecordExceptSystemAdmin, dr.getErrors()[0].getMessage());
             }
         }
         TriggerHandler.clearAllBypasses();
     }
     
     static testmethod void testvalidatePhysicaLocationTypeChange() {
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
         
         Test.startTest();
         
         User testDRDUser = [SELECT Id FROM User WHERE LastName = 'DRDLastName' AND IsActive = true LIMIT 1];
         sked__Location__c testSiteObj = [SELECT Id ,Name, sked_Physical_Location_Type__c FROM sked__Location__c LIMIT 1];
         
         system.runAs(testDRDUser) {
             try {
                 testSiteObj.sked_Physical_Location_Type__c = 'Outside';
                 update testSiteObj;
             } catch(Exception ex) {
                 Assert.isTrue(ex.getMessage().contains('Physical Location Type may not be updated if completed or future drive is planned or associated template is active.'));
             }
         }
         
         TriggerHandler.clearAllBypasses();
         Test.stopTest();
     }
     
     static testMethod void testReturnStatements() {
         BSF_Constants.isTeamMemberCreatedFromBackend = FALSE;
         skedHubBase.BypassInsertTriggers = true;
         skedHubBase.BypassUpdateTriggers = true;
         TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
         TriggerHandler.bypass('OpportunitySplitTriggerHandler');
         TriggerHandler.bypass('DriveTriggerHandler');
         
         Test.startTest();
         SiteService.updateTemplateOpportunitiesForSiteBuidlingNameChange(null,null);
         SiteService.updateDivesOnCalenderForSiteBuidlingNameChange(null,null);
         SiteService.updateSiteCountry(null, null);
         SiteService.checkSiteAddress(null, null);
         TriggerHandler.clearAllBypasses();
         Test.stopTest();
     }
 }