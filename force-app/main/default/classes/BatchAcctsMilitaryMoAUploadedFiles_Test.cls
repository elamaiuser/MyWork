@isTest
public class BatchAcctsMilitaryMoAUploadedFiles_Test {
    @TestSetup
    static void setupTestData() {
        // Create Record Types for Accounts and Sites
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE).getRecordTypeId();
        Id siteRecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get(BSF_Constants.MOBILE_SITE_RECORD_TYPE).getRecordTypeId();

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
        // Create Test Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 1; i <= 3; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                RecordTypeId = accountRecordTypeId,
                Account_Manager__c = accountManager.id // Assigning current user as Account Manager
            ));
        }
        insert accounts;

        // Create Test Sites (sked__Location__c)
        List<sked__Location__c> sites = new List<sked__Location__c>();
        for (Integer i = 1; i <= 2; i++) {
            sites.add(new sked__Location__c(
                Name = 'Test Site ' + i,
                Source__c = 'Custom New Form',
                sked_Physical_Location_Type__c='Inside',
                sked_Room_Name__c='Main Area',
                sked_Site_Building_Name__c='Osawatomie Memorial Hall',
                RecordTypeId = siteRecordTypeId,
                OwnerId = UserInfo.getUserId()
            ));
        }
        insert sites;

        // Create Site - Account Relationship (sked_Location_Account__c)
        List<sked_Location_Account__c> siteAccountLinks = new List<sked_Location_Account__c>();
        for (sked__Location__c site : sites) {
            for (Account acc : accounts) {
                siteAccountLinks.add(new sked_Location_Account__c(
                    sked_Location__c = site.Id,
                    sked_Account__c = acc.Id
                ));
            }
        }
        insert siteAccountLinks;

        // Create Mock Files (ContentVersion)
        List<ContentVersion> files = new List<ContentVersion>();
        for (Account acc : accounts) {
            files.add(new ContentVersion(
                Title = 'Account Document ' + acc.Name,
                PathOnClient = 'TestDoc.pdf',
                VersionData = Blob.valueOf('Sample Content'),
                Description = 'Weapons Policy',
                Expiry_Date__c = Date.today().addDays(20)
            ));
        }

        for (sked__Location__c site : sites) {
            files.add(new ContentVersion(
                Title = 'Site Document ' + site.Name,
                PathOnClient = 'TestDoc.pdf',
                VersionData = Blob.valueOf('Sample Content'),
                Description = 'Weapons Policy',
                Expiry_Date__c = Date.today().addDays(20)
            ));
        }
        insert files;

        // Link Files to Accounts
        List<ContentDocumentLink> fileLinks = new List<ContentDocumentLink>();
        for (ContentVersion file : [SELECT ContentDocumentId FROM ContentVersion where Title LIKE 'Account Document%' ]) {
            for (Account acc : accounts) {
                fileLinks.add(new ContentDocumentLink(
                    LinkedEntityId = acc.Id,
                    ContentDocumentId = file.ContentDocumentId,
                    ShareType = 'I'
                ));
            }
        }
        for (ContentVersion file : [SELECT ContentDocumentId FROM ContentVersion where Title LIKE 'Site Document%' ]) {
            for (sked__Location__c site : sites) {
                fileLinks.add(new ContentDocumentLink(
                    LinkedEntityId = site.Id,
                    ContentDocumentId = file.ContentDocumentId,
                    ShareType = 'I'
                ));
            }
        }
        insert fileLinks;
        
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = accounts[0].Id,
            UserId = accountManager.Id,
            TeamMemberRole = 'Account Manager',
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(90)
        );
        insert atm;
    }    

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        // Run the batch
        BatchAccountsMilitaryMoAUploadedFiles batch = new BatchAccountsMilitaryMoAUploadedFiles();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        // Assertions to verify correct Task creation
        List<Task> createdTasks = [SELECT Id, Subject, WhatId, OwnerId FROM Task];
        System.assertNotEquals(0, createdTasks.size(), 'Tasks should have been created');
    }  
}