@isTest
public class BatchAcctsMilitaryMoAUploadedFiles_Test {
    @TestSetup
    static void setupTestData() {
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        Account acc = new Account(
            name = 'Test Account 1',
        	RecordTypeId = mobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
        insert acc;

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            Description = 'Military MoA - Local'
        );
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
    
        User accountManager = new User(
            ProfileId = p.Id,
            LastName = 'Account Manager',
            Email = 'test1@test.com',
            Username = 'test1@test.com' + System.currentTimeMillis(),
            Alias = 'test1',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles'
        );
        insert accountManager;

        AccountTeamMember atm = new AccountTeamMember(
        AccountId = acc.Id,
        UserId = accountManager.Id,
        TeamMemberRole = 'Account Manager',
        Start_Date__c = Date.today().addDays(-10),
        End_Date__c = Date.today().addDays(90)
    );
    insert atm;
    }    

    @isTest
    static void testBatchWithOldFiles() {
        // Update ContentVersion LastModifiedDate to be old
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        Test.setCreatedDate(cv.Id, DateTime.now().addDays(-336));
        
        Test.startTest();
        BatchAccountsMilitaryMoAUploadedFiles batch = new BatchAccountsMilitaryMoAUploadedFiles();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify task creation
        List<Task> tasks = [SELECT Id, WhatId, Description FROM Task WHERE Subject = 'Renew Military MoA'];
        System.assertEquals(1, tasks.size(), 'One task should be created');
        
        // Verify debug log creation
        List<BSF_Error_Log__c> logs = [SELECT Id FROM BSF_Error_Log__c WHERE ApexClass__c = 'BatchAccountsMilitaryMoAUploadedFiles'];
        System.assertEquals(1, logs.size(), 'One debug log should be created');        
    }    
}