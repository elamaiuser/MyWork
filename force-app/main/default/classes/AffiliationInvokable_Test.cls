@isTest
public class AffiliationInvokable_Test {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static List<Id> AffId = new List<Id>();
    
    @testSetup 
    public static void prepareDataset(){
        
        // create account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);        		
		List<Account> mobileAccList = new List<Account>();        
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30622';        
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        //create contact
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.Email = 'testContact@gmail.com';
		contact.Original_Service_Date__c = system.today().addDays(3);
		contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.AccountId = mobileAccList[0].id;
        insert contact;
        
        //create opportunity
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
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
    }
    
    @isTest static void testAccountInvoke() {
        
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
        List<Account> accList = [select Id from Account where Name = 'Exavalu'];
        List<Opportunity> oppList = [select Id , Name , Drive_Date__c from Opportunity where AccountId =:accList[0].Id];
        
         // create affiliations
        List<Marketing_Program__c> affList = new List<Marketing_Program__c>();
        Marketing_Program__c aff = new Marketing_Program__c();
        aff.Name = 'Test';
        aff.External_Name__c = 'TEST';
        aff.Scope__c = 'Drive';
        aff.End_Date__c = system.today().addDays(3);
        affList.add(aff);
        insert affList;
        
        AffId.add(affList[0].Id);
        
        // create drive affiliations
        List<Drive_Marketing_Programs__c> driveAffList = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c driveAff = new Drive_Marketing_Programs__c();
        driveAff.Marketing_Program__c = affList[0].Id;
        driveAff.Blood_Drive_Opportunity__c = oppList[0].Id;
        driveAffList.add(driveAff);
        insert driveAffList;
        
        Test.startTest();
        AffiliationInvokable.deleteDriveAffiliationOnBookingDateChange(AffId);
        Test.stopTest();

        
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