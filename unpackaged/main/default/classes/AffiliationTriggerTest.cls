/*
 * This Test class covering the following Trigger
 * AffiliationTrigger, 
 * */
@isTest
public class AffiliationTriggerTest {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        // create account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);        		
		List<Account> mobileAccList = new List<Account>();        
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.Internal_Name__c = 'Exavalu1';
        accobj.BillingPostalCode = '30622';        
        mobileAccList.add(accobj);
		
		accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu2';
        accobj.Internal_Name__c = 'Exavalu2';
        accobj.BillingPostalCode = '30623';        
        mobileAccList.add(accobj);        
        insert mobileAccList;
        
        //create contact
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.Email = 'testContact@gmail.com';
        contact.Original_Service_Date__c = system.today().addDays(3);
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.AccountId = mobileAccList[0].id;
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '888-888-8888';
        insert contact;
        
        //create opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.AccountId = mobileAccList[0].id;
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = mobileAccList[0].id; 
        serviceRole.Contact__c = contact.Id;
        insert serviceRole;
        opp.StageName = 'Committed';
        //opp.Drive_Site__c = site.id;
		opp.Drive_Name__c = 'Test Drive 1';
        opp.Drive_Date__c = System.today();
        opp.CloseDate = System.today();
        opp.Call_List_Recipient_Exist__c = true;
        Time startTime = Time.newInstance(10, 0, 0, 0);
        opp.Start_Time__c = startTime;
        Time endTime = Time.newInstance(15, 30, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
		opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';
        opp.WB_Projected_Procedures__c = 4;
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Name = 'Test Opportunity 1';
        opp.Anticipated_Registered_Donors__c =25;
        oppList.add(opp);
		insert oppList;

				
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
        insert mmapList;
        
    }

    @isTest static void updateAccountMarketField() {
                
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
                
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        // update scenario
        List<Account> accUpdateList = [ SELECT Id, BillingPostalCode, Market__c FROM Account where Name IN  ( 'Exavalu' , 'Exavalu2' )  ];        
        
        // Add Account Team Member
        // This code is also covering the insert test scenarios for AccountTeamMemberTrigger
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = accUpdateList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Start_Date__c = system.today();
        atm.End_Date__c = system.today().addDays(5);
        atmList.add(atm);
		
		atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = accUpdateList[1].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Start_Date__c = system.today();
        atm.End_Date__c = system.today().addDays(5);
        atmList.add(atm);		
        insert atmList;        
        
        List<Marketing_Program__c> masterAffList = new List<Marketing_Program__c>();
        
        List<Marketing_Program__c> affList1 = new List<Marketing_Program__c>();
        Marketing_Program__c aff = new Marketing_Program__c();
        aff.Name = 'Test';
        aff.External_Name__c = 'TEST';
        aff.Scope__c = 'Account';
        aff.End_Date__c = system.today().addDays(3);
        affList1.add(aff);
        insert affList1;
        
        List<Marketing_Program__c> affList2 = new List<Marketing_Program__c>();
        Marketing_Program__c aff1 = new Marketing_Program__c();
        aff1.Name = 'Test1';
        aff1.External_Name__c = 'TEST1';
        aff1.Scope__c = 'Drive';
        aff1.End_Date__c = system.today().addDays(4);
        affList2.add(aff1);
        insert affList2;
        
        masterAffList.addAll(affList1);
        masterAffList.addAll(affList2);
        
        System.runAs( DRDAMUser ){
        test.startTest();
            
        List<Account> alst = [select Id, Name from Account where Name = 'Exavalu'];
        
        List<Account_Marketing_Program__c> amList = new List<Account_Marketing_Program__c>();
        Account_Marketing_Program__c am = new Account_Marketing_Program__c();
        am.Marketing_Program__c = affList1[0].id;
        am.Account_Affiliation_External_Key__c = 'Test_123';
        am.Account__c = alst[0].Id;
        am.Date_Removed__c = affList1[0].End_Date__c;
        amList.add(am);
        insert amList;
        
        List<Opportunity> olst = [select Id , Name from Opportunity where AccountId =: alst[0].id LIMIT 1];
        List<Drive_Marketing_Programs__c> dmList = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c dm = new Drive_Marketing_Programs__c();
        dm.Marketing_Program__c = affList2[0].id;
        dm.Blood_Drive_Opportunity__c = olst[0].id ;
        dm.Date_Removed__c = affList2[0].End_Date__c;
        dmList.add(dm);
        insert dmList;
            
        AffiliationService.populateEndDateInAccountAffiliation(masterAffList , 'Update');
            
	    List<ARC_Market_Mapping__c> mmapList = new List<ARC_Market_Mapping__c>();
		ARC_Market_Mapping__c mmap ;
        mmap = new ARC_Market_Mapping__c();
		mmap.Zip_Code__c = '30622';
		mmap.Market__c = 'Alpharetta';
		mmapList.add(mmap);			
		insert mmapList;
            
		List<ARC_Market_Mapping__c> ammap = new List<ARC_Market_Mapping__c>();
		ammap = [select Zip_Code__c,  Market__c from ARC_Market_Mapping__c where Zip_Code__c = '30622' ] ;
		ammap[0].Market__c = 'Marietta GA FS';
		update ammap ;
			
		ammap = [select Zip_Code__c,  Market__c from ARC_Market_Mapping__c where Zip_Code__c = '30622' ] ;
		ammap[0].Zip_Code__c = '30623';
		update ammap ;
            
        accUpdateList = [ SELECT Id, BillingPostalCode, Market__c FROM Account where Name IN  ( 'Exavalu' , 'Exavalu2' )  ];
            
        System.assertEquals( 'Marietta GA FS',  accUpdateList[0].Market__c );
        System.assertEquals( Null,  accUpdateList[1].Market__c );
           
            
        test.stopTest();
            
        }
    }
    
    //Method to get the map of recordType Name as key and recordTypeId as value 
    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    } 
}