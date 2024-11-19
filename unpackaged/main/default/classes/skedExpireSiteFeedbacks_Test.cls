@isTest
private class skedExpireSiteFeedbacks_Test {
    
    static testmethod void skedExpireSiteFeedbacks_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c)mapTestData.get('testLocation1');
        
        Test.startTest();
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked_Site_Feedback__c testSiteFeedback = new sked_Site_Feedback__c(
            sked_Amount__c = 5,
            sked_Buffer_Type__c = 'Add',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Effective_End_Date__c = System.today().addDays(-5),
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Job__c = testJob.Id,
            sked_MigrationID__c = 'test-migration-id',
            sked_Reason__c = 'testing',
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Site__c = testDriveSite.Id,
            sked_Status__c = 'Not Submitted',
            sked_Variance_Applies_To__c = 'Setup Time',
            sked_Variance_Type__c = 'Parking'
        );
        
        insert testSiteFeedback;
            
        skedExpireSiteFeedbacksSchedulable schedulable = new skedExpireSiteFeedbacksSchedulable();
        String chron = '0 0 23 * * ?'; 
        System.schedule('Test schedulable' + Math.random(), chron, schedulable);
        
        Test.stopTest();
    }
}