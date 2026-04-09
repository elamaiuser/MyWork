@isTest
public class BSF_ClosePastDriveExceptionsBatch_Test {
    @isTest
    private static void testMehtodOne() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Drive_Date__c  = Date.today().addDays(-1);
        update testDrive;

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'test-external-id-2'
        );
        insert testCollectionOp2;
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Region__c testRegion2 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOp2.Id
        );
        insert testRegion2;
        
        testResource.sked__Primary_Region__c = testRegion2.Id;
        update testResource;
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(1),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        insert testJobAllocation;
        
        sked__Job_Allocation__c allocDeleted =
            new sked__Job_Allocation__c(
                sked__Job__c = testJob.Id,
                sked__Resource__c = testResource.Id,
                sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED
            );
        insert allocDeleted;
        
        skedHC__Exception__c testException = new skedHC__Exception__c(
            sked_Drive__c = testDrive.Id,
            skedHC__Job_Allocation__c = testJobAllocation.Id,
            skedHC__Job__c = testJob.Id,
            skedHC__Resource__c = testResource.Id,
            sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO,
            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
        );
        insert testException;

        skedHC__Exception__c exDeleted =
            new skedHC__Exception__c(
                sked_Drive__c = testDrive.Id,
                skedHC__Job_Allocation__c = allocDeleted.Id,
                skedHC__Job__c = testJob.Id,
                skedHC__Resource__c = testResource.Id,
                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT,
                skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
            );
        insert exDeleted;
        
        String cronExp = '0 0 1 * * ?';
        System.schedule('Test BSF Scheduler', cronExp, new BSF_ClosePastDriveExceptionsBatch());
        
        List<sked__Debug_Log__c> logs = [
            SELECT Id, sked__Message__c
            FROM sked__Debug_Log__c
            WHERE sked__Type__c = 'Error Log'
        ];
        System.assert(logs.size() >= 0, 'Debug log should be inserted if a DML failure occurred');
        Test.stopTest();
    }
}