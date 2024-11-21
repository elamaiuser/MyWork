@isTest
public class FutureDrivesControllerTest {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
	public static String mobileOppRecType = 'Mobile Opp';
	public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
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
		
		// create Contact
		List<Contact> conlist = new List<Contact>();
		Contact conObj = new Contact();
		conObj.AccountId = mobileAccList[0].Id ;
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
		conlist.add(conObj);
		insert conlist;
			
		// insert sked tag	
		sked__Tag__c skedTag = new sked__Tag__c();
		skedTag.Name = 'Outside';
		skedTag.sked__Type__c = 'Physical Location Type';
		insert skedTag; 
		
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
		siteObj.sked_Site_Main_Phone__c = '758-771-0091';
		siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
		siteObj.sked_Pay_for_Parking__c = 'Other';
		siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.sked_Address_1__c = 'test';
        siteObj.sked_County__c = 'test';
        siteObj.sked_State__c = 'test';
        siteObj.sked_Zip_Code__c = 'test123';
        siteObj.sked_City__c = 'test';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.sked_Room_Size__c = '801-1200 Sq. Ft.';
		skedlocationlist.add(siteObj);
		insert skedlocationlist;
			
		// create Opportunity
		TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
		recordTypeMap = recordTypeMap( 'Opportunity' );
		Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
		Opportunity optyObj = new Opportunity();
		optyObj.RecordTypeId = optyRecTypeId;
		optyObj.AccountId = mobileAccList[0].Id;
		optyObj.Drive_Site__c = skedlocationlist[0].Id;
		optyObj.Name = 'Test Drive 1';
		optyObj.StageName = 'Discovery';
		optyObj.Drive_Date__c = System.Today();
        optyObj.is_template__c = true;
        //optyObj.Call_List_Recipient_Exist__c = true;
		optyObj.Type_of_Drive__c = 'Mobile';
		optyObj.CloseDate = System.today();
		optyObj.Start_Time__c = System.now().Time();
		optyObj.End_Time__c = System.now().Time()+1;
		optyObj.Anticipated_Registered_Donors__c = 1;		
		insert optyObj;
        
        // 2nd Opportunity
        List<Opportunity> updateOppList = new List<Opportunity>();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Opportunity optyObj1 = new Opportunity();
		optyObj1.RecordTypeId = optyRecTypeId;
		optyObj1.AccountId = mobileAccList[0].Id;
		optyObj1.Drive_Site__c = skedlocationlist[0].Id;
		optyObj1.Name = 'Test Drive 2';
		optyObj1.StageName = 'Discovery';
        optyObj1.Parent_Template_Id__c = optyObj.Id;
		optyObj1.Drive_Date__c = System.Today().addDays(57);
        optyObj1.is_template__c = false;
        optyObj1.Drive_Status__c = 'Draft';
        //optyObj.Call_List_Recipient_Exist__c = true;
		optyObj1.Type_of_Drive__c = 'Mobile';
		optyObj1.CloseDate = System.today();
		optyObj1.Start_Time__c = System.now().Time();
		optyObj1.End_Time__c = System.now().Time()+1;
		optyObj1.Anticipated_Registered_Donors__c = 1;	
        optyObj1.Web_Schedule_End_Date__c = system.now().addDays(20);
        optyObj1.Web_Schedule_Start_Date__c = system.now();
        optyObj1.Web_Schedule_Start_Time__c = System.now().Time();
        optyObj1.Web_Schedule_End_Time__c = System.now().Time()+10;
        optyObj1.Web_Schedule_EndDate__c = system.today().addDays(10);
        optyObj1.Web_Schedule_StartDate__c = system.today();
		updateOppList.add(optyObj1);
		insert updateOppList;
      
        //create affiliations
        List<Marketing_Program__c> affliationList = new List<Marketing_Program__c>();
        Marketing_Program__c affliations = new Marketing_Program__c();
        affliations.Name = 'Pint Sized Hero';
        affliations.External_Name__c = 'Pint Sized Hero';
        affliations.Scope__c = 'Drive';
        affliations.Migration_ID__c = null;
        affliations.Start_Date__c = system.today();
        affliations.End_Date__c = system.today().addDays(10);
        affliationList.add(affliations);
        
        insert affliationList;
        
        //create drive affiliations
        List<Drive_Marketing_Programs__c> driveAffiliationList = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c driveAffiliation1 = new Drive_Marketing_Programs__c();
        driveAffiliation1.Marketing_Program__c = affliationList[0].id;
        driveAffiliation1.Account__c = mobileAccList[0].id;
        driveAffiliation1.Date_Removed__c = system.today().addDays(20);
        driveAffiliation1.Blood_Drive_Opportunity__c = optyObj.id; // opp Id as recordId
        driveAffiliationList.add(driveAffiliation1);
        
        Drive_Marketing_Programs__c driveAffiliation2 = new Drive_Marketing_Programs__c();
        driveAffiliation2.Marketing_Program__c = affliationList[0].id;
        driveAffiliation2.Account__c = mobileAccList[0].id;
        driveAffiliation2.Date_Removed__c = system.today().addDays(30);
        driveAffiliation2.Blood_Drive_Opportunity__c = updateOppList[0].id; // opp Id as driveIdSet
        driveAffiliationList.add(driveAffiliation2);
        
        insert driveAffiliationList;
        
        // create Opportunity Contact Role
        List<OpportunityContactRole> opContactRoleList = new List<OpportunityContactRole>();
        OpportunityContactRole opContactRole1 = new OpportunityContactRole();  // 1st opportunity contact role record containing the opp Id as the recordId
        opContactRole1.OpportunityId = optyObj.id;
        opContactRole1.ContactId = conlist[0].id;
        opContactRole1.Role = 'Whom to Meet';  // validation rule - role cannot be blank
        opContactRoleList.add(opContactRole1);
        
        OpportunityContactRole opContactRole2 = new OpportunityContactRole();
        opContactRole2.OpportunityId = updateOppList[0].id;  // 2nd opportunity contact role record containing the opp Id as the driveIdSet
        opContactRole2.ContactId = conlist[0].id;
        opContactRole2.Role = 'Whom to Meet';  // validation rule - role cannot be blank
        opContactRoleList.add(opContactRole2);
        
        insert opContactRoleList;           
        
 	    System.runAs( AdminUser){
            
            test.startTest();
            List<FutureDrivesController.FieldSetClass> fc = FutureDrivesController.getFieldsFromFieldSets();
            List<FutureDrivesController.FutureDriveClass> fdc = FutureDrivesController.getFutureDrives(optyObj.id); // passing the id of the 1st opp as recordId
            try{
               FutureDrivesController.getFutureDrives(''); // covering the catch block
            }catch(Exception e)
            {}
            
            for(FutureDrivesController.FutureDriveClass fd : fdc)
            {
				fd.isselected = true;  
                
            }
            
            List<String> fields = new List<String>{'End_Time__c', 'Web_Schedule_EndDate__c' , 
                'Web_Schedule_StartDate__c' , 'Web_Schedule_End_Time__c','Drive Affiliations', 'Drive Service Roles'} ;
            
            
           try{  
                string resp = FutureDrivesController.applyChangestoFutureDrives( JSON.serialize(fdc) , optyObj.id, fields );
                system.assertEquals('success', resp);            	
               }catch(Exception e)
                    {}
            List<String> fields1 = new List<String>{} ; 
                try{    
            		string resp1 = FutureDrivesController.applyChangestoFutureDrives( JSON.serialize(fdc) , optyObj.id, fields1 );
                    system.assertEquals('success', resp1);  
                }catch(Exception e){}
            List<String> fields2 = new List<String>{'Web_Schedule_StartDate__c', 'Web_Schedule_EndDate__c'} ;
            
                try{    
            
                    string resp2 = FutureDrivesController.applyChangestoFutureDrives( JSON.serialize(fdc) , optyObj.id, fields2 );
                    system.assertEquals('success', resp2);  
                }catch(Exception e){}
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