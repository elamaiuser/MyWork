@isTest
private class RenderSitePlanControllerTest {

    @testSetup
    static void makeData() {
        AzureSitePlanCredentials__c cred = new AzureSitePlanCredentials__c();
        cred.Name = 'Site plan';
        cred.EndPoint__c = 'https://siteplanrest.azurewebsites.net/api/GetSitePlan';
        cred.Key__c = 'testkey';
        insert cred;
        
        TriggerHandler.bypass('DriveTriggerHandler');
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
    }

    @isTest static void getImageTestSuccess_test() {
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String img = RenderSitePlanController.getImage('0068I000002pBodQAE');
        Test.stopTest();
        
        Assert.isTrue('test' == img);
    }

    @isTest static void getOperationTemplateIdSuccess_test() {
        Test.startTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        
        Opportunity opp = [SELECT Id, Parent_Template_Id__c, AccountId, Drive_Site__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
		Opportunity testTemplate = new Opportunity(
            Name = 'Test Template',
            Is_Template__c = true,
            StageName = 'Discovery',
            CloseDate = system.today(),
            AccountId = opp.AccountId,
            Drive_Site__c = opp.Drive_Site__c
        );
        insert testTemplate;

        opp.Parent_Template_Id__c = testTemplate.Id;
        update opp;
      
        sked_Drive__c drive = [SELECT Id FROM sked_Drive__c LIMIT 1];
        
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c();
        driveShift.sked_Drive__c = drive.Id;
        insert driveShift;

        sked_Operation_Record__c opr = new sked_Operation_Record__c();
        opr.sked_Drive__c = drive.Id;
        opr.sked_Drive_Shift__c = driveShift.Id;
        insert opr;

        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        String response = RenderSitePlanController.getOperationTemplateId(opr.Id);
        Assert.isTrue(response == [SELECT Id FROM Opportunity WHERE Is_Template__c = true].Id);
    }

    @isTest static void getOperationTemplateIdNull_test() {
        Test.startTest();
        
        sked_Drive__c drive = [SELECT Id FROM sked_Drive__c LIMIT 1];

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c();
        driveShift.sked_Drive__c = drive.Id;
        insert driveShift;

        sked_Operation_Record__c opr = new sked_Operation_Record__c();
        opr.sked_Drive__c = drive.Id;
        opr.sked_Drive_Shift__c = driveShift.Id;
        insert opr;

        Test.stopTest();
        String response = RenderSitePlanController.getOperationTemplateId(opr.Id);
        Assert.isTrue(response == null);
    }
}