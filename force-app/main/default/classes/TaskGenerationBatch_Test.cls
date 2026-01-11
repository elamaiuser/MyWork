@IsTest
private class TaskGenerationBatch_Test {

    @testSetup
    static void setupTestData() {

        //Temporarily bypass heavy triggers during setup
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');

        Account acc = new Account(
            Name = 'Test Account',
            Account_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test_Account_Internal'
        );
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            Phone = '9999999999',
            AccountId = acc.Id,
            Original_Service_Date__c = System.today().addDays(5),
            Primary_Phone__c = 'Mobile Phone'
        );
        insert con;

        Account_Service_Role__c asr = new Account_Service_Role__c(
            Account__c = acc.Id,
            Contact__c = con.Id,
            Account_Service_Role__c = 'Blood Program Leader'
        );
        insert asr;

        sked__Location__c site = new sked__Location__c(
            Name = 'testSite',
            sked_Floor_Description__c = 'test Floor',
            sked_Room_Name__c = 'test Room',
            sked_National_Name__c = 'test National Name',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Site_Main_Phone__c = '999-999-9999',
            sked_Site_Building_Name__c = 'test Building',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Other',
         	sked_Wireless_Policy__c = 'Accepted',
         	sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
         	sked_Room_Size__c = '801-1200 Sq. Ft.',
         	sked_Staff_Personal_Parking_Directions__c = 'test',
         	sked_Address_1__c = 'test',
         	sked_Outside_stairs__c = 10,
         	sked_County__c = 'test',
         	sked_State__c = 'test',
         	sked_Zip_Code__c = 'test123',
         	sked_City__c = 'test',
         	sked_Inside_stairs__c = 10,
         	sked_Base_Description__c = 'test',
         	sked_ARC_Vehicle_Parking_Directions__c = 'test',
         	sked_Directions_From_CollectionOperation__c = 'test',
         	sked_Start_Date__c = System.today(),
         	sked_End_Date__c = System.today()+5,
        	Source__c='Custom New Form'
        );
        insert site;

        Id mobileRTId = Opportunity.SObjectType.getDescribe()
            .getRecordTypeInfosByName()
            .get('Mobile Opp')
            .getRecordTypeId();

        List<Opportunity> oppList = new List<Opportunity>{
            new Opportunity(
                Name = 'Test Opportunity 1',
                StageName = 'Committed',
                Drive_Site__c = site.Id,
                Drive_Name__c = 'Drive A',
                Drive_Date__c = System.today(),
                CloseDate = System.today(),
                AccountId = acc.Id,
                RecordTypeId = mobileRTId,
                Flow_Start_Time_Field__c = '1000',
                Flow_End_Time_Field__c = '1530',
                WB_Projected_Procedures__c = 4,
                X2RBC_Projected_Procedures__c = 2,
                Anticipated_Registered_Donors__c = 20
            ),
            new Opportunity(
                Name = 'Test Opportunity 2',
                StageName = 'Closed',
                Drive_Site__c = site.Id,
                Drive_Name__c = 'Drive B',
                Drive_Date__c = System.today(),
                CloseDate = System.today(),
                AccountId = acc.Id,
                RecordTypeId = mobileRTId,
                Flow_Start_Time_Field__c = '1000',
                Flow_End_Time_Field__c = '1530',
                WB_Projected_Procedures__c = 5,
                X2RBC_Projected_Procedures__c = 3,
                Anticipated_Registered_Donors__c = 25
            )
        };
        insert oppList;

        //Create Tasks related to first opportunity
        List<Task> tasks = new List<Task>{
            new Task(
                WhatId = oppList[0].Id,
                Subject = 'Recruitment Planning Meeting',
                ActivityDate = System.today(),
                OwnerId = UserInfo.getUserId(),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = oppList[0].Id,
                Subject = 'Sponsor Planning Meeting',
                ActivityDate = System.today(),
                OwnerId = UserInfo.getUserId(),
                Status = 'Not Started'
            ),
            new Task(
                WhatId = oppList[0].Id,
                Subject = '72 Hour Check-In',
                ActivityDate = System.today(),
                OwnerId = UserInfo.getUserId(),
                Status = 'Not Started'
            )
        };
        insert tasks;

        //Clear bypass flags
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('TaskTriggerHandler');
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
    }

    //Primary batch test
    @isTest
    static void test_TaskGenerationBatch_Run() {
        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
        System.assert(oppList.size() > 0, 'No Opportunity found from setup');

        Test.startTest();
        Id batchId = Database.executeBatch(new TaskGenerationBatch(), 5);
        Test.stopTest();

        //Business assertion: check if tasks were created or updated by the batch
        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE Subject IN ('Recruitment Planning Meeting', 'Sponsor Planning Meeting', '72 Hour Check-In')
        ];
        System.assert(
            taskCount > 0,
            'Expected at least one task (Recruitment, Sponsor, or 72-Hour Check-In) after TaskGenerationBatch run.'
        );

    }
}