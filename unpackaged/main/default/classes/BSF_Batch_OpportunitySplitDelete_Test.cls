@isTest
public class BSF_Batch_OpportunitySplitDelete_Test {
    
    public static String rolename = 'West_BDM';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileSiteRecType = 'Mobile Site';    
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
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
            
            //create account
            List<Account> mobileAccList = new List<Account>();
        	Account accObj;
        	accObj = new Account();
        	accObj.RecordTypeId = accRecTypeId;
        	accObj.Name = 'Exavalu';
            accobj.Internal_Name__c = 'Exavalu';
        	accObj.BillingPostalCode = '30622';            
        	mobileAccList.add(accobj); 
        
        	accObj = new Account();
        	accObj.RecordTypeId = accRecTypeId;
        	accObj.Name = 'Exavalu2';
            accobj.Internal_Name__c = 'Exavalu2';
        	accObj.BillingPostalCode = '30623';            
        	mobileAccList.add(accobj);
            
        	insert mobileAccList;
            
            // create account team member
            List<AccountTeammember> atmList = new List<AccountTeammember>();
      		AccountTeammember atm;
      		atm = new AccountTeammember();
      		atm.AccountAccessLevel = 'Edit';
      		atm.CaseAccessLevel = 'Edit';
      		atm.OpportunityAccessLevel = 'Edit';
      		atm.userId = DRDAMUser.Id ;
      		atm.AccountId = mobileAccList[0].Id ;
      		atm.TeamMemberRole = 'Account Specialist';
            atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
      		atm.End_Date__c = Date.Today().addDays(10);
	  		atm.Start_Date__c = Date.Today().addDays(-10);
      		atmList.add(atm);      
      		insert atmList;
            
            // create contact
            Contact conObj = new Contact();
            conObj.AccountId = mobileAccList[0].Id;
            conObj.FirstName = 'Test';
            conObj.LastName = 'Contact';
            conObj.Email = 'testContact@gmail.com';
        	conObj.Original_Service_Date__c = system.today().addDays(3);
        	conObj.Primary_Phone__c = 'Mobile Phone';
        	conObj.MobilePhone = '752-781-0090';
            conObj.MailingCity = 'Ashburn';
            conObj.MailingCountryCode ='US';
            conObj.MailingPostalCode = '20148';
            conObj.MailingStateCode = 'VA';
            conObj.MailingStreet = '23070 Learning Cir';
            insert conObj;
            
            sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type';            
            insert skedTag; 
            
            //create sked_Location__c
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
            siteObj.sked_Address_1__c = 'Test Site Address 1';  
        	siteObj.sked_County__c = 'USA';
        	siteObj.sked_City__c = 'Aubum';
        	siteObj.sked_State__c = 'Alabama';
        	siteObj.sked_Zip_Code__c = '36801';
        	siteObj.sked_Wireless_Policy__c = 'Accepted';
        	siteObj.Source__c = 'Custom New Form';
            insert siteObj;
            
            //create opportunity
            List<Opportunity> oppsobjlist = new List<Opportunity>();
            Opportunity optyObj  = new Opportunity();          
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
            oppsobjlist.add( optyObj );
            insert oppsobjlist;    
        }
    }
        
        @isTest static void oppSplitDelete() { 
            
            Id adminprofileid = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id ;
	  		User adminuser = [ select Id from User where ProfileId =: adminprofileid and isActive = true limit 1];
            
            Id drdprofileid = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id ;
			User drduser = [ select Id from User where ProfileId =: drdprofileid and isActive = true limit 1];
            
            System.runAs( adminuser ){
                List<Opportunity> opps = new List<Opportunity>();
        		opps = [ select Id from Opportunity limit 20];
  				
                //create opportunity split
                List<OpportunitySplit> opsplits = new List<OpportunitySplit>();                
        		OpportunitySplit opsplit;
                opsplit = new OpportunitySplit();
       			opsplit.OpportunityId = opps[0].Id;
        		opsplit.Is_Covering_Incentive__c = false;
        		opsplit.SplitNote = 'test';
        		opsplit.Split_Amount__c = 20;
        		opsplit.Split_Reason__c = 'Coverage Vacancy';
                opsplit.SplitOwnerId = drduser.Id ;
        		opsplits.add( opsplit );
                insert opsplits;
                
                // create opportunity team member
                List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
                OpportunityTeamMember otm = new OpportunityTeamMember();
                otm.OpportunityId = opps[0].Id;
                otm.TeamMemberRole = 'District Manager';
                otm.UserId = drduser.Id;
                otm.Start_Date__c = system.today();
                otmList.add(otm);
                insert otmList;
                
                Test.startTest();
                
                BSF_Batch_OpportunitySplitDelete batchDelete = new BSF_Batch_OpportunitySplitDelete(opsplits , otmList);
                database.executeBatch(batchDelete);
                
                Test.stopTest();       
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