/* The following test class is covering the below apex class
 * CalendarBuildEvaluateDrivesBatch (93%)
 * CalendarBuildBatchHandler (94%)
 * CreateSkedDrivesBatch(84%)
 * 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * *****************************************************************************************************************************
 * 2/19/2024                  Priti Jana            Rewriting entire test class to reduce complexity and increase code coverage
 * 10/29/2024				  Priti Jana			Fixed errors
 * 01/09/2025				  Priti Jana			Commented out test method for Gray Sky consideration (HRP-12299)
 * 02/04/2025                 Anil Kallu            Generate Exception if a calendar build opp falls with in 56 days range of another opp on account(if 56 day accept flag is false) 
 * 03/04/2025				  Priti Jana			Added test methods to increase coverage (HRP-11368)
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
         //HRP-11850 -Begin this is the opp calendar build opp clones
         testMobileOpp.Name='Mobile1';
         testMobileOpp.Drive_date__c=System.today();
         testMobileOpp.CloseDate=System.today().addDays(-15);//HRP-11850-End

         testMobileOpp.accountId = accList[1].Id;
         testMobileOpp.Drive_Site__c = siteList[0].Id;
         testMobileOpp.Parent_Template_Id__c = oppList[1].Id;
         testMobileOpp.stageName = 'Discovery';
         insert testMobileOpp;
        
        //HRP-11850 -Begin, this is the opp that will be with in 56 days of calendar clone of opportunity above
        Opportunity mobileOpp2 = testMobileOpp.clone(false, true, false, false);
        mobileOpp2.Accept_56_Day_Rule_Violation__c=true;
        mobileOpp2.bypass_validation_rule__c = true;
        mobileOpp2.Name='MobileOpp2';
     
        mobileOpp2.CloseDate=System.today().addDays(300);
        //make this with in 56 days of calendar build opp (which will be generated with 20 days prior to today+1year, based on custom metadata config)
        mobileOpp2.Drive_date__c= System.today().addDays(325);
        insert mobileOpp2;//HRP-11850-End
        
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

    //HRP-11850
    static testMethod void testCBMobileDrivesFor56DaysViolation() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Calendar_Build_Batch__c.intValue();
        Test.startTest();
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('DriveAffiliationHandler');

        Opportunity mobileOpp = [select id, stageName, Drive_date__c, Parent_Template_Id__c from Opportunity where type_of_drive__c = 'Mobile' and Name='Mobile1' AND Is_Template__c = FALSE LIMIT 1];
        mobileOpp.bypass_validation_rule__c = TRUE;
        mobileOpp.Drive_Date__c = System.today().addDays(-numOfDays);
        mobileOpp.Drive_Date_Change_Reason__c = 'TEST';
        mobileOpp.StageName = 'Cancelled';
        mobileOpp.Initiated_By__c = 'ARC_Initiated_Mobile';
        mobileOpp.sked_Cancellation_Reason__c = 'System Need';
        update mobileOpp;
        //update template accept 56 day flag to false, so calendar build opp will not have it
        Opportunity templateMobileOpp = [select id, Accept_56_Day_Rule_Violation__c from Opportunity where Id = :mobileOpp.Parent_Template_Id__c AND Is_Template__c = TRUE LIMIT 1];
        templateMobileOpp.Accept_56_Day_Rule_Violation__c = false;//set accept to false;
        update templateMobileOpp;
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Database.executeBatch(cbDrive);
        Test.stopTest();
        Opportunity oppWithError = [select id, Calendar_Build_Reasons_For_Unqualified__c from Opportunity WHERE Source__c = 'Calendar Build' LIMIT 1];
        Assert.areEqual(true, oppWithError.Calendar_Build_Reasons_For_Unqualified__c.contains('Violates Accepts 56 day selection'), 'There should be atleast one opportunity with Calendar_Build_Reasons_For_Unqualified__c populated for Violates Accepts 56 day selection');  
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
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Database.executeBatch(cbDrive);
        //new CalendarBuildEvaluateDrivesBatch(null).execute(null, null);
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

    static testMethod void testCreateSkedFsDrivesBatch() {
        Test.startTest();
        new CreateSkedDrivesBatch(null, 'Calendar Build', Date.newInstance(2025, 01, 01), null);
        Test.stopTest();
    }
    
    static testMethod void testCreateSkedFsDrivesBatch_Exception() {
        Test.startTest();
        new CreateSkedDrivesBatch(null);
        Test.stopTest();
    }
    
    //HRP-11368: New testmethod for Adhoc CB run batch
    static testMethod void testAdhocCbBatchRun() {
        Test.startTest();
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        Opportunity mobileOpp = [select id, StageName, Drive_Date__c,
                                 Type_of_Drive__c, AccountId
                                 from Opportunity where type_of_drive__c = 'Mobile' AND Is_Template__c = FALSE LIMIT 1];
       
        CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput input = new CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput();
        input.bookingStrategy = 'TEST RUN';
        input.opportunitySource = 'Adhoc Calendar Build';
        input.selectedOpportunities = new List<Opportunity>{mobileOpp};
            
        // Call the batch
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch(input);
        Database.executeBatch(cbDrive);
        Test.stopTest();   
    }
    
    //New cystom exception test to increase coverage
    static testMethod void testAdhocCbBatchException() {
        
        // Call the batch
        Test.startTest();
        CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput input;
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch(input);
        Database.executeBatch(cbDrive);
        Test.stopTest();
    }
    
    static testMethod void testManualRunException() {
        Test.startTest();
        Date manualRunDate;
        BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION = TRUE;
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch(manualRunDate);
        Test.stopTest();
    }
    
    static testMethod void testScheduledRunException() {
        Test.startTest();
        BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION = TRUE;
        CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        Test.stopTest();
    }
    
}