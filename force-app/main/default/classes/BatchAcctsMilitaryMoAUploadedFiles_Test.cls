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
        List<Task> tasks = [SELECT Id, WhatId, Description FROM Task];
        System.assertEquals(1, tasks.size(), 'One task should be created');
        
        // Verify debug log creation
        List<BSF_Error_Log__c> logs = [SELECT Id FROM BSF_Error_Log__c];
        System.assertEquals(2, logs.size(), 'Two debug log should be created');        
    }    
}