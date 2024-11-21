//Test Class For PortfolioAssignmentHelper class
@isTest
public class PortfolioAssignmentServiceTest {
    
    @testSetup static void setUpData() {
        triggerHandler.bypass('TaskTriggerHandler');
        Account acc = new Account(name='Test Account 1');
        acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
        acc.BillingCity = 'Herndon';
        acc.BillingStateCode = 'MI';
        acc.BillingPostalCode = '48093';
        acc.Internal_Name__c ='TEst Test Account 1';
        insert acc;
        
        Contact contact = new Contact (firstname='Test Contact First 1',lastname='TestContactLast1');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'MI';
        contact.MailingPostalCode = '48420';
        contact.AccountId = acc.id;
        contact.Original_Service_Date__c=system.today();
         contact.Primary_Phone__c='Mobile Phone';
        insert contact;
        
        Account acc1 = new Account(name='Test Account 2');
        acc1.BillingStreet = '2205 Westcrt ln, Apt 215'; 
        acc1.BillingCity = 'Herndon';
        acc1.BillingStateCode = 'MI';
        acc1.BillingPostalCode = '480923';
        acc1.Internal_Name__c ='TEst Test Account 2';
        insert acc1;
        
        Account acc2 = new Account(name='Test Account 3');
        acc2.BillingStreet = '22054 Westcrt ln, Apt 216'; 
        acc2.BillingCity = 'Herndon';
        acc2.BillingStateCode = 'MI';
        acc2.BillingPostalCode = '480921';
        acc2.Internal_Name__c ='TEst Test Account 3';
        insert acc2;
        
        Contact contact1 = new Contact (firstname='Test Contact First 2',lastname='TestContactLast2');
        contact1.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact1.MailingCity = 'Herndon';
        contact1.MailingStateCode = 'MI';
        contact1.MailingPostalCode = '48093';
        contact1.AccountId = acc1.id;
        contact1.Original_Service_Date__c=system.today();
         contact1.Primary_Phone__c='Mobile Phone';
        //insert contact1;
        
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeId = recordTypesadjustment.get('Bio Recruitment CD').getRecordTypeId();
        Id RecTypeId2 = recordTypesadjustment.get('Bio Account Portfolio').getRecordTypeId();
        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);
        
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',	DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate1,	RecordTypeId=RecTypeId, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S',	Team_Name__c='MICH_Detroit S',		Type__c='Bio Recruitment',	Version_Key__c=108.0, Zip_Code__c='48093');
        Taxonomy__c tax2 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',		DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate1,	RecordTypeId=RecTypeId, Start_Date__c=startDate1, Team_Code__c='MICH_E Michigan',	Team_Name__c='MICH_E Michigan',		Type__c='Bio Recruitment',	Version_Key__c=108.0, Zip_Code__c='48420');
        Taxonomy__c tax3 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1820',DRD_Territory_Name__c='Detroit North 05',	DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate2,	RecordTypeId=RecTypeId, Start_Date__c=startDate2, Team_Code__c='MICH_Detroit N',	Team_Name__c='MICH_Detroit N',		Type__c='Bio Recruitment',	Version_Key__c=109.0, Zip_Code__c='48093');
        Taxonomy__c tax4 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',		DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate2,	RecordTypeId=RecTypeId, Start_Date__c=startDate2, Team_Code__c='MICH_E Michigan',	Team_Name__c='MICH_E Michigan',		Type__c='Bio Recruitment',	Version_Key__c=109.0, Zip_Code__c='48420');
        Taxonomy__c tax5 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',		DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = endDate2,	RecordTypeId=RecTypeId2, Start_Date__c=startDate2, Team_Code__c='MICH_E Michigan',	Team_Name__c='MICH_E Michigan',		Type__c='Bio Account Portfolio',	Version_Key__c=109.0, Zip_Code__c='');
        taxList.add(tax1);
        taxList.add(tax2);
        taxList.add(tax3);
        taxList.add(tax4);
        taxList.add(tax5);
        
        insert taxList;
        
        //create users
        List<User> users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile p1 = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        User u1 = new User(Alias = 'usr1', Email='drduser1@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser1@test.com.tst1');
        users.add(u1);
        
        User u2 = new User(Alias = 'usr2', Email='drduser2@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p1.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser2@test.com.tst1');
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
        
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        
        insert DMPortfolio;
        
        
        BSF_Portfolio__c ABMPortfolio = new BSF_Portfolio__c();
        ABMPortfolio.Portfolio_Code__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Name__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Type__c = BSF_Constants.AREA_BOOKING_MANAGER;
        ABMPortfolio.Account_Based_Portfolio__c = false;
        ABMPortfolio.Territory_Portfolio__c = true;
        ABMPortfolio.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert ABMPortfolio;
        
        BSF_Portfolio__c AMPortfolioWithABM = new BSF_Portfolio__c();
        AMPortfolioWithABM.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolioWithABM.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolioWithABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithABM.Territory_Portfolio__c = true;
        AMPortfolioWithABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c =:BSF_Constants.AREA_BOOKING_MANAGER].Id; 
        
        insert AMPortfolioWithABM;
        
        BSF_Portfolio__c AMPortfolioWithoutABM = new BSF_Portfolio__c();
        AMPortfolioWithoutABM.Portfolio_Name__c = 'Detroit South 07';
        AMPortfolioWithoutABM.Portfolio_Code__c = 'HProdSEMR_1837';
        AMPortfolioWithoutABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithoutABM.Territory_Portfolio__c = true;
        AMPortfolioWithoutABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithoutABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert AMPortfolioWithoutABM;
        
        //insert Sickle Cell Account Manager
        BSF_Portfolio__c sickleCellAM = new BSF_Portfolio__c();
        sickleCellAM.Portfolio_Name__c ='SAM Test Data 1';
        sickleCellAM.Portfolio_Code__c ='SAM Test Data 1';
        sickleCellAM.Account_Based_Portfolio__c = true;
        sickleCellAM.Portfolio_Type__c = 'Sickle Cell Account Manager';
        
        insert sickleCellAM;
        
        //Insert AccountPortfolioAssignments
        List<Account_Portfolio_Assignment__c> accPortfolioAssignemnetList = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c accPortfolio1 = new Account_Portfolio_Assignment__c();
        accPortfolio1.BSF_Portfolio__c =AMPortfolioWithABM.id;
        accPortfolio1.Account__c = [SELECT Id FROM Account WHERE Name = 'Test Account 1'].Id;
        accPortfolio1.Start_Date__c = SYstem.today();
        accPortfolio1.End_Date__c = System.today() +5;
        
        accPortfolioAssignemnetList.add(accPortfolio1);
        
                
        Account_Portfolio_Assignment__c accPortfolio2 = new Account_Portfolio_Assignment__c();
        accPortfolio2.BSF_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Type__c = 'Account Manager' AND Portfolio_Code__c = 'HProdSEMR_1837'].Id;
        accPortfolio2.Account__c = [SELECT Id FROM Account WHERE Name = 'Test Account 2'].Id;
        accPortfolio2.Start_Date__c = SYstem.today();
        accPortfolio2.End_Date__c = System.today() +5;
        
        accPortfolioAssignemnetList.add(accPortfolio2);
        
        Account_Portfolio_Assignment__c accPortfolio3 = new Account_Portfolio_Assignment__c();
        accPortfolio3.BSF_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Type__c = 'Sickle Cell Account Manager' AND Portfolio_Code__c = 'SAM Test Data 1'].Id;
        accPortfolio3.Account__c = [SELECT Id FROM Account WHERE Name = 'Test Account 3'].Id;
        accPortfolio3.Start_Date__c = SYstem.today();
        accPortfolio3.End_Date__c = System.today() +5;
        
        accPortfolioAssignemnetList.add(accPortfolio3);
        
        Insert accPortfolioAssignemnetList;
    }
    
    @isTest static void createPortfolioUserAssignments(){
        List<Portfolio_Assignment__c> portfolioAssignmentList = new List<Portfolio_Assignment__c>();
		list<user> userList = [select id from user WHERE Email IN ('drduser1@test.com','drduser2@test.com','drduser3@test.com','drduser4@test.com','drduser5@test.com')] ; 
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') 
                                          										or (Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager') 
                                          										or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager')
                                         										or (Portfolio_Code__c = 'HProdSEMR_1837' AND Portfolio_Type__c = 'Account Manager')
                                         										or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Type__c,bsf.id);
        }
        Portfolio_Assignment__c portfolioAssignment1 = new Portfolio_Assignment__c();
        portfolioAssignment1.Assignment_Type__c = 'Account Manager';
        portfolioAssignment1.BSF_Portfolio__c =bsfIdMap.get('Account Manager');
        portfolioAssignment1.User__c = userList[0].Id;
        portfolioAssignment1.Start_Date__c = System.today();
        portfolioAssignment1.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment1);
        
        
        Portfolio_Assignment__c portfolioAssignment2 = new Portfolio_Assignment__c();
        portfolioAssignment2.Assignment_Type__c = 'District Manager';
        portfolioAssignment2.BSF_Portfolio__c =bsfIdMap.get('District Manager');
        portfolioAssignment2.User__c = userList[1].Id;
        portfolioAssignment2.Start_Date__c = System.today();
        portfolioAssignment2.End_Date__c = System.today() +10;
        portfolioAssignmentList.add(portfolioAssignment2);
        
        Portfolio_Assignment__c portfolioAssignment3 = new Portfolio_Assignment__c();
        portfolioAssignment3.Assignment_Type__c = 'Area Booking Manager';
        portfolioAssignment3.BSF_Portfolio__c = bsfIdMap.get('Area Booking Manager');
        portfolioAssignment3.User__c =userList[2].Id;
        portfolioAssignment3.Start_Date__c = System.today();
        portfolioAssignment3.End_Date__c = System.today() +10;
        portfolioAssignmentList.add(portfolioAssignment3);
        
        Portfolio_Assignment__c portfolioAssignment4 = new Portfolio_Assignment__c();
        portfolioAssignment4.Assignment_Type__c = 'Account Manager';
        portfolioAssignment4.BSF_Portfolio__c =bsfIdMap.get('Account Manager');
        portfolioAssignment4.User__c = userList[3].Id;
        portfolioAssignment4.Start_Date__c = System.today();
        portfolioAssignment4.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment4);
        
        Portfolio_Assignment__c portfolioAssignment5 = new Portfolio_Assignment__c();
        portfolioAssignment5.Assignment_Type__c = 'Sickle Cell Account Manager';
        portfolioAssignment5.BSF_Portfolio__c =bsfIdMap.get('Sickle Cell Account Manager');
        portfolioAssignment5.User__c =userList[4].Id;
        portfolioAssignment5.Start_Date__c = System.today();
        portfolioAssignment5.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment5);
        
        triggerHandler.bypass('TaskTriggerHandler');
		Test.startTest();
         
        Database.insert(portfolioAssignmentList);
        
		/*PortfolioAssignmentService.createAccountTeamMembers(portfolioAssignmentList); 
        List<Portfolio_Assignment__c> datechangeList = [select id,Start_Date__c,End_Date__c from Portfolio_Assignment__c where User__c IN(SELECT Id FROM User WHERE Email='drduser5@test.com')];
		list<Portfolio_Assignment__c> datechangedList = new list<Portfolio_Assignment__c>();
        for(Portfolio_Assignment__c pa:datechangeList)
        {
            pa.End_Date__c = system.today()+30;
            datechangedList.add(pa);
        }
        update datechangedList;
        
        delete datechangedList;*/
        Test.stopTest();
    }
    
    @isTest static void testMethod2(){
        List<Portfolio_Assignment__c> portfolioAssignmentList = new List<Portfolio_Assignment__c>();
		list<user> userList = [select id from user WHERE Email IN ('drduser1@test.com','drduser2@test.com','drduser3@test.com','drduser4@test.com','drduser5@test.com')] ; 
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c,Portfolio_Code__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager') or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Code__c,bsf.id);
        }
        Portfolio_Assignment__c portfolioAssignment1 = new Portfolio_Assignment__c();
        portfolioAssignment1.Assignment_Type__c = 'Account Manager';
        portfolioAssignment1.BSF_Portfolio__c =bsfIdMap.get('HProdSEMR_1836');
        portfolioAssignment1.User__c = userList[0].Id;
        portfolioAssignment1.Start_Date__c = System.today();
        portfolioAssignment1.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment1);
        
        
        Portfolio_Assignment__c portfolioAssignment2 = new Portfolio_Assignment__c();
        portfolioAssignment2.Assignment_Type__c = 'Area Booking Manager';
        portfolioAssignment2.BSF_Portfolio__c =bsfIdMap.get('NA_Detorit_ABM_1');
        portfolioAssignment2.User__c = userList[1].Id;
        portfolioAssignment2.Start_Date__c = System.today();
        portfolioAssignment2.End_Date__c = System.today() +10;
        portfolioAssignmentList.add(portfolioAssignment2);
        
        Portfolio_Assignment__c portfolioAssignment5 = new Portfolio_Assignment__c();
        portfolioAssignment5.Assignment_Type__c = 'Sickle Cell Account Manager';
        portfolioAssignment5.BSF_Portfolio__c =bsfIdMap.get('SAM Test Data 1');
        portfolioAssignment5.User__c =userList[4].Id;
        portfolioAssignment5.Start_Date__c = System.today();
        portfolioAssignment5.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment5);
        
        
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        Database.insert(portfolioAssignmentList);
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        Test.startTest();
		triggerHandler.bypass('TaskTriggerHandler');
        list<Portfolio_Assignment__c> datechangedList = new list<Portfolio_Assignment__c>();
		portfolioAssignment1.End_Date__c=system.today()+30;
        datechangedList.add(portfolioAssignment1);
        
        portfolioAssignment5.End_Date__c=system.today()+3;
        datechangedList.add(portfolioAssignment5);
        update datechangedList;
        
        portfolioAssignment2.End_Date__c=System.today() +100;
        update portfolioAssignment2;
        Test.stopTest();   
    }
    
    @isTest static void testMethod3(){
        List<Portfolio_Assignment__c> portfolioAssignmentList = new List<Portfolio_Assignment__c>();
		list<user> userList = [select id from user WHERE Email IN ('drduser1@test.com','drduser2@test.com','drduser3@test.com','drduser4@test.com','drduser5@test.com')] ; 
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') 
                                          										or (Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager') 
                                          										or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager')
                                         										or (Portfolio_Code__c = 'HProdSEMR_1837' AND Portfolio_Type__c = 'Account Manager')
                                         										or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Type__c,bsf.id);
        }
        Portfolio_Assignment__c portfolioAssignment1 = new Portfolio_Assignment__c();
        portfolioAssignment1.Assignment_Type__c = 'Account Manager';
        portfolioAssignment1.BSF_Portfolio__c =bsfIdMap.get('Account Manager');
        portfolioAssignment1.User__c = userList[0].Id;
        portfolioAssignment1.Start_Date__c = System.today();
        portfolioAssignment1.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment1);
        
        
        Portfolio_Assignment__c portfolioAssignment2 = new Portfolio_Assignment__c();
        portfolioAssignment2.Assignment_Type__c = 'District Manager';
        portfolioAssignment2.BSF_Portfolio__c =bsfIdMap.get('District Manager');
        portfolioAssignment2.User__c = userList[1].Id;
        portfolioAssignment2.Start_Date__c = System.today();
        portfolioAssignment2.End_Date__c = System.today() +10;
        portfolioAssignmentList.add(portfolioAssignment2);
        
        Portfolio_Assignment__c portfolioAssignment3 = new Portfolio_Assignment__c();
        portfolioAssignment3.Assignment_Type__c = 'Area Booking Manager';
        portfolioAssignment3.BSF_Portfolio__c = bsfIdMap.get('Area Booking Manager');
        portfolioAssignment3.User__c =userList[2].Id;
        portfolioAssignment3.Start_Date__c = System.today();
        portfolioAssignment3.End_Date__c = System.today() +10;
        portfolioAssignmentList.add(portfolioAssignment3);
        
        Portfolio_Assignment__c portfolioAssignment4 = new Portfolio_Assignment__c();
        portfolioAssignment4.Assignment_Type__c = 'Account Manager';
        portfolioAssignment4.BSF_Portfolio__c =bsfIdMap.get('Account Manager');
        portfolioAssignment4.User__c = userList[3].Id;
        portfolioAssignment4.Start_Date__c = System.today();
        portfolioAssignment4.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment4);
        
        Portfolio_Assignment__c portfolioAssignment5 = new Portfolio_Assignment__c();
        portfolioAssignment5.Assignment_Type__c = 'Sickle Cell Account Manager';
        portfolioAssignment5.BSF_Portfolio__c =bsfIdMap.get('Sickle Cell Account Manager');
        portfolioAssignment5.User__c =userList[4].Id;
        portfolioAssignment5.Start_Date__c = System.today();
        portfolioAssignment5.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment5);
        
       triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        Database.insert(portfolioAssignmentList);
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
		Test.startTest();
        triggerHandler.bypass('TaskTriggerHandler');
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account 1'];
        accountTeamMember atm = new accountTeamMember(accountid=acc.id,userid=userList[0].Id,bsf_Portfolio__c= portfolioAssignment1.BSF_Portfolio__c,start_date__c=portfolioAssignment1.Start_Date__c,end_Date__c=portfolioAssignment1.End_Date__c,teamMemberRole=portfolioAssignment1.Assignment_Type__c,is_covering_recruiter__c=false);
		bsf_constants.isTeamMemberCreatedFromBackend =true;
        triggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atm;
        
        
        delete portfolioAssignment1;
        Test.stopTest();   
    }
    @isTest static void testMethod4(){
        List<Portfolio_Assignment__c> portfolioAssignmentList = new List<Portfolio_Assignment__c>();
		list<user> userList = [select id from user WHERE Email IN ('drduser1@test.com','drduser2@test.com','drduser3@test.com','drduser4@test.com','drduser5@test.com')] ; 
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c,Portfolio_Code__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') or (Portfolio_Code__c = 'HProdSEMR_1837' AND Portfolio_Type__c = 'Account Manager') or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Code__c,bsf.id);
        }
        Portfolio_Assignment__c portfolioAssignment1 = new Portfolio_Assignment__c();
        portfolioAssignment1.Assignment_Type__c = 'Account Manager';
        portfolioAssignment1.BSF_Portfolio__c =bsfIdMap.get('HProdSEMR_1836');
        portfolioAssignment1.User__c = userList[0].Id;
        portfolioAssignment1.Start_Date__c = System.today();
        portfolioAssignment1.End_Date__c = System.today() +500;
        portfolioAssignmentList.add(portfolioAssignment1);
        
        
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        Account_Portfolio_Assignment__c accPortfolioAssignemnet = [select id from Account_Portfolio_Assignment__c where BSF_Portfolio__c=:bsfIdMap.get('HProdSEMR_1836')];
        delete accPortfolioAssignemnet;
        
       
        
        
        
        Test.startTest();
		
       Database.insert(portfolioAssignmentList);
        Test.stopTest();   
    }
     @isTest static void testMethod5(){
        List<Portfolio_Assignment__c> portfolioAssignmentList = new List<Portfolio_Assignment__c>();
		list<user> userList = [select id from user WHERE Email IN ('drduser1@test.com','drduser2@test.com','drduser3@test.com','drduser4@test.com','drduser5@test.com')] ; 
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c,Portfolio_Code__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager') or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Code__c,bsf.id);
        }
        Portfolio_Assignment__c portfolioAssignment1 = new Portfolio_Assignment__c();
        portfolioAssignment1.Assignment_Type__c = 'Account Manager';
        portfolioAssignment1.BSF_Portfolio__c =bsfIdMap.get('HProdSEMR_1836');
        portfolioAssignment1.User__c = userList[0].Id;
        portfolioAssignment1.Start_Date__c = System.today();
        portfolioAssignment1.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment1);
        
        
       Portfolio_Assignment__c portfolioAssignment2 = new Portfolio_Assignment__c();
        portfolioAssignment2.Assignment_Type__c = 'Account Manager';
        portfolioAssignment2.BSF_Portfolio__c =bsfIdMap.get('HProdSEMR_1836');
        portfolioAssignment2.User__c = userList[0].Id;
        portfolioAssignment2.Start_Date__c = System.today();
        portfolioAssignment2.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment2);
        
         
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portfolioAssignment1;
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        
		triggerHandler.bypass('TaskTriggerHandler');
         test.startTest();
         try{
             insert portfolioAssignment2;
         }
         catch(exception e)
         {
             assert.isTrue(string.valueof(e).contains('The selected date window is already covered by the user'));
         }
         /*list<Portfolio_Assignment__c> datechangedList = new list<Portfolio_Assignment__c>();
		portfolioAssignment1.End_Date__c=system.today()+30;
        datechangedList.add(portfolioAssignment1);
        
        portfolioAssignment5.End_Date__c=system.today()+3;
        datechangedList.add(portfolioAssignment5);
        update datechangedList;
        
        portfolioAssignment2.End_Date__c=System.today() +100;
        update portfolioAssignment2;*/
        Test.stopTest();   
    }
    
    @isTest static void testMethod6(){
        List<Portfolio_Assignment__c> portfolioAssignmentList = new List<Portfolio_Assignment__c>();
		list<user> userList = [select id from user WHERE Email IN ('drduser1@test.com','drduser2@test.com','drduser3@test.com','drduser4@test.com','drduser5@test.com')] ; 
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c,Portfolio_Code__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager') or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Code__c,bsf.id);
        }
        Portfolio_Assignment__c portfolioAssignment1 = new Portfolio_Assignment__c();
        portfolioAssignment1.Assignment_Type__c = 'Account Manager';
        portfolioAssignment1.BSF_Portfolio__c =bsfIdMap.get('HProdSEMR_1836');
        portfolioAssignment1.User__c = userList[0].Id;
        portfolioAssignment1.Start_Date__c = System.today();
        portfolioAssignment1.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment1);
        
        
       Portfolio_Assignment__c portfolioAssignment2 = new Portfolio_Assignment__c();
        portfolioAssignment2.Assignment_Type__c = 'Account Manager';
        portfolioAssignment2.BSF_Portfolio__c =bsfIdMap.get('HProdSEMR_1836');
        portfolioAssignment2.User__c = userList[0].Id;
        portfolioAssignment2.Start_Date__c = System.today();
        portfolioAssignment2.End_Date__c = System.today() +5;
        portfolioAssignmentList.add(portfolioAssignment2);
        
         test.startTest();
        insert portfolioAssignment1;
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        
		triggerHandler.bypass('TaskTriggerHandler');

        Test.stopTest();   
    }
    
}