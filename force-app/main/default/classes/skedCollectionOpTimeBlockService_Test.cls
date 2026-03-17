@isTest
private class skedCollectionOpTimeBlockService_Test {
    
    static testMethod void getQueryConditions_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        Collection_Operation_Time_Block__c testCoTimeBlock = (Collection_Operation_Time_Block__c) mapTestData.get('testCOTB1');
        system.debug('testCoTimeBlock '+testCoTimeBlock);
        
        skedCollectionOpTimeBlockService.queryModel query = new skedCollectionOpTimeBlockService.queryModel();
        query.startDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        query.endDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        query.collectionOperationIds = new List<String>{testCo.Id};
            
        Test.startTest();
            
        skedCollectionOpTimeBlockService coTimeBlockService = new skedCollectionOpTimeBlockService();
        system.debug('query '+query);
        List<Collection_Operation_Time_Block__c> coTimeBlocks = coTimeBlockService.query(query);
        
        Test.stopTest();
        
    }
}