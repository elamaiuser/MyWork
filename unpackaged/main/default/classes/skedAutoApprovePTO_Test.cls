@isTest
public class skedAutoApprovePTO_Test {

    static testmethod void testPTOBatch() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        sked_Staffing_Budget__c staffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = System.today().addDays(-1),
            sked_Bidding_Start_Date__c = System.today().addDays(-2),
            sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
            sked_Roles__c = '2RBC',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 100
        );
        insert staffingBudget;

        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo1 = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = staffingBudget.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOperation1.Id
        );
        insert testStaffingBudgetCo1;

        sked__Availability__c availability = new sked__Availability__c(
        	sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Pending',
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Staffing_Budget__c = staffingBudget.Id,
            sked_Custom_Status__c = 'Pending',
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO
        );
        insert availability;

        skedProcessBiddingPTOSchedulable schedulable = new skedProcessBiddingPTOSchedulable();
        String chron = '0 0 23 * * ?'; 
        System.schedule('Test schedulable' + Math.random(), chron, schedulable);
        
        Test.stopTest();
    }

}