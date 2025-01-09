/* The following test class is covering the below apex class
 * CalendarBuildEvaluateDrivesBatch (77%)
 * CalendarBuildBatchHandler (95%)
 * 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * *****************************************************************************************************************************
 * 2/19/2024                  Priti Jana            Rewriting entire test class to reduce complexity and increase code coverage
 * 10/29/2024				  Priti Jana			Fixed errors
 * 01/09/2025				  Priti Jana			Commented out test method for Gray Sky consideration (HRP-12299)
 * *****************************************************************************************************************************/

@isTest(SeeAllData = FALSE)
public class CalendarBuildEvaluateDrivesBatch_Test {
    public static string id_site;
  
    @testSetup
    private static void prepareDataSetup(){
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // IMP Containers
        List<Account> accList = new List<Account>();
        List<sked__Location__c> siteList = new List<sked__Location__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<sked_Drive__c> driveList = new List<sked_Drive__c>();
        
        /* Affiliation Preparation
        Marketing_Program__c greySkies = new Marketing_Program__c();
        greySkies.Name = 'Gray Skies';
        greySkies.External_Name__c = 'ABCT001';
        greySkies.Scope__c = 'Drive';
        insert greySkies;*/
        
        // Account Preparation - Fixed & Mobile
        Account testFixedSiteAcc = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testFixedSiteAcc.Account_Strategy__c = 'Sunset';
        Account testMobileAcc = (Account)mapTestData.get('MOBILE_ACCOUNT');   
        testMobileAcc.Account_Strategy__c = 'Sunset';
        accList.add(testFixedSiteAcc);
        accList.add(testMobileAcc);
        insert accList;
        
        // Contact Preparation
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAcc.Id;
        insert testContact;
        
        // Location Preparation - Fixed & Mobile
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');       
        siteList.add(testMobileSite);
        siteList.add(testFixedSite);
        insert siteList;
        id_site = siteList[0].Id;
        
         // Opportunity Preparation - Fixed Site & Template
         Triggerhandler.bypass('OpportunityTriggerHandler');
         Opportunity testFixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
         testFixedSiteOpp.accountId = testFixedSiteAcc.Id;
         testFixedSiteOpp.Drive_Site__c = testFixedSite.Id;
         testFixedSiteOpp.stageName = 'Discovery';
         oppList.add(testFixedSiteOpp);
        
         Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
         testTemplate.accountId = testMobileAcc.Id;
         testTemplate.Drive_Site__c = testMobileSite.Id;
         oppList.add(testTemplate);
         insert oppList;
                
         // Opportunity Preparation - Mobile
         Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
         testMobileOpp.accountId = accList[1].Id;
         testMobileOpp.Drive_Site__c = siteList[0].Id;
         testMobileOpp.Parent_Template_Id__c = oppList[1].Id;
         testMobileOpp.stageName = 'Discovery';
         insert testMobileOpp;
        
         // Drive Preparation - Fixed & Mobile
         sked_Drive__c testFixedSiteDrive = new sked_Drive__c();
         testFixedSiteDrive.Name = 'Test Fixed Site Drive';
         testFixedSiteDrive.sked_Drive_Date__c = oppList[0].Drive_Date__c;
         testFixedSiteDrive.sked_Drive_Site__c = oppList[0].Drive_Site__c;
         testFixedSiteDrive.sked_Opportunity__c = oppList[0].Id;
         testFixedSiteDrive.sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_FIXED_SITE;
         testFixedSiteDrive.sked_Account__c = oppList[0].AccountId;
         testFixedSiteDrive.sked_Start_Time__c = oppList[0].Start_Time__c;
         testFixedSiteDrive.sked_End_Time__c = oppList[0].End_Time__c;
         testFixedSiteDrive.sked_Drive_Productivity_Planned__c = 0.8;
         testFixedSiteDrive.sked_Projected_Registered_Donors__c = oppList[0].Anticipated_Registered_Donors__c;
         testFixedSiteDrive.sked_2RBC_Projected_Procedures__c = oppList[0].X2RBC_Projected_Procedures__c;
         testFixedSiteDrive.sked_WB_Projected_Procedures__c = oppList[0].WB_Projected_Procedures__c;
         testFixedSiteDrive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        
         sked_Drive__c testMobileDrive = new sked_Drive__c();
         testMobileDrive.Name = 'Test Mobile Drive';
         testMobileDrive.sked_Drive_Date__c = testMobileOpp.Drive_Date__c;
         testMobileDrive.sked_Drive_Site__c = testMobileOpp.Drive_Site__c;
         testMobileDrive.sked_Opportunity__c = testMobileOpp.Id;
         testMobileDrive.sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_MOBILE;
         testMobileDrive.sked_Account__c = testMobileOpp.AccountId;
         testMobileDrive.sked_Start_Time__c = testMobileOpp.Start_Time__c;
         testMobileDrive.sked_End_Time__c = testMobileOpp.End_Time__c;
         testMobileDrive.sked_Drive_Productivity_Planned__c = 0.8;
         testMobileDrive.sked_Projected_Registered_Donors__c = testMobileOpp.Anticipated_Registered_Donors__c;
         testMobileDrive.sked_2RBC_Projected_Procedures__c = testMobileOpp.X2RBC_Projected_Procedures__c;
         testMobileDrive.sked_WB_Projected_Procedures__c = testMobileOpp.WB_Projected_Procedures__c;
         testMobileDrive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;  
         driveList.add(testMobileDrive);
         driveList.add(testFixedSiteDrive);
         Triggerhandler.bypass('DriveTriggerHandler');
         insert driveList;
         TriggerHandler.clearAllBypasses();
         DriveTriggerService.populateLookupOnOpportunityDoc(driveList);
    }
    
    static testmethod void testCBFSDrives() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        
        Test.startTest();
        Opportunity fsOpp = [select id, stageName, Drive_date__c from Opportunity where type_of_drive__c = 'Fixed Site' LIMIT 1];
        fsOpp.bypass_validation_rule__c = TRUE;
        fsOpp.Drive_Date__c = System.today().addDays(-numOfDays);
        fsopp.Drive_Date_Change_Reason__c = 'TEST';
        fsOpp.StageName = 'Cancelled';
        fsOpp.Initiated_By__c = 'ARC Initiated-Fixed';
        fsOpp.sked_Cancellation_Reason__c = 'System Need';
        update fsOpp;
        
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Database.executeBatch(cbDrive);
        Test.stopTest();
    }
    
    static testMethod void testCBMobileDrives() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        
        Test.startTest();
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        Opportunity mobileOpp = [select id, stageName, Drive_date__c from Opportunity where type_of_drive__c = 'Mobile' AND Is_Template__c = FALSE LIMIT 1];
        mobileOpp.bypass_validation_rule__c = TRUE;
        mobileOpp.Drive_Date__c = System.today().addDays(-numOfDays);
        mobileOpp.Drive_Date_Change_Reason__c = 'TEST';
        mobileOpp.StageName = 'Cancelled';
        mobileOpp.Initiated_By__c = 'ARC_Initiated_Mobile';
        mobileOpp.sked_Cancellation_Reason__c = 'System Need';
        update mobileOpp;
        
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Database.executeBatch(cbDrive);
        Map<Id, String> dml_error_map = new Map<id, String>();
        dml_error_map.put(mobileOpp.id, 'test class');
        CalendarBuildEvaluateDrivesBatch.sendErrorNotification(null, dml_error_map);
        Test.stopTest();
    }
    
    /*static testMethod void testCBMobileDrivesWithGreySkies() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        
        Test.startTest();
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        Marketing_Program__c aff = [select id, name from Marketing_Program__c limit 1];
        Opportunity mobileOpp = [select id, stageName, Drive_date__c,driveStatus__c from Opportunity where type_of_drive__c = 'Mobile' AND Is_Template__c = FALSE LIMIT 1];
        mobileOpp.bypass_validation_rule__c = TRUE;
        mobileOpp.Drive_Date__c = System.today().addDays(-numOfDays);
        mobileOpp.Drive_Date_Change_Reason__c = 'TEST';
        mobileOpp.StageName = 'Cancelled';
        mobileOpp.Initiated_By__c = 'ARC_Initiated_Mobile';
        mobileOpp.sked_Cancellation_Reason__c = 'System Need';
        update mobileOpp;
        
        // Drive Marketing Program Preparation
        Drive_Marketing_Programs__c driveAff = new Drive_Marketing_Programs__c();
        driveAff.Marketing_Program__c = aff.Id;
        driveAff.Blood_Drive_Opportunity__c = mobileOpp.Id;
        insert driveAff;
        
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Database.executeBatch(cbDrive);
        Test.stopTest();
    }*/
    
    static testMethod void testCBMobileDrivesForLostAcc() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        
        Test.startTest();
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        Opportunity mobileOpp = [select id, stageName, Drive_date__c, AccountId from Opportunity where type_of_drive__c = 'Mobile' AND Is_Template__c = FALSE LIMIT 1];
        update (new  Account(Id = mobileOpp.AccountId , Account_Status__c = 'Lost', Account_Strategy__c = '', Lost_Reason__c = 'Other'));
        mobileOpp.bypass_validation_rule__c = TRUE;
        mobileOpp.Drive_Date__c = System.today().addDays(-numOfDays);
        mobileOpp.Drive_Date_Change_Reason__c = 'TEST';
        mobileOpp.StageName = 'Cancelled';
        mobileOpp.Initiated_By__c = 'ARC_Initiated_Mobile';
        mobileOpp.sked_Cancellation_Reason__c = 'System Need';
        update mobileOpp;
        TriggerHandler.clearAllBypasses();
        
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Database.executeBatch(cbDrive);
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
    static testMethod void testScheduleExecuteMethod() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        
        Test.startTest();
        Opportunity fsOpp = [select id, stageName, Drive_date__c, Related_Scheduled_Drive__c from Opportunity where type_of_drive__c = 'Fixed Site' LIMIT 1];
        system.debug('fsOpp '+fsOpp);
        fsOpp.bypass_validation_rule__c = TRUE;
        fsOpp.Drive_Date__c = System.today().addDays(-numOfDays);
        fsopp.Drive_Date_Change_Reason__c = 'TEST';
        fsOpp.StageName = 'Cancelled';
        fsOpp.Initiated_By__c = 'ARC Initiated-Fixed';
        fsOpp.sked_Cancellation_Reason__c = 'System Need';
        update fsOpp;
        sked_Drive__C drive = [select sked_status__c from sked_Drive__C where sked_Opportunity__c = :fsOpp.Id];
        system.debug('drive '+drive);
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cb = new CalendarBuildEvaluateDrivesBatch();
        SchedulableContext scon;
        cb.execute(scon);
        Test.stopTest();
    }
    
    static testMethod void testCBManualRun() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        Date manualRunDate = System.today().addDays(-numOfDays);
        
        Test.startTest();
        Opportunity fsOpp = [select id, stageName, Drive_date__c from Opportunity where type_of_drive__c = 'Fixed Site' LIMIT 1];
        fsOpp.bypass_validation_rule__c = TRUE;
        fsOpp.Drive_Date__c = manualRunDate;
        fsopp.Drive_Date_Change_Reason__c = 'TEST';
        fsOpp.StageName = 'Cancelled';
        fsOpp.Initiated_By__c = 'ARC Initiated-Fixed';
        fsOpp.sked_Cancellation_Reason__c = 'System Need';
        update fsOpp;
        
        
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch(manualRunDate);
        Database.executeBatch(cbDrive);
        Test.stopTest();
    }
    
    static testMethod void testCBRunForExecuteException() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        Date manualRunDate = System.today().addDays(-numOfDays);
        
        Test.startTest();
        Opportunity fsOpp = [select id, stageName, Drive_date__c from Opportunity where type_of_drive__c = 'Fixed Site' LIMIT 1];
        fsOpp.bypass_validation_rule__c = TRUE;
        fsOpp.Drive_Date__c = manualRunDate;
        fsopp.Drive_Date_Change_Reason__c = 'TEST';
        fsOpp.StageName = 'Cancelled';
        fsOpp.Initiated_By__c = 'ARC Initiated-Fixed';
        fsOpp.sked_Cancellation_Reason__c = 'System Need';
        update fsOpp;

        // Call the batch
        new CalendarBuildEvaluateDrivesBatch(null).execute(null, null);
        Test.stopTest();
    }
    
    static testMethod void testCBWithExecuteDMLException() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        Date manualRunDate = System.today().addDays(-numOfDays);
        
        Test.startTest();
        Opportunity fsOpp = [select id, stageName, Drive_date__c from Opportunity where type_of_drive__c = 'Fixed Site' LIMIT 1];
        fsOpp.bypass_validation_rule__c = TRUE;
        fsOpp.Drive_Date__c = manualRunDate;
        fsopp.Drive_Date_Change_Reason__c = 'TEST';
        fsOpp.StageName = 'Cancelled';
        fsOpp.End_Time__c = Time.newInstance(9, 30, 0, 0);
        fsOpp.Initiated_By__c = 'ARC Initiated-Fixed';
        fsOpp.sked_Cancellation_Reason__c = 'System Need';
        update fsOpp;

        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Database.executeBatch(cbDrive);
        Test.stopTest();
    }
    
    static testMethod void testCBRunForFinishException() {
        new CalendarBuildEvaluateDrivesBatch(null).finish(null);
    }
    
    static testMethod void testCreateSkedFsDrivesBatch() {
        Test.startTest();
        new CreateSkedDrivesBatch(null, 'Calendar Build', Date.newInstance(2025, 01, 01), null);
        Test.stopTest();
    }
    
}