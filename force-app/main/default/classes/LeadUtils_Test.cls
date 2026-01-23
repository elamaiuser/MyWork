@isTest(SeeAllData = false)
private class LeadUtils_Test {
    
    @testSetup
    static void prepareTestData() {
        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();

        Taxonomy__c testTaxonomyRecord = new Taxonomy__c(
            Collection_Operation_Name__c = 'Test Collection Operation',
            Zip_Code__c = '94116',
            Start_Date__c = Date.newInstance(2023, 1, 1),
            End_Date__c = Date.newInstance(4000, 12, 31),
            recordTypeId = recordTypeId,
            City__c = 'Test City',
            State__c = 'Test State'
        );
        insert testTaxonomyRecord;
    }
    
    static testMethod void getCurrentlyValidTaxonomies_test() {
        Test.startTest();
        List<taxonomy__c> testValidTaxonomyList = LeadUtils.getCurrentlyValidTaxonomies('94116');
        Test.stopTest();
        
        Assert.isTrue(testValidTaxonomyList != null && !testValidTaxonomyList.isEmpty());
    }
}