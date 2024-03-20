@isTest
public class DriveServiceTest {
    @testSetup static void setup() {
        Account acc = new Account(name='Test Account',Account_Manager__c = UserInfo.getUserId());
        insert acc;
        
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'test Floor';
        site.sked_Timezone__c = 'America/New_York';
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
        site.Operation_Type__c = 'Integrated';
        site.Source__c = 'Custom New Form';
        site.sked_Date_Site_Inspection_Completed__c = system.today();
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        
        insert site;
        
        Biomed_Collection_Op_Center__c testCollectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation;   
        
        Collections_Region__c region;
        region = new Collections_Region__c();
        region.Name = 'Wisconsin Region';
        region.Region_Code__c = '32E';
        insert region;
        
        DRD_Territory__c dTeritory = new DRD_Territory__c();
        dTeritory.Name = 'Test DRD Territory';
        insert dTeritory;
        
        District__c dst = new District__c() ;
        dst.Name = 'Test District 1';
        insert dst;  
        
        Collections_Territory__c clTeritory;
        clTeritory = new Collections_Territory__c();
        clTeritory.Name = 'Dale, WI 54931';
        clTeritory.Zip__c = '181124' ;
        clTeritory.Region__c = region.Id ;
        clTeritory.DRD_Territory2__c = dTeritory.Id ;
        clTeritory.District__c = dst.Id ;
        clTeritory.Collection_Operation__c = testCollectionOperation.Id;
        insert clTeritory;
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.id;
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Committed';
        opp.Type_of_Drive__c = 'Mobile';
        opp.Drive_Site__c = site.id;
        opp.Drive_Source__c = 'test';
        opp.Drive_Name__c = 'Test Drive';
        opp.Drive_Date__c = Date.newInstance(2022, 10, 15);
        opp.CloseDate = Date.newInstance(2021, 07, 01);
        opp.Call_List_Recipient_Exist__c = true;
        opp.Start_Time__c =  Time.newInstance(10, 0, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';    
        opp.End_Time__c = Time.newInstance(15, 30, 0, 0);
        opp.WB_Projected_Procedures__c = 4;
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Anticipated_Registered_Donors__c =25; 
        opp.Collections_Zip_Code__c = clTeritory.Id;
        opp.OwnerId = UserInfo.getUserId();
        insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        sked_Drive__c driveOnCalendar = new sked_Drive__c();
        driveOnCalendar.Name = opp.Name;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Collection_Operation__c = testCollectionOperation.Id;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Zip_Code__c = '181124';
        driveOnCalendar.sked_Total_Procedures_Projected__c = opp.Total_Projected_Procedures__c;
        driveOnCalendar.sked_Drive_Productivity_Planned__c = 24;
        insert driveOnCalendar;
        
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.AccountId = acc.id;
        contact.Original_Service_Date__c = system.today();
        contact.Primary_Phone__c  = 'Work Phone';
        contact.Email = 'test@gmail.com';
        insert contact;
    }
    
    @isTest static void retrieveDrivesTest(){
        List<Period> period = [SELECT Id,StartDate,EndDate FROM Period WHERE (StartDate <:Date.newInstance(2023, 10, 10) AND EndDate >:Date.newInstance(2023, 10, 10)) limit 1]; 
        String str = '';
        for(Period per : period){
            str = per.id;
        }
        
        Biomed_Collection_Op_Center__c testCollectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation;   
        
        Collections_Region__c region;
        region = new Collections_Region__c();
        region.Name = 'Wisconsin Region';
        region.Region_Code__c = '32E';
        insert region;
        
        DRD_Territory__c dTeritory = new DRD_Territory__c();
        dTeritory.Name = 'Test DRD Territory';
        insert dTeritory;
        
        District__c dst = new District__c() ;
        dst.Name = 'Test District 1';
        insert dst;
        
        Collections_Territory__c clTeritory;
        clTeritory = new Collections_Territory__c();
        clTeritory.Name = 'Dale, WI 54931';
        clTeritory.Zip__c = '181124' ;
        clTeritory.Region__c = region.Id ;
        clTeritory.DRD_Territory2__c = dTeritory.Id ;
        clTeritory.District__c = dst.Id ;
        clTeritory.Collection_Operation__c = testCollectionOperation.Id;
        insert clTeritory;
        
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'test Floor';
        site.sked_Timezone__c = 'America/New_York';
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
        site.Operation_Type__c = 'Integrated';
        site.Source__c = 'Custom New Form';
        site.sked_Date_Site_Inspection_Completed__c = system.today();
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        
        insert site;
        
		TriggerHandler.bypass('OpportunityTriggerHandler');        
        Opportunity opp = new Opportunity();
        Account acc = [select id from Account where name='Test Account' limit 1];
        opp.AccountId = acc.id;
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = acc.id; 
        serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
        insert serviceRole;
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Committed';
        opp.Type_of_Drive__c = 'Mobile';
        opp.Drive_Site__c = site.id;
        opp.Drive_Source__c = 'test';
        opp.Drive_Name__c = 'Test Drive';
        opp.Drive_Date__c =  Date.newInstance(2023, 10, 20) ;
        opp.CloseDate = Date.newInstance(2023, 10, 10) ;
        opp.Call_List_Recipient_Exist__c = true;
        opp.Start_Time__c =  Time.newInstance(10, 0, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';    
        opp.End_Time__c = Time.newInstance(15, 30, 0, 0);
        opp.WB_Projected_Procedures__c = 4;
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Anticipated_Registered_Donors__c =25; 
        opp.Collections_Zip_Code__c = clTeritory.Id;
        opp.OwnerId = UserInfo.getUserId();
        //TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        sked_Drive__c driveOnCalendar = new sked_Drive__c();
        driveOnCalendar.Name = opp.Name;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Collection_Operation__c = testCollectionOperation.Id;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Zip_Code__c = '181124';
        driveOnCalendar.sked_Total_Procedures_Projected__c = opp.Total_Projected_Procedures__c;
        insert driveOnCalendar;
        
        Test.startTest();
        DriveService.retrieveDrives(str,null);
        Test.stopTest();
    }
    
    @isTest static void retrievePriorDrivesTest(){  
        
        List<Period> period = [SELECT Id,StartDate,EndDate FROM Period WHERE (StartDate <:Date.newInstance(2022, 08, 20) AND EndDate >:Date.newInstance(2022, 08, 20)) limit 1]; 
        String str = '';
        for(Period per : period){
            str = per.id;
        }    
        
        Biomed_Collection_Op_Center__c testCollectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation;   
        
        Collections_Region__c region;
        region = new Collections_Region__c();
        region.Name = 'Wisconsin Region';
        region.Region_Code__c = '32E';
        insert region;
        
        DRD_Territory__c dTeritory = new DRD_Territory__c();
        dTeritory.Name = 'Test DRD Territory';
        insert dTeritory;
        
        District__c dst = new District__c() ;
        dst.Name = 'Test District 1';
        insert dst;
        
        Collections_Territory__c clTeritory;
        clTeritory = new Collections_Territory__c();
        clTeritory.Name = 'Dale, WI 54931';
        clTeritory.Zip__c = '181124' ;
        clTeritory.Region__c = region.Id ;
        clTeritory.DRD_Territory2__c = dTeritory.Id ;
        clTeritory.District__c = dst.Id ;
        clTeritory.Collection_Operation__c = testCollectionOperation.Id;
        insert clTeritory;
        
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'test Floor';
        site.sked_Timezone__c = 'America/New_York';
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
        site.Operation_Type__c = 'Integrated';
        site.Source__c = 'Custom New Form';
        site.sked_Date_Site_Inspection_Completed__c = system.today();
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        
        insert site;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity opp = new Opportunity();
        Account acc = [select id from Account where name='Test Account' limit 1];
        opp.AccountId = acc.id;
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = acc.id; 
        serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
        insert serviceRole;
        opp.StageName = 'Committed';
        opp.Type_of_Drive__c = 'Mobile';
        opp.Drive_Site__c = site.id;
        opp.Drive_Source__c = '';
        opp.Drive_Name__c = 'Test Drive';
        opp.Drive_Date__c = Date.newInstance(2022, 09, 02);
        opp.CloseDate = Date.newInstance(2022, 08, 20);
        opp.Call_List_Recipient_Exist__c = true;
        opp.Start_Time__c =Time.newInstance(10, 0, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';
        opp.WB_Projected_Procedures__c = 4;
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Name = 'Test Opportunity';
        opp.Anticipated_Registered_Donors__c =25; 
        opp.Collections_Zip_Code__c = clTeritory.Id;
        insert opp;
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        sked_Drive__c driveOnCalendar = new sked_Drive__c();
        driveOnCalendar.Name = 'testDrive';
        driveOnCalendar.sked_Collection_Operation__c = testCollectionOperation.Id;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Zip_Code__c = '181124';
        driveOnCalendar.sked_Total_Procedures_Projected__c = opp.Total_Projected_Procedures__c;
        insert driveOnCalendar;
        
        Test.startTest();
        DriveService.retrievePriorDrives(str,null);
        Test.stopTest();
    }
    
    @isTest static void retrieveProspectDrivesTest(){
        List<Period> period = [SELECT Id,StartDate,EndDate FROM Period WHERE (StartDate <:Date.newInstance(2022, 10, 10) AND (EndDate >:Date.newInstance(2022, 10, 10))) limit 1]; 
        String str = '';
        for(Period p : period){
            str = p.id;
        }        
        
        Account acc = [select id from Account where name='Test Account' limit 1];
        
        Opportunity opp = [Select Id, Name, StageName, CloseDate, Drive_Source__c, End_Time__c, Start_Time__c, Collections_Zip_Code__r.Collection_Operation__c,
                           Collections_Zip_Code__r.Collection_Operation__r.Name, Total_Projected_Procedures__c From Opportunity LIMIT 1];
        Biomed_Collection_Op_Center__c collOpr = [Select Name, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, sked_Hold_Threshold__c,
                                                 Staging_Location_Geolocation__Latitude__s, Staging_Location_Geolocation__Longitude__s, sked_Work_Week_First_Day__c 
                                                 From Biomed_Collection_Op_Center__c LIMIT 1];
        
        sked_Drive__c driveList = [select Name,sked_Drive_Productivity_Planned__c,sked_Opportunity__r.Name,sked_Opportunity__r.Id,sked_Opportunity__r.StageName,
                                   sked_Opportunity__r.CloseDate,sked_Opportunity__r.Drive_Source__c,sked_Opportunity__r.End_Time__c,sked_Opportunity__r.Start_Time__c,
                                   sked_Opportunity__r.Collections_Zip_Code__r.Collection_Operation__c,sked_Opportunity__r.Collections_Zip_Code__r.Collection_Operation__r.Name,
                                   sked_Opportunity__r.Total_Projected_Procedures__c from sked_Drive__c where sked_Opportunity__r.OwnerId = :UserInfo.getUserId()           
                                                         AND sked_Opportunity__r.StageName != 'Lost' Limit 1];
        
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = acc.id; 
        serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
        insert serviceRole;
        

        
        Test.startTest();
        DriveService.retrieveProspectDrives(str,null);
        Test.stopTest();
    }  
    @isTest static void retrieveDriveTest() {  
        
        Biomed_Collection_Op_Center__c testCollectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation;   
        
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'test Floor';
        site.sked_Timezone__c = 'America/New_York';
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
        site.Operation_Type__c = 'Integrated';
        site.Source__c = 'Custom New Form';
        site.sked_Date_Site_Inspection_Completed__c = system.today();
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        
        insert site;
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity opp = new Opportunity();
        Account acc = [select id from Account where name='Test Account' limit 1];
        opp.AccountId = acc.id;
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = acc.id; 
        serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
        insert serviceRole;
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Committed';
        opp.Type_of_Drive__c = 'Mobile';
        opp.Drive_Site__c = site.id;
        opp.Drive_Source__c = '';
        opp.Drive_Name__c = 'Test Drive';
        opp.Drive_Date__c = System.today();
        opp.CloseDate = System.today();
        opp.Call_List_Recipient_Exist__c = true;
        opp.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';
        opp.WB_Projected_Procedures__c = 4;
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Anticipated_Registered_Donors__c =25;  
        insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        
        sked_Drive__c driveOnCalendar = new sked_Drive__c();
        driveOnCalendar.Name = 'testDrive';
        driveOnCalendar.sked_Collection_Operation__c = testCollectionOperation.Id;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Zip_Code__c = '181124';
        insert driveOnCalendar;
        
        Test.startTest();
        DriveService.Drive testDrive = new DriveService.Drive();
        testDrive = DriveService.retrieveDrive(opp.Id);
        Test.stopTest();
    }
    @isTest static void populateDriveWorksheetDataTest()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        
        Biomed_Collection_Op_Center__c testCollectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation;        
        
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'test Floor';
        site.sked_Timezone__c = 'America/New_York';
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
        site.Operation_Type__c = 'Integrated';
        site.Source__c = 'Custom New Form';
        site.sked_Date_Site_Inspection_Completed__c = system.today();
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        
        insert site;
        
        Opportunity opp = new Opportunity();
        Account acc = [select id from Account where name='Test Account' limit 1];
        opp.AccountId = acc.id;
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = acc.id; 
        serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
        insert serviceRole;
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Committed';
        opp.Type_of_Drive__c = 'Mobile';
        opp.Drive_Site__c = site.id;
        opp.Drive_Source__c = '';
        opp.Drive_Name__c = 'Test Drive';
        opp.Drive_Date__c = System.today();
        opp.CloseDate = System.today();
        opp.Call_List_Recipient_Exist__c = true;
        opp.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';
        opp.WB_Projected_Procedures__c = 4;
        opp.Open_to_Public__c='Yes';
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Anticipated_Registered_Donors__c =25;  
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opp;
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        contact c = new contact();
        c.AccountId=acc.Id;
        c.FirstName='contact1';
        c.LastName='contact2';
        c.Phone='7474749';
        c.Original_Service_Date__c = system.today();
        c.Primary_Phone__c  = 'Work Phone';
        c.Email = 'test@gmail.com';
        insert c;
        
        OpportunityContactRole ocr=new OpportunityContactRole();
        ocr.OpportunityId=opp.Id;
        ocr.ContactId=c.id;
        ocr.Role='Whom to Meet';
        TriggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        
        insert ocr;
        
        TriggerHandler.clearBypass('OpportunityContactRoleTriggerHandler');
        
      /*  OpportunityContactRole ocr1=new OpportunityContactRole();
        ocr1.OpportunityId=opp.Id;
        ocr1.ContactId=c.id;
        ocr1.Role='Primary Contact';
        insert ocr1; */
        
        List<sked_Drive__c> driveList = new List<sked_Drive__c>();
        sked_Drive__c driveOnCalendar = new sked_Drive__c();
        driveOnCalendar.Name = 'testDrive';
        driveOnCalendar.sked_Collection_Operation__c = testCollectionOperation.Id;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Zip_Code__c = '181124';
        driveList.add(driveOnCalendar);
        insert driveList;
        
        Test.startTest();
        
        DriveService.populateDriveWorksheetData(driveList);
        Test.stopTest();
    }   
    @isTest static void populateDriveWorksheetElseIfTest()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        
        Biomed_Collection_Op_Center__c testCollectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation;        
        
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'test Floor';
        site.sked_Timezone__c = 'America/New_York';
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
        site.Operation_Type__c = 'Integrated';
        site.Source__c = 'Custom New Form';
        site.sked_Date_Site_Inspection_Completed__c = system.today();
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        
        insert site;
        
        Opportunity opp = new Opportunity();
        Account acc = [select id from Account where name='Test Account' limit 1];
        opp.AccountId = acc.id;
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = acc.id; 
        serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
        insert serviceRole;
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Committed';
        opp.Type_of_Drive__c = 'Mobile';
        opp.Drive_Site__c = site.id;
        opp.Drive_Source__c = '';
        opp.Drive_Name__c = 'Test Drive';
        opp.Drive_Date__c = System.today();
        opp.CloseDate = System.today();
        opp.Call_List_Recipient_Exist__c = true;
        opp.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';
        opp.WB_Projected_Procedures__c = 4;
        opp.Open_to_Public__c='Yes';
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Anticipated_Registered_Donors__c =25;  
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        contact c = new contact();
        c.AccountId=acc.Id;
        c.FirstName='contact1';
        c.LastName='contact2';
        c.Phone='7474749';
        c.Original_Service_Date__c = system.today();
        c.Primary_Phone__c  = 'Work Phone';
        c.Email = 'test@gmail.com';
        insert c;
        
        OpportunityContactRole ocr=new OpportunityContactRole();
        ocr.OpportunityId=opp.Id;
        ocr.ContactId=c.id;
        ocr.Role='Primary Contact';
        TriggerHandler.bypass('OpportunityContactRoleTriggerHandler');
        insert ocr;
        TriggerHandler.clearBypass('OpportunityContactRoleTriggerHandler');
        
      /*  OpportunityContactRole ocr1=new OpportunityContactRole();
        ocr1.OpportunityId=opp.Id;
        ocr1.ContactId=c.id;
        ocr1.Role='Primary Contact';
        insert ocr1; */
        
        List<sked_Drive__c> driveList = new List<sked_Drive__c>();
        sked_Drive__c driveOnCalendar = new sked_Drive__c();
        driveOnCalendar.Name = 'testDrive';
        driveOnCalendar.sked_Collection_Operation__c = testCollectionOperation.Id;
        driveOnCalendar.sked_Opportunity__c = opp.Id;
        driveOnCalendar.sked_Zip_Code__c = '181124';
        driveList.add(driveOnCalendar);
        insert driveList;
        
        Test.startTest();
        DriveService.populateDriveWorksheetData(driveList);
        Test.stopTest();
    }
     @isTest static void populateDriveWorksheetNullDriveTest(){     
        Test.startTest();
        DriveService.populateDriveWorksheetData(null);
        Test.stopTest();
    }
}