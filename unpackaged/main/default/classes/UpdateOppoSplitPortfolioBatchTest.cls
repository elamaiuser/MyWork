@isTest
public class UpdateOppoSplitPortfolioBatchTest {
	public static String rolename = 'West_BDM';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileSiteRecType = 'Mobile Site';    
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Opportunity' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        
        recordTypeMap = recordTypeMap( 'Account' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        
        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'adminuser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        //insert AdminUser ;
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'last',
            Email = 'DRDProfile000@amamama.com',
            Username = 'drduser000@amamama.com' + System.currentTimeMillis(),
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
            
            Account accObj;
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu';
            accObj.BillingPostalCode = '30622';            
            mobileAccList.add(accobj); 
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu2';
            accObj.BillingPostalCode = '30623';            
            mobileAccList.add(accobj); 
            insert mobileAccList;
            
            List<AccountTeammember> atmList = new List<AccountTeammember>();
            AccountTeammember atm;
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = DRDAMUser.Id ;
            atm.AccountId = mobileAccList[0].Id ;
            atm.TeamMemberRole = 'Account Specialist';
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = AdminUser.Id ;
            atm.AccountId = mobileAccList[0].Id ;
            atm.TeamMemberRole = 'Recruiter';
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = AdminUser.Id ;
            atm.AccountId = mobileAccList[1].Id ;
            atm.TeamMemberRole = 'Recruiter';
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            BSF_Constants.isTeamMemberCreatedFromBackend = true;
            insert atmList;
            
            
            
            
            Contact conObj = new Contact();
            conObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
            conObj.FirstName = 'Test';
            conObj.LastName = 'Contact';
            conObj.MailingCity = 'Ashburn';
            conObj.MailingCountryCode ='US';
            conObj.MailingPostalCode = '20148';
            conObj.MailingStateCode = 'VA';
            conObj.MailingStreet = '23070 Learning Cir';
            conObj.Primary_Phone__c = 'Mobile Phone';
         	conObj.MobilePhone = '222-111-1121';
         	conObj.Email = 'testtest@test3.com';
         	conObj.Original_Service_Date__c = Date.today();
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
            siteObj.sked_Site_Inspection_Completed_By__c = [SELECT Id FROM USER WHERE Email = 'DRDProfile000@amamama.com' ].Id;
            siteObj.sked_Automation_Suitability__c = 'Suitable';
            siteObj.sked_Outside_stairs__c = 1;
            siteObj.sked_Inside_stairs__c = 2;
            siteObj.sked_Base_Description__c = 'test base description';
            siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Site_Contact__c = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'Contact' ].Id;
            siteObj.sked_Site_Main_Phone__c = '758-771-0091';
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
            
            TriggerHandler.bypass('PortfolioAssignmentTriggerHandler');
            
            
            List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
            
            BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();			
            Portland_OR_AM_01.Name='Portland OR AM 01';
            Portland_OR_AM_01.Account_Based_Portfolio__c= true;			
            Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Type__c='Account Manager';
            Portland_OR_AM_01.Taxonomy_Type__c='Bio Recruitment CD';
            Portland_OR_AM_01.Territory_Portfolio__c=false;			
            bsfPortf.add(Portland_OR_AM_01);
            
            BSF_Portfolio__c Greater_Alleghenies_DRA_01 = new BSF_Portfolio__c();
            Greater_Alleghenies_DRA_01.Name='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Account_Based_Portfolio__c = true;
            Greater_Alleghenies_DRA_01.External_Key__c='Booking Support_BD32_27E_Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Code__c='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Name__c='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Type__c=BSF_Constants.Booking_Support;
            Greater_Alleghenies_DRA_01.Taxonomy_Type__c='Bio Booking Support';
            Greater_Alleghenies_DRA_01.Territory_Portfolio__c= false;
            bsfPortf.add(Greater_Alleghenies_DRA_01);
            
            BSF_Portfolio__c American_Red_Cross = new BSF_Portfolio__c();
            American_Red_Cross.Name='American Red Cross';
            American_Red_Cross.Account_Based_Portfolio__c=true;
            American_Red_Cross.External_Key__c='National Account_1';
            American_Red_Cross.Portfolio_Code__c='1';
            American_Red_Cross.Portfolio_Name__c='American Red Cross';
            American_Red_Cross.Portfolio_Type__c='National Account Manager';
            American_Red_Cross.Taxonomy_Type__c='National Account Manager Portfolio';
            American_Red_Cross.Territory_Portfolio__c=false;
            bsfPortf.add(American_Red_Cross);
            
            BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
            Sickle_Cell_AM_04.Name='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
            Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
            Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
            Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Portfolio_Type__c='Sickle Cell Account Manager';
            Sickle_Cell_AM_04.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
            Sickle_Cell_AM_04.Territory_Portfolio__c=false;
            bsfPortf.add(Sickle_Cell_AM_04);
            
            insert bsfPortf;
            
            List<Portfolio_Assignment__c> portfAssignList = new List<Portfolio_Assignment__c>();
            
            Portfolio_Assignment__c assign1 = new Portfolio_Assignment__c();
            assign1.Assignment_Type__c = 'Sickle Cell Account Manager';
            assign1.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign1.End_Date__c = Date.Today().addDays(10);
            assign1.Start_Date__c = Date.Today().addDays(-10);
            assign1.User__c = DRDAMUser.Id;
            portfAssignList.add(assign1);
            
            Portfolio_Assignment__c assign2 = new Portfolio_Assignment__c();
            assign2.Assignment_Type__c = 'Sickle Cell Account Manager';
            assign2.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign2.End_Date__c = Date.Today().addDays(10);
            assign2.Start_Date__c = Date.Today().addDays(-10);
            assign2.User__c = AdminUser.Id;
            portfAssignList.add(assign2);
            
            insert portfAssignList;
            TriggerHandler.bypass('OpportunityTriggerHandler');
            List<Opportunity> oppsobjlist = new List<Opportunity>();
            Opportunity optyObj ; // = new Opportunity();
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
            optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c Limit 1].Id;
            optyObj.Name = 'Test Drive';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = System.now().Time();
            optyObj.End_Time__c = System.now().Time()+1;
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj );
            
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu2'].Id;
            optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c Limit 1].Id;
            optyObj.Name = 'Test Drive2';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = System.now().Time();
            optyObj.End_Time__c = System.now().Time()+1;
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj );          
            
            insert oppsobjlist;
        }        
        
    }
    
    @isTest static void updateOppoSplitPortfolioBatchExecuteTest() {
        String soql = 'SELECT BSF_Portfolio__c,Id,OpportunityId,Opportunity.Name,SplitOwnerId FROM OpportunitySplit' 
            +' WHERE (Opportunity.Drive_Date__c >= TODAY OR Opportunity.Drive_Date__c = NULL)'
            +' AND (Opportunity.StageName NOT IN (\'Excluded\',\'Withdrawn\',\'Closed\')'
            +' OR (Opportunity.StageName = \'Closed\' AND Opportunity.Drive_Status__c NOT IN (\'Completed\',\'Cancel\')))';
        Id adminprofileid = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id ;
        User adminuser = [ select Id from User where ProfileId =: adminprofileid and isActive = true limit 1];        
        
        System.runAs( adminuser ){
            
            Id drdprofileid = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id ;
        	User drduser = [ select Id from User where ProfileId =: drdprofileid and isActive = true limit 1];
            
            List<Portfolio_Assignment__c> portAssignList = [SELECT Id,Name,Assignment_Type__c,BSF_Portfolio__c,End_Date__c,Start_Date__c,User__c FROM Portfolio_Assignment__c];          
            
            BSF_Portfolio__c Portland_OR_AM_01 = [SELECT Id, Name FROM BSF_Portfolio__c WHERE NAME = 'Portland OR AM 01'];
            
            portAssignList[0].Start_Date__c = Date.Today().addDays(10);
            portAssignList[0].End_Date__c = Date.Today().addDays(20);
            portAssignList[1].Start_Date__c = Date.Today().addDays(10);
            portAssignList[1].End_Date__c = Date.Today().addDays(20);
            
            Portfolio_Assignment__c validAssign1 = new Portfolio_Assignment__c();
            validAssign1.Assignment_Type__c = 'Account Manager';
            validAssign1.BSF_Portfolio__c = Portland_OR_AM_01.id;
            validAssign1.End_Date__c = Date.Today().addDays(10);
            validAssign1.Start_Date__c = Date.Today().addDays(-10);
            validAssign1.User__c = drduser.Id;
            portAssignList.add(validAssign1);
            
            upsert portAssignList;
            
            Test.startTest();
            UpdateOppoSplitPortfolioBatch c = new UpdateOppoSplitPortfolioBatch(soql);
            Database.executeBatch(c);
            Test.stopTest();
        }
    }
    
    @isTest static void updateOppoSplitPortfolioBatchScheduleTest() {
        String soql = 'SELECT BSF_Portfolio__c,Id,OpportunityId,Opportunity.Name,SplitOwnerId FROM OpportunitySplit' 
            +' WHERE (Opportunity.Drive_Date__c >= TODAY OR Opportunity.Drive_Date__c = NULL)'
            +' AND (Opportunity.StageName NOT IN (\'Excluded\',\'Withdrawn\',\'Closed\')'
            +' OR (Opportunity.StageName = \'Closed\' AND Opportunity.Drive_Status__c NOT IN (\'Completed\',\'Cancel\')))';
        Test.StartTest();
        
        UpdateOppoSplitPortfolioBatch sh1 = new UpdateOppoSplitPortfolioBatch(soql);
        String sch = '0 0 23 * * ?';
        system.schedule('Test schexample', sch, sh1);
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