@isTest
private class skedBiomedCollectionOpHandler_Test {
    @isTest
    static void createQueues_Test() {
        Set<String> queueNames = new Set<String>{'test collection op'};
        Test.startTest();
            skedBiomedCollectionOpHandler.call('createQueues', new Map<String, Object>{'param1' => JSON.serialize(queueNames)});
        Test.stopTest();

        List<Group> collectionOpQueues = [SELECT Id, Name FROM Group WHERE NAME LIKE '%test collection op%'];
        System.assert(!collectionOpQueues.isEmpty());
    }

    @isTest
    static void deleteQueues_Test() {
        String testCo = 'test collection op';
        insert new Group(
            name = testCo,
            type = skedConstants.GROUP_TYPE_QUEUE
        );

        Set<String> queueNames = new Set<String>{testCo};
        test.startTest();
            skedBiomedCollectionOpHandler.call('deleteQueues', new Map<String, Object>{'param1' => JSON.serialize(queueNames)});
        test.stopTest();

        List<Group> testCoGroups = [SELECT Id, Name FROM Group WHERE Name LIKE :testCo];
        System.assertEquals(0, testCoGroups.size());
    }

    @isTest
    static void captureJobIMPACTChanges_Test() {
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;

        Test.startTest();
            testCollectionOperation1.sked_IMPACT_Start_Date__c = System.today();
            testCollectionOperation1.sked_IMPACT_End_Date__c = System.today().addYears(1);
            update testCollectionOperation1;
        Test.stopTest();
    }

    @isTest
    static void getCollectionOpNames_Test() {
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1'
        );

        Set<String> coNames = skedBiomedCollectionOpHandler.getCollectionOpNames(
            new List<Biomed_Collection_Op_Center__c>{testCollectionOperation1}, true);
    }

    @isTest
    static void validate_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');

        Boolean caughtException = false;
        Test.startTest();
            try {
                testCollectionOp.sked_Is_Deactivated__c = true;
                update testCollectionOp;
            } catch (Exception ex) {
                caughtException = true;
            }
        Test.stopTest();

        System.assertEquals(true, caughtException);
    }

    @isTest
    static void captureWeightLevelValueChanges_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_CollectionOperationOptimizerSetting__c setting = new sked_CollectionOperationOptimizerSetting__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Constraint__c = 'Account/Site Preferences',
            sked_Constraint_Type__c = 'Soft Constraint',
            sked_Default_Weight__c = 'High',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Enabled__c = false,
            sked_Display_Type__c = 'Picklist'
        );
        insert setting;

        Test.startTest();

        testCollectionOp.sked_High_Weight__c = 20;
        update testCollectionOp;

        Test.stopTest();

        setting = [SELECT sked_Optimizer_Mapped_Weight__c FROM sked_CollectionOperationOptimizerSetting__c WHERE Id = :setting.Id];
        System.assertEquals('20soft', setting.sked_Optimizer_Mapped_Weight__c);
    }
}