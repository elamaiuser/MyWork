@isTest
private class skedCOOptimizerSettingUtils_Test {
    
    @isTest
    private static void testPopulateOptimizerMappedWeight() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp2 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation2');
        Map<Id, Biomed_Collection_Op_Center__c> collectionOperationMap = new Map<Id, Biomed_Collection_Op_Center__c> {
            testCollectionOp2.Id => testCollectionOp2
        };
        sked_CollectionOperationOptimizerSetting__c setting1 = new sked_CollectionOperationOptimizerSetting__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Constraint__c = 'Account/Site Preferences',
            sked_Constraint_Type__c = 'Soft Constraint',
            sked_Default_Weight__c = 'High',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Enabled__c = false,
            sked_Display_Type__c = 'Picklist'
        );
        sked_CollectionOperationOptimizerSetting__c setting2 = new sked_CollectionOperationOptimizerSetting__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Constraint__c = 'Geographic Preferences',
            sked_Constraint_Type__c = 'Hard Constraint',
            sked_Default_Weight__c = 'Medium',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Enabled__c = false,
            sked_Display_Type__c = 'Picklist'
        );
        sked_CollectionOperationOptimizerSetting__c setting3 = new sked_CollectionOperationOptimizerSetting__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Constraint__c = 'Hire Date',
            sked_Constraint_Type__c = 'Soft Constraint',
            sked_Default_Weight__c = 'Low',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Enabled__c = false,
            sked_Display_Type__c = 'Picklist'
        );
        sked_CollectionOperationOptimizerSetting__c setting4 = new sked_CollectionOperationOptimizerSetting__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Constraint__c = 'Role Priorities',
            sked_Constraint_Type__c = 'Soft Constraint',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Enabled__c = true,
            sked_Display_Type__c = 'Checkbox'
        );
        List<sked_CollectionOperationOptimizerSetting__c> settings = new List<sked_CollectionOperationOptimizerSetting__c> {setting1, setting2, setting3, setting4};

        skedCollectionOpOptimizerSettingUtils.populateOptimizerMappedWeight(settings, collectionOperationMap);

        System.assertEquals('25soft', setting1.sked_Optimizer_Mapped_Weight__c);
        System.assertEquals('15hard', setting2.sked_Optimizer_Mapped_Weight__c);
        System.assertEquals('10soft', setting3.sked_Optimizer_Mapped_Weight__c);
        System.assertEquals('10soft', setting4.sked_Optimizer_Mapped_Weight__c);
    }
}