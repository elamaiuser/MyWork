@isTest
private class skedRoleTimeDetailTrigger_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        Test.startTest();
        
        sked_Role_Time_Detail__c roleTimeDetail = new sked_Role_Time_Detail__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Effective_End_Date__c = System.today().addDays(10),
            sked_Breakdown_Time__c = 25,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Drive_Type__c = testDrive.sked_Type_of_Drive__c,
            sked_Lead_Time__c = 15,
            sked_Setup_Time__c = 15,
            sked_Wrap_up_Time__c = 15,
            sked_Mobile_Type__c = 'Inside/Outside',
            sked_Resource_Role_Group__c = 'Driving roles;Supervisory roles;Staff roles'
        );
        insert roleTimeDetail;
        
        roleTimeDetail.sked_Lead_Time__c = 30;
        update roleTimeDetail;
        
        delete roleTimeDetail;
        
        Test.stopTest();
    }
    
}