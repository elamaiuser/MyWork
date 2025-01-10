@isTest
private class skedStaffingBudgetUtils_Test {

    @testSetup
    static void prepareDataSetup() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
  
        List<sked_Staffing_Budget__c> staffingBudgetList = new List<sked_Staffing_Budget__c>();
        sked_Staffing_Budget__c staffingBudget;
        
        staffingBudget = new sked_Staffing_Budget__c(
                sked_Bidding_End_Date__c = System.today().addDays(-1),
                sked_Bidding_Start_Date__c = System.today().addDays(-2),
                sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
                sked_Roles__c = '2RBC',
                sked_Drive_Types__c = 'Mobile;Fixed Site',
                sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
                sked_Total_Slots__c = 100,
                sked_Convert_to_Standard_On__c = System.today().addDays(-1)
        );
        staffingBudgetList.add(staffingBudget);
        
        staffingBudget = new sked_Staffing_Budget__c(
                sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_STANDARD,
                sked_Roles__c = '2RBC',
                sked_Drive_Types__c = 'Mobile;Fixed Site',
                sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
                sked_Total_Slots__c = 5
        );
        staffingBudgetList.add(staffingBudget);
        
        insert staffingBudgetList;

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
            sked_Staffing_Budget__c = staffingBudgetList[1].Id,
            sked_Custom_Status__c = 'Pending',
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO
        );

        insert availability;
               
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
    
    static testMethod void skedStaffingBudgetHandler_Test() {
        
        Test.startTest();
        List<sked_Staffing_Budget__c> results = [SELECT Id, sked_Request_Type__c, sked_Total_Slots__c FROM sked_Staffing_Budget__c];
        results[0].sked_Request_Type__c = 'Standard';
        results[0].sked_Total_Slots__c = 6;
        update results[0];
        Test.stopTest();
    }
    
    static testMethod void autofillStaffingBudgetSlotsFromWaitlist_Test() {
        Test.startTest();
        
        Biomed_Collection_Op_Center__c testColOpp = [SELECT Id, sked_Auto_Approval_Cutoff_Days__c FROM Biomed_Collection_Op_Center__c LIMIT 1];
        testColOpp.sked_Auto_Approval_Cutoff_Days__c = 1;
        update testColOpp;
        
        List<sked_Staffing_Budget__c> results = [SELECT Id, sked_Request_Type__c, sked_Total_Slots__c FROM sked_Staffing_Budget__c WHERE sked_Request_Type__c = 'Standard'];
        skedStaffingBudgetUtils.publishAutofillEvent(new Set<Id>{results[0].Id});
        skedStaffingBudgetUtils.updateAvailabilityBiddingTypeByStaffingBudgets(new Set<Id>{results[0].Id});
        
        Test.stopTest();
    }
}