@isTest(SeeAlldata = false)
private class skedEmailService_Test {
    
    @testSetup
    static void prepareTestData() {
        
		Folder testFolder = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];
        
        system.debug('testFolder '+testFolder);
        EmailTemplate testEmailTemplate = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template',
            TemplateType = 'text',
            Subject = 'Test Subject',
            Body = 'Hello {!Contact.FirstName}',
            FolderId = testFolder.Id,
            IsActive = true
        );
        insert testEmailTemplate;
    }

    static testMethod void sendEmailsTest() {
        Test.startTest();
        
        
        
        List<skedEmailService.emailModel> testEmailModels = new List<skedEmailService.emailModel>();
        skedEmailService.emailModel testEmailModel = new skedEmailService.emailModel();
        testEmailModel.htmlBody = 'Test Email';
        testEmailModel.subject = 'Test Subject';
        testEmailModel.toList = new List<String>{'priti.jana@redcross.org.invalid'};
        testEmailModel.templateApiName = 'Test_Template';
        testEmailModel.saveAsActivity = true;
        testEmailModel.fromAddress = 'bsfSupport@redcross.org.invalid';
        testEmailModels.add(testEmailModel);
        
        skedEmailService testInstance = new skedEmailService();
        testInstance.sendEmails(testEmailModels);
        
        Test.stopTest();
    }
}