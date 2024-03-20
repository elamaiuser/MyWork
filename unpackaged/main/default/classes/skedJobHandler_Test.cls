@isTest
private class skedJobHandler_Test {
    @isTest
    static void generateDriveTypeTag_FixedSite_WB_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Account testAccount = (Account) mapTestData.get('testAccount1');
        testAccount.Operation_Type__c = skedConstants.OPERATION_TYPE_WB;
        update testAccount;

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked_Drive__c fixedSiteTestDrive = testDrive.clone(false, false, false, false);
        fixedSiteTestDrive.sked_Type_Of_Drive__c = 'Fixed Site';


        Test.startTest();
            insert fixedSiteTestDrive;
        Test.stopTest();
    }

    @isTest
    static void generateDriveTypeTag_FixedSite_APH_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Account testAccount = (Account) mapTestData.get('testAccount1');
        testAccount.Operation_Type__c = skedConstants.OPERATION_TYPE_APH;
        update testAccount;

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked_Drive__c fixedSiteTestDrive = testDrive.clone(false, false, false, false);
        fixedSiteTestDrive.sked_Type_Of_Drive__c = 'Fixed Site';


        Test.startTest();
            insert fixedSiteTestDrive;
        Test.stopTest();
    }
}