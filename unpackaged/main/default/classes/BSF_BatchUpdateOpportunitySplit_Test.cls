/* 
 * Modification Log 
 * Date                      Developer Name              Comments
 * ***********************************************************************************************************************************************
 *  12/21/2023               Kishore Das                Test class for the batch BSF_BatchUpdateOpportunitySplit(HRP-11168)

 *************************************************************************************************************************************************
*/
@isTest
public class BSF_BatchUpdateOpportunitySplit_Test {
    public static String mobileAccRecType = 'Mobile Account';
    public static String fixedOppRecType = 'Fixed Site Opp';
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
    static testMethod void BSF_BatchUpdateOpportunitySplit1(){
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
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.AccountId = mobileAccList[0].id;
        opp.StageName = 'Committed';
        //opp.Drive_Site__c = site.id;
        opp.Drive_Name__c = 'Test Drive 1';
        opp.Drive_Date__c = System.today().addDays(20);
        opp.CloseDate = System.today().addDays(10);
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
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert oppList ;
        
        
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
        insert AdminUser;
        
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
            LocaleSidKey = 'en_US'
        );
        
    
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        List<AccountTeammember> atmList = new List<AccountTeammember>();
      AccountTeammember atm;
      atm = new AccountTeammember();
      atm.AccountAccessLevel = 'Edit';
      atm.CaseAccessLevel = 'Edit';
      atm.OpportunityAccessLevel = 'Edit';
      atm.userId = DRDAMUser.Id ;
      atm.AccountId = mobileAccList[0].Id ;
      atm.TeamMemberRole = 'Account Manager';
      atm.End_Date__c = Date.Today().addDays(40);
      atm.Start_Date__c = Date.Today().addDays(-10);
      atm.Coverage_Reason__c = 'Leave of Absence (LOA)';      
      atmList.add(atm);
      
      atm = new AccountTeammember();
      atm.AccountAccessLevel = 'Edit';
      atm.CaseAccessLevel = 'Edit';
      atm.OpportunityAccessLevel = 'Edit';
      atm.userId = DRDAMUser.Id ;
      atm.AccountId = mobileAccList[0].Id ;
      atm.TeamMemberRole = 'Account Manager';
      atm.End_Date__c = Date.Today().addDays(30);
      atm.Start_Date__c = Date.Today().addDays(+10);
      atm.Is_Covering_Recruiter__c = true;
      atm.Coverage_Reason__c = 'Vacant Territory';
      atmList.add(atm);
      skedHubBase.BypassInsertTriggers = true;
      TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
      insert atmList;
        
        List<AccountTeamMember> atmList2 = [SELECT Id, AccountId,UserId, AccountAccessLevel, OpportunityAccessLevel,
             CaseAccessLevel, Coverage_Reason__c, Start_Date__c, End_Date__c, 
             Is_Covering_Recruiter__c FROM AccountTeamMember 
             WHERE End_Date__c > TODAY AND Is_Covering_Recruiter__c = true and AccountId =: mobileAccList[0].Id];
            
            Assert.areEqual(atmList2.size(),1,'ATM not inserted.');

        
        OpportunitySplitType overlaySplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName = 'Overlay'];
        List<OpportunitySplit> opsplits = new List<OpportunitySplit>();                
            OpportunitySplit opsplit;
                    
            opsplit = new OpportunitySplit();
            opsplit.OpportunityId = oppList[0].Id;
            opsplit.Is_Covering_Incentive__c = true;
            opsplit.SplitNote = 'test';
            opsplit.Split_Amount__c = 20;
            opsplit.Split_Reason__c = 'Coverage Leave of Absence';
            opsplit.SplitOwnerId = AdminUser.Id;
            opsplit.SplitTypeId =overlaySplitType.id;
            opsplits.add( opsplit );
            TriggerHandler.bypass('OpportunitySplitTriggerHandler');
            //insert opsplits;
        
        list<OpportunitySplit> opSplit2 = [select Id,OpportunityId,SplitTypeId,SplitPercentage,Split_Reason__c,SplitOwnerId from OpportunitySplit where OpportunityId =:oppList[0].Id
                                         AND SplitTypeId =: overlaySplitType.Id];
            
        test.startTest();
        BSF_BatchUpdateOpportunitySplit batch = new BSF_BatchUpdateOpportunitySplit ();
        database.executeBatch(batch);
        test.stopTest();
    }
    @isTest
    Public static void Test_Schedule_Class1()
    {
        Test.StartTest();
        
        BSF_BatchUpdateOpportunitySplitSchedular testsche1 = new BSF_BatchUpdateOpportunitySplitSchedular(200);
        String sch1 = '0 0 23 * * ?';
        system.schedule('Test schedule class1', sch1, testsche1 );
        Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class1'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class1');
    }
}