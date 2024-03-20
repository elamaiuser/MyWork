@isTest
private class skedResourceRoleGroupHandler_Test {
    @isTest
    static void validate_Test() {
        delete [SELECT Id from sked_Resource_Role_Group__c];

        Test.startTest();
            sked_Resource_Role_Group__c testResourceRoleGroup = new sked_Resource_Role_Group__c(
                sked_Resource_Role_Group__c = 'Driving roles',
                sked_Resource_Roles__c = 'Driver Tech Trainee'
            );
            insert testResourceRoleGroup;
        Test.stopTest();

        List<sked_Resource_Role_Group__c> testResourceRoleGroups = [SELECT Id FROM sked_Resource_Role_Group__c];
        System.assertEquals(1, testResourceRoleGroups.size());
    }

    @isTest
    static void validate_Invalid_Test() {
        List<sked_Resource_Role_Group__c> testResourceRoleGroups = [
            SELECT Id, sked_Resource_Roles__c
            FROM sked_Resource_Role_Group__c
            WHERE sked_Resource_Role_Group__c != 'Driving roles'
        ];

        // Set it to the value for Driving Roles
        for (sked_Resource_Role_Group__c testResourceRoleGroup : testResourceRoleGroups) {
            testResourceRoleGroup.sked_Resource_Roles__c = 'Competent Driver; Driver; Driver CDL B; Driver Support; Driver Tech Trainee; Staff Shuttle';
        }

        Boolean exceptionCaught = false;
        try {
            Test.startTest();
                update testResourceRoleGroups;
            Test.stopTest();
        } catch (Exception ex) {
            exceptionCaught = true;
        }

        System.assert(exceptionCaught);
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}