@isTest
private class skedResourceCollectionOpHandler_Test {
    @isTest
    static void createResourceRegions_Test() {
        Test.startTest();
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testOpCenter = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];

        sked_Resource_Biomed_Collection_Op__c testResourceCollectionOp = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c = testResource.Id,
            sked_Biomed_Collection_Op_Center__c = testOpCenter.Id,
            sked_Start_Date__c = System.today(),
            Sked_End_Date__c = System.today().addDays(100)
        );

        insert testResourceCollectionOp;
        Test.stopTest();

        sked__Resource_Region__c testResourceRegion = [SELECT Id FROM sked__Resource_Region__c LIMIT 1][0];
        System.assertNotEquals(null, testResourceRegion);
    }

    @isTest
    static void updateResourceRegions_Test() {
        Test.startTest();
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testOpCenter = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];

        sked_Resource_Biomed_Collection_Op__c testResourceCollectionOp = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c = testResource.Id,
            sked_Biomed_Collection_Op_Center__c = testOpCenter.Id,
            sked_Start_Date__c = System.today(),
            Sked_End_Date__c = System.today().addDays(100)
        );
        insert testResourceCollectionOp;
        
        Date newEndDate = System.today().addDays(1000);
        testResourceCollectionOp.sked_End_Date__c = newEndDate;
        update testResourceCollectionOp; 
        Test.stopTest();


        sked__Resource_Region__c testResourceRegion = [SELECT Id, sked__End__c FROM sked__Resource_Region__c LIMIT 1][0];
        System.assertEquals(skedDateTimeUtils.newDateTimeInstance(newEndDate, 0, UserInfo.getTimeZone().getID()), testResourceRegion.sked__End__c);
    }

    @isTest
    static void deleteResourceRegions_Test() {
        Test.startTest();
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testOpCenter = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];

        sked_Resource_Biomed_Collection_Op__c testResourceCollectionOp = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c = testResource.Id,
            sked_Biomed_Collection_Op_Center__c = testOpCenter.Id,
            sked_Start_Date__c = System.today(),
            Sked_End_Date__c = System.today().addDays(100)
        );
        insert testResourceCollectionOp;
        delete testResourceCollectionOp;
        Test.stopTest();

        List<sked__Resource_Region__c> testResourceRegions = [SELECT Id FROM sked__Resource_Region__c];
        System.assertEquals(0, testResourceRegions.size());
    }
    

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        delete [SELECT Id FROM sked__Resource_Region__c];
    }
}