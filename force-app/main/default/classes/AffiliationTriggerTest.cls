/*
 * This Test class covering the following Trigger
 * AffiliationTrigger, ARCMarketMappingService, ARCMarketMappingTriggerHandler
*/

@isTest
private class AffiliationTriggerTest {
    
    @testSetup 
    static void prepareDataset() {
 		skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
        
        //insert DRD User
        User testDRDUser = (User)mapTestData.get('DRD_USER');
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDRDUser;
        }
        
        //insert Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
		
        // prepare ARC Market Mapping Data
        List<ARC_Market_Mapping__c> mmapList = new List<ARC_Market_Mapping__c>();
        ARC_Market_Mapping__c mmap ;

        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30146';
        mmap.Market__c = 'Marietta GA FS';
        mmapList.add(mmap);
        
        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30147';
        mmap.Market__c = 'Stone Mountain';
        mmapList.add(mmap); 
        
        mmap = new ARC_Market_Mapping__c();
		mmap.Zip_Code__c = '30622';
		mmap.Market__c = 'Alpharetta';
		mmapList.add(mmap); 
        
        insert mmapList; 
        
        // insert affiliations
        List<sObject> testSobjectList = new List<sObject>();
        testSobjectList.add(new Marketing_Program__c(
            Name = 'Test',
            External_Name__c = 'TEST',
            Scope__c = 'Account',
            End_Date__c = system.today().addDays(3)
        ));
        
        testSobjectList.add(new Marketing_Program__c(
            Name = 'Test1',
            External_Name__c = 'TEST1',
            Scope__c = 'Drive',
            End_Date__c = system.today().addDays(4)
        ));
        insert testSobjectList;
      
        Account_Marketing_Program__c testAccountAffiliation = new Account_Marketing_Program__c(
            Marketing_Program__c = testSobjectList[0].Id,
            Account_Affiliation_External_Key__c = 'Test_123',
            Account__c = testMobileAccount.Id
        );
                            
        Drive_Marketing_Programs__c testDriveAffiliation = new Drive_Marketing_Programs__c(
            Marketing_Program__c = testSobjectList[1].Id,
            Blood_Drive_Opportunity__c = testMobileOpp.Id
        );
        
        testSobjectList.clear();
        testSobjectList.add(testAccountAffiliation);
        testSobjectList.add(testDriveAffiliation);
        insert testSobjectList;                    
    }

    @isTest static void updateAccountMarketField() {
        Test.startTest();
        TriggerHandler.bypass('AccountAffiliationTriggerHandler');
        TriggerHandler.bypass('DriveMarketingProgramTriggerHandler');
        
        User testUser = [SELECT Id FROM User LIMIT 1];

        System.runAs(testUser) {
        	AffiliationService.populateEndDateInAccountAffiliation([SELECT Id FROM Marketing_Program__c], 'Update');

            List<ARC_Market_Mapping__c> ammap = new List<ARC_Market_Mapping__c>();
            ammap = [select Zip_Code__c,  Market__c from ARC_Market_Mapping__c where Zip_Code__c = '30622' ] ;
            ammap[0].Market__c = 'Marietta GA FS';
            update ammap ;
                
            ammap = [select Zip_Code__c,  Market__c from ARC_Market_Mapping__c where Zip_Code__c = '30622' ] ;
            ammap[0].Zip_Code__c = '30623';
            update ammap ;
                
            List<Account> accUpdateList = [ SELECT Id, BillingPostalCode, Market__c FROM Account];  
            Assert.isTrue('Marietta GA FS' == accUpdateList[0].Market__c);   
        }    
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
}