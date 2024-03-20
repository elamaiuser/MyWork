@isTest
private class skedPopulateStagingLocForDrives_Test {
    
    static testmethod void skedPopulateStagingLocForDrives_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        sked_Collection_Op_Staging_Location__c testCosl = (sked_Collection_Op_Staging_Location__c) mapTestData.get('testCollectionOpStagingLoc1');
        skedHubBase.setBypassAllTriggers(true);
        testCosl.sked_Start_Date__c = skedConstants.EARLIEST_START_DATE;
        testCosl.sked_End_Date__c = skedConstants.LATEST_END_DATE;
        update testCosl;
        
        testDrive1.sked_Staging_Location__c = NULL;
        update testDrive1;
        
        skedHubBase.setBypassAllTriggers(false);

        Test.startTest();
        
        Database.executeBatch(new skedPopulateStagingLocForDrivesBatch());
        
        Test.stopTest();
    }
    
}