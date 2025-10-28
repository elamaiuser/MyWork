@isTest
private class skedSetting_Test {

    @isTest
    static void skedSetting_Test() {
        skedSetting.skedAppSetting appSetting = skedSetting.instance.App;
        skedSetting.skedBookingGridSetting bookingGridSetting = skedSetting.instance.BG;
        skedSetting.skedEcSetting ecSetting = skedSetting.instance.EC;
        skedSetting.skedLacSetting lacSetting = skedSetting.instance.LAC;
        skedSetting.skedPacSetting pacSetting = skedSetting.instance.PAC;
        skedSetting.skedRacSetting racSetting = skedSetting.instance.RAC;
        skedSetting.skedEmailSetting emailSetting = skedSetting.instance.Email;
        skedSetting.skedTravelTimeManager travelTimeSetting = skedSetting.instance.TravelTime;
        skedSetting.skedTTIRRStuckJobConfigSetting stuckTTIRRSetting = skedSetting.instance.stuckTTIRR;
        skedSetting.skedJAPostProcessBatchConfigSetting jaPostProcessSetting = skedSetting.instance.jaPostProcessBatchConfig;
        Map<String, Set<Date>> holidays = appSetting.mapHoliday;
        appSetting.setTimezoneSidId(UserInfo.getTimeZone().getID());
        appSetting.detectDaylightSaving(system.today(), system.today().addDays(10));
        appSetting.detectDaylightSaving(system.now(), system.now().addHours(10));
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject>  mapTestData = testDataFactory.setupCommonTestData();

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');

        sked__Holiday__c testGlobalHoliday = new sked__Holiday__c(
            Name = 'Test',
            sked__Start_Date__c = System.today().addDays(100),
            sked__End_Date__c = System.today().addDays(100)
        );
        insert testGlobalHoliday;

        sked__Holiday_Region__c testHolidayRegion = new sked__Holiday_Region__c(
            sked__Holiday__c = testGlobalHoliday.Id,
            sked__Region__c = testRegion.Id
        );
        insert testHolidayRegion;

        sked_Event_Type_Setting__c testEventTypeSetting = new sked_Event_Type_Setting__c(
            Name = 'Test',
            sked_Is_Active__c = true,
            sked_Item__c = 'Test Item',
            sked_Available_Start__c = 800,
            sked_Available_End__c = 1900,
            sked_Background_Color__c = '#fff',
            sked_Can_Be_Pre_dated__c = true,
            sked_Color__c = '#666',
            sked_Short_Name__c = 'Test',
            sked_Step__c = 1,
            sked_Is_Available__c = true,
            sked_Show_Legend__c = true,
            sked_Category__c = 'job'
        );
        insert testEventTypeSetting;
        
        sked_Email_Setting__c testEmailSetting = new sked_Email_Setting__c(
        	sked_APS_Directors__c = 'test1@abc.org',
        	sked_BHQ_APS_Staff_SchedulingTimekeeping__c = 'test2@abc.org',
        	sked_BHQ_APS_Staff_Scheduling_Managers__c = 'test3@abc.org',
        	sked_BIT_Technical_Support__c = 'test4@abc.org',
        	sked_Opp_DOC_Sync_Error_Email__c = 'test5@abc.org'
        );
        insert testEmailSetting;
        
        sked_Travel_Time_Manager__c testTravelTimeManager = new sked_Travel_Time_Manager__c(
        	sked_Drive_Impact_Threshold__c = 100,
        	sked_Manual_Refresh_Priority__c = 10
        );
        insert testTravelTimeManager;
        
        sked_User_Filter__c testUserFilter = new sked_User_Filter__c(
        	sked_User__c = UserInfo.getUserId(),
        	sked_Category__c = 'RAC',
        	sked_JSON_Data__c = ''
        );
        insert testUserFilter;

        sked_TTIRR_Stuck_Job_Config_Setting__c testTTIRRStuckJobSetting = new sked_TTIRR_Stuck_Job_Config_Setting__c(
        	sked_Enable_Auto_Reschedule__c = true,
        	sked_Is_Active__c = true,
        	sked_Maximum_Retries__c = 3,
        	sked_Reschedule_Interval_Minutes__c = 5,
        	sked_Stuck_Threshold_Minutes__c = 0
        );
        insert testTTIRRStuckJobSetting;
        
        sked_JA_Post_Process_Config__c testJAPostProcessSetting = new sked_JA_Post_Process_Config__c(
        	sked_Allowed_Maximum_Retries__c = 1,
        	sked_Allowed_No_of_Jobs_in_Flex_Queue__c = 1,
        	sked_Reschedule_Interval_Sec_Flex_Queue__c = 10
        );
        insert testJAPostProcessSetting;
    }
}