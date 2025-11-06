/* The following test class covers the below mentioned classes and Trigger(s)
	DriveMarketingProgramTriggerService (98%)
	DriveMarketingProgramTriggerHandler (100%)
	DriveMarketingProgramTrigger (100%)
*/

@isTest
private class DriveMarketingProgramTriggerService_Test {
    
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        // insert Order 
		Order testOrder = new Order(
            name='Test Order',
			AccountId= testMobileAccount.Id,
			OpportunityId = testMobileOpp.Id,
			Material_Recipient_Type__c = 'Same',
			Material_Recipient__c = 'Account Manager',
			EffectiveDate = system.today(),
			status = 'draft'
        );
        insert testOrder;
        
        //insert Affiliations
        List<Marketing_Program__c> testAffiliations = new List<Marketing_Program__c>();
        Marketing_Program__c testAffiliation;
        testAffiliation = (Marketing_Program__c)mapTestData.get('AFFILIATION');
        testAffiliations.add(testAffiliation);
        
        testAffiliation = new Marketing_Program__c(
        	Name = 'Pint Sized Hero',
            External_Name__c = 'Pint Sized Hero',
            Scope__c = 'Drive'
        );
        testAffiliations.add(testAffiliation);
        insert testAffiliations;
        
        //insert Drive Affiliations
        List<Drive_Marketing_Programs__c> testDriveAffiliations = new List<Drive_Marketing_Programs__c>();
        for(Integer i = 0; i < testAffiliations.size(); i++) {
            testDriveAffiliations.add(new Drive_Marketing_Programs__c(
            	Blood_Drive_Opportunity__c = testMobileOpp.Id,
                Marketing_Program__c = testAffiliations[i].Id
            ));
        }
        insert testDriveAffiliations;
        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void test_syncSpecialAffiliationsUponUpdate() {
        List<sObject> testSObjects = new List<sObject>();
        List<Drive_Marketing_Programs__c> testDriveAffiliations = new List<Drive_Marketing_Programs__c>();
        Opportunity testMobileOpp = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        
        for(String affiliation : BSF_Utilities.getActivePicklistValues('Opportunity', 'Special_Affiliations__c')) {
            if(affiliation.equalsIgnoreCase('Battle of the Badges')) continue;
            testSObjects.add(new Marketing_Program__c(
            	Name = affiliation,
                External_Name__c = affiliation,
                Scope__c = 'Drive;Template',
                RecordTypeId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByDeveloperName().get('Marketing_Program').getRecordTypeId()
            ));
        }
        insert testSObjects;
        
        for(sObject testAffiliation : testSObjects) {
            testDriveAffiliations.add(new Drive_Marketing_Programs__c(
            	Blood_Drive_Opportunity__c = testMobileOpp.Id,
                Marketing_Program__c = testAffiliation.Id
            ));
        }
        insert testDriveAffiliations;
        
        Test.startTest();
        
        testSObjects.clear();
        for(Integer i = 0; i < testDriveAffiliations.size() - 2; i++) {
            Drive_Marketing_Programs__c testDriveAffiliationToUpdate = testDriveAffiliations[i];
            testDriveAffiliationToUpdate.Date_Removed__c = System.Today();
            testSObjects.add(testDriveAffiliationToUpdate);
        }
        update testSObjects;
        
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, Special_Affiliations__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        
        Assert.isTrue((updatedOpp.Special_Affiliations__c?.split(';') ?? new List<String>()).size() != testDriveAffiliations.size());
    }
    
    static testMethod void test_syncSpecialAffiliationsUponDelete() {
        Test.startTest();
        
        List<Drive_Marketing_Programs__c> testDriveAffiliations = [SELECT Id FROM Drive_Marketing_Programs__c];
        delete testDriveAffiliations;
        
        Test.stopTest();
        Opportunity testMobileOpp = [SELECT Id, Special_Affiliations__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        Assert.isTrue(String.isBlank(testMobileOpp.Special_Affiliations__c));
    }
        
 }