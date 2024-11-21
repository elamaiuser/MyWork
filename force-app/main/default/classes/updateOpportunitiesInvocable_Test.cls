@isTest
public class updateOpportunitiesInvocable_Test {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Fixed Site Account';
    public static String fixedOppRecType = 'Fixed Site Opp';
    public static String taskRecType = '72 Hour Check In'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static List<Id> taskIds = new List<Id>();
    
    @testSetup
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );
    }
    
    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
    static testMethod void testUpdateBloodDriveFromFlow(){
        
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        List<Account> mobileAccList = new List<Account>();
        Account accobj;
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';
        mobileAccList.add(accobj);
        insert mobileAccList;
		
        // create contact
        Contact contact = new Contact (firstname='Test Contact First',lastname='TestContactLast');
        contact.MailingStreet = '1104 Westcrt ln, Apt 213';
        contact.MailingCity = 'iamndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218';
        contact.Email = 'testContact@gmail.com';
		contact.Original_Service_Date__c = system.today().addDays(3);
		contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.AccountId = mobileAccList[0].id;
        insert contact;

        // create opportunity
        TriggerHandler.bypass('OpportunityTriggerHandler');
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.AccountId = mobileAccList[0].id;
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
        opp.Is_Template__c = true;
        opp.Template_Status__c='Active';
        opp.Send_Emails__c = false;
        opp.Send_Mailers__c = false;
        opp.Web_Scheduling_Enabled__c  = false;
        opp.Publish_to_Call_Center__c = false;
        oppList.add(opp);
		insert oppList ;
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = mobileAccList[0].id;
        opp1.StageName = 'Withdrawn';
        //opp1.Drive_Site__c = site.id;
        opp1.Drive_Name__c = 'Test Drive 2';
        opp1.Drive_Date__c = System.today().addDays(30);
        opp1.CloseDate = System.today();
        opp1.Call_List_Recipient_Exist__c = true;
        Time startTime1 = Time.newInstance(10, 0, 0, 0);
        opp1.Start_Time__c = startTime1;
        Time endTime1 = Time.newInstance(15, 30, 0, 0);
        opp1.Flow_Start_Time_Field__c = '1000';
        opp1.Accept_56_Day_Rule_Violation__c = true;
        opp1.Flow_End_Time_Field__c = '1530';
        opp1.WB_Projected_Procedures__c = 4;
        opp1.X2RBC_Projected_Procedures__c = 2;
        opp1.Name = 'Test Opportunity 2';
        opp1.Anticipated_Registered_Donors__c = 25;
        opp1.Send_Emails__c = true;
        opp1.Send_Mailers__c = true;
        opp1.Web_Scheduling_Enabled__c  = false;
        opp1.Publish_to_Call_Center__c = false;
        opp1.Parent_Template_Id__c = oppList[0].id;        
        insert opp1;
		

        

        Test.startTest();
        
        updateOpportunitiesInvocable.updateBloodDriveFromFlow(new List<Id>{oppList[0].Id});

        Test.stopTest();

        Opportunity updatedFutureOpp = [SELECT Id, Publish_to_Call_Center__c, Send_Emails__c, Send_Mailers__c, Web_Scheduling_Enabled__c 
                                         FROM Opportunity 
                                         WHERE Id = :opp1.Id];

        System.assertEquals(oppList[0].Publish_to_Call_Center__c, updatedFutureOpp.Publish_to_Call_Center__c);
        System.assertEquals(oppList[0].Send_Emails__c, updatedFutureOpp.Send_Emails__c);
        System.assertEquals(oppList[0].Send_Mailers__c, updatedFutureOpp.Send_Mailers__c);
        System.assertEquals(oppList[0].Web_Scheduling_Enabled__c, updatedFutureOpp.Web_Scheduling_Enabled__c);
    
    }
}