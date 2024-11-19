@isTest
public class skedAvailabilityTrigger_Test {
    
    static  void testException() {
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
        
        availability.sked__Finish__c = availability.sked__Finish__c.addHours(1);
        availability.sked_Custom_Status__c = 'Approved';
        update availability;
        
        sked__Availability__c checkConflictAvailability = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Approved',
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Staffing_Budget__c = staffingBudget.Id,
            sked_Custom_Status__c = 'Approved'
        );
        insert checkConflictAvailability;
        
        availability.sked__Start__c = availability.sked__Start__c.addDays(7);
        availability.sked__Finish__c = availability.sked__Finish__c.addDays(7);
        update availability;
        
        delete checkConflictAvailability;
        
        Test.stopTest();
    }
    
    static  void populateStaffingBudgetAvailabilities_Test_NoMatchingCO() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCollectionOperation2 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation2');
        
        sked__Resource__c testResource1 = (sked__Resource__c) mapTestData.get('testResource1');
        
        sked_Staffing_Budget__c testStaffingBudget1 = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = testDataFactory.summary.endDate,
            sked_Bidding_Start_Date__c = testDataFactory.summary.endDate.addDays(-3),
            sked_Request_Type__c = 'Standard',
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 100
        );
        
        insert new List<SObject>{testStaffingBudget1};
            
            sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo1 = new sked_Staffing_Budget_Collection_Op__c(
                sked_Staffing_Budget__c = testStaffingBudget1.Id,
                sked_Biomed_Collection_Operation__c = testCollectionOperation2.Id
            );
        
        insert new List<SObject>{testStaffingBudgetCo1};
            
            Test.startTest();
        Boolean caughtException = false;
        
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Approved',
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Custom_Status__c = 'Approved',
            sked__Type__c = 'PTO'
        );
        
        try {
            insert testAvailability;
        }
        catch (Exception ex) {
            caughtException = true;
        }
        
        Test.stopTest();
    }
    
    static  void populateStaffingBudgetAvailabilities_Test_MatchingCO() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        
        sked__Resource__c testResource1 = (sked__Resource__c) mapTestData.get('testResource1');
        
        sked_Staffing_Budget__c testStaffingBudget1 = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = testDataFactory.summary.endDate,
            sked_Bidding_Start_Date__c = testDataFactory.summary.endDate.addDays(-3),
            sked_Request_Type__c = 'Standard',
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 100
        );
        
        sked_Staffing_Budget__c testStaffingBudget2 = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = testDataFactory.summary.endDate,
            sked_Bidding_Start_Date__c = testDataFactory.summary.endDate.addDays(-3),
            sked_Request_Type__c = 'Standard',
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 100
        );
        
        insert new List<SObject>{testStaffingBudget1, testStaffingBudget2};
            
            sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo1 = new sked_Staffing_Budget_Collection_Op__c(
                sked_Staffing_Budget__c = testStaffingBudget1.Id,
                sked_Biomed_Collection_Operation__c = testCollectionOperation1.Id
            );
        
        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo2 = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = testStaffingBudget1.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOperation1.Id
        );
        
        insert new List<SObject>{testStaffingBudgetCo1, testStaffingBudgetCo2};
            
            Test.startTest();
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Approved',
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Custom_Status__c = 'Approved',
            sked__Type__c = 'PTO'
        );
        
        insert testAvailability;
        
        List<sked_Staffing_Budget_Availability__c> sbas = [SELECT Id FROM sked_Staffing_Budget_Availability__c];
        System.assertEquals(2, sbas.size());
        Test.stopTest();
    }
    
    static testmethod void testCalloutAndCancelCallout() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        mapTestData = testDataFactory.setupDriveData();
        
        Test.startTest();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        List<sObject> secondList = new List<sObject>();
        
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        secondList.add(job);
        insert secondList;

        List<sObject> thirdList = new List<sObject>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        thirdList.add(testResource1_job1);
        insert thirdList;
        
        slwcResourceService.saveCallOutRequestModel model = new slwcResourceService.saveCallOutRequestModel();
        model.jobId = job.Id;
        model.resourceId = testResource1.Id;
        model.callOutNotes = 'Testing Notes';
        model.callOutReason = 'Testing';
        model.callOutReported = true;
        model.callOutType = 'Call Out';
        model.usePtoForCallOut = false;
        model.hasTimeOffPlans = false;
        slwcResourceService.saveCallOut(model);
        
        sked__Availability__c callOutAvail = [SELECT Id, sked_Custom_Status__c
                                              FROM sked__Availability__c
                                              WHERE sked_Call_Out_for_Job_Allocation__c = :testResource1_job1.Id];
        callOutAvail.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_CANCELLED;
        update callOutAvail;
        
        Test.stopTest();
    }
    
}