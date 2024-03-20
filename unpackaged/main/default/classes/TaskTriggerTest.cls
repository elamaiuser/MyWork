/*
 * This Test class covering following classes 
 * TaskService 
 */
@isTest
public class TaskTriggerTest {
    
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Fixed Site Account'; 
    public static String fixedOppRecType = 'Fixed Site Opp';
    public static String taskRecType = '72 Hour Check In';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> taskrecordTypeMap  = new Map<String,Id>();
    public static List<Task> tasks = new List<Task>();
    public static Map<Id,Task> taskMap = new Map<Id,Task>();
	
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );
        opprecordTypeMap = opprecordTypeMap('Opportunity');
        taskrecordTypeMap = taskrecordTypeMap('Task');
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
    //Method to get the map of recordType Name as key and recordTypeId as value for opportunity records
    public static Map<String,Id> opprecordTypeMap(string obj){
        Map<String,Id> opprecTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                opprecTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return opprecTypeNameWithIdMap;
    }
    //Method to get the map of recordType Name as key and recordTypeId as value for Task records
    public static Map<String,Id> taskrecordTypeMap(string obj){
        Map<String,Id> taskrecTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                taskrecTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return taskrecTypeNameWithIdMap;
    }
    
    @isTest static void validateTask() {
        
        	/*skedTriggerHub.BypassInsertTriggers = true;
        	TriggerHandler.bypass('skedLinkedOpportunityDrivesHandler');*/
        
        	User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             FirstName='SystemAdmin',
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
             FirstName = 'Amy',
             LastName = 'Brown',
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
        
        // create account
        recordTypeMap = recordTypeMap( 'Account' );
		Id recTypeId = recordTypeMap.get(mobileAccRecType);
		List<Account> mobileAccList = new List<Account>();
		Account accobj;
		accobj = new Account();
		accobj.RecordTypeId = recTypeId;
		accobj.Name = 'Exavalu';
        accobj.Internal_Name__c = 'Exavalu';
		accobj.BillingPostalCode = '30146';
		mobileAccList.add(accobj);
		insert mobileAccList;
        
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
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '888-888-8888';
        insert contact;
        
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
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        insert atmList;
		
        // create site 
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'test Floor';
        site.sked_Room_Name__c = 'test Room';
        site.sked_National_Name__c = 'test National Name';
        site.sked_Automation_Suitability__c = 'Suitable';
        site.sked_Site_Main_Phone__c = '999-999-9999';
        site.sked_Site_Building_Name__c = 'test Building';
        site.sked_Physical_Location_Type__c = 'Inside';
        site.sked_Pay_for_Parking__c = 'Other';
        site.sked_Pay_for_Parking_Details__c = 'Other';
        site.sked_Wireless_Policy__c = 'Accepted';
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        site.sked_Room_Size__c = '801-1200 Sq. Ft.';
        site.sked_Staff_Personal_Parking_Directions__c = 'test';
        site.sked_Address_1__c = 'test';
        site.sked_Outside_stairs__c = 10;
        site.sked_County__c = 'test';
        site.sked_State__c = 'test';
        site.sked_Zip_Code__c = 'test123';
        site.sked_City__c = 'test';
        site.sked_Inside_stairs__c = 10;
        site.sked_Base_Description__c = 'test';
        site.sked_ARC_Vehicle_Parking_Directions__c = 'test';
        site.sked_Directions_From_CollectionOperation__c = 'test';
        site.sked_Start_Date__c = System.today();
        site.sked_End_Date__c = System.today()+5;
        site.Source__c = 'Custom New Form';
        insert site;
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Opportunity opp = new Opportunity();
        opp.AccountId = mobileAccList[0].id;
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = mobileAccList[0].id; 
        serviceRole.Contact__c = contact.Id;
        insert serviceRole;
        opp.StageName = 'Committed';
        opp.Drive_Site__c = site.id;
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
		insert opp;
        
        //create doc
        
        //TriggerHandler.bypass('skedDriveHandler');
        
        List<sked_Drive__c> docList = new List<sked_Drive__c>();
        sked_Drive__c doc = new sked_Drive__c();
        doc.sked_Account__c = mobileAccList[0].id;
        doc.Name = 'Test DOC';
        doc.sked_Drive_Site__c = site.id ;
        doc.sked_Opportunity__c = opp.id;
        docList.add(doc);
        insert docList;
        
        //TriggerHandler.clearBypass('skedDriveHandler');
        
        // create task
        taskrecordTypeMap = taskrecordTypeMap( 'Task' );
		Id taskrecTypeId = taskrecordTypeMap.get(taskRecType);
        List<Task> taskList = new List<Task>();
        Task t1 = new Task();
		t1.OwnerId = UserInfo.getUserId();
        t1.RecordTypeId = taskrecTypeId; 
        t1.whatId = mobileAccList[0].Id;
		t1.Subject='Call';
		t1.Status='Not Started';
		t1.Priority='Normal';
        taskList.add(t1);
        
        Task t2 = new Task();
		t2.OwnerId = UserInfo.getUserId();
        t2.RecordTypeId = taskrecTypeId; 
        t2.whatId = opp.Id;
		t2.Subject='Send Letter';
		t2.Status='Not Started';
		t2.Priority='Normal';
        taskList.add(t2);
        
        Task t3 = new Task();
		t3.OwnerId = UserInfo.getUserId();
        t3.RecordTypeId = taskrecTypeId; 
        t3.whatId = docList[0].Id;
        system.debug('Doc Id - '+t3.whatId);
        t3.Related_Account_Name__c = docList[0].sked_Account__r.Name ;
        t3.Related_Account_Id__c = docList[0].sked_Account__c ;
        t3.Related_Record_Name__c = docList[0].Name;
		t3.Subject='Send Letter';
		t3.Status='Not Started';
		t3.Priority='Normal';
        taskList.add(t3);
               
        Test.startTest();
            try{
                insert taskList;
                
            }catch(Exception e)
            {
                String errormsg = e.getMessage();
                System.assert( errormsg.contains('Cannot create 72 Hour Check In/Recruitment Meeting task for Fix Site Account/Opportunity.'));
            }
         
        
        List<Task> taskList1 = new List<Task>();
        Task t4 = new Task();
		t4.OwnerId = UserInfo.getUserId();
        t4.whatId =  docList[0].Id;
		t4.Subject='Send Letter';
		t4.Status='Not Started';
		t4.Priority='Normal';
        taskList1.add(t4);
        insert taskList1;

        taskList1[0].Related_Record_Name__c = taskList1[0].What.Name;
        update taskList1;                    
        Test.stopTest(); 
        
     }
}