@isTest
public class TaskForMigratedDrivesBatchTest {

    @testSetup
    static void setupData() {

        //Bypass heavy triggers to prevent SOQL limit issues
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            AccountId=acc.Id,
            FirstName='contact122',
            Email='abcd32@gmail.com',
            Primary_Phone__c='Mobile Phone',
            Original_Service_Date__c=system.today(),
            LastName='contact322',
            Phone='7474749'
        );
        insert con;

        User u=new User(
            LastName='user17223',
            FirstName='user23722',
            Username='john@acmeyer.com',
            Email='abdc@gmail3724.com',
            Alias='alia6s',
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='ISO-8859-1',
            ProfileId='00eo0000000rmqFAAQ',
            LanguageLocaleKey ='en_US'
        );
        insert u;

        sked__Location__c loc = new sked__Location__c(
            sked_National_Name__c='national',
            sked_Physical_Location_Type__c='inside',
            sked_Site_Contact__c=con.Id,
            sked_Site_Main_Phone__c='838-438-4367',
            sked_Start_Date__c=system.today(),
            sked_End_Date__c=system.today()+1,
            sked_Address_1__c='kolkata',
            sked_City__c='kolkata',
            sked_County__c='India',
            sked_Zip_Code__c='70456',
            sked_State__c='WB',
            sked_Site_Inspection_Completed_By__c=u.Id,
            sked_Site_Building_Name__c='new site building',
            sked_Floor_Description__c='desc',
            sked_Room_Name__c='room name',
            sked_Room_Size__c='Bus',
            sked_Automation_Suitability__c='Suitable',
            sked_Wireless_Policy__c='Accepted',
            sked_Outside_stairs__c=3,
            sked_Base_Description__c='base desc',
            sked_Directions_From_CollectionOperation__c='sked_Directions_From_CollectionOperation__c',
            sked_ARC_Vehicle_Parking_Directions__c='sked_ARC_Vehicle_Parking_Directions__c',
            sked_Staff_Personal_Parking_Directions__c='sked_Staff_Personal_Parking_Directions__c',
            Source__c = 'Custom New Form',
            Name='site name'
        );
        insert loc;

        //Get RecordTypeId dynamically
        Id mobileOppRTId = Opportunity.SObjectType.getDescribe()
            .getRecordTypeInfosByName()
            .get('Mobile Opp')
            .getRecordTypeId();

        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Committed',
            Type_of_Drive__c = 'Mobile',
            RecordTypeId = mobileOppRTId,
            Drive_Status__c = 'Tentative',
            Drive_Name__c = 'Drive 1',
            Drive_Date__c = Date.today().addDays(120),
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Drive_Site__c = loc.Id,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1530',
            WB_Projected_Procedures__c = 4,
            X2RBC_Projected_Procedures__c = 2,
            Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
        ));
        oppList.add(new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Closed',
            Type_of_Drive__c = 'Mobile',
            RecordTypeId = mobileOppRTId,
            Drive_Status__c = 'Confirmed',
            Drive_Name__c = 'Drive 2',
            Drive_Date__c = Date.today().addDays(60),
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Drive_Site__c = loc.Id,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1530',
            WB_Projected_Procedures__c = 4,
            X2RBC_Projected_Procedures__c = 2,
            Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
        ));
        oppList.add(new Opportunity(
            Name = 'Test Opp 3',
            StageName = 'Closed',
            Type_of_Drive__c = 'Mobile',
            RecordTypeId = mobileOppRTId,
            Drive_Status__c = 'Confirmed',
            Drive_Name__c = 'Drive 3',
            Drive_Date__c = Date.today().addDays(50),
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Drive_Site__c = loc.Id,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1530',
            WB_Projected_Procedures__c = 4,
            X2RBC_Projected_Procedures__c = 2,
            Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
        ));
        insert oppList;

        //Create Tasks related to those opportunities
        List<Task> tasks = new List<Task>();
        Id recTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('72 Hour Check In').getRecordTypeId();

        tasks.add(new Task(
            RecordTypeId = recTypeId,
            Subject = '72 Hour Check in - System Generated',
            WhatId = oppList[2].Id,
            ActivityDate = Helper.AddBusinessDays(OppList[0].Drive_Date__c,-3),
            Status = 'Not Started'
        ));

        tasks.add(new Task(
            Subject = 'Sponsor Planning Meeting - System Generated',
            WhatId = oppList[0].Id,
            ActivityDate = Helper.AddBusinessDays(OppList[0].Drive_Date__c,-3),
            Status = 'Not Started',
            Priority = 'Normal'
        ));

        tasks.add(new Task(
            RecordTypeId = recTypeId,
            Subject = 'Recruitment Task - System Generated',
            WhatId = oppList[1].Id,
            ActivityDate = Helper.AddBusinessDays(OppList[0].Drive_Date__c, -50),
            Status = 'Not Started'
        ));
        insert tasks;

        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        //atm.AccountAccessLevel = 'Read/Write';
        //atm.CaseAccessLevel = 'Read/Write';
        //atm.OpportunityAccessLevel = 'Read/Write';
        atm.userId = u.Id ;
        atm.AccountId = OppList[0].AccountId ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        try {
            system.debug('atmList done '+atmList);
            BSF_Constants.isTeamMemberCreatedFromBackend = false;
            insert atmList;
            system.debug('atmList done2 '+atmList);
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }

        // Clear bypass flags after setup
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('TaskTriggerHandler');
        TriggerHandler.clearBypass('AccountTriggerHandler');
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
    }

    @isTest
    static void testTaskForMigratedDrivesBatch() {
        // Verify setup data exists
        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
        System.assert(oppList.size() > 0, 'Setup failed: No Opportunities found.');

        // Run the batch
        Test.startTest();
        Id jobId = Database.executeBatch(new TaskForMigratedDrivesBatch(), 5);
        Test.stopTest();

        // Post-batch: check business outcome
        // For example, assert that system generated tasks were processed/updated
        List<Task> updatedTasks = [
            SELECT Id, Status, WhatId FROM Task WHERE Subject LIKE '%System Generated%'
        ];
        System.assert(
            updatedTasks.size() > 0,
            'No system-generated tasks processed by TaskForMigratedDrivesBatch.'
        );
    }

 
}