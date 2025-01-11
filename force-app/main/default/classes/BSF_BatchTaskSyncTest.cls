@isTest
public class BSF_BatchTaskSyncTest {
    @isTest static void Test(){
        
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
        insert AdminUser;
        //List<Account> mobileAccList = new List<Account>();       
        Account accobj = new Account();
        accobj.Name = 'Exavalu';
        accobj.Type = 'Business';
        accobj.Internal_Name__c='test';
        insert accobj;
        //List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        optyObj.Name = 'Test Drive 1';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.Today()-1;
        optyObj.CloseDate= System.Today()-2;
        optyObj.AccountId=accobj.id;
        optyObj.Account_Manager__c=AdminUser.Id;
        optyObj.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        optyObj.End_Time__c = Time.newInstance(15, 30, 0, 0);
        optyObj.Flow_Start_Time_Field__c = '1000';
        optyObj.Flow_End_Time_Field__c = '1530';
        optyObj.WB_Projected_Procedures__c = 4;
        optyObj.X2RBC_Projected_Procedures__c = 2;
        optyObj.Anticipated_Registered_Donors__c = 25;
        optyObj.Online_Scheduling_Enabled__c = 'No';
            
            insert optyObj;
        
        
        OpportunityTeamMember testoppteammem= new OpportunityTeamMember();
        testoppteammem.OpportunityId=optyObj.id;
        testoppteammem.UserId=AdminUser.Id;
        testoppteammem.TeamMemberRole=BSF_Constants.DISTRICT_MANAGER ;
        insert testoppteammem;
        Task testtsk = new Task();
        testtsk.WhatId=optyObj.Id;
        testtsk.Status='Not Started';
        testtsk.Subject='Recruitment Planning Meeting';//HRP-7123
        insert testtsk;
        Task testtaskDM = new Task();
        testtaskDM.WhatId=optyObj.Id;
        testtaskDM.Status='Not Started';
        testtaskDM.Subject='Request for Marketing Exception';
        insert testtaskDM;
        /*Task_Reassignment_Matrix__mdt testreassign = new Task_Reassignment_Matrix__mdt();
        testreassign.Assigned_To__c='AM'; 
        testreassign.Task_Subject__c='72 Hour Check in - Sytem Generated';
        testreassign.Label='72 Hour Check In';*/
        Test.startTest();
        BSF_BatchTaskSync taskbatch = new BSF_BatchTaskSync();
        DataBase.executeBatch(taskbatch); 
        
        Test.stopTest();
    }
    @isTest static void executeTest(){
        
        SchedulableContext sc = null;
        BSF_BatchTaskSync taskbatch = new BSF_BatchTaskSync();
        taskbatch.execute(sc);
        
    }  
}