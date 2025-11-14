@isTest
private class skedStaffingBudgetSiteService_Test {
    
    @isTest
    static void getQueryConditions_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();

        sked__Location__c testLocation = (sked__Location__c) mapTestData.get('testLocation1');
        sked_Staffing_Budget__c testSb = (sked_Staffing_Budget__c) mapTestData.get('testStaffingBudget1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');

        Test.startTest();
        skedStaffingBudgetSiteService.queryModel query = new skedStaffingBudgetSiteService.queryModel();
        query.siteIds = new List<String>{testLocation.Id};
        query.staffingBudgetIds = new List<String>{testSb.Id};
        query.siteCoIds = new List<String>{testCo.Id};
        query.requestTypes = new List<String>{'Standard'};
        query.isBiddingPeriodRequest = TRUE;
        query.startDate = '2024-12-01';
        query.endDate = '2024-12-01';
        skedStaffingBudgetSiteService sbSiteService = (skedStaffingBudgetSiteService) skedServiceFactory.instance.resolve('sked_Staffing_Budget_Site__c');
        List<sked_Staffing_Budget_Site__c> sbSites = sbSiteService.query(query);
        Test.stopTest();
    }

}