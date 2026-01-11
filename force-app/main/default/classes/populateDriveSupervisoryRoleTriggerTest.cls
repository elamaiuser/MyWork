/* Modification Log 
 * Date					     Developer Name			     Comments
 * ********************************************************************************************************************************************************************************************************
 * 04/25/2024				  Raktim Ghosal				Test class for the code coverage of JobTrigger,JobAllocationTrigger,JobTriggerHandler,JobAllocationTriggerHandler,
 * 11/11/2025				  Priti Jana				Restructured the test class
 **********************************************************************************************************************************************************************************************************
*/

@isTest
private class populateDriveSupervisoryRoleTriggerTest {
    
    @testSetup static void prepareTestData() {
        TriggerHandler.bypass('DriveTriggerHandler');
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked__Resource__c testVehicle1 = (sked__Resource__c) mapTestData.get('testVehicle1');
        sked__Resource__c testVehicle2 = (sked__Resource__c) mapTestData.get('testVehicle2');
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
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Resource_Role__c = 'VP/HH',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Job_Allocation_Time_Source__c = FALSE
        );
        secondList.add(job2);
        
        sked__Job__c testVehicleJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Asset_Type__c = 'Vehicle',
            sked__Job_Allocation_Time_Source__c = FALSE
        );
        secondList.add(testVehicleJob);
        insert secondList;

        List<sObject> thirdList = new List<sObject>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC'
        );
        thirdList.add(testResource1_job1);
        
        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = 'VP/HH'
        );
        thirdList.add(testResource2_job2);
        
        sked__Job_Allocation__c testVehicleJob_Allocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob.Id,
            sked__Resource__c = testVehicle1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        thirdList.add(testVehicleJob_Allocation1);
        
        sked__Job_Allocation__c testVehicleJob_Allocation2 = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob.Id,
            sked__Resource__c = testVehicle2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        thirdList.add(testVehicleJob_Allocation2);
        insert thirdList;
        TriggerHandler.clearAllBypasses();
    }
    
    @isTest
    private static void testMethodOne() {
        Test.startTest();
        
        sked_Drive__c testDrive = [SELECT Id, Name, Supervisory_Role__c FROM sked_Drive__c LIMIT 1];
        sked__Job__c testJob  = [SELECT Id, sked__Type__c, sked_Resource_Role__c, sked_Drive_Shift__c, sked_Drive__c FROM sked__Job__c WHERE sked_Drive__c = :testDrive.Id LIMIT 1];
        sked__Job_Allocation__c testJobAllocation = [SELECT Id, sked_Additional_Roles__c, sked__Resource__c, sked__Job__r.sked_Drive__c FROM sked__Job_Allocation__c WHERE sked__Job__c = :testJob.Id LIMIT 1];

        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;
    
        testJobAllocation.sked_Additional_Roles__c = 'Drive Lead;Apheresis Charge';
        update testJobAllocation;   
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        sked_Drive__c updatedDrive = [SELECT Id, Name, Supervisory_Role__c FROM sked_Drive__c LIMIT 1];
        Assert.isTrue(updatedDrive.Supervisory_Role__c == 'Test Resource 1');
    }
    
    @isTest
    private static void testMethodTwo() {
        Test.startTest();
        
        sked_Drive__c testDrive = [SELECT Id, Name, Supervisory_Role__c FROM sked_Drive__c LIMIT 1];
        sked__Job__c testJob  = [SELECT Id, sked__Type__c, sked_Resource_Role__c, sked_Drive_Shift__c, sked_Drive__c FROM sked__Job__c WHERE sked_Drive__c = :testDrive.Id LIMIT 1];
        sked__Job_Allocation__c testJobAllocation = [SELECT Id, sked_Additional_Roles__c, sked__Resource__c, sked__Job__r.sked_Drive__c FROM sked__Job_Allocation__c WHERE sked__Job__c = :testJob.Id LIMIT 1];

        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;
    
        testJobAllocation.sked_Additional_Roles__c = 'Drive Lead;Apheresis Charge';
        update testJobAllocation;  
        
        delete testJobAllocation;
        
        Assert.isTrue([SELECT Id, Supervisory_Role__c FROM sked_Drive__c WHERE Id = :testDrive.Id LIMIT 1].Supervisory_Role__c == null); 
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
    @isTest
    private static void testMethodThree() {
        Test.startTest();
        
        sked_Drive__c testDrive = [SELECT Id, Name, Supervisory_Role__c FROM sked_Drive__c LIMIT 1];
        sked__Job__c testJob  = [SELECT Id, sked__Type__c, sked_Resource_Role__c, sked_Drive_Shift__c, sked_Drive__c FROM sked__Job__c WHERE sked_Drive__c = :testDrive.Id LIMIT 1];
        sked__Job_Allocation__c testJobAllocation = [SELECT Id, sked_Additional_Roles__c, sked__Resource__c, sked__Job__r.sked_Drive__c FROM sked__Job_Allocation__c WHERE sked__Job__c = :testJob.Id LIMIT 1];

        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;
    
        testJobAllocation.sked_Additional_Roles__c = 'Drive Lead;Apheresis Charge';
        update testJobAllocation;  
        
        delete testJob;
        
        Assert.isTrue([SELECT Id, Supervisory_Role__c FROM sked_Drive__c WHERE Id = :testDrive.Id LIMIT 1].Supervisory_Role__c == null); 
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
    @isTest
    private static void testMethodFour() {
        Test.startTest();
        
        sked_Drive__c testDrive = [SELECT Id, Name, Supervisory_Role__c FROM sked_Drive__c LIMIT 1];
        sked__Job__c testJob  = [SELECT Id, sked__Type__c, sked_Resource_Role__c, sked_Drive_Shift__c, sked_Drive__c FROM sked__Job__c WHERE sked_Drive__c = :testDrive.Id LIMIT 1];
        sked__Job_Allocation__c testJobAllocation = [SELECT Id, sked_Additional_Roles__c, sked__Resource__c, sked__Job__r.sked_Drive__c FROM sked__Job_Allocation__c WHERE sked__Job__c = :testJob.Id LIMIT 1];

        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;

        testJob.sked_Dual_Role__c = 'Drive Lead';
        update testJob;
               
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        sked_Drive__c updatedDrive = [SELECT Id, Name, Supervisory_Role__c FROM sked_Drive__c LIMIT 1];
        Assert.isTrue(updatedDrive.Supervisory_Role__c == 'Test Resource 1');
    }
}