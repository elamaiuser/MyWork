@isTest
public class skedAccountResourceScoreTrigger_Test {
    
    static testmethod void testException() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
        Test.startTest();
        
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id
        );
        insert job;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        insert testResource1_job1;
        
        sked__Account_Resource_Score__c accountResourceScore1 = new sked__Account_Resource_Score__c(
            sked__Account__c = testAccount1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Blacklisted__c = TRUE,
            sked_Account_Resource_Relationship__c = skedConstants.ACCCOUNT_RESOURCE_SCORE_PREFERRED
        );
        insert accountResourceScore1;
        
        sked__Account_Resource_Score__c accountResourceScore2 = new sked__Account_Resource_Score__c(
            sked__Account__c = testAccount1.Id,
            sked__Resource__c = testResource2.Id,
            sked__Blacklisted__c = TRUE,
            sked_Account_Resource_Relationship__c = skedConstants.ACCCOUNT_RESOURCE_SCORE_DECLINED
        );
        insert accountResourceScore2;
        
        accountResourceScore1.sked_Account_Resource_Relationship__c = skedConstants.ACCCOUNT_RESOURCE_SCORE_DECLINED;
        update accountResourceScore1;
        
        delete accountResourceScore1;
        
        sked__Account_Resource_Score__c accountResourceScore3 = new sked__Account_Resource_Score__c(
            sked__Account__c = testAccount1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Blacklisted__c = TRUE,
            sked_Account_Resource_Relationship__c = skedConstants.ACCCOUNT_RESOURCE_SCORE_DECLINED
        );
        insert accountResourceScore3;
        
		Test.stopTest();
    }

}