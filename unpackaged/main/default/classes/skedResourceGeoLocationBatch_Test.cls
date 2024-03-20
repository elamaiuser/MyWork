@isTest
private class skedResourceGeoLocationBatch_Test {
    
    static testmethod void skedResourceGeoLocationBatch_Test() {
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID()
        );
        insert testRegion1;
        
        sked__Resource__c testResource1 = new sked__Resource__c(
            Name = 'Test Resource 1',
            sked__Primary_Region__c = testRegion1.Id,
            sked__Resource_Type__c = 'Person',
            sked__Employment_Type__c = 'Full-time',
            sked__Category__c = 'Employee',
            sked__Is_Active__c = TRUE,
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Test',
            sked_Last_Name__c = 'Resource 1',
            sked_ULID__c = 'ULID1',
            sked_Timezone__c = 'America/New_York',
            sked_Home_Address_1__c = 'Inner Parkside', 
            sked_Home_City__c = 'San Francisco', 
            sked_Home_State__c = 'CA', 
            sked_Home_Zip_Code__c = '94116',
            sked_Work_Address_1__c = 'Inner Parkside', 
            sked_Work_City__c = 'San Francisco', 
            sked_Work_State__c = 'CA', 
            sked_Work_Zip_Code__c = '94116'
        );
        skedHubBase.BypassInsertTriggers = true;
        insert testResource1;
        skedHubBase.BypassInsertTriggers = false;
        
        skedMocktest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Test.startTest();
        
        Database.executeBatch(new skedResourceGeoLocationBatch(new Set<Id>{testResource1.Id}));
        
        Test.stopTest();
    }
    
}