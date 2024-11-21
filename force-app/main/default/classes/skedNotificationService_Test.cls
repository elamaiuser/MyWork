@isTest
private class skedNotificationService_Test {
    testmethod static void testGenerateNotfications_TriggerActionUpdate() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
                
        Test.startTest();
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked_Drive__c testDrive1Old = testDrive1.clone();
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;

        skedNotificationService notificationService = new skedTriggerActionNotificationService('Update', 'sked_Drive__c');
        notificationService.generateNotifications(new List<sObject>{testDrive1}, new Map<Id, sObject> {testDrive1.Id => testDrive1Old});
        
        Test.stopTest();
    }

    testmethod static void testGenerateNotfications_TriggerActionInsert() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked_Staffing_Budget__c staffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = testDataFactory.summary.endDate,
            sked_Bidding_Start_Date__c = testDataFactory.summary.endDate.addDays(-3),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.id,
            sked_Request_Type__c = 'Standard',
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 100
        );
        insert staffingBudget;
        
        Test.startTest();
        
        sked__Availability__c availability = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Pending',
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Staffing_Budget__c = staffingBudget.Id,
            sked_Custom_Status__c = 'Pending'
        );
        insert availability;
        
        sked__Availability__c oldAvailability = availability.clone();

        availability.sked__Finish__c = availability.sked__Finish__c.addHours(1);
        availability.sked_Custom_Status__c = 'Approved';
        availability.sked__Status__c = 'Approved';

        skedNotificationService notificationService = new skedTriggerActionNotificationService('Insert', 'sked__Availability__c');
        notificationService.generateNotifications(new List<sObject>{availability}, new Map<Id, sObject> {availability.Id => oldAvailability});
    }

    testmethod static void testGenerateNotfications_TriggerCustom() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
                
        Test.startTest();
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked_Drive__c testDrive1Old = testDrive1.clone();
        testDrive1Old.Id = testDrive1.Id;
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;

        List<string> settingNames = new List<string>();
        settingNames.add('sked_Logistic_Change_SF_Push');
        settingNames.add('sked_Logistic_Change_SF_Push_7Days');

        skedNotificationService notificationService = new skedCustomNotificationService(settingNames);
        notificationService.generateNotifications(new List<sObject>{testDrive1}, new Map<Id, sObject> {testDrive1.Id => testDrive1Old});
        
        Test.stopTest();
    }
}