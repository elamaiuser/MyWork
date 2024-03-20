@isTest
public class OpportunitySplitTriggerTestInfo {
    /*
    public static String rolename = 'West_BDM';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileSiteRecType = 'Mobile Site';    
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        recordTypeMap = recordTypeMap( 'Opportunity' );
        //System.debug( '#debug#1 is ' + recordTypeMap );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        
        recordTypeMap = recordTypeMap( 'Account' );
       // System.debug( '#debug#1 is ' + recordTypeMap );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        //System.debug( '#debug#1 is ' + recordTypeMap );
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
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
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
      atm.Coverage_Reason__c = 'Vacant Territory';  
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
      atm.Coverage_Reason__c = 'Vacant Territory';  
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
      atm.Coverage_Reason__c = 'Vacant Territory';  
      atmList.add(atm);
      
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
            conObj.Email = 'test@gmail.com';
            conObj.MobilePhone = '999-999-9999';
            conObj.Primary_Phone__c = 'Mobile Phone';
            insert conObj;
            
            sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type'; 
            
            insert skedTag; 
            
            
            sked__Location__c siteObj = new sked__Location__c();
            siteObj.RecordTypeId = siteRecTypeId;
            siteObj.Name = 'Test Site';
            siteObj.sked__Address__c = 'Test Site Address';
            siteObj.sked_Address_1__c = 'Test Site Address';
            siteObj.sked_City__c = 'Test';
            siteObj.sked_State__c = 'Test';
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            siteObj.sked_Zip_Code__c = '12345';
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
            siteObj.sked_Site_Main_Phone__c = '999-999-9999';
            siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj.sked_Pay_for_Parking__c = 'Other';
            siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            siteObj.Source__c = 'Custom New Form';
            insert siteObj;
            
            List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
      
      BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();      
      Portland_OR_AM_01.Name='Portland OR AM 01';
      Portland_OR_AM_01.Account_Based_Portfolio__c= true;      
      Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
      Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
      Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
      Portland_OR_AM_01.Portfolio_Type__c='Account Manager';
      //Portland_OR_AM_01.Taxonomy_Type__c='Account';
      Portland_OR_AM_01.Territory_Portfolio__c=false;      
      bsfPortf.add(Portland_OR_AM_01);
      
      BSF_Portfolio__c Greater_Alleghenies_DRA_01 = new BSF_Portfolio__c();
      Greater_Alleghenies_DRA_01.Name='Greater Alleghenies DRA 01';
      Greater_Alleghenies_DRA_01.Account_Based_Portfolio__c = true;
      Greater_Alleghenies_DRA_01.External_Key__c='Booking Support_BD32_27E_Greater Alleghenies DRA 01';
      Greater_Alleghenies_DRA_01.Portfolio_Code__c='Greater Alleghenies DRA 01';
      Greater_Alleghenies_DRA_01.Portfolio_Name__c='Greater Alleghenies DRA 01';
      Greater_Alleghenies_DRA_01.Portfolio_Type__c=BSF_Constants.Booking_Support;
     // Greater_Alleghenies_DRA_01.Taxonomy_Type__c='Booking Support';
      Greater_Alleghenies_DRA_01.Territory_Portfolio__c= false;
      bsfPortf.add(Greater_Alleghenies_DRA_01);
      
      BSF_Portfolio__c American_Red_Cross = new BSF_Portfolio__c();
      American_Red_Cross.Name='American Red Cross';
      American_Red_Cross.Account_Based_Portfolio__c=true;
      American_Red_Cross.External_Key__c='National Account_1';
      American_Red_Cross.Portfolio_Code__c='1';
      American_Red_Cross.Portfolio_Name__c='American Red Cross';
      American_Red_Cross.Portfolio_Type__c='National Account Manager';
     // American_Red_Cross.Taxonomy_Type__c='National Account';
      American_Red_Cross.Territory_Portfolio__c=false;
      bsfPortf.add(American_Red_Cross);
      
      BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
      Sickle_Cell_AM_04.Name='Sickle Cell AM 04';
      Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
      Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
      Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
      Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
      Sickle_Cell_AM_04.Portfolio_Type__c='District Manager';
      //Sickle_Cell_AM_04.Taxonomy_Type__c='Sickle Cell';
      Sickle_Cell_AM_04.Territory_Portfolio__c=false;
      bsfPortf.add(Sickle_Cell_AM_04);
      
      insert bsfPortf;
      
      List<Portfolio_Assignment__c> portfAssignList = new List<Portfolio_Assignment__c>();
      
      Portfolio_Assignment__c assign1 = new Portfolio_Assignment__c();
      assign1.Assignment_Type__c = 'District Manager';
      assign1.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
      assign1.End_Date__c = Date.Today().addDays(10);
      assign1.Start_Date__c = Date.Today().addDays(-10);
      assign1.User__c = DRDAMUser.Id;
      portfAssignList.add(assign1);

            
            insert portfAssignList;
            
            List<Opportunity> oppsobjlist = new List<Opportunity>();
            Opportunity optyObj ; // = new Opportunity();
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
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
            
            oppsobjlist.add( optyObj );
            
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu2'].Id;
            optyObj.Drive_Site__c = siteObj.Id;
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
  }*/
    
    @isTest static void allowSpecificProfileUsers() {        
          /*
      Id adminprofileid = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id ;
    User adminuser = [ select Id from User where ProfileId =: adminprofileid and isActive = true limit 1];
      
      System.runAs( adminuser ){
        List<Opportunity> opps = new List<Opportunity>();
        opps = [ select Id from Opportunity limit 20];
        
        List<OpportunitySplit> opsplits = new List<OpportunitySplit>();                
        OpportunitySplit opsplit;
                
                opsplit = new OpportunitySplit();
        opsplit.OpportunityId = opps[0].Id;
        opsplit.Is_Covering_Incentive__c = false;
        opsplit.SplitNote = 'test';
        opsplit.Split_Amount__c = 20;
        opsplit.Split_Reason__c = 'Coverage Vacancy';
          opsplit.SplitOwnerId = adminuser.Id;
                opsplits.add( opsplit );
                
                opsplit = new OpportunitySplit();
        opsplit.OpportunityId = opps[1].Id;
        opsplit.Is_Covering_Incentive__c = false;
        opsplit.SplitNote = 'test';
        opsplit.Split_Amount__c = 20;
        opsplit.Split_Reason__c = 'Coverage Vacancy';
          opsplit.SplitOwnerId = adminuser.Id;
                opsplits.add( opsplit );
                
                try{
                    insert opsplits[0];
                }catch(Exception e){
                    String exceptionmsg = 'Only Account Specialist or District Manager is allowed to edit and apply. Currently there are no Account Specialist avaialble in Account Team';
                    String exceptionmsg2 = 'Only Account Specialist and District Managers are allowed to edit Opportunity Split';
                    //System.debug( 'exc msg=>' + e.getMessage() );
                    String excmsg = e.getMessage();
                    System.assert( excmsg.contains( exceptionmsg2 ) );
                }
                
                try{
                    insert opsplits[1];
                }catch(Exception e){
                    String exceptionmsg = 'Only Account Specialist or District Manager is allowed to edit and apply. Currently there are no Account Specialist avaialble in Account Team';
                    String exceptionmsg2 = 'Only Account Specialist and District Managers are allowed to edit Opportunity Split';
                    //System.debug( 'exc msg=>' + e.getMessage() );
                    String excmsg = e.getMessage();
                    System.assert( excmsg.contains( exceptionmsg ) );
                }
        
      
      
      }
         */   
    }
  
  /*@isTest static void addTeamMemberPortfolioTest() {
    
    Id adminprofileid = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id ;
    User adminuser = [ select Id from User where ProfileId =: adminprofileid and isActive = true limit 1];
    Id drdprofileid = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id ;
    User drduser = [ select Id from User where ProfileId =: drdprofileid and isActive = true limit 1];
      
    System.runAs( drduser ){
      List<Opportunity> opps = new List<Opportunity>();
      opps = [ select Id from Opportunity limit 20];

      List<OpportunitySplit> opsplits = new List<OpportunitySplit>();                
      OpportunitySplit opsplit;
          
          opsplit = new OpportunitySplit();
      opsplit.OpportunityId = opps[0].Id;
      opsplit.Is_Covering_Incentive__c = false;
      opsplit.SplitNote = 'test';
      opsplit.Split_Amount__c = 20;
      opsplit.Split_Reason__c = 'Coverage Vacancy';
      opsplit.SplitOwnerId = drduser.Id;
          opsplits.add( opsplit );
          
          opsplit = new OpportunitySplit();
      opsplit.OpportunityId = opps[1].Id;
      opsplit.Is_Covering_Incentive__c = false;
      opsplit.SplitNote = 'test';
      opsplit.Split_Amount__c = 20;
      opsplit.Split_Reason__c = 'Coverage Vacancy';
      opsplit.SplitOwnerId = adminuser.Id;
          opsplits.add( opsplit );
         System.assert( opsplits != null ); 
      insert opsplits;
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
    } */
    
}