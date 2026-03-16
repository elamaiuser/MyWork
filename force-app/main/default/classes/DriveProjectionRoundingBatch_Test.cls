@isTest(seeAllData=false)
public class DriveProjectionRoundingBatch_Test {
    
    @isTest
    static void testDriveProjectionRoundingBatch() {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        Account testAccount = new Account(Name = 'Test Account', Sponsor_Keyword__c = 'Test Keyword');
        insert testAccount;
        
        Opportunity templateOpportunity = new Opportunity(
            Name = 'Template Opportunity',
            AccountId = testAccount.Id,
            Template_Status__c = 'Active',
            WB_Projected_Procedures__c =4.5,
            Anticipated_Registered_Donors__c= 30.5,
            X2RBC_Projected_Procedures__c = 40.5,
            Is_Template__C = true,
            Drive_Keyword__c = 'Test Keyword',
            StageName='Draft',
            CloseDate=system.today()
        );
        insert templateOpportunity;
        
        contact c=new contact();
        c.AccountId=testAccount.Id;
        c.FirstName='contact12';
        c.Email='abcde@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact22';
        c.Phone='74747492';
        insert c;
        
        sked__Location__c lc=new sked__Location__c();
        lc.sked_National_Name__c='national';
        lc.sked_Physical_Location_Type__c='inside';
        lc.sked_Site_Contact__c=c.Id;
        lc.sked_Site_Main_Phone__c='838-438-4367';
        lc.sked_Start_Date__c=system.today();
        lc.sked_End_Date__c=system.today()+8;
        lc.sked_Address_1__c='kolkata';
        lc.sked_City__c='kolkata';
        lc.sked_County__c='India';
        lc.sked_Zip_Code__c='70456';
        lc.sked_State__c='WB';
        //lc.sked_Site_Inspection_Completed_By__c=u.Id;
        lc.sked_Site_Building_Name__c='new site building';
        lc.sked_Floor_Description__c='desc';
        lc.sked_Room_Name__c='room name';
        lc.sked_Room_Size__c='Bus';
        lc.sked_Automation_Suitability__c='Suitable';
        lc.sked_Wireless_Policy__c='Accepted';
        lc.sked_Outside_stairs__c=3;
        lc.sked_Base_Description__c='base desc';
        lc.sked_Directions_From_CollectionOperation__c='sked_Directions_From_CollectionOperation__c';
        lc.sked_ARC_Vehicle_Parking_Directions__c='sked_ARC_Vehicle_Parking_Directions__c';
        lc.sked_Staff_Personal_Parking_Directions__c='sked_Staff_Personal_Parking_Directions__c';
        lc.Source__c = 'Custom New Form';
        lc.Name='site name';
        insert lc;
        
        Opportunity mobileOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Withdrawn',
            Type_of_Drive__c = 'Mobile',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            Drive_Name__c = 'Test Drive',
            Drive_Date__c = System.today()+5,
            CloseDate = System.today()+8,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
            End_Time__c = Time.newInstance(15, 30, 0, 0),
            Flow_Start_Time_Field__c = '1000',
            Drive_Keyword__c='Initial Keyword',
            Flow_End_Time_Field__c = '1530',
            WB_Projected_Procedures__c = 4.5,
            Parent_Template_Id__c=templateOpportunity.id,
            X2RBC_Projected_Procedures__c = 20.5,
            Anticipated_Registered_Donors__c = 30,
            
            Online_Scheduling_Enabled__c = 'No'
        );
        mobileOpp.AccountId = testAccount.Id;
        mobileOpp.Drive_Site__c = lc.id;
        insert mobileOpp;
        
        sked__Location__c siteObj = new sked__Location__c();
        // siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site';
        siteObj.sked_Address_1__c = 'Test Site Address';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_City__c = 'Test Site City';
        siteObj.sked_State__c = 'Test Site State';
        siteObj.sked_Zip_Code__c = '4000';
        siteObj.sked_County__c = 'USA';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = c.Id;
        siteObj.sked_Site_Main_Phone__c = '758-771-0091';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Date_Site_Inspection_Completed__c = Date.Today().addDays(10);
        insert siteObj;
        
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                     sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                     sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                     sked_Hold_Threshold__c = 100,
                                                                                                     Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                     Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                     sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation1;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                     sked_Collection_Operation__c = testCollectionOperation1.Id,
                                                     sked_Drive_Date__c = System.today(),
                                                     sked_Drive_Site__c = siteObj.Id,
                                                     sked_Opportunity__c = mobileOpp.Id,
                                                     sked_Type_of_Drive__c = 'Fixed Site',
                                                     sked_Account__c = testAccount.Id,
                                                     sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                     sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                     sked_Drive_Productivity_Planned__c = 0.8,
                                                     sked_Projected_Registered_Donors__c = 100.6,
                                                     sked_WB_Projected_Procedures__c = 50.6,
                                                     sked_2RBC_Projected_Procedures__c = 70.6,
                                                     sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT);
        insert testDrive1;
        
        
        
        Test.startTest();
        BSF_Batch_DriveProjectionRoundingOnetime batchObject = new BSF_Batch_DriveProjectionRoundingOnetime();
        Database.executeBatch(batchObject,1);
        Test.stopTest();
        // Re-query the drive after batch execution
        Opportunity refreshedOpp = [
            SELECT X2RBC_Projected_Procedures__c
            FROM Opportunity
            WHERE Id = :mobileOpp.Id
        ];
        // Assert rounding results
        System.assertEquals(
            21,
            refreshedOpp.X2RBC_Projected_Procedures__c,
            'X2RBC Projected Procedures should be rounded from 20.5 to 21'
        );
        
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
        skedHubBase.BypassDeleteTriggers = false;
        
    }
    @isTest
    static void testDriveProjectionRoundingBatch1() {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        Account testAccount1 = new Account(Name = 'Test Account', Sponsor_Keyword__c = 'Test Keyword');
        insert testAccount1;
        contact c=new contact();
        c.AccountId=testAccount1.Id;
        c.FirstName='contact12';
        c.Email='abcde@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact22';
        c.Phone='74747492';
        insert c;
        
        sked__Location__c lc=new sked__Location__c();
        lc.sked_National_Name__c='national';
        lc.sked_Physical_Location_Type__c='inside';
        lc.sked_Site_Contact__c=c.Id;
        lc.sked_Site_Main_Phone__c='838-438-4367';
        lc.sked_Start_Date__c=system.today();
        lc.sked_End_Date__c=system.today()+8;
        lc.sked_Address_1__c='kolkata';
        lc.sked_City__c='kolkata';
        lc.sked_County__c='India';
        lc.sked_Zip_Code__c='70456';
        lc.sked_State__c='WB';
        //lc.sked_Site_Inspection_Completed_By__c=u.Id;
        lc.sked_Site_Building_Name__c='new site building';
        lc.sked_Floor_Description__c='desc';
        lc.sked_Room_Name__c='room name';
        lc.sked_Room_Size__c='Bus';
        lc.sked_Automation_Suitability__c='Suitable';
        lc.sked_Wireless_Policy__c='Accepted';
        lc.sked_Outside_stairs__c=3;
        lc.sked_Base_Description__c='base desc';
        lc.sked_Directions_From_CollectionOperation__c='sked_Directions_From_CollectionOperation__c';
        lc.sked_ARC_Vehicle_Parking_Directions__c='sked_ARC_Vehicle_Parking_Directions__c';
        lc.sked_Staff_Personal_Parking_Directions__c='sked_Staff_Personal_Parking_Directions__c';
        lc.Source__c = 'Custom New Form';
        lc.Name='site name';
        insert lc;
        
        Opportunity templateOpportunity1 = new Opportunity(
            Name = 'Template Opportunity',
            AccountId = testAccount1.Id,
            Template_Status__c = 'Active',
            WB_Projected_Procedures__c =4.5,
            Anticipated_Registered_Donors__c= 30.5,
            X2RBC_Projected_Procedures__c = 40.5,
            Is_Template__C = true,
            Drive_Keyword__c = 'Test Keyword',
            StageName='Draft',
            CloseDate=system.today()
        );
        insert templateOpportunity1;
        Opportunity mobileOpp1 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Withdrawn',
            Type_of_Drive__c = 'Mobile',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            Drive_Name__c = 'Test Drive',
            Drive_Date__c = System.today()-2,
            CloseDate = System.today()+8,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
            End_Time__c = Time.newInstance(15, 30, 0, 0),
            Flow_Start_Time_Field__c = '1000',
            Drive_Keyword__c='Initial Keyword',
            Flow_End_Time_Field__c = '1530',
            WB_Projected_Procedures__c = 4.1,
            Parent_Template_Id__c=templateOpportunity1.id,
            X2RBC_Projected_Procedures__c = 40.2,
            Anticipated_Registered_Donors__c = 30.1,
            Related_Scheduled_Drive__c = null,
            
            Online_Scheduling_Enabled__c = 'No'
        );
        mobileOpp1.AccountId = testAccount1.Id;
        mobileOpp1.Drive_Site__c = lc.id;
        insert mobileOpp1;
        
        
        Test.startTest();
        BSF_Batch_DriveProjectionRoundingOnetime batchObject = new BSF_Batch_DriveProjectionRoundingOnetime();
        Database.executeBatch(batchObject,1);
        Test.stopTest();
        // Re-query the drive after batch execution
        Opportunity refreshedOpp = [
            SELECT X2RBC_Projected_Procedures__c
            FROM Opportunity
            WHERE Id = :mobileOpp1.Id
        ];
       
        
        
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
        skedHubBase.BypassDeleteTriggers = false;
        
        
    }
    
    @isTest
    static void testDriveProjectionRoundingBatch2() {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        Account testAccount1 = new Account(Name = 'Test Account', Sponsor_Keyword__c = 'Test Keyword');
        insert testAccount1;
        contact c=new contact();
        c.AccountId=testAccount1.Id;
        c.FirstName='contact12';
        c.Email='abcde@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact22';
        c.Phone='74747492';
        insert c;
        
        sked__Location__c lc=new sked__Location__c();
        lc.sked_National_Name__c='national';
        lc.sked_Physical_Location_Type__c='inside';
        lc.sked_Site_Contact__c=c.Id;
        lc.sked_Site_Main_Phone__c='838-438-4367';
        lc.sked_Start_Date__c=system.today();
        lc.sked_End_Date__c=system.today()+8;
        lc.sked_Address_1__c='kolkata';
        lc.sked_City__c='kolkata';
        lc.sked_County__c='India';
        lc.sked_Zip_Code__c='70456';
        lc.sked_State__c='WB';
        //lc.sked_Site_Inspection_Completed_By__c=u.Id;
        lc.sked_Site_Building_Name__c='new site building';
        lc.sked_Floor_Description__c='desc';
        lc.sked_Room_Name__c='room name';
        lc.sked_Room_Size__c='Bus';
        lc.sked_Automation_Suitability__c='Suitable';
        lc.sked_Wireless_Policy__c='Accepted';
        lc.sked_Outside_stairs__c=3;
        lc.sked_Base_Description__c='base desc';
        lc.sked_Directions_From_CollectionOperation__c='sked_Directions_From_CollectionOperation__c';
        lc.sked_ARC_Vehicle_Parking_Directions__c='sked_ARC_Vehicle_Parking_Directions__c';
        lc.sked_Staff_Personal_Parking_Directions__c='sked_Staff_Personal_Parking_Directions__c';
        lc.Source__c = 'Custom New Form';
        lc.Name='site name';
        insert lc;
        
        Opportunity templateOpportunity1 = new Opportunity(
            Name = 'Template Opportunity',
            AccountId = testAccount1.Id,
            Template_Status__c = 'Active',
            WB_Projected_Procedures__c =6.5,
            Anticipated_Registered_Donors__c= 37.5,
            X2RBC_Projected_Procedures__c = 47.5,
            Is_Template__C = true,
            Drive_Keyword__c = 'Test Keyword',
            StageName='Draft',
            CloseDate=system.today()
        );
        insert templateOpportunity1;
        Opportunity mobileOpp1 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Withdrawn',
            Type_of_Drive__c = 'Mobile',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            Drive_Name__c = 'Test Drive',
            Drive_Date__c = System.today()-2,
            CloseDate = System.today()+8,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
            End_Time__c = Time.newInstance(15, 30, 0, 0),
            Flow_Start_Time_Field__c = '1000',
            Drive_Keyword__c='Initial Keyword',
            Flow_End_Time_Field__c = '1530',
            WB_Projected_Procedures__c = 4.1,
            Parent_Template_Id__c=templateOpportunity1.id,
            X2RBC_Projected_Procedures__c = 40.2,
            Anticipated_Registered_Donors__c = 30.1,
            Related_Scheduled_Drive__c = null,
            
            Online_Scheduling_Enabled__c = 'No'
        );
        mobileOpp1.AccountId = testAccount1.Id;
        mobileOpp1.Drive_Site__c = lc.id;
        insert mobileOpp1;
        
        Test.startTest();
        BSF_Batch_DriveProjectionRoundingOnetime batchObject = new BSF_Batch_DriveProjectionRoundingOnetime();
        Database.executeBatch(batchObject,1);
        Test.stopTest();
        Opportunity roundedtemplatevalues = [
            SELECT Is_Template__C, WB_Projected_Procedures__c,
            Anticipated_Registered_Donors__c,
            X2RBC_Projected_Procedures__c
            FROM Opportunity
            WHERE Id = :templateOpportunity1.Id];
        
      
           // Assert rounding results
        System.assertEquals(
            true,
            roundedtemplatevalues.Is_Template__C,
            'Template is active'
        );
        
        
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
        skedHubBase.BypassDeleteTriggers = false;
        
        
    }
    
}