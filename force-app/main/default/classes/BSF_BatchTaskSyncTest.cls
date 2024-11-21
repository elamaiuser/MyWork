@isTest
public class BSF_BatchTaskSyncTest {
    @testSetup static void createData()
    {
        skedHubBase.BypassInsertTriggers = true;
        //TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        TriggerHandler.clearBypass('OpportunityHandler');
        //TriggerHandler.clearBypass('AccountTriggerHandler');
        skedHubBase.BypassInsertTriggers = false;
        
    }
    @isTest static void Test()
    {
        
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
        
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Opportunity mobileOpportunity = [Select Id,Name,AccountId,Drive_Date__c,Drive_Site__c,Drive_Site__r.Name FROM Opportunity Where Is_Template__c = FALSE AND RecordType.DeveloperName = 'Mobile_Opp' Limit 1];
        system.debug('mobileOpportunity '+mobileOpportunity.Drive_Site__r.Name);
        Sked_Site_Collection_Operation__c siteCollOpList = [select id,sked_Site__c,sked_Start_Date__c,sked_End_Date__c,sked_collection_operation__r.Name from Sked_Site_Collection_Operation__c where sked_Site__c =:mobileOpportunity.Drive_Site__c Limit 1];
        siteCollOpList.sked_Start_Date__c=system.Today();
        update siteCollOpList;
        
        System.runAs(AdminUser)
        {
            String siteCoName=siteCollOpList.sked_collection_operation__r.Name+': DMDCR';
        Group q =[Select id from Group where Name=:siteCoName Limit 1];
        QueuesObject testQueue = new QueueSObject(QueueID = q.id, SobjectType = 'Task');
		insert testQueue;
        }
        
        system.debug('siteCollOpList '+siteCollOpList);
        OpportunityTeamMember testoppteammem= new OpportunityTeamMember();
        testoppteammem.OpportunityId=mobileOpportunity.id;
        testoppteammem.UserId=AdminUser.Id;
        testoppteammem.TeamMemberRole=BSF_Constants.DISTRICT_MANAGER ;
        insert testoppteammem;
        Task testtsk = new Task();
        testtsk.WhatId=mobileOpportunity.Id;
        testtsk.Status='Not Started';
        testtsk.Subject='Recruitment Task - System Generated';
        insert testtsk;
        Task testtaskDM = new Task();
        testtaskDM.WhatId=mobileOpportunity.Id;
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
    
    @isTest static void Test2()
    {
        
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
        
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Opportunity mobileOpportunity = [Select Id,Name,AccountId,Drive_Date__c,Drive_Site__c,Drive_Site__r.Name FROM Opportunity Where Is_Template__c = FALSE AND RecordType.DeveloperName = 'Mobile_Opp' Limit 1];
        system.debug('mobileOpportunity '+mobileOpportunity.Drive_Site__r.Name);
        Sked_Site_Collection_Operation__c siteCollOpList = [select id,sked_Site__c,sked_Start_Date__c,sked_End_Date__c,sked_collection_operation__r.Name from Sked_Site_Collection_Operation__c where sked_Site__c =:mobileOpportunity.Drive_Site__c Limit 1];
        siteCollOpList.sked_Start_Date__c=system.Today();
        update siteCollOpList;
        
        System.runAs(AdminUser)
        {
            String siteCoName=siteCollOpList.sked_collection_operation__r.Name+': DMDCR';
        Group q =[Select id from Group where Name=:siteCoName Limit 1];
        QueuesObject testQueue = new QueueSObject(QueueID = q.id, SobjectType = 'Task');
		insert testQueue;
        }
        
        system.debug('siteCollOpList '+siteCollOpList);
        OpportunityTeamMember testoppteammem= new OpportunityTeamMember();
        testoppteammem.OpportunityId=mobileOpportunity.id;
        testoppteammem.UserId=AdminUser.Id;
        testoppteammem.TeamMemberRole=BSF_Constants.DISTRICT_MANAGER ;
        insert testoppteammem;
        Task testtsk = new Task();
        testtsk.WhatId=mobileOpportunity.Id;
        testtsk.Status='Not Started';
        testtsk.Subject='Recruitment Task - System Generated';
        insert testtsk;
        Task testtaskDM = new Task();
        testtaskDM.WhatId=mobileOpportunity.Id;
        testtaskDM.Status='Not Started';
        testtaskDM.Subject='Request for Marketing Exception';
        insert testtaskDM;
        /*Task_Reassignment_Matrix__mdt testreassign = new Task_Reassignment_Matrix__mdt();
        testreassign.Assigned_To__c='AM'; 
        testreassign.Task_Subject__c='72 Hour Check in - Sytem Generated';
        testreassign.Label='72 Hour Check In';*/
        Test.startTest();
        BSF_BatchTaskSync taskbatch = new BSF_BatchTaskSync(null,new List<Id>{testtaskDM.Id});
        DataBase.executeBatch(taskbatch);
        Test.stopTest();        
        
    }
    
    @isTest static void Test3()
    {
        
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
        
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Opportunity mobileOpportunity = [Select Id,Name,AccountId,Drive_Date__c,Drive_Site__c,Drive_Site__r.Name FROM Opportunity Where Is_Template__c = FALSE AND RecordType.DeveloperName = 'Mobile_Opp' Limit 1];
        system.debug('mobileOpportunity '+mobileOpportunity.Drive_Site__r.Name);
        Sked_Site_Collection_Operation__c siteCollOpList = [select id,sked_Site__c,sked_Start_Date__c,sked_End_Date__c,sked_collection_operation__r.Name from Sked_Site_Collection_Operation__c where sked_Site__c =:mobileOpportunity.Drive_Site__c Limit 1];
        siteCollOpList.sked_Start_Date__c=system.Today();
        update siteCollOpList;
        
        System.runAs(AdminUser)
        {
            String siteCoName=siteCollOpList.sked_collection_operation__r.Name+': DMDCR';
        Group q =[Select id from Group where Name=:siteCoName Limit 1];
        QueuesObject testQueue = new QueueSObject(QueueID = q.id, SobjectType = 'Task');
		insert testQueue;
        }
        
        system.debug('siteCollOpList '+siteCollOpList);
        OpportunityTeamMember testoppteammem= new OpportunityTeamMember();
        testoppteammem.OpportunityId=mobileOpportunity.id;
        testoppteammem.UserId=AdminUser.Id;
        testoppteammem.TeamMemberRole=BSF_Constants.DISTRICT_MANAGER ;
        insert testoppteammem;
        Task testtsk = new Task();
        testtsk.WhatId=mobileOpportunity.Id;
        testtsk.Status='Not Started';
        testtsk.Subject='Recruitment Task - System Generated';
        insert testtsk;
        Task testtaskDM = new Task();
        testtaskDM.WhatId=mobileOpportunity.Id;
        testtaskDM.Status='Not Started';
        testtaskDM.Subject='Request for Marketing Exception';
        insert testtaskDM;
        /*Task_Reassignment_Matrix__mdt testreassign = new Task_Reassignment_Matrix__mdt();
        testreassign.Assigned_To__c='AM'; 
        testreassign.Task_Subject__c='72 Hour Check in - Sytem Generated';
        testreassign.Label='72 Hour Check In';*/
        
         Test.startTest();
        BSF_BatchTaskSync taskbatch1 = new BSF_BatchTaskSync(new List<Id>{mobileOpportunity.Id},new List<Id>{testtaskDM.Id});
        DataBase.executeBatch(taskbatch1);
         Test.stopTest();     
        
    }
    
    @isTest static void Test4()
    {
        
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
        
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Opportunity mobileOpportunity = [Select Id,Name,AccountId,Drive_Date__c,Drive_Site__c,Drive_Site__r.Name FROM Opportunity Where Is_Template__c = FALSE AND RecordType.DeveloperName = 'Mobile_Opp' Limit 1];
        system.debug('mobileOpportunity '+mobileOpportunity.Drive_Site__r.Name);
        Sked_Site_Collection_Operation__c siteCollOpList = [select id,sked_Site__c,sked_Start_Date__c,sked_End_Date__c,sked_collection_operation__r.Name from Sked_Site_Collection_Operation__c where sked_Site__c =:mobileOpportunity.Drive_Site__c Limit 1];
        siteCollOpList.sked_Start_Date__c=system.Today();
        update siteCollOpList;
        
        System.runAs(AdminUser)
        {
            String siteCoName=siteCollOpList.sked_collection_operation__r.Name+': DMDCR';
        Group q =[Select id from Group where Name=:siteCoName Limit 1];
        QueuesObject testQueue = new QueueSObject(QueueID = q.id, SobjectType = 'Task');
		insert testQueue;
        }
        
        system.debug('siteCollOpList '+siteCollOpList);
        OpportunityTeamMember testoppteammem= new OpportunityTeamMember();
        testoppteammem.OpportunityId=mobileOpportunity.id;
        testoppteammem.UserId=AdminUser.Id;
        testoppteammem.TeamMemberRole=BSF_Constants.DISTRICT_MANAGER ;
        insert testoppteammem;
        Task testtsk = new Task();
        testtsk.WhatId=mobileOpportunity.Id;
        testtsk.Status='Not Started';
        testtsk.Subject='Recruitment Task - System Generated';
        insert testtsk;
        Task testtaskDM = new Task();
        testtaskDM.WhatId=mobileOpportunity.Id;
        testtaskDM.Status='Not Started';
        testtaskDM.Subject='Request for Marketing Exception';
        insert testtaskDM;
        /*Task_Reassignment_Matrix__mdt testreassign = new Task_Reassignment_Matrix__mdt();
        testreassign.Assigned_To__c='AM'; 
        testreassign.Task_Subject__c='72 Hour Check in - Sytem Generated';
        testreassign.Label='72 Hour Check In';*/
        
        Test.startTest();
        BSF_BatchTaskSync taskbatch2 = new BSF_BatchTaskSync(new List<Id>{mobileOpportunity.Id},null);
        DataBase.executeBatch(taskbatch2); 
         Test.stopTest();
        
        
    }
    @isTest static void executeTest(){
        
        SchedulableContext sc = null;
        BSF_BatchTaskSync taskbatch = new BSF_BatchTaskSync();
        taskbatch.execute(sc);
        
    }  
}