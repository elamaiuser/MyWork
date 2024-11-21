@isTest
public class skedAutoApprovePTO_Test {
    
    @testSetup
    static void prepareTestData() {
        // Create sked_Event_Type_Setting__c
        sked_Event_Type_Setting__c eventTypeSetting = new sked_Event_Type_Setting__c(
            Name = 'Test Event Type Setting',
        	sked_Is_Active__c = TRUE,
        	sked_Integrated_with_Workday__c = TRUE,
        	sked_Category__c = 'availability',
        	sked_Item__c = 'PTO',
        	sked_Available_Start__c = 0,
        	sked_Available_End__c = 2400,
        	sked_Background_Color__c = '#F1B606',
        	sked_Can_Be_Pre_dated__c = FALSE,
        	sked_Color__c = '#fff',
        	sked_Step__c = 30,
        	sked_Show_Legend__c = TRUE
        );
        insert eventTypeSetting;
    }

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
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 100,
            sked_Convert_to_Standard_On__c = System.today()
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
            sked_Custom_Status__c = 'Pending',
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO
        );
        insert availability;

        skedProcessBiddingPTOSchedulable schedulable = new skedProcessBiddingPTOSchedulable();
        String chron = '0 0 23 * * ?'; 
        System.schedule('Test schedulable' + Math.random(), chron, schedulable);
        
        Test.stopTest();
    }

    static testMethod void testPTOBatch_AutoExpiry() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        
        sked_Staffing_Budget__c staffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = System.today().addDays(-1),
            sked_Bidding_Start_Date__c = System.today().addDays(-2),
            sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 100,
            sked_Convert_to_Standard_On__c = System.today().addDays(-1)
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

        sked__Availability__c availability2 = new sked__Availability__c(
        	sked__Resource__c = testResource2.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Pending',
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Staffing_Budget__c = staffingBudget.Id,
            sked_Custom_Status__c = 'Waitlist',
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO
        );
        insert availability2;

        Test.setCreatedDate(availability.Id, System.today().addDays(-skedSetting.instance.Admin.numAutoExpireDays));
        Test.setCreatedDate(availability2.Id, System.today().addDays(-skedSetting.instance.Admin.numAutoExpireDays));

        Test.startTest();
        skedProcessBiddingPTOSchedulable schedulable = new skedProcessBiddingPTOSchedulable();
        String chron = '0 0 23 * * ?'; 
        System.schedule('Test schedulable' + Math.random(), chron, schedulable);
        Test.stopTest();

        availability = [SELECT Id, sked_Custom_Status__c FROM sked__Availability__c WHERE Id = :availability.Id];
        Assert.areEqual(skedConstants.AVAILABILITY_STATUS_PENDING_EXPIRED, availability.sked_Custom_Status__c);

        availability2 = [SELECT Id, sked_Custom_Status__c FROM sked__Availability__c WHERE Id = :availability2.Id];
        Assert.areEqual(skedConstants.AVAILABILITY_STATUS_WAITLIST_EXPIRED, availability2.sked_Custom_Status__c);
    }

}