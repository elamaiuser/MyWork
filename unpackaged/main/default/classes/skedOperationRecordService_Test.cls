@isTest
public class skedOperationRecordService_Test {
    
    @testSetup static void prepareTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Account testAccount = (Account) mapTestData.get('testAccount1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        testDrive.sked_Drive_Owner__c = Userinfo.getUserId();
        update testDrive;
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
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
        insert testDriveShift;
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS,
            sked_Call_Out_Type__c = skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL,
            sked_DateTime_Call_Out_Received__c = system.now().addDays(10),
            sked_Call_Out_Reason_Code__c = 'Personal'
        );
        insert testJobAllocation;
    }
    
    @isTest
    public static List<sked_Operation_Record__c> generateOperationRecords_Test() {
        
        Test.startTest();
        sked_Drive__c testDrive = [SELECT Id FROM sked_Drive__c LIMIT 1];
        List<sked_Operation_Record__c> operationRecords = skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});
        Set<Id> operationRecordIds = new Set<Id>();
        for (sked_Operation_Record__c operationRecord : operationRecords) {
            operationRecordIds.add(operationRecord.Id);
        }

        skedOperationRecordService.populateExternalIds(operationRecordIds);
        Test.stopTest();
        return operationRecords;
    }
    
    @isTest
    private static void regenrateOpRecords_Test() {
        Test.startTest();
        sked_Drive__c testDrive = [SELECT Id FROM sked_Drive__c LIMIT 1];
        List<sked_Operation_Record__c> operationRecords = skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});
        
        skedHubBase.BypassDeleteTriggers = TRUE;
        List<sked_Operation_Record__c> regeneratedOpRecords = skedOperationRecordService.regenerateOperationRecords(new Set<Id>{testDrive.Id});
        skedHubBase.BypassDeleteTriggers = FALSE;
        
        Test.stopTest();
        Assert.isTrue(regeneratedOpRecords != NULL && !regeneratedOpRecords.isEmpty());
    }
}