@isTest
private class skedNightlyTradeProcessBatch_Test {
    @isTest
    static void skedNightlyTradeProcessBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.setMock(HttpCalloutMock.class, new skedWorkdayTimeTrackingHttpMock());

        sked_Trade_API_Data__c tradeRecord = new sked_Trade_API_Data__c(
            sked_Approver_Email__c = 'bsfsupport@redcross.com',
            sked_Resource__c = testResource.Id,
            sked_Event_Date__c = System.TODAY().addDays(-1),
            sked_Event_Id__c = '123123123',
            sked_Status__c = 'Queued'
        );
        insert tradeRecord;

        Test.startTest();
        Database.executeBatch(new skedNightlyTradeProcessBatch());
        Test.stopTest();
    }

    @isTest
    static void skedNightlyTradeProcessBatch_Error_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        sked_Trade_API_Data__c tradeRecord = new sked_Trade_API_Data__c(
            sked_Approver_Email__c = 'bsfsupport@redcross.com',
            sked_Resource__c = testResource.Id,
            sked_Event_Date__c = System.TODAY().addDays(-1),
            sked_Event_Id__c = '123123123',
            sked_Status__c = 'Queued'
        );
        insert tradeRecord;

        Test.startTest();
        Database.executeBatch(new skedNightlyTradeProcessBatch());
        Test.stopTest();
    }
}