@isTest
private class TaskGenerationBatch_Test {
    @testSetup
    static void setup() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Account acc = new Account(name='Test Account',Account_Manager__c = UserInfo.getUserId(),Internal_Name__c='test234');

        insert acc;
        TriggerHandler.clearBypass('AccountTriggerHandler');
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
        contact.AccountId = acc.id;
        insert contact;
    }

    @isTest static void batchtest() {
            
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
        	site.Source__c='Custom New Form';
            insert site;
            
            Opportunity opp = new Opportunity();
            Account acc = [select id from Account where name='Test Account' limit 1];
            opp.AccountId = acc.id;
             Account_Service_Role__c serviceRole = new Account_Service_Role__c();
             serviceRole.Account_Service_Role__c='Blood Program Leader';
             serviceRole.Account__c = acc.id; 
            serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
            insert serviceRole;
            opp.StageName = 'Committed';
            opp.Drive_Site__c = site.id;
			opp.Drive_Name__c = 'Test Drive';
            opp.Drive_Date__c = System.today();
            opp.CloseDate = System.today();
            opp.Call_List_Recipient_Exist__c = true;
            Time startTime = Time.newInstance(10, 0, 0, 0);
            System.debug('startTime->'+startTime);
            opp.Start_Time__c = startTime;
            Time endTime = Time.newInstance(15, 30, 0, 0);
            System.debug('endTime->'+endTime);
			//opp.Flow_Start_Time_Field__c = '10:00 AM';
            opp.Flow_Start_Time_Field__c = '1000';
			opp.Accept_56_Day_Rule_Violation__c = true;
            opp.Flow_End_Time_Field__c = '1530';
            //opp.Flow_End_Time_Field__c = '3:30 PM';

            //opp.End_Time__c = endTime;
            opp.WB_Projected_Procedures__c = 4;
            opp.X2RBC_Projected_Procedures__c = 2;
            opp.Name = 'Test Opportunity';
            opp.Anticipated_Registered_Donors__c =25;
            TriggerHandler.bypass('OpportunityTriggerHandler');
			insert opp;
			TriggerHandler.clearBypass('OpportunityTriggerHandler');
            Opportunity opp2 = new Opportunity();
            opp2.AccountId = acc.id;
            
            opp2.StageName = 'Closed';
            opp2.Drive_Site__c = site.id;
			opp2.Drive_Name__c = 'Test Drive';
            opp2.Drive_Date__c = System.today();
            opp2.CloseDate = System.today();
            opp2.Call_List_Recipient_Exist__c = true;
            System.debug('startTime->'+startTime);
            opp2.Start_Time__c = startTime;
            System.debug('endTime->'+endTime);
			//opp2.Flow_Start_Time_Field__c = '10:00 AM';
            opp2.Flow_Start_Time_Field__c = '1000';
			opp2.Accept_56_Day_Rule_Violation__c = true;
            opp2.Flow_End_Time_Field__c = '1530';
            //opp2.Flow_End_Time_Field__c = '3:30 PM';
			
            list<task> taskList = new list<task>();
            //opp2.End_Time__c = endTime;
            opp2.WB_Projected_Procedures__c = 4;
            opp2.X2RBC_Projected_Procedures__c = 2;
            opp2.Name = 'Test opp2ortunity';
            opp2.Anticipated_Registered_Donors__c =25;
			insert opp2;
            task tsk1 = new task();
            tsk1.ActivityDate =  System.today();
            tsk1.OwnerId = UserInfo.getUserId();
            tsk1.subject = 'Recruitment Task - System Generated';
            tsk1.WhatId = opp.id;
            taskList.add(tsk1);

            task tsk2 = new task();
            tsk2.ActivityDate =  System.today();
            tsk2.OwnerId = UserInfo.getUserId();
            tsk2.subject = '72 Hour Check in - System Generated';
            tsk2.WhatId = opp.id;
            taskList.add(tsk2);

            task tsk3 = new task();
            tsk3.ActivityDate =  System.today();
            tsk3.OwnerId = UserInfo.getUserId();
            tsk3.Type = 'Sponsor Planning Meeting';
            tsk3.WhatId = opp.id;
            taskList.add(tsk3);
			
        	insert taskList;
        
        Test.startTest();
        TaskGenerationBatch tgb = new TaskGenerationBatch();
        Id batchId = Database.executeBatch(tgb);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        //System.assertEquals(10, [select count() from contact where MailingCity = 'New York']);
    }
    
    @isTest static void batchtest1() {
            
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
        	site.Source__c='Custom New Form';
            insert site;
            
            Opportunity opp = new Opportunity();
            Account acc = [select id from Account where name='Test Account' limit 1];
            opp.AccountId = acc.id;
             Account_Service_Role__c serviceRole = new Account_Service_Role__c();
             serviceRole.Account_Service_Role__c='Blood Program Leader';
             serviceRole.Account__c = acc.id; 
            serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
            insert serviceRole;
            opp.StageName = 'Committed';
            opp.Drive_Site__c = site.id;
			opp.Drive_Name__c = 'Test Drive';
            opp.Drive_Date__c = System.today();
            opp.CloseDate = System.today();
            opp.Call_List_Recipient_Exist__c = true;
            Time startTime = Time.newInstance(10, 0, 0, 0);
            System.debug('startTime->'+startTime);
            opp.Start_Time__c = startTime;
            Time endTime = Time.newInstance(15, 30, 0, 0);
            System.debug('endTime->'+endTime);
			//opp.Flow_Start_Time_Field__c = '10:00 AM';
            opp.Flow_Start_Time_Field__c = '1000';
			opp.Accept_56_Day_Rule_Violation__c = true;
            opp.Flow_End_Time_Field__c = '1530';
            //opp.Flow_End_Time_Field__c = '3:30 PM';

            //opp.End_Time__c = endTime;
            opp.WB_Projected_Procedures__c = 4;
            opp.X2RBC_Projected_Procedures__c = 2;
            opp.Name = 'Test Opportunity';
            opp.Anticipated_Registered_Donors__c =25;
			insert opp;

            task tsk1 = new task();
            tsk1.ActivityDate =  System.today();
            tsk1.OwnerId = UserInfo.getUserId();
            tsk1.subject = 'Recruitment Task - System Generated';
            tsk1.WhatId = opp.id;
            insert tsk1;

            task tsk2 = new task();
            tsk2.ActivityDate =  System.today();
            tsk2.OwnerId = UserInfo.getUserId();
            tsk2.subject = '72 Hour Check in - System Generated';
            tsk2.WhatId = opp.id;
            insert tsk2;

        Test.startTest();
        TaskGenerationBatch tgb = new TaskGenerationBatch();
        Id batchId = Database.executeBatch(tgb);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        //System.assertEquals(10, [select count() from contact where MailingCity = 'New York']);
    }
    
    @isTest static void batchtest2() {
            
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
        	site.Source__c='Custom New Form';
            insert site;
            
            Opportunity opp = new Opportunity();
            Account acc = [select id from Account where name='Test Account' limit 1];
            opp.AccountId = acc.id;
             Account_Service_Role__c serviceRole = new Account_Service_Role__c();
             serviceRole.Account_Service_Role__c='Blood Program Leader';
             serviceRole.Account__c = acc.id; 
            serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
            insert serviceRole;
            opp.StageName = 'Committed';
            opp.Drive_Site__c = site.id;
			opp.Drive_Name__c = 'Test Drive';
            opp.Drive_Date__c = System.today();
            opp.CloseDate = System.today();
            opp.Call_List_Recipient_Exist__c = true;
            Time startTime = Time.newInstance(10, 0, 0, 0);
            System.debug('startTime->'+startTime);
            opp.Start_Time__c = startTime;
            Time endTime = Time.newInstance(15, 30, 0, 0);
            System.debug('endTime->'+endTime);
			//opp.Flow_Start_Time_Field__c = '10:00 AM';
            opp.Flow_Start_Time_Field__c = '1000';
			opp.Accept_56_Day_Rule_Violation__c = true;
            opp.Flow_End_Time_Field__c = '1530';
            //opp.Flow_End_Time_Field__c = '3:30 PM';

            //opp.End_Time__c = endTime;
            opp.WB_Projected_Procedures__c = 4;
            opp.X2RBC_Projected_Procedures__c = 2;
            opp.Name = 'Test Opportunity';
            opp.Anticipated_Registered_Donors__c =25;
			insert opp;

        Test.startTest();
        TaskGenerationBatch tgb = new TaskGenerationBatch();
        Id batchId = Database.executeBatch(tgb);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        //System.assertEquals(10, [select count() from contact where MailingCity = 'New York']);
    }
}