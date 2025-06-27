@isTest
public class DeleteOrphanJobBatchTest {
    
    @isTest
    static void test_DeleteOrphanJobAllocations() {
     
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        mapTestData = testDataFactory.setupDriveData();
        
        Test.startTest();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
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
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Job_Allocation_Time_Source__c = FALSE
        );
        secondList.add(job1);
        insert secondList;
        List<sObject> thirdList = new List<sObject>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = secondList[0].Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        thirdList.add(testResource1_job1);
        
        insert thirdList;
       // delete thirdList;
  
        DeleteOrphanJobBatch batch1 = new DeleteOrphanJobBatch();
        Database.executeBatch(batch1, 50);
        // Assert orphaned job allocation is deleted
       
        
      
     
    }
    
    
    
      @isTest
    static void testSchedulerExecution() {
       
        String cronExp = '0 0 0 1 1 ? 2099'; // A valid cron expression (future date to avoid conflict)
       Test.startTest();

        // Schedule the job
        String jobId = System.schedule('TestDeleteOrphanJobBatchScheduler', cronExp, new DeleteOrphanJobBatchScheduler());
        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
        Test.stopTest(); // Executes the scheduled job and batch

       
    }
}