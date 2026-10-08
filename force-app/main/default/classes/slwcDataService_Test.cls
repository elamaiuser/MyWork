@isTest
private class slwcDataService_Test {
    
    static testmethod void testExecuteQueries() {
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Test.startTest();
        
        string singleQuery = 'SELECT Id FROM sked__Region__c WHERE Name =\'Region 1\'';
        List<sObject> singleQueryResult = (List<sObject>)slwcDataService.executeQuery(singleQuery);
        
        List<slwcDataService.queryModel> queries = new List<slwcDataService.queryModel>();
        slwcDataService.queryModel coQuery = new slwcDataService.queryModel();
        coQuery.key = 'Collection Operation';
        coQuery.query = 'SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Name =\'Collection Operation 1\'';
        coQuery.fieldToExtractId = 'Id';
        queries.add(coQuery);
        
        slwcDataService.queryModel regionQuery = new slwcDataService.queryModel();
        regionQuery.key = 'Region';
        regionQuery.query = 'SELECT Id, Name, sked_Biomed_Collection_Op_Center__c FROM sked__Region__c WHERE sked_Biomed_Collection_Op_Center__c IN :allIds';
        queries.add(regionQuery);
        
        List<slwcDataService.queryResultModel> multipleQueriesResult = (List<slwcDataService.queryResultModel>)slwcDataService.executeQueries(queries);
        
        Test.stopTest();
    }

    static testmethod void testGetCustomSettings() {
        sked_Resource_Role_Group__c drivingGroup = new sked_Resource_Role_Group__c(
        	sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c = 'Competent Driver;Driver;Driver CDL B;Driver Support;Driver Tech Trainee;Staff Shuttle'
        );
        insert drivingGroup;
        
        sked_Event_Type_Setting__c eventTypeSetting = new sked_Event_Type_Setting__c(
        	Name = 'Event Setting 1',
            sked_Is_Active__c = TRUE,
            sked_Category__c = 'clientAvailability'
        );
        insert eventTypeSetting;
        
        sked_Staff_Count_Threshold__c testStaffCountThreshold = new sked_Staff_Count_Threshold__c(
        	sked_Staff_Count_Threshold__c = 11
        );
        insert testStaffCountThreshold;
        
        Test.startTest();
        
        List<string> settingKeys = new List<string>();
        settingKeys.add('adminSetting');
        settingKeys.add('lac');
        settingKeys.add('pac');
        settingKeys.add('rac');
        settingKeys.add('mapRoleToPremiumOpPay');
        settingKeys.add('resourceRoleGroups');
        settingKeys.add('lunchBreakSettings');
        settingKeys.add('maxCDLDOTDuration');
        settingKeys.add('exceptionSettings');
        settingKeys.add('staffSetupExcludedRoles');
        settingKeys.add('optimizerDefaultWeights');
        settingKeys.add('optimizerDefaultSettings');
        settingKeys.add('rtvAPSApprovalWindow');
        settingKeys.add('travelTimeManager');
        settingKeys.add('redcrossVolunteerMatrix');
        settingKeys.add('staffCountThresholds');
        slwcDataService.getCustomSettings(settingKeys);
        
        Test.stopTest();
    }
    
    static testmethod void testGetSObjectName() {
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;
        
        Test.startTest();
        
        slwcDataService.getSObjectName(testCollectionOperation1.Id);
        
        Test.stopTest();
    }
    
    static testmethod void testDynamicDML() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        Date driveDate = system.today().addMonths(6);
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
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
            sked_Date_Site_Inspection_Completed__c = system.today(),
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
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        insert testLocation1;
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery', 
            CloseDate = driveDate,
            Is_template__c = TRUE
        );
        insert parentOpp;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = driveDate,
            Drive_Site__c = testLocation1.Id,
            StageName = 'Solicitation',
            CloseDate = driveDate,
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No'
        );
        insert testOpportunity;
        
        Test.startTest();
        
        List<slwcDataService.sObjectWrapper> wrappers = new List<slwcDataService.sObjectWrapper>();
        slwcDataService.sObjectWrapper driveWrapper = new slwcDataService.sObjectWrapper();
        wrappers.add(driveWrapper);
        
        sked_Drive__c testDrive1 = new sked_Drive__c(
        	Name = 'Test Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Date__c = driveDate,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = testOpportunity.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(9, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 50
        );
        driveWrapper.sObj = testDrive1;
        driveWrapper.relatedListWrappers = new List<slwcDataService.relatedListWrapper>();
        
        slwcDataService.relatedListWrapper driveShiftsWrapper = new slwcDataService.relatedListWrapper();
        driveShiftsWrapper.parentField = 'sked_Drive__c';
        driveShiftsWrapper.sObjectType = 'sked_Drive_Shift__c';
        driveShiftsWrapper.sObjectWrappers = new List<slwcDataService.sObjectWrapper>();
        driveWrapper.relatedListWrappers.add(driveShiftsWrapper);
        
        slwcDataService.sObjectWrapper driveShiftWrapper = new slwcDataService.sObjectWrapper();
        sked_Drive_Shift__c testDriveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(17,0,0,0),
            sked_Start_Time__c = Time.newInstance(9,0,0,0),
            sked_Drive_Date__c = driveDate,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(driveDate, Time.newInstance(17,0,0,0)),
            sked_Start__c = DateTime.newInstance(driveDate, Time.newInstance(9,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        driveShiftWrapper.sObj = testDriveShift1;
        driveShiftsWrapper.sObjectWrappers.add(driveShiftWrapper);
        
        slwcDataService.dynamicUpsert(wrappers);
        
        List<string> deletedRecordIds = new List<string>();
        deletedRecordIds.add(testDrive1.Id);
        slwcDataService.dynamicDelete('sked_Drive__c', deletedRecordIds);
        
        List<slwcDataService.deleteWrapper> deleteWrappers = new List<slwcDataService.deleteWrapper>();
        slwcDataService.deleteWrapper coDeleteWrapper = new slwcDataService.deleteWrapper();
        coDeleteWrapper.id = testCollectionOperation1.Id;
        coDeleteWrapper.children = new List<slwcDataService.deleteWrapper>();
        deleteWrappers.add(coDeleteWrapper);
        
        slwcDataService.deleteWrapper regionDeleteWrapper = new slwcDataService.deleteWrapper();
        regionDeleteWrapper.id = testRegion1.Id;
        coDeleteWrapper.children.add(regionDeleteWrapper);
        
        slwcDataService.dynamicUpsert(new List<slwcDataService.sObjectWrapper>(), deleteWrappers);

        try {
            driveWrapper.isChanged = true;
            slwcDataService.dynamicUpsert(wrappers);
        } catch (skedException e) {
            System.assert(e.getMessage().contains('Object sked_Drive__c with record IDs ' + testDrive1.Id + ' failed by following errors'));
        }
        
        Test.stopTest();
    }
    
    static testmethod void testGetPicklistOptions() {
        slwcDataService.getPicklistOptions('Account', 'Type');
        slwcDataService.getMapDependentOptions('Account', 'Type', 'Industry_Code__c');
    }
    
}