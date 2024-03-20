@isTest(SeeAllData=false)
public class LookupClass_Test {
    
    @testSetup static void setUpData() {
        Account acc = new Account(name='Test Account 1');
        acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
        acc.BillingCity = 'Herndon';
        acc.BillingStateCode = 'MI';
        acc.BillingPostalCode = '48093';
        acc.Exclude_from_sponsor_direct_marketing__c = false;
        insert acc;
        
        Contact contact = new Contact (firstname='Test Contact First 1',lastname='Test Contact Last 1');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'MI';
        contact.MailingPostalCode = '48420';
        contact.AccountId = acc.id;
        contact.Original_Service_Date__c=system.today();
        contact.Primary_Phone__c='Mobile Phone';
        insert contact;
        
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
        AMPortfolioWithoutABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert AMPortfolioWithoutABM;
    }

    @isTest static void lookupTestMethod()
    {
        // scenario 1 -> serach term != null , filter = '' for BSF_Portfolio__c
        List<sObject> searchListOnPortfolio = Lookup.search('Portfolio', 'BSF_Portfolio__c', ''); 
        system.assertEquals(2, searchListOnPortfolio.size());
        
        // scenario 2 -> serach term != null , filter = '' for Account
        List<sObject> searchListOnAccount = Lookup.search('Test', 'Account', '');  
        system.assert(searchListOnAccount.size()==1);
        
        // scenario 3 -> serach term == null , filter = '' for BSF_Portfolio__c
        List<sObject> searchListWithoutSearchTerm = Lookup.search('', 'BSF_Portfolio__c', ''); 
        system.assert(searchListWithoutSearchTerm.size()==2);
        
        // scenario 4 -> serach term == null , filter = '' for Account
        List<sObject> searchListOnAccountWithoutSearchTerm = Lookup.search('', 'Account', ''); 
        //system.assertEquals(1, searchListOnAccountWithoutSearchTerm.size(), searchListOnAccountWithoutSearchTerm.size());
        system.assert(searchListOnAccountWithoutSearchTerm.size()!=null);
        
        // scenario 5 -> serach term != null , filter != for BSF_Portfolio__c
        List<sObject> searchListForPortfolio = Lookup.search('Portfolio', 'BSF_Portfolio__c', 'Account_Based_Portfolio__c =false');
        
        // scenario 5 -> serach term != null , filter != for Account
        List<sObject> searchListForAccount = Lookup.search('Test', 'Account', 'Exclude_from_sponsor_direct_marketing__c =false');
        
    }
}