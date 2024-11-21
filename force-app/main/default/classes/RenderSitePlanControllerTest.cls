@isTest
private class RenderSitePlanControllerTest {

    @testSetup
    static void makeData(){
        Test.startTest();
        AzureSitePlanCredentials__c cred = new AzureSitePlanCredentials__c();
        cred.Name = 'Site plan';
        cred.EndPoint__c = 'https://siteplanrest.azurewebsites.net/api/GetSitePlan';
        cred.Key__c = 'testkey';
        insert cred;
        Test.stopTest();
    }

    @isTest static void getImageTestSuccess() {
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String img = RenderSitePlanController.getImage('0068I000002pBodQAE');
        Test.stopTest();
        System.assertEquals('test', img);
    }

    @isTest static void getOperationTemplateIdSuccess() {
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity template = new Opportunity();
        template.Name = 'Template';
        template.StageName = 'Discovery';
        template.CloseDate = Date.today();
        template.Is_Template__c = true;
        template.AccountId = acc.Id;
        template.Data_Source__c = 'BSFApplication';
        insert template;

        Opportunity driveOpp = new Opportunity();
        driveOpp.Name = 'Drive Opportunity';
        driveOpp.StageName = 'Discovery';
        driveOpp.CloseDate = Date.today();
        driveOpp.Parent_Template_Id__c = template.Id;
        driveOpp.AccountId = acc.Id;
        driveOpp.Data_Source__c = 'BSFApplication';
        insert driveOpp;

        sked_Drive__c drive  = new sked_Drive__c();
        drive.sked_Opportunity__c = driveOpp.Id;
        insert drive;

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c();
        driveShift.sked_Drive__c = drive.Id;
        insert driveShift;

        sked_Operation_Record__c opr = new sked_Operation_Record__c();
        opr.sked_Drive__c = drive.Id;
        opr.sked_Drive_Shift__c = driveShift.Id;
        insert opr;

        Test.stopTest();
        String response = RenderSitePlanController.getOperationTemplateId(opr.Id);
        System.assertEquals(template.Id, response);
    }

    @isTest static void getOperationTemplateIdNull() {
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity driveOpp = new Opportunity();
        driveOpp.Name = 'Drive Opportunity';
        driveOpp.StageName = 'Discovery';
        driveOpp.CloseDate = Date.today();
        driveOpp.AccountId = acc.Id;
        driveOpp.Data_Source__c = 'BSFApplication';
        insert driveOpp;

        sked_Drive__c drive  = new sked_Drive__c();
        drive.sked_Opportunity__c = driveOpp.Id;
        insert drive;

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c();
        driveShift.sked_Drive__c = drive.Id;
        insert driveShift;

        sked_Operation_Record__c opr = new sked_Operation_Record__c();
        opr.sked_Drive__c = drive.Id;
        opr.sked_Drive_Shift__c = driveShift.Id;
        insert opr;

        Test.stopTest();
        String response = RenderSitePlanController.getOperationTemplateId(opr.Id);
        System.assertEquals(null, response);
    }
}