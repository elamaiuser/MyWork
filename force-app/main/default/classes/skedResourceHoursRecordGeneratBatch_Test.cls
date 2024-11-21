@isTest
private class skedResourceHoursRecordGeneratBatch_Test {
    static testmethod void testBatch() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 14);
        factory.setupCommonTestData();
        Test.startTest();
        new skedResourceHoursRecordGenerateBatch().execute(null);
        Test.stopTest();
        Integer createdResourceHoursRecordCount = [SELECT COUNT() FROM sked_Resource_Hours_Record__c];
        System.assertEquals(2, createdResourceHoursRecordCount);
        Integer createdResourceExceptionLogCount = [SELECT COUNT() FROM skedHC__Exception__c WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION];
        System.assertEquals(2, createdResourceExceptionLogCount);
    }
}