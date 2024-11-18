@isTest
private class skedResourceSeniorityRankingBatch_Test {
    @isTest
    static void skedResourceSeniorityRankingBatch_Test() {
        Test.startTest();
        Database.executeBatch(new skedResourceSeniorityRankingBatch());
        Test.stopTest();

        List<sked__Resource__c> testResources = [
            SELECT Id, sked_Seniority_Rank__c 
            FROM sked__Resource__c 
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
        ];

        for (sked__Resource__c testResource : testResources) {
            System.assertNotEquals(null, testResource.sked_Seniority_Rank__c);
        }
    }
    
    @isTest
    static void skedResourceSeniorityRankingBatch_Test_Parameterized() {
        Set<Id> territoryIds = new Set<Id>();
    	Set<Id> skedResourceIds = new Set<Id>();
        List<sked__Resource__c> resourceRecord = [ SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c FROM sked__Resource__c WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON];
        for(sked__Resource__c resource: resourceRecord){
            skedResourceIds.add(resource.Id);
            territoryIds.add(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c);
        }
        Test.startTest();
        Database.executeBatch(new skedResourceSeniorityRankingBatch(territoryIds, skedResourceIds));
        Test.stopTest();

        List<sked__Resource__c> testResources = [
            SELECT Id, sked_Seniority_Rank__c 
            FROM sked__Resource__c 
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
        ];

        for (sked__Resource__c testResource : testResources) {
            System.assertEquals(null, testResource.sked_Seniority_Rank__c);
        }
    }

    @isTest
    static void skedResourceSeniorityRankingBatch_MatchingResources_Test() {
        List<sked__Resource__c> testResources = [
            SELECT Id, sked_Seniority_Rank__c 
            FROM sked__Resource__c 
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
        ];

        for (sked__Resource__c testResource : testResources) {
            testResource.sked_Hire_Date__c = System.today().addDays(-50);
        }
        update testResources;

        Test.startTest();
            Database.executeBatch(new skedResourceSeniorityRankingBatch());
        Test.stopTest();

        List<skedHC__Exception__c> exceptions = [SELECT Id FROM skedHC__Exception__c WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_RESOURCE_DUPLICATE_SENIORITY_RANKING];
        System.assert(!exceptions.isEmpty());
    }

    @isTest
    static void skedResourceSeniorityRankingBatch_InactiveResource_Test() {
        sked__Resource__c resource1 = [
            SELECT Id, sked_Employment_Status__c 
            FROM sked__Resource__c 
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            ORDER BY Name ASC
            LIMIT 1
        ][0];
        resource1.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE;
        update resource1;

        Test.startTest();
            Database.executeBatch(new skedResourceSeniorityRankingBatch(), 1);
        Test.stopTest();

        List<sked__Resource__c> testResources = [
            SELECT Id, Name, sked_Seniority_Rank__c
            FROM sked__Resource__c
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            ORDER BY sked_Seniority_Rank__c ASC
            LIMIT 2
        ];

        System.assert(testResources[0].sked_Seniority_Rank__c < testResources[1].sked_Seniority_Rank__c, 'resource1: ' + testResources[0].sked_Seniority_Rank__c + ', resource2: ' + testResources[1].sked_Seniority_Rank__c);
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource2 = (sked__Resource__c) mapTestData.get('testResource2');
        sked__Tag__c tag2RBC = [SELECT Id FROM sked__Tag__c WHERE Name = '2RBC' LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Territory__c testDistrict = (sked_Territory__c) mapTestData.get('testTerritory1');

        sked_Territory__c testArcRegion = new sked_Territory__c(
            Name = 'ARC Region',
            RecordTypeId = sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('sked_ARC_Region').getRecordTypeId()
        );
        insert testArcRegion;

        testDistrict.sked_Parent__c = testArcRegion.Id;
        testCollectionOp.sked_Territory__c = testDistrict.Id;
        update new List<SObject>{testDistrict, testCollectionOp};
    }
}