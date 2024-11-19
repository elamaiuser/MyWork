@isTest
private class skedCOOptimizerSettingTrigger_Test {
    
    @isTest
    static void testBeforeInsert() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');

        Test.startTest();
        sked_CollectionOperationOptimizerSetting__c setting = new sked_CollectionOperationOptimizerSetting__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Constraint__c = 'Account/Site Preferences',
            sked_Constraint_Type__c = 'Soft Constraint',
            sked_Default_Weight__c = 'High',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Enabled__c = false,
            sked_Display_Type__c = 'Picklist'
        );
        insert setting;

        Test.stopTest();

        setting = [SELECT sked_Optimizer_Mapped_Weight__c FROM sked_CollectionOperationOptimizerSetting__c WHERE Id = :setting.Id];
        System.assertEquals('25soft', setting.sked_Optimizer_Mapped_Weight__c);
    }

    @isTest
    static void testBeforeUpdate() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');
        sked_CollectionOperationOptimizerSetting__c setting = new sked_CollectionOperationOptimizerSetting__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Constraint__c = 'Account/Site Preferences',
            sked_Constraint_Type__c = 'Soft Constraint',
            sked_Default_Weight__c = 'High',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Enabled__c = false,
            sked_Display_Type__c = 'Picklist'
        );
        insert setting;

        Test.startTest();
        
        setting.sked_Constraint_Type__c = 'Hard Constraint';
        setting.sked_Default_Weight__c = 'Medium';
        update setting;

        Test.stopTest();
        setting = [SELECT sked_Optimizer_Mapped_Weight__c FROM sked_CollectionOperationOptimizerSetting__c WHERE Id = :setting.Id];
        System.assertEquals('15hard', setting.sked_Optimizer_Mapped_Weight__c);
    }
}