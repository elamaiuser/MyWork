/*
 * This Test class covering the following Classes
 * FutureDrivesController 
 * */
@isTest
public class FutureDrivesController_Test {
	public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
	public static String mobileOppRecType = 'Mobile Opp';
	public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();
    
    @isTest static void Method1() {
        // create user 
		
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
        
        //UserRole urole  = [select id from userrole where developername =: rolename ];
        
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
             LocaleSidKey = 'en_US'
        );
        
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
		
		
		
		
		
		// create Account
		recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        System.debug( 'recTypeId is ' + recTypeId );
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';        
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
        //insert atmList;
		
		
		// To Create opportunity multiple data setup requited, location object
		
		// create Contact
		List<Contact> conlist = new List<Contact>();
		Contact conObj = new Contact();
		conObj.AccountId = mobileAccList[0].Id ;
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
		conlist.add(conObj);
		insert conlist;
			
		// insert sked tag	
		sked__Tag__c skedTag = new sked__Tag__c();
		skedTag.Name = 'Outside';
		skedTag.sked__Type__c = 'Physical Location Type';
		insert skedTag; 
 			
			// sked_Date_Site_Inspection_Completed__c
		// create sked location
		siterecordTypeMap = recordTypeMap( 'sked__Location__c' );
		Id siteRecTypeId = siterecordTypeMap.get(mobileSiteRecType);
		List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
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
        siteObj.Source__c = 'Custom New Form';
		skedlocationlist.add(siteObj);
		insert skedlocationlist;
			
		// create Opportunity
		opprecordTypeMap = recordTypeMap( 'Opportunity' );
		Id optyRecTypeId = opprecordTypeMap.get(mobileOppRecType);
		List<Opportunity> opplist = new List<Opportunity>();
		Opportunity optyObj ;
        
        // 1st Opportunity
        optyObj = new Opportunity();
		optyObj.RecordTypeId = optyRecTypeId;
		optyObj.AccountId = mobileAccList[0].Id;
		optyObj.Drive_Site__c = skedlocationlist[0].Id;
		optyObj.Name = 'Test Drive';
		optyObj.StageName = 'Discovery';
		optyObj.Drive_Date__c = System.today();
        optyObj.is_template__c = true;
        optyObj.Call_List_Recipient_Exist__c = true;
		optyObj.Type_of_Drive__c = 'Mobile';
		optyObj.CloseDate = System.today();
		optyObj.Start_Time__c = System.now().Time();
		optyObj.End_Time__c = System.now().Time()+2;
		optyObj.Anticipated_Registered_Donors__c = 1;	
		// fields to calculate Total Products projected
		optyObj.X2RBC_Projected_Procedures__c = 1;
		optyObj.WB_Projected_Procedures__c = 2;
		optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
		optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Web_Scheduling_Start_Date_Offset__c=1;
        optyObj.Web_Scheduling_End_Date_Offset__c=0;
        optyObj.Web_Scheduling_End_Time_Offset__c=0;
		
		opplist.add(optyObj);
        
        // 2nd Opportunity
        optyObj = new Opportunity();
		optyObj.RecordTypeId = optyRecTypeId;
		optyObj.AccountId = mobileAccList[0].Id;
		optyObj.Drive_Site__c = skedlocationlist[0].Id;
		optyObj.Name = 'Test Drive';
		optyObj.StageName = 'Discovery';
		optyObj.Drive_Date__c = System.today().AddDays(2);
        optyObj.is_template__c = false;
        optyObj.Call_List_Recipient_Exist__c = false;
		optyObj.Type_of_Drive__c = 'Mobile';
		optyObj.CloseDate = System.today();
		optyObj.Start_Time__c = System.now().Time();
		optyObj.End_Time__c = System.now().Time()+2;
		optyObj.Anticipated_Registered_Donors__c = 1;	
		// fields to calculate Total Products projected
		optyObj.X2RBC_Projected_Procedures__c = 1;
		optyObj.WB_Projected_Procedures__c = 2;
		optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
		optyObj.Platelet_Projected_Procedures__c = 1;
        opplist.add(optyObj);
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
		insert opplist;
        opportunity opp =opplist.get(1);
        opp.Parent_Template_Id__c = opplist[0].id;
        update opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        String sourceOppId = opplist[0].Id ;
       skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
		
        //This is added to cover 1084 AccountTeamMemberService methods--Starts
        /*AccountTeamMember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = DRDAMUser.Id ;
        atm2.AccountId = mobileAccList[0].Id;
        atm2.TeamMemberRole = 'District Manager';
        atm2.Start_Date__c = System.today();
        atm2.End_Date__c = System.today();
        atm2.Is_Covering_Recruiter__c = true;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);*/
        
        AccountTeamMember atm3 = new AccountTeammember();
        atm3.AccountAccessLevel = 'Edit';
        atm3.CaseAccessLevel = 'Edit';
        atm3.OpportunityAccessLevel = 'Edit';
        atm3.userId = AdminUser.Id ;
        atm3.AccountId = mobileAccList[0].Id;
        atm3.TeamMemberRole = 'Account Manager';
        atm3.Start_Date__c = System.today();
        atm3.End_Date__c = System.today();
        atm3.Is_Covering_Recruiter__c = true;
        atm3.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm3);
        
        
        insert atmList;
        
       Marketing_program__c mp=new Marketing_program__c();
        mp.name='abc';
        mp.External_Name__c='abctest';
        mp.Scope__c='drive';
        insert mp;
     
        // create drive affiliations
        List<Drive_Marketing_Programs__c> newDriveAffiliations = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c newDriveAff = new Drive_Marketing_Programs__c();
        newDriveAff.Migration_ID__c =null;//empty migration id
        newDriveAff.Blood_Drive_Opportunity__c = opplist[0].id;
        newDriveAff.Account__c = mobileAccList[0].Id;
        newDriveAff.Marketing_Program__c=mp.id; 
        newDriveAffiliations.add(newDriveAff);
        insert newDriveAffiliations;
        
        OpportunityContactRole ocr1 = new OpportunityContactRole();
                ocr1.ContactId = conlist[0].Id;
                ocr1.OpportunityId = opplist[0].id;
                ocr1.IsPrimary = true;
                ocr1.Role = 'Primary Contact';
                insert ocr1;
        
        test.startTest();
        System.runAs( AdminUser){
            List<FutureDrivesController.FieldSetClass> fc = FutureDrivesController.getFieldsFromFieldSets();
            List<FutureDrivesController.FutureDriveClass> fdc = FutureDrivesController.getFutureDrives(sourceOppId);
            
            for( FutureDrivesController.FutureDriveClass fdcitr : fdc ){
                fdcitr.isselected = true;
            }
            
            List<String> fields = new List<String>{'Call_List_Recipient_Exist__c','Drive Affiliations','Web_Schedule_EndDate__c','Web_Schedule_StartDate__c','Web_Schedule_End_Time__c','Drive Service Roles'} ;
            String resp = FutureDrivesController.applyChangestoFutureDrives( JSON.serialize( fdc ) , sourceOppId, fields );
            test.stopTest();
            System.assertEquals( 'success', resp);
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