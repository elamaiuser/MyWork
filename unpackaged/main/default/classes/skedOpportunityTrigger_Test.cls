@isTest
private class skedOpportunityTrigger_Test {

    static testmethod void testOpportunityTriggers() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        
        Test.startTest();
        
        List<Opportunity> opportunities = new List<Opportunity>();
        
        Opportunity testOpportunity1 = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = testDataFactory.summary.startDate.addDays(20),
            Drive_Site__c = testLocation1.Id,
            StageName = 'Solicitation',
            CloseDate = testDataFactory.summary.startDate,
            Online_Scheduling_Enabled__c = 'No',
            Accept_56_Day_Rule_Violation__c = true
        );
        opportunities.add(testOpportunity1);
        
        insert opportunities;
        
        List<sked_Drive__c> skedDrives = new List<sked_Drive__c>();
        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Date__c = testDataFactory.summary.startDate.addDays(20),
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = testOpportunity1.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 50
        );
        skedDrives.add(testDrive1);
        
        insert skedDrives;
        
        testOpportunity1.Drive_Date__c = testOpportunity1.Drive_Date__c.addDays(1);
        update testOpportunity1;
        
        Test.stopTest();
    }
    
}