/**
 * @description: Test class for BSF_UpdateCollectionOperationsBatch
**/
@isTest
private class BSF_UpdateCollectionOperationsBatchTest {
    @TestSetup
    static void makeData(){
        Biomed_Collection_Op_Center__c testCo = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id'
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCo;
        System.assertNotEquals(null, testCo.Id,'Collection Op not inserted.');
    }
    
    @isTest 
    static void testBatch1() {
        Map<Id, Biomed_Collection_Op_Center__c> collectionMap = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, Name FROM Biomed_Collection_Op_Center__c]);
        System.assertNotEquals(0, collectionMap.size(),'Collection Op not found.');
        Test.setMock(HttpCalloutMock.class, new MockToolingResponse());
        Test.startTest();
            BSF_UpdateCollectionOperationsBatch batchobj = new BSF_UpdateCollectionOperationsBatch(collectionMap,'INSERT');
            Database.executeBatch(batchobj,200);
        Test.stopTest();
    }

    @isTest 
    static void testBatch2() {
        List<Biomed_Collection_Op_Center__c> collectionList = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c];
        System.assertNotEquals(0, collectionList.size(),'Collection Op not found.');
        collectionList.get(0).Name = 'Test Collection Op';
        Map<Id, Biomed_Collection_Op_Center__c> collectionMap = new Map<Id, Biomed_Collection_Op_Center__c>(collectionList);
        Test.setMock(HttpCalloutMock.class, new MockToolingResponse());
        Test.startTest();
            BSF_UpdateCollectionOperationsBatch batchobj = new BSF_UpdateCollectionOperationsBatch(collectionMap,'UPDATE');
            Database.executeBatch(batchobj,200);
        Test.stopTest();
    }

    @isTest 
    static void testBatch3() {
        Map<Id, Biomed_Collection_Op_Center__c> collectionMap = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, Name FROM Biomed_Collection_Op_Center__c]);
        System.assertNotEquals(0, collectionMap.size(),'Collection Op not found.');
        Test.setMock(HttpCalloutMock.class, new MockToolingResponse());
        Test.startTest();
            BSF_UpdateCollectionOperationsBatch batchobj = new BSF_UpdateCollectionOperationsBatch(collectionMap,'DELETE');
            Database.executeBatch(batchobj,200);
        Test.stopTest();
    }

    private class MockToolingResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            if (req.getEndpoint().contains('query')) {
                res.setBody('{"entityTypeName":"GlobalValueSet","records":[{"attributes":{"type":"GlobalValueSet","url":"/services/data/v56.0/tooling/sobjects/GlobalValueSet/0Nt5c000000brHdCAI"},"Id":"0Nt5c000000brHdCAI"}]}');
            }
            return res;
        }
    }
}