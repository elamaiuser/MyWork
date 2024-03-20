@isTest
private class slwcAdminConsoleController_Test {

    @isTest
    static void getEventTypeSettings_Test() {
        slwcAuraResult eventTypeSettings = slwcAdminConsoleController.getEventTypeSettings();
    }

    @isTest
    static void getScheduleList_Test() {
        System.schedule('skedBiddingExpirationSchedulable_getScheduleList_Test', '20 30 8 10 2 ?', new skedBiddingExpirationSchedulable());
        slwcAuraResult scheduleList = slwcAdminConsoleController.getScheduleList();
    }

    @isTest
    static void executeSchedule_Test() {
        System.schedule('skedBiddingExpirationSchedulable_executeSchedule_Test', '20 30 8 10 2 ?', new skedBiddingExpirationSchedulable());
        slwcAdminConsoleController.executeScheduleRequestModel model = new slwcAdminConsoleController.executeScheduleRequestModel();
        model.scheduleName = 'skedBiddingExpirationSchedulable';
        slwcAuraResult executeScheduleResult = slwcAdminConsoleController.executeSchedule(model);
    }
    
    
    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData(); 

        sked_Event_Type_Setting__c testEventTypeSetting = new sked_Event_Type_Setting__c(
            Name = 'Test Type Setting',
            sked_Item__c = 'Test Type Setting',
            sked_Available_Start__c = 800,
            sked_Available_End__c = 1900,
            sked_Background_Color__c = '555',
            sked_Can_Be_Pre_dated__c = false,
            sked_Color__c = '777',
            sked_Short_Name__c = 'TTS',
            sked_Step__c = 0,
            sked_Is_Available__c = true,
            sked_Show_Legend__c = true,
            sked_Category__c = 'Test',
            sked_Is_Active__c = true
        );

        insert testEventTypeSetting;
    }
}