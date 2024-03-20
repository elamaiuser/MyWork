@isTest
private class skedResourceRoleMaintenanceBatch_Test {
    @isTest
    static void skedResourceRoleMaintenanceBatch_Test() {
        Test.startTest();
            Database.executeBatch(new skedResourceRoleMaintenanceBatch());
        Test.stopTest();
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Tag__c testRoleTag = [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 1][0];

        sked__Resource_Tag__c testResourceTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = testRoleTag.Id,
            sked_Expiry_Date__c = system.today().addYears(-1),
            sked_Start_Date__c = system.today().addYears(-2),
            sked_Role_Status__c = 'Active'
        );
        insert testResourceTag;
    }
}