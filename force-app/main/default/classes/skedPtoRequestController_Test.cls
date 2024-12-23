@isTest
private class skedPtoRequestController_Test {
    
    @isTest
    static void initialize_test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        skedPtoRequestController.initializeRequestModel model = new skedPtoRequestController.initializeRequestModel();
        model.configKeys = new List<string>();
        model.configKeys.add('availabilityTypes');
        model.resourceId = testResource.Id;
        model.viewData = new Map<String, Object>();
        skedRemoteResultModel initializeResult = skedPtoRequestController.initialize(model);
    }
    
    @isTest
    static void confirmUnavailability_Test() {
        sked__Availability__c testAvailability = [SELECT Id FROM sked__Availability__c LIMIT 1][0];
        skedPtoRequestController.saveAvailabilityRequestModel model = new skedPtoRequestController.saveAvailabilityRequestModel();
        model.viewData = new Map<String, Object>(); 
        model.event = new skedModels.availability();
        model.event.Id = testAvailability.Id;
        model.event.waitlistConfirmed = true;
        model.event.status = skedConstants.AVAILABILITY_STATUS_APPROVED;
        
        Test.startTest();

        skedPtoRequestController.confirmUnavailability(model);

        Test.stopTest();
    }
    
    @isTest
    static void getPendingAvailability_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        skedPtoRequestController.getPendingAvailabilityRequest model = new skedPtoRequestController.getPendingAvailabilityRequest();
        Date startDate = System.today();
        Date endDate = startDate.addDays(100);
        model.viewData = new Map<String, Object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimezone().getID());
        
        model.configKeys = new List<string>();
        model.configKeys.add('availabilityTypes');
        
        model.resourceId = testResource.Id;
        model.startDate = '' + startDate.year() + '-' + startDate.month() + '-' + startDate.day();
        model.endDate = '' + endDate.year() + '-' + endDate.month() + '-' + endDate.day();
        
        Test.startTest();
        
        skedRemoteResultModel pendingAvailability = skedPtoRequestController.getPendingAvailability(model);
        
        Test.stopTest();
    }
    
    @isTest
    static void getUnavailabilityStatistic_Test() {
        Date testDate = System.today().addDays(10);
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        
        skedPtoRequestController.getUnavailabilityStatisticRequest model = new skedPtoRequestController.getUnavailabilityStatisticRequest();
        model.viewData = new Map<String, Object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        model.selectedDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        model.resourceId = testResource.Id;
        
        Test.startTest();
        
        skedRemoteResultModel getUnavailabilityStatisticResult = skedPtoRequestController.getUnavailabilityStatistic(model);
        
        Test.stopTest();
    }
    
    
    @isTest
    static void saveUnavailability_Test() {
        sked__Availability__c testAvailability = [SELECT Id FROM sked__Availability__c LIMIT 1][0];
        skedPtoRequestController.saveUnavailabilityRequestModel model = new skedPtoRequestController.saveUnavailabilityRequestModel();
        model.viewData = new Map<String, Object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.id = testAvailability.Id;
        testAvailabilityModel.isAvailable = false;
        testAvailabilityModel.waitlistConfirmed = false;
        model.availability = new List<skedModels.availability>();
        model.availability.add(testAvailabilityModel);
        
        Test.startTest();
        
        skedRemoteResultModel saveAvailabilityResult = skedPtoRequestController.saveUnavailability(model);
        
        Test.stopTest();
    }   
    
    @isTest
    static void verifyUnavailabilityBalance_Test() {
        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_Workday_Integration__c = TRUE;
        upsert skedAdminSetting;
        
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOBalanceMock());
        
        Date testDate = System.today().addDays(10);
        sked__Availability__c testAvailability = [SELECT Id FROM sked__Availability__c LIMIT 1][0];
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        skedPtoRequestController.verifyUnavailabilityBalanceRequestModel model = new skedPtoRequestController.verifyUnavailabilityBalanceRequestModel();
        model.viewData = new Map<String, Object>();
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.id = testAvailability.Id;
        testAvailabilityModel.isAvailable = false;
        testAvailabilityModel.waitlistConfirmed = false;
        testAvailabilityModel.resourceId = testResource.Id;
        testAvailabilityModel.startDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.startTime = 900;
        testAvailabilityModel.endDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.endTime = 1700;
        model.unavailability = new List<skedModels.availability>();
        model.unavailability.add(testAvailabilityModel);
        
        Test.startTest();
        
        skedRemoteResultModel unavailabilityBalance = skedPtoRequestController.verifyUnavailabilityBalance(model);
        
        Test.stopTest();
    }
    
    @isTest
    static void prepareUnavailabilityRequest_Test() {
        Date testDate = System.today().addDays(10);
        sked__Availability__c testAvailability = [SELECT Id FROM sked__Availability__c LIMIT 1][0];
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        skedPtoRequestController.saveAvailabilityRequestModel model = new skedPtoRequestController.saveAvailabilityRequestModel();
        model.viewData = new Map<String, Object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.id = testAvailability.Id;
        testAvailabilityModel.isAvailable = false;
        testAvailabilityModel.waitlistConfirmed = false;
        testAvailabilityModel.resourceId = testResource.Id;
        testAvailabilityModel.startDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.startTime = 900;
        testAvailabilityModel.endDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.endTime = 1700;
        testAvailabilityModel.eventType = 'Sick';
        model.event = testAvailabilityModel;
        
        Test.startTest();
        
        skedRemoteResultModel prepareUnavailabilityResult = skedPtoRequestController.prepareUnavailabilityRequest(model);
        
        Test.stopTest();
    }
    
    @isTest
    static void deleteAvailabilities_Test() {
        sked__Availability__c testAvailability = [SELECT Id FROM sked__Availability__c LIMIT 1][0];
        skedPtoRequestController.saveAvailabilityRequestModel model = new skedPtoRequestController.saveAvailabilityRequestModel();
        model.viewData = new Map<String, Object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        model.events = new List<skedModels.availability>();
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.id = testAvailability.Id;
        Date testDate = System.today().addDays(10);
        testAvailabilityModel.startDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.startTime = 900;
        testAvailabilityModel.endDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.endTime = 1700;
        model.events.add(testAvailabilityModel);
        
        Test.startTest();
        
        skedRemoteResultModel deleteAvailabilityResult = skedPtoRequestController.deleteAvailabilities(model);
        
        Test.stopTest();
    }
    
    @isTest
    static void cancelAvailability_Test() {
        sked__Availability__c testAvailability = [SELECT Id FROM sked__Availability__c LIMIT 1][0];
        skedPtoRequestController.saveAvailabilityRequestModel model = new skedPtoRequestController.saveAvailabilityRequestModel();
        model.viewData = new Map<String, Object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        model.events = new List<skedModels.availability>();
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.id = testAvailability.Id;
        Date testDate = System.today().addDays(10);
        testAvailabilityModel.startDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.startTime = 900;
        testAvailabilityModel.endDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        testAvailabilityModel.endTime = 1700;
        testAvailabilityModel.timezoneSidId = UserInfo.getTimeZone().getID();
        model.events.add(testAvailabilityModel);
        
        Test.startTest();

        skedRemoteResultModel deleteAvailabilityResult = skedPtoRequestController.cancelAvailability(model);

        Test.stopTest();
    }
    
    @isTest
    static void saveCustomAvailability_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        
        Date testDate = System.today().addDays(10);
        skedPtoRequestController.saveCustomAvailabilityRequestModel model = new skedPtoRequestController.saveCustomAvailabilityRequestModel();
        model.viewData = new Map<string, object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        model.event = new skedModels.customAvailability();
        model.event.isAvailable = TRUE;
        model.event.notes = 'test';
        model.event.resourceId = testResource.Id;
        model.event.startDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        model.event.startTime = 900;
        model.event.endDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        model.event.endTime = 1700;
        model.event.eventType = 'Volunteer';
        
        Test.startTest();

        skedRemoteResultModel saveCustomAvailabilityResult = skedPtoRequestController.saveCustomAvailability(model);

        Test.stopTest();
    }
    
    @isTest
    static void getCustomAvailabilityDetails_Test() {
        sked_Custom_Availability__c testCustomAvailability = [SELECT Id FROM sked_Custom_Availability__c LIMIT 1][0];
        
        Date testDate = System.today().addDays(10);
        skedPtoRequestController.getCustomAvailabilityDetailsRequest model = new skedPtoRequestController.getCustomAvailabilityDetailsRequest();
        model.viewData = new Map<string, object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        model.event = new skedModels.customAvailability();
        model.event.id = testCustomAvailability.Id;
        
        Test.startTest();
        
        skedRemoteResultModel getCustomAvailabilityDetailsResult = skedPtoRequestController.getCustomAvailabilityDetails(model);
        
        Test.stopTest();
    }
    
    @isTest 
    static void deleteCustomAvailability_Test() {
        sked_Custom_Availability__c testCustomAvailability = [SELECT Id FROM sked_Custom_Availability__c LIMIT 1][0];
        
        Date testDate = System.today().addDays(10);
        skedPtoRequestController.saveCustomAvailabilityRequestModel model = new skedPtoRequestController.saveCustomAvailabilityRequestModel();
        model.viewData = new Map<string, object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        model.event = new skedModels.customAvailability();
        model.event.id = testCustomAvailability.Id;
        
        Test.startTest();
        
        skedRemoteResultModel deleteCustomAvailabilityResult = skedPtoRequestController.deleteCustomAvailability(model);
        
        Test.stopTest();
    }
    
    @isTest
    static void getResourceCustomAvailabilityData_Test() {
        Date today = System.today();
        Date endDate = System.today().addDays(10);
        sked__Resource__c testResource = [SELECT Id, Name FROM sked__Resource__c LIMIT 1][0];
        skedPtoRequestController.getResourceCustomAvailabilityModel customAvailModel = new skedPtoRequestController.getResourceCustomAvailabilityModel();
        customAvailModel.resourceId = testResource.Id;
        customAvailModel.startDate = today.year() + '-' + today.month() + '-' + today.day();
        customAvailModel.endDate = endDate.year() + '-' + endDate.month() + '-' + endDate.day();
        customAvailModel.viewData = new Map<String, Object>();
        customAvailModel.viewData.put('timezoneSidId', UserInfo.getTimezone().getID());
        
        Test.startTest();
        
        skedRemoteResultModel result = skedPtoRequestController.getResourceCustomAvailabilityData(customAvailModel);
        
        Test.stopTest();
    }
    
    @isTest
    static void skedPtoRequestController_Test() {
        Test.startTest();
        skedPtoRequestController controllerInstance = new skedPtoRequestController();
        Assert.isTrue(controllerInstance.resourceId != NULL);
        Test.stopTest();
    }
    
    @isTest
    static void cancelCustomAvailability_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        
        Date testDate = System.today().addDays(10);
        skedPtoRequestController.saveCustomAvailabilityRequestModel model = new skedPtoRequestController.saveCustomAvailabilityRequestModel();
        model.viewData = new Map<string, object>();
        model.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        model.event = new skedModels.customAvailability();
        model.event.isAvailable = TRUE;
        model.event.notes = 'test';
        model.event.resourceId = testResource.Id;
        model.event.startDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        model.event.startTime = 900;
        model.event.endDate = '' + testDate.year() + '-' + testDate.month() + '-' + testDate.day();
        model.event.endTime = 1700;
        model.event.eventType = 'Volunteer';
        
        Test.startTest();

        skedRemoteResultModel saveCustomAvailabilityResult = skedPtoRequestController.saveCustomAvailability(model);
        skedRemoteResultModel cancelCustomAvailabilityResult = skedPtoRequestController.cancelCustomAvailability(model);

        Test.stopTest();
    }
    
    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked_Custom_Availability__c testCustomAvailability = new sked_Custom_Availability__c(
            sked_Type__c = 'Volunteer',
            sked_Status__c = 'Approved',
            sked_Notes__c = 'Test Custom Availability',
            sked_Resource__c = ((sked__Resource__c) mapTestData.get('testResource1')).Id,
            sked_Start_Date__c = System.today().addDays(5),
            sked_Finish_Date__c = System.today().addDays(6)
        );
        insert testCustomAvailability;
    }
}