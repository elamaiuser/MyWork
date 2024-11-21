/* the following test class is covering the below classes - 
 * 1. createPreDriveTaskBatch batch class 
 * 2. createdPreDriveTaskSchedule schedulable class
 * */

@isTest(SeeAllData = false)
public class createPreDriveTaskBatchTest
{

    public static String mobileAccRecType = 'Mobile Account';
	public static String mobileOppRecType = 'Mobile Opp';
	public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){   
        
		// insert admin user - system admin        
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
        insert AdminUser ;
        
        // insert DRD User - AM
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'DRD AM',
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
        
        //creating required lists 
        List<Account>accountList=new List<Account>();
        List<AccountTeamMember> accTeamList = new List<AccountTeamMember>();
        List<Contact>contactList=new List<Contact>();
        List<sked__Location__c> siteList=new List<sked__Location__c>();
        List<Opportunity> oppList=new List<Opportunity>();
        List<sked_Drive__c> driveList = new List<sked_Drive__c>();
        List<OpportunityContactRole> oppServiceRoleList=new List<OpportunityContactRole>();
        List<Task> preDriveSecurityTaskList = new List<Task>();
        
        // insert account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        Account accObj = new Account();
        accObj.RecordTypeId = recTypeId;
        accObj.Name = 'Exavalu';
        accObj.Internal_Name__c = 'EXAVALU';
        accObj.BillingPostalCode = '30146'; 
        accountList.add(accObj);
        insert accountList;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        
		// insert Account Team and add DRDAMUser		
        AccountTeamMember atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = accountList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = system.today();
        atm.End_Date__c = system.today()+50;
        atm.Is_Covering_Recruiter__c = true;
        accTeamList.add(atm);
        insert accTeamList;
        
        // insert Contact
		Contact conObj ;
        conObj = new Contact();
		conObj.AccountId = accountList[0].Id ;
		conObj.FirstName = 'Test';
		conObj.LastName = 'Contact1';
        conObj.Email = 'testContact1@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
		conObj.MailingCity = 'Ashburn';
		conObj.MailingCountryCode ='US';
		conObj.MailingPostalCode = '20148';
		conObj.MailingStateCode = 'VA';
		conObj.MailingStreet = '23070 Learning Cir';
		contactList.add(conObj);
        
        conObj = new Contact();
		conObj.AccountId = accountList[0].Id ;
		conObj.FirstName = 'Test';
		conObj.LastName = 'Contact2';
        conObj.Email = 'testContact2@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(5);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0098';
		conObj.MailingCity = 'Ashburn';
		conObj.MailingCountryCode ='US';
		conObj.MailingPostalCode = '20148';
		conObj.MailingStateCode = 'VA';
		conObj.MailingStreet = '23070 Learning Cir';
		contactList.add(conObj);
        
		insert contactList;
        
        // insert sked__Location__c
		recordTypeMap = recordTypeMap( 'sked__Location__c' );
		Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
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
		siteObj.sked_Site_Contact__c = contactList[0].Id;
		siteObj.sked_Site_Main_Phone__c = '758-771-0091';
		siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
		siteObj.sked_Pay_for_Parking__c = 'Other';
		siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';        
        siteObj.sked_Address_1__c = 'Test Site Address 1';  
        siteObj.sked_County__c = 'USA';
        siteObj.sked_City__c = 'Aubum';
        siteObj.sked_State__c = 'Alabama';
        siteObj.sked_Zip_Code__c = '36801';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Pre_Drive_Security_Due_Date__c = '14';
        siteObj.Sponsor_Security_Form_Required__c = 'Pre-Drive';
        siteObj.sked_Staff_List__c='Staff Full Names';
        siteObj.sked_Security_Directions__c = 'I got it';
        siteList.add(siteObj);
        insert siteList;
        
        // insert Opportunity
		recordTypeMap = recordTypeMap( 'Opportunity' );
		Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
		Opportunity optyObj = new Opportunity();
		optyObj.RecordTypeId = optyRecTypeId;
		optyObj.AccountId = accountList[0].Id;
		optyObj.Drive_Site__c = siteList[0].Id;
		optyObj.Name = 'Test Drive';
		optyObj.StageName = 'Closed';
		optyObj.Drive_Date__c = System.today().addDays(27); // within 28 days
        optyObj.Drive_Status__c = 'Confirmed';
		optyObj.Type_of_Drive__c = 'Mobile';
		optyObj.CloseDate = System.today();
		optyObj.Start_Time__c = System.now().Time();
		optyObj.End_Time__c = System.now().Time()+1;
		optyObj.Anticipated_Registered_Donors__c = 1;	
		optyObj.X2RBC_Projected_Procedures__c = 1;
		optyObj.WB_Projected_Procedures__c = 2;
		optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
		optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Account_Manager__c = accTeamList[0].userId; //DRD User
        oppList.add(optyObj);
        Triggerhandler.bypass('OpportunityTriggerHandler');
        insert oppList;
        Triggerhandler.clearBypass('OpportunityTriggerHandler');
        //insert Drives on Calendar
        sked_Drive__c doc = new sked_Drive__c();
        doc.sked_Account__c = accountList[0].id;
        doc.Name = 'Test DOC';
        doc.sked_Drive_Site__c = siteList[0].id ;
        doc.sked_Opportunity__c = oppList[0].id;
        driveList.add(doc);
        insert driveList;
        
        // insert opportunity contact role 1. Primary Contact to have opp.Stagename = 'Closed' ; 2. Security List Recipient for this batch
        OpportunityContactRole ocrObj ;
        ocrObj = new OpportunityContactRole();
        ocrObj.OpportunityId = oppList[0].id;
        ocrObj.ContactId = contactList[0].id;
        ocrobj.Role = 'Primary Contact';
        oppServiceRoleList.add(ocrobj);
        
        ocrObj = new OpportunityContactRole();
        ocrObj.OpportunityId = oppList[0].id;
        ocrObj.ContactId = contactList[1].id;
        ocrobj.Role = 'Security List Recipient';
        oppServiceRoleList.add(ocrobj);
        
        insert oppServiceRoleList;
                        
    }
    
    @isTest
    static  void testCreatePreDrivebatch()
    {
        Test.startTest();
        createdPreDriveTaskSchedule b = new createdPreDriveTaskSchedule();
        string sch = '0 0 2 * * ?';
        System.Schedule('TEST CREATE PRE DRIVE TASK BATCH',sch,b);
        
        createPreDriveTaskBatch c = new createPreDriveTaskBatch();
        database.executebatch(c);
        
        //integer taskCount=[Select count() from Task where subject='Security Information Completion'];
        //System.assertEquals(1,taskCount);
        
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