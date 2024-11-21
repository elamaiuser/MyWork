@isTest
public class CreateDriveAffiliationsBatch_test {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
 
    @isTest static void createDriveAffiliationTestMethod() {
                
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

         // create Account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '301461';        
        mobileAccList.add(accobj);
        insert mobileAccList;
               
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email='abcd@gmail.com';
        conObj.Primary_Phone__c='Mobile Phone';
        conObj.Original_Service_Date__c=system.today();
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conlist.add(conObj);
        insert conlist;
            
        // create sked location
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
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
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conlist[0].Id;
        siteObj.sked_Site_Main_Phone__c = '999-999-9999';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.source__c='Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='946082';
        skedlocationlist.add(siteObj);
        insert skedlocationlist;
            
        // create Opportunity
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        recordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Is_Template__c=true;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Open_to_Public__c='Yes';
        optyObj.Online_Scheduling_Enabled__c='Yes';
        insert optyObj;     
         
        Opportunity opp=new Opportunity();
        
        opp.AccountId=mobileAccList[0].Id;
        opp.From_Template_Id__c=optyObj.Id;
        opp.Parent_Template_Id__c=optyObj.Id;
        opp.Drive_Site__c = skedlocationlist[0].Id;
        opp.Name = 'Test Drive test';
        opp.StageName='Discovery';
        opp.Drive_Date__c = System.today();
        opp.Type_of_Drive__c = 'Mobile';
        opp.CloseDate = System.today();
        opp.Start_Time__c = System.now().Time();
        opp.End_Time__c = System.now().Time()+1;
        opp.Anticipated_Registered_Donors__c = 1;
        opp.X2RBC_Projected_Procedures__c = 1;
        opp.WB_Projected_Procedures__c = 2;
        opp.Plasma_Pheresis_Projected_Procedures__c = 3;
        opp.Platelet_Projected_Procedures__c = 1;
        opp.Open_to_Public__c='Yes';
        insert opp;
        
        // create affiliations
        List<Marketing_program__c> mar=new List<Marketing_program__c>();
        Marketing_program__c mp=new Marketing_program__c();
        mp.name='abc';
        mp.External_Name__c='abctest';
        mp.Scope__c='drive';
        mar.add(mp); 
        insert mar;
     
        // create drive affiliations
        List<Drive_Marketing_Programs__c> newDriveAffiliations = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c newDriveAff = new Drive_Marketing_Programs__c();
        newDriveAff.Migration_ID__c =null;//empty migration id
        newDriveAff.Blood_Drive_Opportunity__c = optyObj.id;
        newDriveAff.Account__c = accobj.Id;
        newDriveAff.Marketing_Program__c=mar[0].id; 
        newDriveAffiliations.add(newDriveAff);
        insert newDriveAffiliations;
        
       
        Set<ID> templateIdSet = new Set<Id>(); // you have to take your own data
        Map<Id,Opportunity> newOppMap = new Map<Id,Opportunity>(); // take own data of map
        
        templateIdSet.add(optyObj.id);
        newOppmap.put(opp.id,opp);
        system.debug('newOppmap## '+newOppmap);
        system.debug('templateIdSet##'+templateIdSet);
        
            
  		
        test.startTest();
        Database.executeBatch(new CreateDriveAffiliationsBatch (templateIdSet ,newOppMap ));  
        test.stopTest();
       
        
    }
    //Method to get the map of recordType Name as key and recordTypeId as value for account records
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