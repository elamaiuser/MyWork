/*
* This Test class covering following class
* AddTeamMemberToOpportunity
*/  
@isTest(SeeAllData=false)
public class AddTeamMemberToOpportunityTest {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> accrecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        accrecordTypeMap = recordTypeMap( 'Account' );
        opprecordTypeMap = recordTypeMap( 'Opportunity' );
        siterecordTypeMap = recordTypeMap('sked__Location__c');
        Id recTypeId = accrecordTypeMap.get(mobileAccRecType);
        Id optyRecTypeId = opprecordTypeMap.get(mobileOppRecType);
        Id siteRecTypeId = siterecordTypeMap.get(mobileSiteRecType);
        
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
            LastName = 'Jana',
            Email = 'DRDProfile000@amamama.com',
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
        System.runAs( AdminUser ){
            List<Account> mobileAccList = new List<Account>();            
            Account accObj = new Account();
            accObj.RecordTypeId = recTypeId;
            accObj.Name = 'ExavaluTest';
            accObj.BillingPostalCode = '30622';            
            mobileAccList.add(accobj);            
            insert mobileAccList;
            
            Contact conObj = new Contact();
            conObj.AccountId = mobileAccList[0].Id;
            conObj.FirstName = 'Test';
            conObj.LastName = 'Contact';
            conObj.MailingCity = 'Ashburn';
            conObj.MailingCountryCode ='US';
            conObj.MailingPostalCode = '20148';
            conObj.MailingStateCode = 'VA';
            conObj.MailingStreet = '23070 Learning Cir';
            conObj.Email = 'testContact1@gmail.com';
        	conObj.Original_Service_Date__c = system.today().addDays(3);
	    	conObj.Primary_Phone__c = 'Mobile Phone';
        	conObj.MobilePhone = '752-781-0091';
            insert conObj;
            
            sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type';            
            insert skedTag; 
            
            sked__Location__c siteObj = new sked__Location__c();
            siteObj.RecordTypeId = siteRecTypeId;
            siteObj.Name = 'Test Site';
            siteObj.sked__Address__c = 'Test Site Address';
            siteObj.sked_Site_Building_Name__c = 'Test Site Building';
            siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
            siteObj.sked_Room_Name__c = 'Room 15';
            siteObj.sked_National_Name__c = 'AMERICA';
            siteObj.sked_Physical_Location_Type__c = 'Outside';
            siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
            siteObj.sked_Automation_Suitability__c = 'Suitable';
            siteObj.sked_Outside_stairs__c = 1;
            siteObj.sked_Inside_stairs__c = 2;
            siteObj.sked_Base_Description__c = 'test base description';
            siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Site_Contact__c = conObj.Id;
            siteObj.sked_Site_Main_Phone__c = '999-999-9999';
            siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj.sked_Pay_for_Parking__c = 'Other';
            siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            siteObj.sked_Address_1__c = 'Test Address';
            siteObj.sked_City__c = 'city';
            siteObj.sked_County__c = 'United States';
            siteObj.sked_State__c = 'Texas';
            siteObj.sked_Zip_Code__c = '27560';
            siteObj.Source__c ='Custom New Form';
            insert siteObj;
            
            Opportunity optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = mobileAccList[0].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = System.now().Time();
            optyObj.End_Time__c = System.now().Time()+1;
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            insert optyObj;
        }       
        
    }
      
    @isTest static void addOpportunityTeamMemberTest() {
        
        User DRDUser = [select Id ,LastName from User where Email = 'DRDProfile000@amamama.com' ];
        Account accItem = [select Id , Name , BillingPostalCode from Account where Name = 'ExavaluTest' limit 1];
        Opportunity oppItem = [select id , Name , AccountId from Opportunity where AccountId = :accItem.id];
        
        List<String> selectedIdsList = new List<String>();
        selectedIdsList.add(oppItem.Id);
        
         AddTeamMemberToOpportunity.AddTeamMember  otm = new AddTeamMemberToOpportunity.AddTeamMember();
         otm.userId = DRDUser.Id;
         otm.teamRole = 'Account Manager';
         otm.bloodDriveAccessLevel = 'None';
            
         String otmJson = JSON.serialize( otm );
         test.startTest();
            
         AddTeamMemberToOpportunity.addOpportunityTeamMember( otmJson, selectedIdsList);
        
         test.stopTest();
        
         List<OpportunityTeamMember> oppTeamMemberItem = [select Id from OpportunityTeamMember limit 1]; 
         System.assert( oppTeamMemberItem.size() == 1 );
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