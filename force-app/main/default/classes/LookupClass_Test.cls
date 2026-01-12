@isTest(SeeAllData = false)
private class LookupClass_Test {
    
    @testSetup static void prepareTestData() {
      	skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
       
        //insert Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        insert testMobileAccount;
        
        //insert Contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id;
        insert testContact;
        
        //insert Portfolios
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Name = 'DM Portfolio';
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        
        insert DMPortfolio;
        
        BSF_Portfolio__c AMPortfolioWithoutABM = new BSF_Portfolio__c();
        AMPortfolioWithoutABM.Name = 'AM Portfolio';
        AMPortfolioWithoutABM.Portfolio_Name__c = 'Detroit South 07';
        AMPortfolioWithoutABM.Portfolio_Code__c = 'HProdSEMR_1837';
        AMPortfolioWithoutABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithoutABM.Territory_Portfolio__c = true;
        AMPortfolioWithoutABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithoutABM.Parent_Portfolio__c = DMPortfolio.Id; 
        
        insert AMPortfolioWithoutABM;
    }

    @isTest static void lookupTestMethod() {
        // scenario 1 -> serach term != null , filter = '' for BSF_Portfolio__c
        List<sObject> searchListOnPortfolio = Lookup.search('Portfolio', 'BSF_Portfolio__c', ''); 
        Assert.isTrue(searchListOnPortfolio.size() == 2);
        
        // scenario 2 -> serach term != null , filter = '' for Account
        List<sObject> searchListOnAccount = Lookup.search('Test', 'Account', '');  
        Assert.isTrue(searchListOnAccount.size() == 1);
        
        // scenario 3 -> serach term == null , filter = '' for BSF_Portfolio__c
        List<sObject> searchListWithoutSearchTerm = Lookup.search('', 'BSF_Portfolio__c', ''); 
        Assert.isTrue(searchListWithoutSearchTerm.size() == 2);
        
        // scenario 4 -> serach term == null , filter = '' for Account
        List<sObject> searchListOnAccountWithoutSearchTerm = Lookup.search('', 'Account', ''); 
        Assert.isTrue(searchListOnAccountWithoutSearchTerm.size() != null);
        
        // scenario 5 -> serach term != null , filter != for BSF_Portfolio__c
        List<sObject> searchListForPortfolio = Lookup.search('Portfolio', 'BSF_Portfolio__c', 'Account_Based_Portfolio__c = false');
        Assert.isTrue(!searchListForPortfolio.isEmpty());
        
        // scenario 5 -> serach term != null , filter != for Account
        List<sObject> searchListForAccount = Lookup.search('Test', 'Account', 'Exclude_from_sponsor_direct_marketing__c = false');
        Assert.isTrue(!searchListForAccount.isEmpty());  
    }
}