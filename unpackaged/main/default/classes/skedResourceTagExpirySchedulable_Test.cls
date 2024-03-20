@isTest
private class skedResourceTagExpirySchedulable_Test {
    @isTest
    static void skedResourceTagExpirySchedulable_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        testResource1.sked_Supervisor_Email__c = 'testemail@test.com';
        update testResource1;
        
        sked__Tag__c testRoleTag = [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 1][0];

        sked__Resource_Tag__c testResourceTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource1.Id,
            sked__Tag__c = testRoleTag.Id,
            sked_Expiry_Date__c = System.today().addDays(skedSetting.instance.admin.tagExpiryAlertDays),
            sked_Start_Date__c = System.today().addYears(-2),
            sked_Role_Status__c = 'Active'
        );

        insert testResourceTag;

        Test.startTest();
            String chron = '0 0 23 * * ?'; 
            System.schedule('Test schedulable' + Math.random(), chron, new skedResourceTagExpirySchedulable());
        Test.stopTest();
    }
    
}