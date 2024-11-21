@isTest
private class skedDriveChangeRequestItemHandler_Test {
    @isTest 
    private static void skedDriveChangeRequestItemHandler_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject>  mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');

        Test.startTest();

        sked__Location__c testSite2 = testSite.clone(false, false, false, false);
        insert testSite2;
        
        sked_Drive_Change_Request__c testDriveChangeRequest = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive.Id
        );
        insert testDriveChangeRequest;

        sked_Drive_Change_Request_Item__c testDriveChangeRequestItem = new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = testDriveChangeRequest.Id,
            sked_Old_Value__c = testSite.Id,
            sked_New_Value__c = testSite.Id,
            sked_Change_Reason__c = 'Test',
            sked_Field_API_Name__c = 'sked_Drive_Site__c',
            sked_Type__c = 'Change'
        );
        insert testDriveChangeRequestItem;
        
        testDriveChangeRequestItem.sked_New_Value__c = testSite2.Id;
        update testDriveChangeRequestItem;
        
        delete testDriveChangeRequestItem;
        
        Test.stopTest();
    }
    
}