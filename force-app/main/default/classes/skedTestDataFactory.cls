@isTest
public class skedTestDataFactory {

    public testDataSummary summary {get;set;}

    public Map<string, sObject> mapTestData {get;set;}

    public skedTestDataFactory(string locale, integer period) {
        this.summary = new testDataSummary();
        setLocale(locale);
        setupDateTime(system.today(), period);
        
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
    }

    public skedTestDataFactory(string locale, Date startDate, integer period) {
        this.summary = new testDataSummary();
        setLocale(locale);
        setupDateTime(startDate, period);
        
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
    }

    public List<sObject> setupPredefinedData() {
        List<sObject> predefinedData = new List<sObject>();

        List<string> roles = skedUtils.getPickListValues('sked__Resource__c', 'sked_Roles__c');
        for (Integer i = 0; i < roles.size(); i++) {
            sked__Tag__c roleTag = new sked__Tag__c(
                Name = roles[i],
                sked__Type__c = 'Role',
                sked_Priority__c = 9,
                sked_Role_ID__c = 'SKED-T-' + i
            );
            predefinedData.add(roleTag);
        }
        sked__Tag__c physicalLocationTypeTagInside = new sked__Tag__c(
            Name = 'Inside',
            sked__Type__c = 'Physical Location Type'
        );
        predefinedData.add(physicalLocationTypeTagInside);
        sked__Tag__c physicalLocationTypeTagOutside = new sked__Tag__c(
            Name = 'Outside',
            sked__Type__c = 'Physical Location Type'
        );
        predefinedData.add(physicalLocationTypeTagOutside);
        
        sked__Tag__c assetTypeTagVehicle = new sked__Tag__c(
            Name = 'Vehicle',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagVehicle);
        sked__Tag__c assetTypeTagEquipment = new sked__Tag__c(
            Name = 'Equipment',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagEquipment);
        sked__Tag__c assetTypeTag2RBC = new sked__Tag__c(
            Name = '2RBC Asset',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTag2RBC);
        sked__Tag__c assetTypeTagPlasma = new sked__Tag__c(
            Name = 'Plasma Asset',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagPlasma);
        sked__Tag__c assetTypeTagPlatelet = new sked__Tag__c(
            Name = 'Platelet Asset',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagPlatelet);

        sked__Tag__c driveTypeTagMobile = new sked__Tag__c(
            Name = 'Mobile',
            sked__Type__c = 'Drive Type'
        );
        predefinedData.add(driveTypeTagMobile);

        sked__Tag__c driveTypeTagFixedSite = new sked__Tag__c(
            Name = 'Fixed Site',
            sked__Type__c = 'Drive Type'
        );
        predefinedData.add(driveTypeTagFixedSite);
        
        sked__Tag__c realIdTypeTag = new sked__Tag__c(
            Name = 'REAL ID',
            sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION
        );
        predefinedData.add(realIdTypeTag);

        sked_Resource_Role_Group__c driverRoleGroup = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c = 'Competent Driver; Driver; Driver CDL B; Driver Support; Driver Tech Trainee; Staff Shuttle'
        );
        predefinedData.add(driverRoleGroup);

        sked_Resource_Role_Group__c supervisoryRoleGroup = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Supervisory roles',
            sked_Resource_Roles__c = 'Apheresis Charge; Charge; Drive Lead; Team Supervisor'
        );
        predefinedData.add(supervisoryRoleGroup);

        sked_Resource_Role_Group__c staffRoleGroup = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Resource_Roles__c = '2RBC; 2RBC Sign-off; Apheresis; HH; OJI; Plasma; Post Collections; Special Collections; Trainee; Translator; VOL Limited HH; VP; VP/HH'
        );
        predefinedData.add(staffRoleGroup);

        return predefinedData;
    }

    public Map<string, sObject> setupCommonTestData() {
        skedHubBase.setBypassAllTriggers(true);
        this.mapTestData = new Map<string, sObject>();

        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_DateTime_Conversion__c = TRUE;
        skedAdminSetting.sked_Max_CDL_DOT_Duration__c = 14;
        skedAdminSetting.sked_Admin_FCC_Code_Mobile__c = '83140';
        skedAdminSetting.sked_Admin_FCC_Code_Fixed_Site__c = '83340;83347';
        skedAdminSetting.sked_Ops_Record_Client_Scer__c = 'test-secret';
        skedAdminSetting.sked_Ops_Record_API_URL__c = 'https://test.url';
        skedAdminSetting.sked_Max_Record_Submission_WD_TimeBlock__c = 100;
        skedAdminSetting.sked_Admin_Op_Record_Tech_Support_Email__c = 'ops-support@redcross.com';
        skedAdminSetting.sked_Admin_Last_Collections_Zip_Run__c = System.now() - 1;
        skedAdminSetting.sked_Num_Auto_Expire_Days__c = 100;

        sked_Workday_Token_Credentials__c skedWorkdayTokenCredentials = sked_Workday_Token_Credentials__c.getOrgDefaults();
        skedWorkdayTokenCredentials.sked_Certificate_Name__c = 'test-cert';
        skedWorkdayTokenCredentials.sked_Client_ID__c = 'test-client-id';
        skedWorkdayTokenCredentials.sked_Token_Endpoint__c = 'token-endpoint';

        sked_Notification_Manager__c skedNotificationManager = sked_Notification_Manager__c.getOrgDefaults();
        skedNotificationManager.sked_Notification_Generation_Enabled__c = true;
        
        sked_JA_Post_Process_Config__c testJobAllocPostProcessSetting = new sked_JA_Post_Process_Config__c();
        testJobAllocPostProcessSetting.sked_Allowed_Maximum_Retries__c = 10;
        testJobAllocPostProcessSetting.sked_Allowed_No_of_Jobs_in_Flex_Queue__c = 100;
        testJobAllocPostProcessSetting.sked_Reschedule_Interval_Sec_Flex_Queue__c = 15;

        upsert new List<SObject>{skedAdminSetting, skedWorkdayTokenCredentials, skedNotificationManager, testJobAllocPostProcessSetting};

        Map<string, List<string>> mapResourceTypeCategories =
        skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
        List<string> resourceCategories = mapResourceTypeCategories.get(skedConstants.RESOURCE_TYPE_PERSON);
        List<string> assetCategories = mapResourceTypeCategories.get(skedConstants.RESOURCE_TYPE_ASSET);
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');

        /***** Predefined Data ****/
        List<sObject> predefinedData = setupPredefinedData();
        
        sked_Territory__c testTerritory1 = new sked_Territory__c(
        	Name = 'Test Territory 1',
            RecordTypeId = sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('sked_District').getRecordTypeId()
        );
        predefinedData.add(testTerritory1);
        mapTestData.put('testTerritory1', testTerritory1);

        Account accountBPL = new Account(
            Name = 'Test BPL Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test BPL Internal Name',
            APT_Required__c = FALSE,
            Type = skedConstants.ACCOUNT_TYPE_EDUCATION,
            Industry_Code__c = skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL
        );
        insert accountBPL;

        Contact contactBPL = new Contact(
            Active__c = TRUE,
            LastName = 'Test',
            FirstName = 'BPL',
            Primary_Phone__c = 'Work Phone',
            OtherPhone = '999-999-9987',
            Original_Service_Date__c = this.summary.startDate,
            AccountId = accountBPL.Id
        );
        predefinedData.add(contactBPL);
        
        insert predefinedData;

        List<sObject> firstList = new List<sObject>();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Address__c = '101 Test Lane, Test Avenue, 10101',
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id-1',
            sked_Low_Weight__c = 10,
            sked_Medium_Weight__c = 15,
            sked_High_Weight__c = 25,
            sked_Role_Priorities_Weight__c = 10,
            sked_Minimum_Drive_Start_Time__c = Time.newInstance(5, 0, 0, 0),
            sked_Maximum_Drive_End_Time__c = Time.newInstance(23, 0, 0, 0)
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);

        Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id-2',
            sked_Low_Weight__c = 10,
            sked_Medium_Weight__c = 15,
            sked_High_Weight__c = 25,
            sked_Role_Priorities_Weight__c = 10
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);

        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 36.7450046,
            sked_Geolocation__Longitude__s = -121.4816244
        );
        firstList.add(testStagingLocation1);
        mapTestData.put('testStagingLocation1', testStagingLocation1);
        
        Time_Block__c testTimeBlock1 = new Time_Block__c(
        	Name = 'Time Block 1',
            Start_Time__c = Time.newInstance(1, 0, 0, 0),
            End_Time__c = Time.newInstance(23, 0, 0, 0),
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        firstList.add(testTimeBlock1);
        mapTestData.put('testTimeBlock1', testTimeBlock1);

        Account testAccount1 = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Internal Name',
            APT_Required__c = FALSE,
            Type = skedConstants.ACCOUNT_TYPE_EDUCATION,
            Industry_Code__c = skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL,
            Contact_BPL__c = contactBPL.Id
        );
        firstList.add(testAccount1);
        this.mapTestData.put('testAccount1', testAccount1);
        
        sked_Staffing_Decision_Matrix__c mobileMatrix = new sked_Staffing_Decision_Matrix__c(
            sked_VP_HH_Capacity__c = 2.2,
            sked_Charge_Capacity__c = 1.1,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Team_Supervisor_Threshold__c = 36,
            sked_Charge_Threshold__c = 36,
        	RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(mobileMatrix);
        this.mapTestData.put('mobileMatrix', mobileMatrix);
        
        sked_Staffing_Decision_Matrix__c fixedSiteMatrix = new sked_Staffing_Decision_Matrix__c(
            sked_WB_Hourly_Capacity__c = 2.1,
            sked_2RBC_Hourly_Capacity__c = 1,
            sked_Plasma_Hourly_Capacity__c = 1.67,
            sked_Platelet_Round_Capacity__c = 1.17,
            sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 18,
            sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 70,
        	RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(fixedSiteMatrix);
        this.mapTestData.put('fixedSiteMatrix', fixedSiteMatrix);

        insert firstList;

        /***** Second list ****/
        List<sObject> secondList = new List<sObject>();
        
        sked_Fixed_Site_Procedure_Projection__c fspp1 = new sked_Fixed_Site_Procedure_Projection__c(
        	sked_Account__c = testAccount1.Id,
            sked_Deferral__c = 11,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Procedure_Type__c = 'WB',
            sked_QNS__c = 2
        );
        secondList.add(fspp1);
        
        sked_Fixed_Site_Procedure_Projection__c fspp2 = new sked_Fixed_Site_Procedure_Projection__c(
        	sked_Account__c = testAccount1.Id,
            sked_Deferral__c = 9,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Procedure_Type__c = 'Platelet',
            sked_QNS__c = 2
        );
        secondList.add(fspp2);

        sked_Fixed_Site_Procedure_Projection__c fspp3 = new sked_Fixed_Site_Procedure_Projection__c(
        	sked_Account__c = testAccount1.Id,
            sked_Deferral__c = 11,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Procedure_Type__c = '2RBC',
            sked_QNS__c = 2
        );
        secondList.add(fspp3);
        
        sked_Fixed_Site_Procedure_Projection__c fspp4 = new sked_Fixed_Site_Procedure_Projection__c(
        	sked_Account__c = testAccount1.Id,
            sked_Deferral__c = 9,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Procedure_Type__c = 'Plasma',
            sked_QNS__c = 2
        );
        secondList.add(fspp4);
        
        sked_Territory_Collection_Operation__c testTerritory1_testCollectionOperation1 = new sked_Territory_Collection_Operation__c(
        	sked_Territory__c = testTerritory1.Id,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Start_Date__c = this.summary.startDate,
            sked_End_Date__c = this.summary.endDate
        );
        secondList.add(testTerritory1_testCollectionOperation1);
        
        sked_Collection_Operation_SDM__c testCollectionOperation1_mobileMatrix = new sked_Collection_Operation_SDM__c(
        	sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Staffing_Decision_Matrix__c = mobileMatrix.Id
        );
 		secondList.add(testCollectionOperation1_mobileMatrix);
        
        sked_Collection_Operation_SDM__c testCollectionOperation1_fixedSiteMatrix = new sked_Collection_Operation_SDM__c(
        	sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Staffing_Decision_Matrix__c = fixedSiteMatrix.Id
        );
 		secondList.add(testCollectionOperation1_fixedSiteMatrix);
        
        sked_Collection_Operation_SDM__c testCollectionOperation2_mobileMatrix = new sked_Collection_Operation_SDM__c(
        	sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Staffing_Decision_Matrix__c = mobileMatrix.Id
        );
 		secondList.add(testCollectionOperation2_mobileMatrix);
        
        sked_Collection_Operation_SDM__c testCollectionOperation2_fixedSiteMatrix = new sked_Collection_Operation_SDM__c(
        	sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Effective_Start_Date__c = this.summary.startDate,
            sked_Effective_End_Date__c = this.summary.endDate,
            sked_Staffing_Decision_Matrix__c = fixedSiteMatrix.Id
        );
 		secondList.add(testCollectionOperation2_fixedSiteMatrix);

        AccountTeamMember testAccount1Member1 = new AccountTeamMember(
            AccountId = testAccount1.ID,
            TeamMemberRole = 'District Manager',
            UserId = UserInfo.getUserId(),
            Start_Date__c = this.summary.startDate,
            End_Date__c = this.summary.endDate,
            Coverage_Reason__c = 'Vacant Territory'
        );
 		secondList.add(testAccount1Member1);

        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        this.mapTestData.put('testRegion1', testRegion1);
        
        sked__Region__c testRegion1_2 = new sked__Region__c(
            Name = 'Region 1_2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1_2);
        this.mapTestData.put('testRegion1_2', testRegion1_2);

        sked__Region__c testRegion2 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation2.Id
        );
        secondList.add(testRegion2);
        this.mapTestData.put('testRegion2', testRegion2);

        sked__Tag__c testTag1 = new sked__Tag__c(
            Name = 'Test Tag 1'
        );
        secondList.add(testTag1);
        this.mapTestData.put('testTag1', testTag1);

        sked__Availability_Template__c testTemplate1 = new sked__Availability_Template__c(
            Name = 'Test Template 1'
        );
        secondList.add(testTemplate1);
        mapTestData.put('testTemplate1', testTemplate1);

        skedAvailabilityPatternData weeklyPatternData = new skedAvailabilityPatternData();
        weeklyPatternData.type = 'weekly';
        weeklyPatternData.repeatWeeks = 1;
        List<string> weekdays = new List<string> {'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'};
        weeklyPatternData.days = new List<skedAvailabilityPatternData.dayModel>();
        for (string weekday : weekdays) {
            skedAvailabilityPatternData.dayModel day = new skedAvailabilityPatternData.dayModel();
            day.weekday = weekday;
            day.intervals = new List<skedAvailabilityPatternData.intervalModel>();
            skedAvailabilityPatternData.intervalModel interval = new skedAvailabilityPatternData.intervalModel();
            interval.startTime = '09:00';
            interval.endTime = '18:00';
            day.intervals.add(interval);
            weeklyPatternData.days.add(day);
        }
        sked__Availability_Pattern__c testWeeklyPattern1 = new sked__Availability_Pattern__c(
            Name = 'Test Weekly Pattern 1',
            sked__Hash__c = 'weeklyPatternHash',
            sked_Validate_2CDO_Rule__c = FALSE,
            sked__Pattern__c = Json.serialize(weeklyPatternData)
        );
        secondList.add(testWeeklyPattern1);
        mapTestData.put('testWeeklyPattern1', testWeeklyPattern1);

        skedAvailabilityPatternData customPatternData = new skedAvailabilityPatternData();
        customPatternData.type = 'custom';
        customPatternData.repeatWeeks = 1;
        customPatternData.lengthDays = 1;
        List<string> customWeekdays = new List<string> {'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'};
        customPatternData.days = new List<skedAvailabilityPatternData.dayModel>();
        for (integer index = 0; index < customWeekdays.size(); index++) {
            string weekday = customWeekdays.get(index);
            skedAvailabilityPatternData.dayModel day = new skedAvailabilityPatternData.dayModel();
            day.weekday = weekday;
            day.day = index;
            day.intervals = new List<skedAvailabilityPatternData.intervalModel>();
            skedAvailabilityPatternData.intervalModel interval = new skedAvailabilityPatternData.intervalModel();
            interval.startTime = '09:00';
            interval.endTime = '18:00';
            day.intervals.add(interval);
            customPatternData.days.add(day);
        }
        sked__Availability_Pattern__c testWeeklyPattern2 = new sked__Availability_Pattern__c(
            Name = 'Test Weekly Pattern 2',
            sked__Hash__c = 'customPatternHash',
            sked_Validate_2CDO_Rule__c = FALSE,
            sked__Pattern__c = Json.serialize(customPatternData)
        );
        secondList.add(testWeeklyPattern2);
        mapTestData.put('testWeeklyPattern2', testWeeklyPattern2);

        sked_Collection_Op_Staging_Location__c testCollectionOpStagingLoc1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        secondList.add(testCollectionOpStagingLoc1);
        mapTestData.put('testCollectionOpStagingLoc1', testCollectionOpStagingLoc1);

        Collection_Operation_Time_Block__c testCOTB1 = new Collection_Operation_Time_Block__c(
            Collection_Operation__c = testCollectionOperation1.Id,
            Time_Block__c = testTimeBlock1.Id,
            Effective_Start_Date__c = this.summary.startDate,
            Effective_End_Date__c = this.summary.endDate
        );
        secondList.add(testCOTB1);
        mapTestData.put('testCOTB1', testCOTB1);

        insert secondList;

        /***** Third list ****/
        List<sObject> thirdList = new List<sObject>();

        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked_Address_1__c = 'Inner Parkside', 
            sked_City__c = 'San Francisco', 
            sked_State__c = 'CA', 
            sked_Zip_Code__c = '94116', 
            sked_County__c = 'USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = this.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = this.summary.timezoneSidId,
            sked_MigrationID__c = 'migration-id',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        thirdList.add(testLocation1);
        this.mapTestData.put('testLocation1', testLocation1);
        
        sked__Location__c testLocation2 = new sked__Location__c(
            Name = 'Test Location 2',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked_Address_1__c = 'Inner Parkside', 
            sked_City__c = 'San Francisco', 
            sked_State__c = 'CA', 
            sked_Zip_Code__c = '94117', 
            sked_County__c = 'USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = this.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name 2',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = this.summary.timezoneSidId,
            sked_MigrationID__c = 'migration-id',
            Source__c = 'Custom New Form',
            Operation_Type__c = skedConstants.OPERATION_TYPE_WB,
            RecordTypeId = sked__Location__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId()
        );
        thirdList.add(testLocation2);
        this.mapTestData.put('testLocation2', testLocation2);

        sked__Resource__c testResource1 = new sked__Resource__c(
            Name = 'Test Resource 1',
            sked__Primary_Region__c = testRegion1.Id,
            sked__User__c = UserInfo.getUserId(),
            sked__Resource_Type__c = 'Person',
            sked__Employment_Type__c = resourceEmploymentTypes.get(0),
            sked__Category__c = resourceCategories.get(0),
            sked__Home_Address__c = 'Inner Sunset, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked__Email__c = 'test@com.test1',
            sked__Primary_Phone__c = '1234567890',
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = '2RBC',
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Test',
            sked_Last_Name__c = 'Resource 1',
            sked_ULID__c = 'ULID1',
            sked_Timezone__c = this.summary.timezoneSidId,
            sked_Address_Referenced_for_Scheduling__c = 'Home',
            sked_Home_Address_GeoLocation__Latitude__s = 37.7575256,
            sked_Home_Address_GeoLocation__Longitude__s = -122.4730585,
            sked_Max_Travel_Time__c = 5,
            sked_Min_Working_Days_Per_Week__c = '2',
            Use_CO_Address_for_Scheduling__c = false,
            sked_FCC_Code__c = '83140;83340',
            sked_Supervisor_Email__c = UserInfo.getUserEmail()
        );
        thirdList.add(testResource1);
        this.mapTestData.put('testResource1', testResource1);

        sked__Resource__c testResource2 = new sked__Resource__c(
            Name = 'Test Resource 2',
            sked__Primary_Region__c = testRegion1.Id,
            sked__Resource_Type__c = 'Person',
            sked__Employment_Type__c = resourceEmploymentTypes.get(0),
            sked__Category__c = resourceCategories.get(0),
            sked__Home_Address__c = 'Inner Sunset, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked__Email__c = 'test@com.test1',
            sked__Primary_Phone__c = '1234567890',
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = '2RBC',
            sked_Employee_ID__c = '002',
            sked_Title__c = 'Sir',
            sked_First_Name__c = 'Barry',
            sked_Last_Name__c = 'White',
            sked_ULID__c = 'fe37f73y2',
            sked_Timezone__c = this.summary.timezoneSidId,
            sked_Address_Referenced_for_Scheduling__c = 'Home',
            sked_Home_Address_GeoLocation__Latitude__s = 37.7575256,
            sked_Home_Address_GeoLocation__Longitude__s = -122.4730585,
            sked_Min_Working_Days_Per_Week__c = '2',
            Use_CO_Address_for_Scheduling__c = false,
            sked_FCC_Code__c = '83140;83340'
        );
        thirdList.add(testResource2);
        this.mapTestData.put('testResource2', testResource2);

        sked__Resource__c testVehicle1 = new sked__Resource__c(
            Name = 'Test Vehicle 1',
            sked__Primary_Region__c = testRegion1.Id,
            sked__Resource_Type__c = 'Asset',
            sked__Category__c = assetCategories.get(0),
            sked_Asset_Type__c = 'Vehicle',
            sked_Pres_Donor_Capacity__c = 50,
            sked__Is_Active__c = TRUE,
            sked_Max_Hours_Per_Week__c = null,
            Use_CO_Address_for_Scheduling__c = false
        );
        thirdList.add(testVehicle1);
        this.mapTestData.put('testVehicle1', testVehicle1);

        sked__Resource__c testVehicle2 = new sked__Resource__c(
            Name = 'Test Vehicle 2',
            sked__Primary_Region__c = testRegion1.Id,
            sked__Resource_Type__c = 'Asset',
            sked__Category__c = assetCategories.get(1),
            sked_Asset_Type__c = 'Vehicle',
            sked_Pres_Donor_Capacity__c = 50,
            sked__Is_Active__c = TRUE,
            sked_Max_Hours_Per_Week__c = null,
            Use_CO_Address_for_Scheduling__c = false
        );
        thirdList.add(testVehicle2);
        this.mapTestData.put('testVehicle2', testVehicle2);

        sked__Resource__c testEquipment1 = new sked__Resource__c(
            Name = 'Test Equipment 1',
            sked__Primary_Region__c = testRegion1.Id,
            sked__Resource_Type__c = 'Asset',
            sked__Category__c = assetCategories.get(0),
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset',
            sked__Is_Active__c = TRUE,
            sked_Max_Hours_Per_Week__c = null,
            Use_CO_Address_for_Scheduling__c = false
        );
        thirdList.add(testEquipment1);
        this.mapTestData.put('testEquipment1', testEquipment1);

        for (string weekday : this.summary.weekdays) {
            sked__Availability_Template_Entry__c testEntry = new sked__Availability_Template_Entry__c(
                sked__Availability_Template__c = testTemplate1.Id,
                sked__Weekday__c = weekday.toUpperCase(),
                sked__Start_Time__c = 700,
                sked__Finish_Time__c = 1900
            );
            thirdList.add(testEntry);
        }

        insert thirdList;

        /***** Forth list ****/
        List<sObject> forthList = new List<sObject>();
        
        sked_Site_Collection_Operation__c testLocation1_testCollectionOperation1 = new sked_Site_Collection_Operation__c(
        	sked_Site__c = testLocation1.Id,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Region__c = testRegion1.Id,
            sked_Start_Date__c = this.summary.startDate,
            sked_End_Date__c = this.summary.endDate,
            External_Id_BackEnd__c = UUID.randomUUID().toString(),
            External_Id__c = UUID.randomUUID().toString()
        );
        forthList.add(testLocation1_testCollectionOperation1);
        this.mapTestData.put('testLocation1_testCollectionOperation1', testLocation1_testCollectionOperation1);
        
        sked__Tag__c tag2RBC;
        for (sObject record : predefinedData) {
            if (record.get('Name') == '2RBC') {
                tag2RBC = (sked__Tag__c) record;
                break;
            }
        }
        this.mapTestData.put('testTag2RBC', tag2RBC);

        sked__Resource_Tag__c testResource1_testTag2RBC = new sked__Resource_Tag__c(
            sked__Resource__c = testResource1.Id,
            sked__Tag__c = tag2RBC.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = 'Active'
        );
        forthList.add(testResource1_testTag2RBC);
        this.mapTestData.put('testResource1_testTag2RBC', testResource1_testTag2RBC);

        sked__Resource_Tag__c testResource1_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource1.Id,
            sked__Tag__c = testTag1.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        forthList.add(testResource1_testTag1);

        sked__Resource_Region__c testResource1_testRegion2 = new sked__Resource_Region__c(
            sked__Resource__c = testResource1.Id,
            sked__Region__c = testRegion2.Id
        );
        forthList.add(testResource1_testRegion2);

        sked__Availability_Template_Resource__c testResource1_testTemplate1 = new sked__Availability_Template_Resource__c(
            sked__Resource__c = testResource1.Id,
            sked__Availability_Template__c = testTemplate1.Id
        );
        forthList.add(testResource1_testTemplate1);
        
		TriggerHandler.bypass('SiteTriggerHandler');
        insert forthList;

        skedHubBase.setBypassAllTriggers(false);
        TriggerHandler.clearBypass('SiteTriggerHandler');
        return this.mapTestData;
    }

    public Map<string, sObject> setupRacTestData() {
        skedHubBase.setBypassAllTriggers(true);
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        
        setupAdminConsoleTestData();

        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        Biomed_Collection_Op_Center__c testCollectionOp1 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');

        List<sObject> secondList = new List<sObject>();

        sked__Availability__c testAvailability1 = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Available',
            sked__Is_Available__c = TRUE,
            sked__Start__c = this.summary.startTime.addHours(9),
            sked__Finish__c = this.summary.startTime.addHours(17),
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
        secondList.add(testAvailability1);
        this.mapTestData.put('testAvailability1', testAvailability1);

        sked__Activity__c testActivity1 = new sked__Activity__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = this.summary.startTime.addHours(9),
            sked__End__c = this.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        secondList.add(testActivity1);
        this.mapTestData.put('testActivity1', testActivity1);

        sked__Activity__c testGroupActivity1 = new sked__Activity__c(
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked__Type__c = 'Administration',
            sked__Start__c = this.summary.startTime.addDays(1).addHours(9),
            sked__End__c = this.summary.startTime.addDays(1).addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Is_Group_Activity__c = TRUE
        );
        secondList.add(testGroupActivity1);
        this.mapTestData.put('testGroupActivity1', testGroupActivity1);

        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = this.summary.startTime.addHours(11),
            sked__Finish__c = this.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION
        );
        secondList.add(testJob1);
        this.mapTestData.put('testJob1', testJob1);

        sked__Recurring_Schedule__c testRecurringSchedule1 = new sked__Recurring_Schedule__c();
        insert testRecurringSchedule1;

        sked_Staffing_Budget__c testStaffingBudget1 = new sked_Staffing_Budget__c(
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = this.summary.startDate.addDays(1),
            sked_Total_Slots__c = 20,
            sked_Request_Type__c = 'Standard',
            sked_Recurring_Schedule__c = testRecurringSchedule1.Id
        );
        secondList.add(testStaffingBudget1);
        this.mapTestData.put('testStaffingBudget1', testStaffingBudget1);
        
        sked_Staffing_Budget__c testStaffingBudget2 = new sked_Staffing_Budget__c(
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = this.summary.startDate,
            sked_Total_Slots__c = 10,
            sked_Request_Type__c = 'Standard'
        );
        secondList.add(testStaffingBudget2);
        this.mapTestData.put('testStaffingBudget_nonRecurring', testStaffingBudget2);

        insert secondList;

        List<sObject> thirdList = new List<sObject>();

        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCollectionOp1 = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = testStaffingBudget1.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOp1.Id
        );
        thirdList.add(testStaffingBudgetCollectionOp1);
        this.mapTestData.put('testStaffingBudgetCollectionOp1', testStaffingBudgetCollectionOp1);

        sked__Job_Allocation__c testJobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        thirdList.add(testJobAllocation1);
        this.mapTestData.put('testJobAllocation1', testJobAllocation1);

        sked__Activity_Resource__c testActivityResource1 = new sked__Activity_Resource__c(
            sked__Activity__c = testGroupActivity1.Id,
            sked__Resource__c = testResource1.Id,
            sked_Start1__c = testGroupActivity1.sked__Start__c,
            sked_End__c = testGroupActivity1.sked__End__c
        );
        thirdList.add(testActivityResource1);
        this.mapTestData.put('testActivityResource1', testActivityResource1);

        insert thirdList;

        skedHubBase.setBypassAllTriggers(false);
        return this.mapTestData;
    }

    public Map<string, sObject> setupAdminConsoleTestData() {
        setupCommonTestData();

        return this.mapTestData;
    }

    public List<sObject> setupDriveRankingSettings() {
        List<sObject> settings = new List<sObject>();

        sked_Drive_Rank_Setting__c plannedProductivity0 = new sked_Drive_Rank_Setting__c(
        	Name = 'Planned Productivity 0',
            sked_Type__c = 'Planned Productivity',
            sked_Point__c = 0,
            sked_Low_End__c = 0,
            sked_High_End__c = 0.49
        );
        settings.add(plannedProductivity0);

        sked_Drive_Rank_Setting__c plannedProductivity1 = new sked_Drive_Rank_Setting__c(
        	Name = 'Planned Productivity 1',
            sked_Type__c = 'Planned Productivity',
            sked_Point__c = 1,
            sked_Low_End__c = 0.49,
            sked_High_End__c = 0.55
        );
        settings.add(plannedProductivity1);

        sked_Drive_Rank_Setting__c plannedProductivity2 = new sked_Drive_Rank_Setting__c(
        	Name = 'Planned Productivity 2',
            sked_Type__c = 'Planned Productivity',
            sked_Point__c = 2,
            sked_Low_End__c = 0.55,
            sked_High_End__c = 0.66
        );
        settings.add(plannedProductivity2);

        sked_Drive_Rank_Setting__c plannedProductivity3 = new sked_Drive_Rank_Setting__c(
        	Name = 'Planned Productivity 3',
            sked_Type__c = 'Planned Productivity',
            sked_Point__c = 3,
            sked_Low_End__c = 0.66,
            sked_High_End__c = 0.8
        );
        settings.add(plannedProductivity3);

        sked_Drive_Rank_Setting__c plannedProductivity4 = new sked_Drive_Rank_Setting__c(
        	Name = 'Planned Productivity 4',
            sked_Type__c = 'Planned Productivity',
            sked_Point__c = 4,
            sked_Low_End__c = 0.8,
            sked_High_End__c = 999
        );
        settings.add(plannedProductivity4);


        sked_Drive_Rank_Setting__c size0 = new sked_Drive_Rank_Setting__c(
        	Name = 'Size 0',
            sked_Type__c = 'Size',
            sked_Point__c = 0,
            sked_Low_End__c = 0,
            sked_High_End__c = 14
        );
        settings.add(size0);

        sked_Drive_Rank_Setting__c size1 = new sked_Drive_Rank_Setting__c(
        	Name = 'Size 1',
            sked_Type__c = 'Size',
            sked_Point__c = 1,
            sked_Low_End__c = 15,
            sked_High_End__c = 24
        );
        settings.add(size1);

        sked_Drive_Rank_Setting__c size2 = new sked_Drive_Rank_Setting__c(
        	Name = 'Size 2',
            sked_Type__c = 'Size',
            sked_Point__c = 2,
            sked_Low_End__c = 25,
            sked_High_End__c = 29
        );
        settings.add(size2);

        sked_Drive_Rank_Setting__c size3 = new sked_Drive_Rank_Setting__c(
        	Name = 'Size 3',
            sked_Type__c = 'Size',
            sked_Point__c = 3,
            sked_Low_End__c = 30,
            sked_High_End__c = 49
        );
        settings.add(size3);

        sked_Drive_Rank_Setting__c size4 = new sked_Drive_Rank_Setting__c(
        	Name = 'Size 4',
            sked_Type__c = 'Size',
            sked_Point__c = 4,
            sked_Low_End__c = 50,
            sked_High_End__c = 74
        );
        settings.add(size4);

        sked_Drive_Rank_Setting__c size5 = new sked_Drive_Rank_Setting__c(
        	Name = 'Size 5',
            sked_Type__c = 'Size',
            sked_Point__c = 5,
            sked_Low_End__c = 75,
            sked_High_End__c = 99
        );
        settings.add(size5);

        sked_Drive_Rank_Setting__c size6 = new sked_Drive_Rank_Setting__c(
        	Name = 'Size 6',
            sked_Type__c = 'Size',
            sked_Point__c = 6,
            sked_Low_End__c = 100,
            sked_High_End__c = 9999
        );
        settings.add(size6);

        return settings;
    }

    public List<sked_Staff_Setup_Excluded_Role__c> setupStaffSetupExcludedRoles() {
        return new List<sked_Staff_Setup_Excluded_Role__c> {
            new sked_Staff_Setup_Excluded_Role__c(
                Name = 'Charge Mentor',
                sked_Resource_Role__c = 'Charge Mentor',
                sked_Excluded_For_Staff_Allocated__c = false,
                sked_Excluded_For_Assigned_Staff_Count__c = true
            ),
            new sked_Staff_Setup_Excluded_Role__c(
                Name = 'OJI',
                sked_Resource_Role__c = 'OJI',
                sked_Excluded_For_Staff_Allocated__c = false,
                sked_Excluded_For_Assigned_Staff_Count__c = true
            ),
            new sked_Staff_Setup_Excluded_Role__c(
                Name = 'Trainee',
                sked_Resource_Role__c = 'Trainee',
                sked_Excluded_For_Staff_Allocated__c = true,
                sked_Excluded_For_Assigned_Staff_Count__c = true
            ),
            new sked_Staff_Setup_Excluded_Role__c(
                Name = 'Work Restriction',
                sked_Resource_Role__c = 'Work Restriction',
                sked_Excluded_For_Staff_Allocated__c = false,
                sked_Excluded_For_Assigned_Staff_Count__c = true
            ),
            new sked_Staff_Setup_Excluded_Role__c(
                Name = 'TRN HH',
                sked_Resource_Role__c = 'TRN HH',
                sked_Excluded_For_Staff_Allocated__c = false,
                sked_Excluded_For_Assigned_Staff_Count__c = true
            ),
            new sked_Staff_Setup_Excluded_Role__c(
                Name = 'TRN VP',
                sked_Resource_Role__c = 'TRN VP',
                sked_Excluded_For_Staff_Allocated__c = false,
                sked_Excluded_For_Assigned_Staff_Count__c = true
            ),
            new sked_Staff_Setup_Excluded_Role__c(
                Name = 'Regulated - Medical Screeners',
                sked_Resource_Role__c = 'Regulated - Medical Screeners',
                sked_Excluded_For_Staff_Allocated__c = true,
                sked_Excluded_For_Assigned_Staff_Count__c = false
            )
        };
    }

    public Map<string, sObject> setupDriveData() {
        skedHubBase.setBypassAllTriggers(true);
        List<sObject> rankingSettings = setupDriveRankingSettings();
        insert rankingSettings;

        List<sked_Staff_Setup_Excluded_Role__c> staffSetupExcludedRoles = setupStaffSetupExcludedRoles();
        insert staffSetupExcludedRoles;

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Territory__c testTerritory1 = (sked_Territory__c)mapTestData.get('testTerritory1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        sked__Location__c testLocation2 = (sked__Location__c)mapTestData.get('testLocation2');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');

        // Opportunity parentOpp = new Opportunity(
        //     Name = 'parent',
        //     AccountId = testAccount1.Id,
        //     StageName = 'Discovery',
        //     CloseDate = this.summary.startDate,
        //     Is_template__c = TRUE,
        //     Web_Sched_Offset_from_CO_Global_Settings__c = TRUE
        // );
        // insert parentOpp;

        List<sObject> firstList = new List<sObject>();

        Date taxonomyEffectiveDate = Date.newInstance(2024, 1, 22);
        Date driveStartDate = this.summary.startDate > taxonomyEffectiveDate ? this.summary.startDate : taxonomyEffectiveDate;
        
        DateTime driveDateDt = DateTime.newInstance(driveStartDate, Time.newInstance(0, 0, 0, 0));
        string driveDateDayOfWeek = driveDateDt.format('EEEE');
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = driveStartDate,
            Drive_Site__c = testLocation1.Id,
            StageName = 'Solicitation',
            CloseDate = driveStartDate,
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            //Split_Reason__c = 'RSMO Donations**'
            Accept_56_Day_Rule_Violation__c = true
        );
        firstList.add(testOpportunity);
        this.mapTestData.put('testOpportunity', testOpportunity);

        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = driveStartDate.addDays(1),
            Drive_Site__c = testLocation1.Id,
            StageName = 'Solicitation',
            CloseDate = driveStartDate,
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No'
            //Split_Reason__c = 'RSMO Donations**'
        );
        firstList.add(testOpportunity2);
        this.mapTestData.put('testOpportunity2', testOpportunity2);

        Opportunity testOpportunity3 = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = driveStartDate.addDays(1),
            Drive_Site__c = testLocation2.Id,
            StageName = 'Solicitation',
            CloseDate = driveStartDate,
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Source__c = 'Calendar Build',
            Anticipated_Registered_Donors__c = 100
            //Split_Reason__c = 'RSMO Donations**'
        );
        firstList.add(testOpportunity3);
        this.mapTestData.put('testOpportunity3', testOpportunity3);

        insert firstList;

        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive',
            sked_District__c = testTerritory1.Id,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Date__c = driveStartDate,
            sked_Day_of_Week__c = driveDateDayOfWeek,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = testOpportunity.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10,
            sked_Staging_Location__c = testStagingLocation1.Id
        );
        insert testDrive1;
        this.mapTestData.put('testDrive1', testDrive1);

        sked_Drive__c testDrive2 = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Date__c = driveStartDate,
            sked_Day_of_Week__c = driveDateDayOfWeek,
            sked_Drive_Site__c = testLocation2.Id,
            sked_Opportunity__c = testOpportunity3.Id,
            sked_Type_of_Drive__c = 'Fixed Site',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10,
            sked_Staging_Location__c = testStagingLocation1.Id
        );
        insert testDrive2;
        this.mapTestData.put('testDrive2', testDrive2);

        skedHubBase.setBypassAllTriggers(false);
        return this.mapTestData;
    }

    /********************************************** Private methods ******************************************/
    private void setLocale(string locale) {
        this.summary.timezoneSidId = UserInfo.getTimezone().getID();
        locale = locale.toLowerCase();
        if (locale == 'us') {
            this.summary.firstDay = 0;
            this.summary.weekdays = new List<string> {'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'};
            this.summary.weekends = new List<string> {'sat', 'sun'};
        }
    }

    private void setupDateTime(Date startDate, integer period) {
        Date nextWeekFirstDate = startDate.addDays(this.summary.firstDay).toStartOfWeek().addDays(7).addDays(-this.summary.firstDay);
        this.summary.startDate = nextWeekFirstDate;
        this.summary.endDate = nextWeekFirstDate.addDays(period);
        this.summary.startTime = DateTime.newInstance(this.summary.startDate, time.newInstance(0, 0, 0, 0));
        this.summary.endTime = DateTime.newInstance(this.summary.endDate, time.newInstance(0, 0, 0, 0));
        this.summary.startDateIso = Json.serialize(this.summary.startDate).replace('"', '');
        this.summary.endDateIso = Json.serialize(this.summary.endDate).replace('"', '');
    }

    /********************************************** Test Summary ******************************************/
    public class testDataSummary {
        public integer firstDay;
        public Date startDate;
        public Date endDate;
        public DateTime startTime;
        public DateTime endTime;
        public string startDateIso;
        public string endDateIso;
        public string timezoneSidId;
        public List<string> weekdays;
        public List<string> weekends;
    }

}