//Test Class For MassAssignUserToRMPortfolioClass class
@isTest
public class MassAssignUserToRMPortfolioClassTest {
    
    
    @testSetup static void setUpData() {
        Account acc = new Account(name='Test Account 1');
        acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
        acc.BillingCity = 'Herndon';
        acc.BillingStateCode = 'MI';
        acc.BillingPostalCode = '48093';
        insert acc;
        
        Contact contact = new Contact (firstname='Test Contact First 1',lastname='Test Contact Last 1');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'MI';
        contact.MailingPostalCode = '48420';
        contact.AccountId = acc.id;
        contact.Primary_Phone__c='Mobile Phone';
        contact.Email='avs@dfh.com';
        contact.Original_Service_Date__c=Date.newInstance(2022, 08, 01);
        insert contact;
        
        Account acc1 = new Account(name='Test Account 2');
        acc1.BillingStreet = '2205 Westcrt ln, Apt 215'; 
        acc1.BillingCity = 'Herndon';
        acc1.BillingStateCode = 'MI';
        acc1.BillingPostalCode = '48093';
        insert acc1;
        
        Contact contact1 = new Contact (firstname='Test Contact First 2',lastname='Test Contact Last 2');
        contact1.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact1.MailingCity = 'Herndon';
        contact1.MailingStateCode = 'MI';
        contact1.MailingPostalCode = '48093';
        contact1.AccountId = acc1.id;
        contact1.Primary_Phone__c='Mobile Phone';
        contact1.Email='avs1@dfh.com';
        contact1.Original_Service_Date__c=Date.newInstance(2022, 09, 01);
        insert contact1;
        
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeId = recordTypesadjustment.get(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE).getRecordTypeId();
        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);
        
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',	DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate1,	RecordTypeId=RecTypeId, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S',	Team_Name__c='MICH_Detroit S',		Type__c='Bio Recruitment',	Version_Key__c=108.0, Zip_Code__c='48093');
        Taxonomy__c tax2 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',		DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate1,	RecordTypeId=RecTypeId, Start_Date__c=startDate1, Team_Code__c='MICH_E Michigan',	Team_Name__c='MICH_E Michigan',		Type__c='Bio Recruitment',	Version_Key__c=108.0, Zip_Code__c='48420');
        Taxonomy__c tax3 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1820',DRD_Territory_Name__c='Detroit North 05',	DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate2,	RecordTypeId=RecTypeId, Start_Date__c=startDate2, Team_Code__c='MICH_Detroit N',	Team_Name__c='MICH_Detroit N',		Type__c='Bio Recruitment',	Version_Key__c=109.0, Zip_Code__c='48093');
        Taxonomy__c tax4 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',		DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate2,	RecordTypeId=RecTypeId, Start_Date__c=startDate2, Team_Code__c='MICH_E Michigan',	Team_Name__c='MICH_E Michigan',		Type__c='Bio Recruitment',	Version_Key__c=109.0, Zip_Code__c='48420');
        taxList.add(tax1);
        taxList.add(tax2);
        taxList.add(tax3);
        taxList.add(tax4);
        
        insert taxList;
        
        //create users
        List<User> users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        
        User u1 = new User(Alias = 'usr1', Email='drduser1@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser1@test.com.tst1');
        users.add(u1);
        
        User u2 = new User(Alias = 'usr2', Email='drduser2@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser2@test.com.tst1');
        users.add(u2);
        
        User u3 = new User(Alias = 'usr3', Email='drduser3@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser3@test.com.tst1');
        users.add(u3);
        
        User u4 = new User(Alias = 'usr4', Email='drduser4@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser4@test.com.tst1');
        users.add(u4);
        
        User u5 = new User(Alias = 'usr5', Email='drduser5@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser5@test.com.tst1');
        users.add(u5);
        
        User u6 = new User(Alias = 'usr6', Email='drduser6@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser6@test.com.tst1');
        users.add(u6);
        
        insert users;
    }
    
    @isTest static void testcreateAccountTeamMembers(){
        Test.startTest();
        
        //Insert Portfolios
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        
        insert DMPortfolio;
        
        BSF_Portfolio__c AMPortfolio = new BSF_Portfolio__c();
        AMPortfolio.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolio.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolio.Account_Based_Portfolio__c = false;
        AMPortfolio.Territory_Portfolio__c = true;
        AMPortfolio.Portfolio_Type__c = 'Account Manager';
        AMPortfolio.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert AMPortfolio;
        
        List<BSF_Portfolio__c> portfolioList = new List<BSF_Portfolio__c>();
        portfolioList.add(DMPortfolio);
        portfolioList.add(AMPortfolio);
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(portfolioList);
        sc.setSelected(portfolioList);
        MassAssignUserToRMPortfolioClass controller = new MassAssignUserToRMPortfolioClass(sc);
        Test.setCurrentPage(Page.MassAssignUserToRMPortfolioPage);
        
        
        
        Test.stopTest();
    }
    
}