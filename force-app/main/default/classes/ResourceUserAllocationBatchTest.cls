@isTest
private class ResourceUserAllocationBatchTest {
    @TestSetup
    static void makeData(){
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType='sked__Resource__c' AND Name = 'Staff'];
        //Live_Biomed_Collection_Op_Center__mdt mtObj = [SELECT MasterLabel FROM Live_Biomed_Collection_Op_Center__mdt LIMIT 1];

        RecordType rtt1 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'Division'];
        RecordType rtt2 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'ARC Region'];
        RecordType rtt3 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'District'];

        sked_Territory__c territoryObj1 = new sked_Territory__c(Name = 'Test Territory',
                                                               recordTypeId = rtt1.Id);

        insert territoryObj1;

        sked_Territory__c territoryObj2 = new sked_Territory__c(Name = 'Test Territory',
                                                               recordTypeId = rtt2.Id,
                                                               sked_Parent__c = territoryObj1.Id);

        insert territoryObj2;

        sked_Territory__c territoryObj3 = new sked_Territory__c(Name = 'Test Territory',
                                                               recordTypeId = rtt3.Id,
                                                               sked_Parent__c = territoryObj2.Id);

        insert territoryObj3;

        Biomed_Collection_Op_Center__c collopObj = new Biomed_Collection_Op_Center__c(
                                                                                        Name = 'Test coll opp',
                                                                                        Collection_Operation_ID__c = '123456.0',
                                                                                        External_Id__c = 'Bio_Collection_Test',
                                                                                        Staging_Location_Address__c =  '11970 Gager St,Sylmar, California, 91342',
                                                                                        Staging_Location_Geolocation__Latitude__s = 34.280308,
                                                                                        Staging_Location_Geolocation__Longitude__s = -118.393922,
                                                                                        sked_Territory__c = territoryObj3.Id,
                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30', 
                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30'
                                                                                     );

        insert collopObj;

        sked__Region__c regionObj = new sked__Region__c(sked__Timezone__c = 'America/Los_Angeles',
                                                        Name = 'Test',
                                                        sked__Description__c = 'Test',
                                                        sked_External_Id__c = 'Bio_Collection_Test_America/Los_Angeles',
                                                        sked_Biomed_Collection_Op_Center__c = collopObj.Id,
                                                        sked_Territory__c = territoryObj3.Id
                                                        );

        insert regionObj;

        sked__Tag__c tagObj = new sked__Tag__c(Name = 'Inside',
                                                sked__Classification__c = 'Global',
                                                sked__Type__c = 'Physical Location Type'
                                                );

        insert tagObj;
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        sked__Resource__c resourceObj = new sked__Resource__c(
                                                recordTypeId = rt.Id,
                                                sked__Email__c = 'test12@yopmail.com',
                                                sked_Employee_ID__c = '12345',
                                                sked__Is_Active__c = true,
                                                sked_Title__c = 'Test',
                                                sked_First_Name__c = 'Barnojit',
                                                sked_Preferred_First_Name__c = 'Barnotest',
                                                sked_Last_Name__c = 'Testone',
                                                sked_ULID__c = 'ULID1234',
                                                sked__Category__c = 'Employee',
                                                sked_Employment_Status__c = 'Active',
                                                sked_Timezone__c = 'America/Los_Angeles',
                                                sked__Primary_Region__c = regionObj.Id,
                                                sked__Resource_Type__c = 'Person',
                                                sked_Primary_Phone_Type__c = 'Home Phone',
                                                sked_Home_Phone__c = '123-123-4321',
                                                sked__Primary_Phone__c = '123-123-4321',
                                                sked_Address_Referenced_for_Scheduling__c = 'Work',
                                                sked_Mobile_Type__c = 'Inside',
                                                sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
                                                sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
                                                sked_Work_Country__c = 'USA',
                                                sked_Work_City__c = 'Sylmar',
                                                sked_Work_State__c = 'CA',
                                                sked_Work_Address_1__c = '11970 Gager St',
                                                sked_Work_Zip_Code__c = '91342',
            									sked_FCC_Code__c='83140'
                                                );

        insert resourceObj;
    }

    @IsTest
    static void testMethod1(){
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'Collections'];
        User usr = new User(
                            ProfileId = pf.Id,
                            Email = 'test1@yopmail.com',
                            FederationIdentifier = 'test1@yopmail.com',
                            EmployeeNumber = '12345',
                            IsActive = true,
                            FirstName = 'test',
                            LastName = 'test',
                            Username = 'hjgfdxyuigxtryujgh@yopmail.com',
                            EmailEncodingKey = 'ISO-8859-1',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US',
                            Alias = 'test56', 
                            TimeZoneSidKey = 'America/Los_Angeles',
                            CommunityNickname = 'test.test'
                           );
        insert usr;

        Test.startTest();
            ResourceUserAllocationBatch batchObject = new ResourceUserAllocationBatch(true);
            Database.executeBatch(batchObject,2);
        Test.stopTest();
    }

    @IsTest
    static void testMethod2(){
        Test.startTest();
            ResourceUserAllocationBatch batchObject = new ResourceUserAllocationBatch(2);
            Database.executeBatch(batchObject,2);
        Test.stopTest();
    }

    @IsTest
    static void testMethod3(){
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'Collections'];
        User usr = new User(
                            ProfileId = pf.Id,
                            Email = 'test1@yopmail.com',
                            FederationIdentifier = 'test1@yopmail.com',
                            EmployeeNumber = '12345',
                            IsActive = true,
                            FirstName = 'test',
                            LastName = 'test',
                            Username = 'hjgfdxyuigxtryujgh@yopmail.com',
                            EmailEncodingKey = 'ISO-8859-1',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US',
                            Alias = 'test56', 
                            TimeZoneSidKey = 'America/Los_Angeles'
                           );
        insert usr;
		
        skedHubBase.BypassUpdateTriggers = true;
        sked__Resource__c resourceObj = [SELECT Id, sked__User__c FROM sked__Resource__c LIMIT 1];
        resourceObj.sked__User__c = usr.Id;
        update resourceObj;

        Test.startTest();
            ResourceUserAllocationBatch batchObject = new ResourceUserAllocationBatch(false,2);
            Database.executeBatch(batchObject,2);
        Test.stopTest();
    }
    @IsTest
    static void testMethod4() {
        List<sked__Resource__c> resourceList = [SELECT CreatedDate,
                                                        Id,
                                                        LastModifiedDate,
                                                        Name,
                                                        RecordTypeId,
                                                        sked_ARC_Region_Name__c,
                                                        sked_Address_Referenced_for_Scheduling__c,
                                                        sked_Anticipated_Leave_Return_Date__c,
                                                        sked_Anticipated_Return_Date__c,
                                                        sked_Asset_Type__c,
                                                        sked_Beds__c,
                                                        sked_Biomed_Collection_Op_Center_Name__c,
                                                        sked_CDL__c,
                                                        sked_Code__c,
                                                        sked_Collection_Operation_ID_Staging__c,
                                                        sked_Collection_Operation_Id__c,
                                                        sked_Collection_Operation_Name_Staging__c,
                                                        sked_DOT__c,
                                                        sked_Daily_Time_Off_Hours__c,
                                                        sked_Dedicated_to_Site__c,
                                                        sked_District_Name__c,
                                                        sked_Element_Unit__c,
                                                        sked_Employee_ID__c,
                                                        sked_Employment_Status__c,
                                                        sked_Employment_Subtype__c,
                                                        sked_Equipment_Subtype__c,
                                                        sked_FCC_Code_Description__c,
                                                        sked_FCC_Code__c,
                                                        sked_First_Name__c,
                                                        sked_HH__c,
                                                        sked_Hire_Date__c,
                                                        sked_Home_Address_1__c,
                                                        sked_Home_Address_2__c,
                                                        sked_Home_Address_3__c,
                                                        sked_Home_Address_GeoLocation__Latitude__s,
                                                        sked_Home_Address_GeoLocation__Longitude__s,
                                                        sked_Home_Address_GeoLocation__c,
                                                        sked_Home_City__c,
                                                        sked_Home_Country__c,
                                                        sked_Home_Phone_Reference_Type__c,
                                                        sked_Home_Phone__c,
                                                        sked_Home_State__c,
                                                        sked_Home_Zip_Code__c,
                                                        sked_Is_Pooled__c,
                                                        sked_Job_Code__c,
                                                        sked_Last_Date_Staffed_in_Specified_Role__c,
                                                        sked_Last_Name__c,
                                                        sked_Liftgate__c,
                                                        sked_Line_of_Service__c,
                                                        sked_Logon_User_Name__c,
                                                        sked_Long_Desc__c,
                                                        sked_Manual_Ranking_Priority__c,
                                                        sked_Max_Consecutive_Days_per_week__c,
                                                        sked_Max_Hours_Per_Week__c,
                                                        sked_Max_Hours_Per_Weekend__c,
                                                        sked_Max_Overtime_Hours__c,
                                                        sked_Max_Travel_Time__c,
                                                        sked_Maximum_Travel_Radius__c,
                                                        sked_MigrationID__c,
                                                        sked_Min_Hours_Per_Week__c,
                                                        sked_Mobile_Type__c,
                                                        sked_Overtime_Threshold__c,
                                                        sked_Planned_Termination_Date__c,
                                                        sked_Preferred_First_Name__c,
                                                        sked_Premium_Pay_Roles__c,
                                                        sked_Pres_Donor_Capacity__c,
                                                        sked_Primary_Phone_Type__c,
                                                        sked_Primary_Work_Area__c,
                                                        sked_Quantity__c,
                                                        sked_Re_hire_Date__c,
                                                        sked_Roles__c,
                                                        sked_Satellite_Address_1__c,
                                                        sked_Satellite_Address_Geolocation__Latitude__s,
                                                        sked_Satellite_Address_Geolocation__Longitude__s,
                                                        sked_Satellite_Address_Geolocation__c,
                                                        sked_Satellite_Address__c,
                                                        sked_Satellite_City__c,
                                                        sked_Satellite_Country__c,
                                                        sked_Satellite_State__c,
                                                        sked_Satellite_Zip_Code__c,
                                                        sked_Secondary_Work_Area_s__c,
                                                        sked_Seniority_Date__c,
                                                        sked_Seniority_Rank__c,
                                                        sked_Seniority_Time__c,
                                                        sked_Short_Desc__c,
                                                        sked_Site_Type_Preference__c,
                                                        sked_Site_Type__c,
                                                        sked_Supervisor_Email__c,
                                                        sked_Supervisor_Employee_ID__c,
                                                        sked_Supervisor_Name__c,
                                                        sked_Supervisor_Primary_Phone__c,
                                                        sked_Termination_Date__c,
                                                        sked_Timezone__c,
                                                        sked_Title__c,
                                                        sked_Turnaround_Time__c,
                                                        sked_ULID__c,
                                                        sked_Union_Affiliation__c,
                                                        sked_Union_Description__c,
                                                        sked_VCN_Volunteer_ID__c,
                                                        sked_VIN__c,
                                                        sked_Work_Address_1__c,
                                                        sked_Work_Address_2__c,
                                                        sked_Work_Address_3__c,
                                                        sked_Work_Address_GeoLocation__Latitude__s,
                                                        sked_Work_Address_GeoLocation__Longitude__s,
                                                        sked_Work_Address_GeoLocation__c,
                                                        sked_Work_City__c,
                                                        sked_Work_Country__c,
                                                        sked_Work_Limitations__c,
                                                        sked_Work_Phone_Reference_Type__c,
                                                        sked_Work_Phone__c,
                                                        sked_Work_State__c,
                                                        sked_Work_Zip_Code__c,
                                                        sked__Alias__c,
                                                        sked__Auto_Schedule__c,
                                                        sked__Category__c,
                                                        sked__Country_Code__c,
                                                        sked__Email__c,
                                                        sked__Employment_Type__c,
                                                        sked__GeoLocation__Latitude__s,
                                                        sked__GeoLocation__Longitude__s,
                                                        sked__GeoLocation__c,
                                                        sked__Home_Address__c,
                                                        sked__Hourly_Rate__c,
                                                        sked__Is_Active__c,
                                                        sked__Mobile_Phone__c,
                                                        sked__Notes__c,
                                                        sked__Notification_Type__c,
                                                        sked__Primary_Phone__c,
                                                        sked__Primary_Region__c,
                                                        sked__Rating__c,
                                                        sked__Resource_Type__c,
                                                        sked__UniqueKey__c,
                                                        sked__User__c,
                                                        sked__Weekly_Hours__c,
                                                        sked__Working_Hour_Type__c,
                                                        sked_eBDR_ID__c 
                                                FROM sked__Resource__c];
		Test.StartTest();
            ResourceUserAllocationBatch testsche = new ResourceUserAllocationBatch(resourceList,2);
            String sch = '0 0 23 * * ?';
            system.schedule('Test Scheduler batch', sch, testsche );
		Test.stopTest();
	}
    @IsTest
    static void testMethod5(){
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'Collections'];
        User usr = new User(
                            ProfileId = pf.Id,
                            Email = 'test1@yopmail.com',
                            FederationIdentifier = 'test1@yopmail.com',
                            EmployeeNumber = '0123456',
                            IsActive = true,
                            FirstName = 'test',
                            LastName = 'test',
                            Username = 'hjgfdxyuigxtryujgh@yopmail.com',
                            EmailEncodingKey = 'ISO-8859-1',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US',
                            Alias = 'test56', 
                            TimeZoneSidKey = 'America/Los_Angeles',
                            CommunityNickname = 'Barnotest.Testone'
                           );
        insert usr;

        Test.startTest();
            ResourceUserAllocationBatch batchObject = new ResourceUserAllocationBatch();
            Database.executeBatch(batchObject,2);
        Test.stopTest();
    }
    @IsTest
    static void testMethod6(){
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'Collections'];
        User usr = new User(
                            ProfileId = pf.Id,
                            Email = 'test1@yopmail.com',
                            FederationIdentifier = 'test1@yopmail.com',
                            EmployeeNumber = '12345',
                            IsActive = true,
                            FirstName = 'test',
                            LastName = 'test',
                            Username = 'hjgfdxyuigxtryujgh@yopmail.com',
                            EmailEncodingKey = 'ISO-8859-1',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US',
                            Alias = 'test56', 
                            TimeZoneSidKey = 'America/Los_Angeles'
                           );
        insert usr;
		Biomed_Collection_Op_Center__c collopObj1 = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c LIMIT 1];
        skedHubBase.BypassUpdateTriggers = true;
        sked__Resource__c resourceObj = [SELECT Id, sked_Timezone__c, sked_Collection_Operation_Name_Staging__c FROM sked__Resource__c LIMIT 1];
        resourceObj.sked_Timezone__c = 'sked_Timezone__c';
        resourceObj.sked_Collection_Operation_Name_Staging__c = collopObj1.Name;
        update resourceObj;

        Test.startTest();
            ResourceUserAllocationBatch batchObject = new ResourceUserAllocationBatch(false,2);
            Database.executeBatch(batchObject,2);
        Test.stopTest();
    }
}