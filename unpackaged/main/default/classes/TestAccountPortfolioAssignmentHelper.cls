/**
 * This Class contains testMethods for AccountPortfolioAssignmentHelper
 * 
 * */
@isTest
public class TestAccountPortfolioAssignmentHelper {
    /*@testSetup static void setUpData() {
         Account acc = new Account(name='Test Account 1');
         acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
         acc.BillingCity = 'Herndon';
         acc.BillingStateCode = 'MI';
         acc.BillingPostalCode = '48420';
         insert acc;
        
         Contact contact = new Contact (firstname='Test Contact First 1',lastname='Test Contact Last 1');
         contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
         contact.MailingCity = 'Herndon';
         contact.MailingStateCode = 'MI';
         contact.MailingPostalCode = '48420';
        contact.Email = 'testContact@gmail.com';
		contact.Original_Service_Date__c = system.today().addDays(3);
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
         contact.AccountId = acc.id;
        
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
         contact1.Email = 'testContact@gmail.com';
		contact1.Original_Service_Date__c = system.today().addDays(3);
        contact1.Primary_Phone__c = 'Mobile Phone';
        contact1.MobilePhone = '752-781-0090';
         insert contact1;
        
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeId = recordTypesadjustment.get('Bio Recruitment CD').getRecordTypeId();
        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);
            
            
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',   DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate1, RecordTypeId=RecTypeId, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S',    Team_Name__c='MICH_Detroit S',      Type__c='Bio Recruitment',  Version_Key__c=108.0, Zip_Code__c='48093');
        Taxonomy__c tax2 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',        DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate1, RecordTypeId=RecTypeId, Start_Date__c=startDate1, Team_Code__c='MICH_E Michigan',   Team_Name__c='MICH_E Michigan',     Type__c='Bio Recruitment',  Version_Key__c=108.0, Zip_Code__c='48420');
        Taxonomy__c tax3 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1820',DRD_Territory_Name__c='Detroit North 05',   DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate2, RecordTypeId=RecTypeId, Start_Date__c=startDate2, Team_Code__c='MICH_Detroit N',    Team_Name__c='MICH_Detroit N',      Type__c='Bio Recruitment',  Version_Key__c=109.0, Zip_Code__c='48093');
        Taxonomy__c tax4 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',        DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate2, RecordTypeId=RecTypeId, Start_Date__c=startDate2, Team_Code__c='MICH_E Michigan',   Team_Name__c='MICH_E Michigan',     Type__c='Bio Recruitment',  Version_Key__c=109.0, Zip_Code__c='48420');
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
    }*/
    
    @isTest static void testPortfolioInsert(){
        /*
        Test.startTest();
        
        BSFPortfolioHelper.processTaxonomyData(108,BSF_Constants.BIO_COLLECTION_RECORD_TYPE);
        List<BSF_Portfolio__c> list1 = [Select Id from BSF_Portfolio__c];
        System.debug(list1.size());
        //System.assertEquals(6, list1.size(), 'Error creating Portfolio records.');
        
        BSFPortfolioHelper.processTaxonomyData(109,BSF_Constants.BIO_COLLECTION_RECORD_TYPE);
        List<BSF_Portfolio__c> list2 = [Select Id from BSF_Portfolio__c];
        System.debug(list1.size());
        //System.assertEquals(8, list2.size(), 'Error creating Portfolio records.');
        
        List<User> users = [Select Id from User where Profile.Name = 'DRD Profile'];
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,External_Key__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Territory_Portfolio__c  = TRUE];
        
        Date startDate = System.today().addMonths(-6); 
        Date endDate = System.today().addMonths(6); 
        
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        
        for(BSF_Portfolio__c portfolio:portfolios){
            if(portfolio.Name == 'Detroit South 05'){
                Portfolio_Assignment__c am = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=users[0].Id,Start_Date__c=startDate ,End_Date__c=endDate);
                
                Portfolio_Assignment__c dm = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=users[1].Id,Start_Date__c=startDate ,End_Date__c=endDate);
                portAssigment.add(am);
                portAssigment.add(dm);
                
            }else if(portfolio.Name == 'Detroit North 05'){
                Portfolio_Assignment__c am = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=users[2].Id,Start_Date__c=startDate ,End_Date__c=endDate);
                
                Portfolio_Assignment__c dm = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=users[3].Id,Start_Date__c=startDate ,End_Date__c=endDate);
                portAssigment.add(am);
                portAssigment.add(dm);
                
                am = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=users[4].Id,Start_Date__c=endDate+1 ,End_Date__c=endDate+60);
                
                dm = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=users[5].Id,Start_Date__c=endDate+1 ,End_Date__c=endDate+60);
                portAssigment.add(am);
                portAssigment.add(dm);
            }else if(portfolio.Name == 'MI North 03'){
                Portfolio_Assignment__c am = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=users[0].Id,Start_Date__c=startDate ,End_Date__c=endDate);
                
                Portfolio_Assignment__c dm = new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=users[1].Id,Start_Date__c=startDate ,End_Date__c=endDate);
                portAssigment.add(am);
                portAssigment.add(dm);
            }
        }
        insert portAssigment;
        
        List<Portfolio_Assignment__c> portFolioUsers = [Select Id,Name, User__c ,Start_Date__c ,End_Date__c,BSF_Portfolio__c FROM Portfolio_Assignment__c WHERE  End_Date__c > TODAY ORDER BY Start_Date__c];
        System.debug('portFolioUsers' +portFolioUsers.size());
        
        AccountPortfolioAssignmentHelper.processTaxonomyData(108);
        
        AccountPortfolioAssignmentHelper.processTaxonomyData(109);
        
        Account acc3 = new Account(name='Test Account 3');
         acc3.BillingStreet = '2215 Westcrt ln, Apt 315'; 
         acc3.BillingCity = 'Herndon';
         acc3.BillingStateCode = 'MI';
         acc3.BillingPostalCode = '48093';
         insert acc3;
        
         Contact contact3 = new Contact (firstname='Test Contact First 3',lastname='Test Contact Last 3');
         contact3.MailingStreet = '2215 Westcrt ln, Apt 315'; 
         contact3.MailingCity = 'Herndon';
         contact3.MailingStateCode = 'MI';
         contact3.MailingPostalCode = '48093';
         contact3.AccountId = acc3.id;
         contact3.Email = 'testContact@gmail.com';
		contact3.Original_Service_Date__c = system.today().addDays(3);
        contact3.Primary_Phone__c = 'Mobile Phone';
        contact3.MobilePhone = '752-781-0090';
         insert contact3;
        
         AccountPortfolioAssignmentHelper.processTaxonomyData(109);
        
        BSF_Batch_AccountPortfolioAssignment batch1 = new BSF_Batch_AccountPortfolioAssignment('Batch Test 11',108,null,null);
        Database.executeBatch(batch1);
        
        Test.stopTest();*/
    }
    
}