@isTest
private class skedRoleTimeVariance_Test {

    static testmethod void testException() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        Test.startTest();
        
        sked_Role_Time_Variance__c roleTimeVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add',
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
        	sked_Location__c = testLocation1.Id,
            sked_Variance_Applies_to__c = 'Lead Time',
            sked_Variation_Amount__c = 15,
            sked_Variation_Type__c = 'Elevator',
            sked_Resource_Role_Group__c = 'Driving roles'
        );
        insert roleTimeVariance;
        
        roleTimeVariance.sked_Variation_Amount__c = 30;
        update roleTimeVariance;
        
        delete roleTimeVariance;
        
        Test.stopTest();
    }
    
}