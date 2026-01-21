@isTest
private class skedStaffingBudgetCollOp_Test {
    
    @isTest
    static void getQueryConditions_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();

        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staffing_Budget__c testSb = (sked_Staffing_Budget__c) mapTestData.get('testStaffingBudget1');
        
        testSb.sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate;
        update testSb;

        Test.startTest();
            skedStaffingBudgetCollectionOpService.queryModel query = new skedStaffingBudgetCollectionOpService.queryModel();
            query.collectionOpIds = new List<String>{testCo.Id};
            query.staffingBudgetIds = new List<String>{testSb.Id};
            query.startDate = testDataFactory.summary.startDateIso;
        	query.endDate = testDataFactory.summary.endDateIso;
        	query.requestTypes = new List<String>{'Standard'};
            skedStaffingBudgetCollectionOpService sbCoService = (skedStaffingBudgetCollectionOpService) skedServiceFactory.instance.resolve('sked_Staffing_Budget_Collection_Op__c');
            List<sked_Staffing_Budget_Collection_Op__c> sbcos = sbCoService.query(query);
        Test.stopTest();
        
        Assert.isTrue(sbcos != null && !sbcos.isEmpty());
    }
}