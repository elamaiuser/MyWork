@isTest
private class skedScheduleChangeNotificationBatch_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        System.debug('start test');
        Test.startTest();
        
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        List<sObject> firstList = new List<sObject>();
        
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
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
        firstList.add(driveShift);
        insert firstList;
        
        List<sObject> secondList = new List<sObject>();
        sked__Job__c job = new sked__Job__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Location__c = testLocation1.Id,
            sked__Region__c = testRegion1.Id,
            sked__Job_Allocation_Time_Source__c = FALSE
        );
        secondList.add(job);
        
        sked__Job__c updatedJob = job.clone();
        updatedJob.sked__Start__c = job.sked__Start__c.addMinutes(15);
        updatedJob.sked__Finish__c = job.sked__Finish__c.addMinutes(15);
        secondList.add(updatedJob);
        
        insert secondList;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        insert testResource1_job1;
        
        Set<Id> jobIds = new Set<Id>();
        jobIds.add(job.Id);
    	
        Map<Id, sked__Job__c> mapOldJob = new Map<Id, sked__Job__c>();
        mapOldJob.put(job.Id, job);
        
        Map<Id, sked__Job__c> mapNewJob = new Map<Id, sked__Job__c>();
        mapNewJob.put(job.Id, updatedJob);
        
        Database.executeBatch(new skedScheduleChangeNotificationBatch(jobIds, mapNewJob, mapOldJob));
        
        Test.stopTest();
    }
    
}