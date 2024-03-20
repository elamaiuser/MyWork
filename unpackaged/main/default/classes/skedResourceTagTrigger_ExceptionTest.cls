@isTest
private class skedResourceTagTrigger_ExceptionTest {

    static testmethod void roleStatusException() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        
        sked__Tag__c x2rbcTag = [SELECT Id
                                 FROM sked__Tag__c
                                 WHERE Name = '2RBC'
                                 AND sked__Type__c = :skedConstants.TAG_TYPE_ROLE];
        sked__Resource_Tag__c testResource1_2rbc = new sked__Resource_Tag__c(
            sked__Resource__c = testResource1.Id,
            sked__Tag__c = x2rbcTag.Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_ACTIVE
        );
        insert testResource1_2rbc;
        
        List<sObject> secondList = new List<sObject>();
        
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(10),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        secondList.add(job1);
        insert secondList;

        List<sObject> thirdList = new List<sObject>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        thirdList.add(testResource1_job1);
        insert thirdList;
        
        testResource1_2rbc.sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_INACTIVE;
        update testResource1_2rbc;
        
        Test.stopTest();
    }
    
}