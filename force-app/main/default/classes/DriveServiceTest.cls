@isTest
private class DriveServiceTest {
    @testSetup static void prepareTestData() {
        TriggerHandler.bypass('DriveTriggerHandler');
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Account testAccount = (Account)mapTestData.get('testAccount1');
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Test' LIMIT 1];
        
        //create account service roles
        Account_Service_Role__c testAccServiceRole = new Account_Service_Role__c(
            Account_Service_Role__c = 'Blood Program Leader',
            Account__c = testAccount.Id,
            Contact__c = testContact.id
        );
        insert testAccServiceRole;
    }
    
    @isTest static void retrieveDrivesTest() {
        Test.startTest();
        
        Period period = [SELECT Id,StartDate,EndDate FROM Period WHERE (StartDate < :system.today() AND EndDate > :system.today()) LIMIT 1]; 
        
        List<DriveService.Drive> testDrivesList1 = DriveService.retrieveDrives(period.Id, 1);
        Test.stopTest();
        
        Assert.isTrue(testDrivesList1 != null && !testDrivesList1.isEmpty());
    }
    
    @isTest static void retrievePriorDrivesTest() {  
        Test.startTest();
        
        Opportunity testOpp = [SELECT Id, CloseDate FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update new Opportunity(Id = testOpp.Id, CloseDate = system.today().addDays(-10));       
        TriggerHandler.clearAllBypasses();
        
        Period period = [SELECT Id,StartDate,EndDate FROM Period WHERE (StartDate < :system.today() AND EndDate > :system.today()) LIMIT 1];  
       
        List<DriveService.Drive> testDrives = DriveService.retrievePriorDrives(period.Id, 1);
        Test.stopTest();
        
        Assert.isTrue(testDrives != null && !testDrives.isEmpty());
    }
    
    @isTest static void retrieveProspectDrivesTest() {  
        Test.startTest();
        
        Opportunity testOpp = [SELECT Id, CloseDate FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update new Opportunity(Id = testOpp.Id, CloseDate = system.today().addYears(-1));       
        TriggerHandler.clearAllBypasses();
        
        Period period = [SELECT Id,StartDate,EndDate FROM Period WHERE (StartDate < :system.today() AND EndDate > :system.today()) LIMIT 1];  
       
        List<DriveService.Drive> testDrives = DriveService.retrieveProspectDrives(period.Id, null);
        Test.stopTest();
        
        Assert.isTrue(testDrives != null && !testDrives.isEmpty());
    }
    
    @isTest static void retrieveDriveTest() {  
        Test.startTest(); 
        Opportunity testOpp = [SELECT Id, CloseDate FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        DriveService.Drive testDrive = DriveService.retrieveDrive(testOpp.Id);
        Test.stopTest();
        
        Assert.isTrue(testDrive != null);
    }
    
    @isTest static void populateDriveWorksheetDataTest() {
        Test.startTest();
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Opportunity testOpp = [SELECT Id, CloseDate FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        sked_Drive__c testDrive = [SELECT Id, sked_Opportunity__c, sked_Primary_Contact__c FROM sked_Drive__c LIMIT 1];
        
        List<OpportunityContactRole> testOppContactRoles = new List<OpportunityContactRole>();
        for(String role : new List<String>{'Whom to Meet', 'Primary Contact'}) {
            testOppContactRoles.add(new OpportunityContactRole(
                OpportunityId = testOpp.Id,
                ContactId = testContact.id,
                Role = role
            ));
        }
        TriggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        insert testOppContactRoles;    
        TriggerHandler.clearBypass('OpportunityContactRoleTriggerHandler');
       
        DriveService.populateDriveWorksheetData(new List<sked_Drive__c>{testDrive});
        
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
        Test.stopTest();
    }   
    
     @isTest static void populateDriveWorksheetNullDriveTest() {     
        Test.startTest();
        DriveService.populateDriveWorksheetData(null);
        Test.stopTest();
    }
}