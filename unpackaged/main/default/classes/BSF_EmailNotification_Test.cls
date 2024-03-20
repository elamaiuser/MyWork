@isTest
public class BSF_EmailNotification_Test {
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

    static testMethod void testSendEmail() {
        
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
        
        Contact contact = new Contact (firstname='Test Contact First',lastname='TestContactLast');
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
		insert opp;
        
        
        List<Task> taskList1 = new List<Task>();
        Task t4 = new Task();
		t4.OwnerId = UserInfo.getUserId();
        t4.whatId =  opp.Id;
		t4.Subject='Send Letter';
		t4.Status='Not Started';
		t4.Priority='Normal';
        taskList1.add(t4);
        insert taskList1;

        BSF_EmailNotification.Request request = new BSF_EmailNotification.Request();
        request.taskId = taskList1[0].Id;
        List<BSF_EmailNotification.Request> requests = new List<BSF_EmailNotification.Request>{request};

        Test.startTest();

        BSF_EmailNotification.sendEmail(requests);

        Test.stopTest();

       }
}