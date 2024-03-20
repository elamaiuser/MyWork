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
        Map<String, Set<Date>> holidays = appSetting.mapHoliday;
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
    }
}