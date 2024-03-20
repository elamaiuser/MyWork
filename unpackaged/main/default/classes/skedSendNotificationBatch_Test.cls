@isTest
private class skedSendNotificationBatch_Test {
    
    static testmethod void testOneOff() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Job__c testSkedJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(13).addMinutes(30),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(14).addMinutes(30),
            sked__Duration__c = 60,
            sked__Type__c = 'Skilled Nursing',
            sked__Address__c = '15 Dalkeith Road, Edinburgh, EH16 5XZ',
            sked__GeoLocation__Latitude__s = 55.9403904,
            sked__GeoLocation__Longitude__s = -3.1744057999999313
        );
        insert testSkedJob1;
        sked__Job_Allocation__c testSkedJobAllocation1 = new sked__Job_Allocation__c(
        	sked__Job__c = testSkedJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testSkedJobAllocation1;
        
        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel();
        setting.contentRenderer = '';
        setting.customFilter = '';
        setting.destinationField = 'sked__Resource__c';
        setting.subject = 'Job Type: {{sked__Job__r.sked__Type__c}}';
        setting.emailFromAddressField = '';
        setting.notificationType = 'oneoff';
        setting.oneoffProtocolField = 'sked__Resource__r.sked__Notification_Type__c';
        setting.targetSObject = 'sked__Job_Allocation__c';
        setting.template = 'Hi {{sked__resource__r.name}}, You are assigned to {{sked__job__r.name}} at [[StartTime]]. Please open Sked X for details.';
        setting.notificationFormats = new List<skedNotificationBatchBase.notificationFormatModel>();
        skedNotificationBatchBase.notificationFormatModel notificationFormat = new skedNotificationBatchBase.notificationFormatModel();
        notificationFormat.dateTimeField = 'sked__Job__r.sked__Start__c';
        notificationFormat.formatForToken = 'StartTime';
        notificationFormat.formatString = 'MM/dd/yyyy HH:mm';
        notificationFormat.timezoneField = 'sked__Job__r.sked__Timezone__c';
        setting.notificationFormats.add(notificationFormat);
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Set<Id> inputRecordIds =  new Set<Id>{testSkedJobAllocation1.Id};
        setting.recordIds = inputRecordIds;
        List<skedNotificationBatchBase.notificationSettingModel> notificationSettings = new List<skedNotificationBatchBase.notificationSettingModel>();
        notificationSettings.add(setting);
        Database.executeBatch(new skedSendNotificationBatch(notificationSettings), 20);
        Test.stopTest();
    }
	
    static testmethod void testEmail() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Job__c testSkedJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(13).addMinutes(30),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(14).addMinutes(30),
            sked__Duration__c = 60,
            sked__Type__c = 'Skilled Nursing',
            sked__Address__c = '15 Dalkeith Road, Edinburgh, EH16 5XZ',
            sked__GeoLocation__Latitude__s = 55.9403904,
            sked__GeoLocation__Longitude__s = -3.1744057999999313
        );
        insert testSkedJob1;
        sked__Job_Allocation__c testSkedJobAllocation1 = new sked__Job_Allocation__c(
        	sked__Job__c = testSkedJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testSkedJobAllocation1;
        
        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel();
        setting.contentRenderer = '';
        setting.customFilter = '';
        setting.destinationField = 'sked__Resource__c';
        setting.subject = 'Job Type: {{sked__Job__r.sked__Type__c}}';
        setting.emailFromAddressField = 'sked__Resource__r.sked__Email__c';
        setting.notificationType = 'email';
        setting.oneoffProtocolField = 'sked__Resource__r.sked__Notification_Type__c';
        setting.targetSObject = 'sked__Job_Allocation__c';
        setting.template = 'Hi {{sked__resource__r.name}}, You are assigned to {{sked__job__r.name}} at [[StartTime]]. Please open Sked X for details.';
        setting.notificationFormats = new List<skedNotificationBatchBase.notificationFormatModel>();
        skedNotificationBatchBase.notificationFormatModel notificationFormat = new skedNotificationBatchBase.notificationFormatModel();
        notificationFormat.dateTimeField = 'sked__Job__r.sked__Start__c';
        notificationFormat.formatForToken = 'StartTime';
        notificationFormat.formatString = 'MM/dd/yyyy HH:mm';
        notificationFormat.timezoneField = 'sked__Job__r.sked__Timezone__c';
        setting.notificationFormats.add(notificationFormat);
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Set<Id> inputRecordIds =  new Set<Id>{testSkedJobAllocation1.Id};
        setting.recordIds = inputRecordIds;
        List<skedNotificationBatchBase.notificationSettingModel> notificationSettings = new List<skedNotificationBatchBase.notificationSettingModel>();
        notificationSettings.add(setting);
        Database.executeBatch(new skedSendNotificationBatch(notificationSettings), 20);
        Test.stopTest();
    }

    static testmethod void testSms() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Job__c testSkedJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(13).addMinutes(30),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(14).addMinutes(30),
            sked__Duration__c = 60,
            sked__Type__c = 'Skilled Nursing',
            sked__Address__c = '15 Dalkeith Road, Edinburgh, EH16 5XZ',
            sked__GeoLocation__Latitude__s = 55.9403904,
            sked__GeoLocation__Longitude__s = -3.1744057999999313
        );
        insert testSkedJob1;
        sked__Job_Allocation__c testSkedJobAllocation1 = new sked__Job_Allocation__c(
        	sked__Job__c = testSkedJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testSkedJobAllocation1;
        
        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel();
        setting.subject = 'Job Type: {{sked__Job__r.sked__Type__c}}';
        setting.contentRenderer = '';
        setting.customFilter = '';
        setting.destinationField = 'sked__Resource__r.sked__Email__c';
        setting.emailFromAddressField = 'sked__Resource__r.sked__Email__c';
        setting.notificationType = 'customsms';
        setting.oneoffProtocolField = 'sked__Resource__r.sked__Notification_Type__c';
        setting.targetSObject = 'sked__Job_Allocation__c';
        setting.template = 'Hi {{sked__resource__r.name}}, You are assigned to {{sked__job__r.name}}. Please open Sked X for details.';
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Set<Id> inputRecordIds =  new Set<Id>{testSkedJobAllocation1.Id};
        setting.recordIds = inputRecordIds;
        List<skedNotificationBatchBase.notificationSettingModel> notificationSettings = new List<skedNotificationBatchBase.notificationSettingModel>();
        notificationSettings.add(setting);
        Database.executeBatch(new skedSendNotificationBatch(notificationSettings), 20);
        Test.stopTest();
    }
    
    static testmethod void testSalesforcePush() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Job__c testSkedJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(13).addMinutes(30),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(14).addMinutes(30),
            sked__Duration__c = 60,
            sked__Type__c = 'Skilled Nursing',
            sked__Address__c = '15 Dalkeith Road, Edinburgh, EH16 5XZ',
            sked__GeoLocation__Latitude__s = 55.9403904,
            sked__GeoLocation__Longitude__s = -3.1744057999999313
        );
        insert testSkedJob1;
        sked__Job_Allocation__c testSkedJobAllocation1 = new sked__Job_Allocation__c(
        	sked__Job__c = testSkedJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testSkedJobAllocation1;
        
        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel();
        setting.subject = 'Job Type: {{sked__Job__r.sked__Type__c}}';
        setting.contentRenderer = '';
        setting.customFilter = '';
        setting.destinationField = 'sked__Job__r.OwnerId';
        setting.emailFromAddressField = 'sked__Resource__r.sked__Email__c';
        setting.notificationType = 'salesforcepush';
        setting.notificationTargetField = 'sked__Job__c';
        setting.oneoffProtocolField = 'sked__Resource__r.sked__Notification_Type__c';
        setting.targetSObject = 'sked__Job_Allocation__c';
        setting.template = 'Hi {{sked__resource__r.name}}, You are assigned to {{sked__job__r.name}}. Please open Sked X for details.';
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Set<Id> inputRecordIds =  new Set<Id>{testSkedJobAllocation1.Id};
        setting.recordIds = inputRecordIds;
        List<skedNotificationBatchBase.notificationSettingModel> notificationSettings = new List<skedNotificationBatchBase.notificationSettingModel>();
        notificationSettings.add(setting);
        Database.executeBatch(new skedSendNotificationBatch(notificationSettings), 20);
        Test.stopTest();
    }
    
    static testmethod void testCustomRenderer() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Test.startTest();
        
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        List<sked_Drive__c> newRecords = new List<sked_Drive__c>();
        sked_Drive__c newTestDrive1 = new sked_Drive__c(
        	Id = testDrive1.Id,
            Name = testDrive1.Name,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_WB_Projected_Procedures__c = testDrive1.sked_WB_Projected_Procedures__c + 10
        );
        newRecords.add(newTestDrive1);
        
        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>();
        oldMap.put(testDrive1.Id, testDrive1);
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testDrive1.Id);
        
        List<sObject> secondList = new List<sObject>();
        sked__Job__c job = new sked__Job__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Region__c = testRegion1.Id
        );
        secondList.add(job);
        insert secondList;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testVehicle1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        insert testResource1_job1;
        
        List<sked_Notification_Setting__mdt> skedNotificationSettings = [SELECT Id
                                                                         FROM sked_Notification_Setting__mdt
                                                                         WHERE DeveloperName IN ('sked_Logistic_Change_SF_Push')];
        if (!skedNotificationSettings.isEmpty()) {
            Map<Id, Set<Id>> map_settingId_recordIds = new Map<Id, Set<Id>>();
            for (sked_Notification_Setting__mdt skedNotificationSetting : skedNotificationSettings) {
                if (!recordIds.isEmpty()) {
                    map_settingId_recordIds.put(skedNotificationSetting.Id, recordIds);
                    Database.executeBatch(new skedSendNotificationBatch(map_settingId_recordIds,  newRecords, oldMap), 20);
                }
            }
        }
        
        Test.stopTest();
    }
    
    static testmethod void testDriveShiftTradeExceptionRender() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        Opportunity testOpportunity2 = (Opportunity)mapTestData.get('testOpportunity2');
        
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
        Test.startTest();
        
        sked_Drive__c testDrive2 = testDrive1.clone();
        testDrive2.sked_Opportunity__c = testOpportunity2.Id;
        insert testDrive2;
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        
        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        driveShifts.add(driveShift1);
        
        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);
        
        insert driveShifts;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job1);
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;
        
		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;
        

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        insert driveShiftTrade;
        
        driveShiftTrade.sked_Reason_Approval_Required__c = 'Trading User exceeds Max Hours per week';
        update driveShiftTrade;
        
        testResource1_job1.sked_Drive_Shift_Trade__c = driveShiftTrade.Id;
        testResource2_job2.sked_Drive_Shift_Trade__c = driveShiftTrade.Id;
        update jobAllocations;
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testResource1_job1.Id);
        recordIds.add(testResource2_job2.Id);
        
        List<sked_Notification_Setting__mdt> skedNotificationSettings = [SELECT Id
                                                                         FROM sked_Notification_Setting__mdt
                                                                         WHERE DeveloperName IN ('sked_Drive_Shift_Trade_Overtime_Ex_1Days')];
        if (!skedNotificationSettings.isEmpty()) {
            Map<Id, Set<Id>> map_settingId_recordIds = new Map<Id, Set<Id>>();
            for (sked_Notification_Setting__mdt skedNotificationSetting : skedNotificationSettings) {
                if (!recordIds.isEmpty()) {
                    map_settingId_recordIds.put(skedNotificationSetting.Id, recordIds);
                    Database.executeBatch(new skedSendNotificationBatch(map_settingId_recordIds), 20);
                }
            }
        }
        
        Test.stopTest();
    }
    
    static testmethod void testCustomTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Job__c testSkedJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(13).addMinutes(30),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(14).addMinutes(30),
            sked__Duration__c = 60,
            sked__Type__c = 'Charge',
            sked_Resource_Role__c = 'Charge',
            sked__Address__c = '15 Dalkeith Road, Edinburgh, EH16 5XZ',
            sked__GeoLocation__Latitude__s = 55.9403904,
            sked__GeoLocation__Longitude__s = -3.1744057999999313
        );
        insert testSkedJob1;
        sked__Job_Allocation__c testSkedJobAllocation1 = new sked__Job_Allocation__c(
        	sked__Job__c = testSkedJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testSkedJobAllocation1;
        
        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel();
        setting.contentRenderer = '';
        setting.customFilter = '';
        setting.customTargetDestination = 'driveLeadTargetDestination';
        setting.destinationField = 'sked__Resource__c';
        setting.subject = 'Job Type: {{sked__Job__r.sked__Type__c}}';
        setting.emailFromAddressField = 'sked__Resource__r.sked__Email__c';
        setting.notificationType = 'email';
        setting.oneoffProtocolField = 'sked__Resource__r.sked__Notification_Type__c';
        setting.targetSObject = 'sked__Job_Allocation__c';
        setting.template = 'Hi {{sked__resource__r.name}}, You are assigned to {{sked__job__r.name}} at [[StartTime]]. Please open Sked X for details.';
        setting.notificationFormats = new List<skedNotificationBatchBase.notificationFormatModel>();
        skedNotificationBatchBase.notificationFormatModel notificationFormat = new skedNotificationBatchBase.notificationFormatModel();
        notificationFormat.dateTimeField = 'sked__Job__r.sked__Start__c';
        notificationFormat.formatForToken = 'StartTime';
        notificationFormat.formatString = 'MM/dd/yyyy HH:mm';
        notificationFormat.timezoneField = 'sked__Job__r.sked__Timezone__c';
        setting.notificationFormats.add(notificationFormat);
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Set<Id> inputRecordIds =  new Set<Id>{testSkedJobAllocation1.Id};
        setting.recordIds = inputRecordIds;
        List<skedNotificationBatchBase.notificationSettingModel> notificationSettings = new List<skedNotificationBatchBase.notificationSettingModel>();
        notificationSettings.add(setting);
        Database.executeBatch(new skedSendNotificationBatch(notificationSettings), 20);
        Test.stopTest();
    }

    static testmethod void convertQueueIdToUserEmails_Test() {
        Group testGroup = new Group(
            name = 'Test Group',
            type = skedConstants.GROUP_TYPE_QUEUE
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testGroup;
            insert new GroupMember(
                UserOrGroupId = UserInfo.getUserId(),
                GroupId = testGroup.Id
            );
        }

        skedEmailService.emailModel model = new skedEmailService.emailModel();
        model.targetObjId = testGroup.Id;

        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel();
        setting.contentRenderer = '';
        setting.customFilter = '';
        setting.customTargetDestination = 'driveLeadTargetDestination';
        setting.destinationField = 'sked__Resource__c';
        setting.subject = 'Job Type: {{sked__Job__r.sked__Type__c}}';
        setting.emailFromAddressField = 'sked__Resource__r.sked__Email__c';
        setting.notificationType = 'email';
        setting.oneoffProtocolField = 'sked__Resource__r.sked__Notification_Type__c';
        setting.targetSObject = 'sked__Job_Allocation__c';
        setting.template = 'Hi {{sked__resource__r.name}}, You are assigned to {{sked__job__r.name}} at [[StartTime]]. Please open Sked X for details.';
        setting.notificationFormats = new List<skedNotificationBatchBase.notificationFormatModel>();
        skedNotificationBatchBase.notificationFormatModel notificationFormat = new skedNotificationBatchBase.notificationFormatModel();
        notificationFormat.dateTimeField = 'sked__Job__r.sked__Start__c';
        notificationFormat.formatForToken = 'StartTime';
        notificationFormat.formatString = 'MM/dd/yyyy HH:mm';
        notificationFormat.timezoneField = 'sked__Job__r.sked__Timezone__c';
        setting.notificationFormats.add(notificationFormat);

        Test.startTest();
        List<skedNotificationBatchBase.notificationSettingModel> notificationSettings = new List<skedNotificationBatchBase.notificationSettingModel>();
        notificationSettings.add(setting);
        skedSendNotificationBatch batch = new skedSendNotificationBatch(notificationSettings);
        batch.convertQueueIdToUserEmails(new List<skedEmailService.emailModel>{model});
        Test.stopTest();
    }
    
}