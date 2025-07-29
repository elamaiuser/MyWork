@isTest
public class GenerateDriveTestData {
    public static List<sObject> fifthList = new List<sObject>();
    
    @isTest
    public static Map<string, sObject> setupData()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        Map<string, sObject> mapTestData = new Map<string, sObject>();
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        /***** First list ****/
        List<sObject> firstList = new List<sObject>();
        
        // Collection Operation - 1
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 15,
            sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Travel_Time_Included_Fixed_Site__c = 'Drivers Only',
            sked_Travel_Time_Included_Mobile__c = 'All Roles',
            sked_Lunch_Break__c = true
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);
        
        // Collection Operation - 2
        Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 25,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
          	sked_Breakdown_Time_Threshold__c = 15,
          	sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Lunch_Break__c = true,
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Travel_Time_Included_Fixed_Site__c = 'Drivers Only',
            sked_Travel_Time_Included_Mobile__c = 'All Roles'
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);
        
        /* Staffing Decision matrix - Mobile
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 1,
            sked_VP_HH_Capacity__c = 2.2,
           // sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 15,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix);*/
        
        // Staffing Decision matrix - fixed site
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_WB_Hourly_Capacity__c = 2.1,
            sked_Plasma_Hourly_Capacity__c = 1.17,
            sked_Platelet_Round_Capacity__c = 0.17,
            sked_2RBC_Hourly_Capacity__c = 1,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix2);
        
        // Lunch Break Setting
        sked_Lunch_Break_Setting__c lunchBreakSetting30 = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        firstList.add(lunchBreakSetting30);
        
        // Mobile Account
        Account mobileAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='TEst_Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId()
        );
        firstList.add(mobileAccount);
        mapTestData.put('mobileAccount', mobileAccount);
        
        // Fixed Site Account
        Account fixedSiteAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='TEst_Account1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()
        );
        firstList.add(fixedSiteAccount);
        mapTestData.put('fixedSiteAccount', fixedSiteAccount);
        
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(usCitizenTag);
        mapTestData.put('usCitizenTag', usCitizenTag);
        
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(spanishTag);
        mapTestData.put('spanishTag', spanishTag);
        
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(liftGateTag);
        mapTestData.put('liftGateTag', liftGateTag);
        
        
        sked__Tag__c personTag = new sked__Tag__c(
            Name = 'Sample Person Tag',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(personTag);
        mapTestData.put('personTag', personTag);
        
        sked__Tag__c vehicleTag = new sked__Tag__c(
            Name = 'Sample Vehicle Tag',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(vehicleTag);
        mapTestData.put('vehicleTag', vehicleTag);
        
        sked__Tag__c equipmentTag = new sked__Tag__c(
            Name = 'Sample Equipment Tag',
            sked_Resource_Type__c = 'Equipment'
        );
        firstList.add(equipmentTag);        
        mapTestData.put('equipmentTag', equipmentTag);
        
        insert firstList;
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = Userinfo.getUserId() ;
        atm.AccountId = mobileAccount.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        /***** Second list ****/
        List<sObject> secondList = new List<sObject>();
        
        // Template Opp
        Opportunity parentOpp = new Opportunity(
            AccountId = mobileAccount.Id,
            Name = 'parent',
            StageName = 'Discovery', 
            CloseDate = testDataFactory.summary.startDate,
            Is_Template__c = TRUE,
            Source__c = 'Calendar Build',
            Web_Sched_Offset_from_CO_Global_Settings__c = True
        );
        secondList.add(parentOpp);
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        mapTestData.put('testRegion1', testRegion1);
        
        // fixed site
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Effective_End_Date__c = Date.newInstance(4000,12,31), 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id
        );
        secondList.add(collectionOperationSdm2);
        
        sked_Lunch_Break_Definition__c setting30definition1 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 50,
            sked_Min_Number_of_Staff__c = 49,
            sked_Slot_Reduction__c = 25
        );
        secondList.add(setting30definition1);
        
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 15,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 50,
            sked_Min_Number_of_Staff__c = 9,
            
            sked_Slot_Reduction__c = 25
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 12,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 50,
            sked_Min_Number_of_Staff__c = 49,
            
            sked_Slot_Reduction__c = 6.67
        );
        secondList.add(setting30definition5);
        
        //  skedFixedSiteProcedureProjectionHandler.bypassInsertTrigger = true;
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'WB',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection1);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = '2RBC',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection2);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Plasma',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection4);
        
        /*sked__Account_Tag__c mobileAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(mobileAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = spanishTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag2);
        
        sked__Account_Tag__c fixedSiteAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = personTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(fixedSiteAccountTag1);
        
        sked__Account_Tag__c fixedSiteAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = equipmentTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(fixedSiteAccountTag2);*/
        
        sked__Account_Tag__c fixedSiteAccountTag3 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = false,
            sked_Minimum_Quantity__c = 1,
            sked__Weighting__c = 10
           // ,sked_Minimum_Quantity__c = 1
        );
        secondList.add(fixedSiteAccountTag3);
        insert secondList;
        
        sked__Account_Tag__c fixedSiteAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = personTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        
        insert fixedSiteAccountTag2;
        
        /***** Third list ****/
        List<sObject> thirdList = new List<sObject>();
        
        // Mobile site
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
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
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form'
            ,sked_Address_1__c = 'ABC STREET'
            , sked_City__c = 'Test City'
            , sked_County__c = 'Test'
            , sked_State__c = 'PA'
            , sked_Zip_Code__c = '18411'
        );
        thirdList.add(testLocation1);
        mapTestData.put('testLocation1', testLocation1);
        
        for (integer i = 1; i <= 5; i++) {
            sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE
            );
            thirdList.add(testVehicle);
            mapTestData.put('testVehicle' + i, testVehicle);
        }
        
        for (integer i = 1; i <= 10; i++) {
            sked__Resource__c test2rbcAsset = new sked__Resource__c(
                Name = 'Test 2RBC ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Equipment', 
                sked_Equipment_Subtype__c = '2RBC Asset',
                sked__Is_Active__c = TRUE
            );
            thirdList.add(test2rbcAsset);
            mapTestData.put('test2rbcAsset' + i, test2rbcAsset);
        }
        
        // Fixed Site
        sked__Location__c testLocation2 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Even',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId(),
            Operation_Type__c = 'Integrated',
            Source__c = 'Custom New Form'
            ,sked_Address_1__c = 'ABC STREET'
            , sked_City__c = 'Test City'
            , sked_County__c = 'Test'
            , sked_State__c = 'PA'
            , sked_Zip_Code__c = '18411'
        );
        thirdList.add(testLocation2);
        mapTestData.put('testLocation2', testLocation2);     
        insert thirdList;

        /***** Forth list ****/
        List<sObject> forthList = new List<sObject>();
        
        sked_Location_Tag__c driveSiteTag1 = new sked_Location_Tag__c(
            sked_Location__c = testLocation2.Id,
            sked_Tag__c = liftGateTag.Id,
            sked_Minimum_Quantity__c = 5,
            sked_Required__c = FALSE
        );
        forthList.add(driveSiteTag1); 
        
        sked_Site_Collection_Operation__c siteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = testLocation1.Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id,
            External_Id__c = 'Bio_Collection_BSF_SiteCo'+'_'+testLocation1.Id+'_'+testDataFactory.summary.startDate,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_SiteCo_Backend_External_Id',
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]',
            sked_Travel_Time_Breakdown_JSON_2__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]'
        );
        system.debug('siteCollectionOperation '+siteCollectionOperation);
        forthList.add(siteCollectionOperation);
        
        sked_Site_Collection_Operation__c siteCollectionOperation2 = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = testLocation2.Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id,
            External_Id__c = 'Bio_Collection_BSF_SiteCo'+'_'+testLocation2.Id+'_'+testDataFactory.summary.startDate,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_SiteCo_Backend_External_Id',
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]',
            sked_Travel_Time_Breakdown_JSON_2__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]'
        );
        forthList.add(siteCollectionOperation2);
        
        sked_Role_Time_Variance__c driverVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation2.Id,
            sked_Resource_Role_Group__c = 'Driving roles', 
            sked_Variance_Applies_to__c = 'Setup Time', 
            sked_Variation_Amount__c = 15, 
            sked_Variation_Type__c = 'Safety Video',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
            
        );
        forthList.add(driverVariance);
        
        sked_Role_Time_Variance__c fixSiteVariance1 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation2.Id,
            sked_Resource_Role_Group__c = 'Staff roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        ); 
        forthList.add(fixSiteVariance1);
        
        sked_Role_Time_Variance__c fixSiteVariance2 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Subtract', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation2.Id,
            sked_Resource_Role_Group__c = 'Supervisory roles', 
            sked_Variance_Applies_to__c = 'Lead Time;Wrap-up Time', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        ); 
        
        forthList.add(fixSiteVariance2);
        
        sked_Role_Time_Detail__c fixSiteRoleTime1 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Resource_Role_Group__c	= 'Staff roles',
            sked_Lead_Time__c = 0,
            sked_Setup_Time__c = 45,
            sked_Breakdown_Time__c = 45,
            sked_Wrap_up_Time__c = 0,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Fixed_Site_Operation_Type__c = 'Integrated'
        );
        forthList.add(fixSiteRoleTime1);
        
        sked_Role_Time_Detail__c fixSiteRoleTime2 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Collection Operation',
            sked_Drive_Type__c = 'Mobile',
            sked_Resource_Role_Group__c	= 'Supervisory roles',
            sked_Lead_Time__c = 10,
            sked_Setup_Time__c = 60,
            sked_Breakdown_Time__c = 60,
            sked_Wrap_up_Time__c = 10,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert fixSiteRoleTime2;
        //forthList.add(fixSiteRoleTime2);
        
        /*sked_Resource_Role_Group__c fixSiteRoleGrp1 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Supervisory roles',
            sked_Resource_Roles__c	= 'Apheresis Charge;Charge;Drive Lead;Team Supervisor'
        );
        forthList.add(fixSiteRoleGrp1);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp2 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Resource_Roles__c	= 'Apheresis;2RBC;2RBC Sign-off;Post Collections'
        );
        forthList.add(fixSiteRoleGrp2);*/
        
        sked_Resource_Role_Group__c fixSiteRoleGrp3 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c	= 'Driver CDL A'
        );
        forthList.add(fixSiteRoleGrp3);
        
        insert forthList;
        
        /***** Sixth list ****/
        List<sObject> sixthList = new List<sObject>();
        
        // Mobile Opp
        Opportunity mobileOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = mobileAccount.Id,
            Anticipated_Registered_Donors__c = 200,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate,
            Drive_Site__c = testLocation1.Id,
            End_Time__c = Time.newInstance(23, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(6, 0, 0, 0), 
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Type_of_Drive__c = 'Mobile',
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830',
            Source__c = 'Calendar Build',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No'
        );
        
        System.debug( 'mobileOpportunity==' + mobileOpportunity );
        sixthList.add(mobileOpportunity);
        mapTestData.put('mobileOpportunity', mobileOpportunity);
        
        //Fixed Site Opp
        Opportunity fixedSiteOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = fixedSiteAccount.Id,
            Anticipated_Registered_Donors__c = 100,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate+2,
            Drive_Site__c = testLocation2.Id,
            End_Time__c = Time.newInstance(23, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Plasma_Pheresis_Projected_Procedures__c = 15,
            Platelet_Projected_Procedures__c = 15,
            Type_of_Drive__c = 'Fixed Site',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Number_of_2RBC_Assets__c = 2,
            Source__c = 'Calendar Build',
            Number_of_Plasma_Assets__c = 2,
            Number_of_Platelet_Assets__c = 2,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830'
        );
        mapTestData.put('fixedSiteOpportunity', fixedSiteOpportunity);
        sixthList.add(fixedSiteOpportunity);
        
        Group collQueue = new Group (Name=testCollectionOperation1.Name+': DMDCR', Type='QUEUE');
        sixthList.add(collQueue);
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert sixthList;
        
        List<sObject> seventhList = new List<sObject>();
        sked_Staging_Location__c stagingLocation = new sked_Staging_Location__c(Name = 'Test Staging Location 1', sked_Timezone__c = 'America/New_York', sked_Zip_Code__c = '18411',
                                                                               sked_GeoLocation__Latitude__s = 38.7631899,
            																	sked_GeoLocation__Longitude__s = -90.3815903);
        seventhList.add(stagingLocation);
        mapTestData.put('stagingLocation', stagingLocation);
        insert seventhList;
        
        List<sObject> eighthList = new List<sObject>();
        sked_Collection_Op_Staging_Location__c colOppStagingLocation = new sked_Collection_Op_Staging_Location__c();
        colOppStagingLocation.sked_Collection_Operation__c = testCollectionOperation2.Id;
        colOppStagingLocation.sked_Staging_Location__c = stagingLocation.Id;
        colOppStagingLocation.sked_Start_Date__c = Date.newInstance(2020,01,01);
        colOppStagingLocation.sked_End_Date__c = Date.newInstance(4000,12,31);
        eighthList.add(colOppStagingLocation);
        mapTestData.put('colOppStagingLocation', colOppStagingLocation);
        insert eighthList;
        
        List<sked_Travel_Time_Index_Item__c> travelTimeIndexItemList = new List<sked_Travel_Time_Index_Item__c>();
        
        sked_Travel_Time_Index_Item__c travelTimeCoToSite = new sked_Travel_Time_Index_Item__c();
        travelTimeCoToSite.sked_From__Latitude__s = 38.7631899;
        travelTimeCoToSite.sked_From__Longitude__s = -90.3815903;
        travelTimeCoToSite.sked_To__Latitude__s = 37.7450046;
        travelTimeCoToSite.sked_To__Longitude__s = -122.4816244;
        travelTimeCoToSite.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]';
        
        travelTimeIndexItemList.add(travelTimeCoToSite);
        
        sked_Travel_Time_Index_Item__c travelTimeSiteToCO = new sked_Travel_Time_Index_Item__c();
        travelTimeSiteToCO.sked_From__Latitude__s = 37.7450046;
        travelTimeSiteToCO.sked_From__Longitude__s = -122.4816244;
        travelTimeSiteToCO.sked_To__Latitude__s = 38.7631899;
        travelTimeSiteToCO.sked_To__Longitude__s = -90.3815903;
        travelTimeSiteToCO.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"}]';
        
        travelTimeIndexItemList.add(travelTimeSiteToCO);
        
        insert travelTimeIndexItemList;    
        
        return mapTestData;
    }

    @isTest
    public static Map<string, sObject> testSetupForElseCondition()
    {
        Triggerhandler.bypass('OpportunitySplitTriggerHandler');
        Map<string, sObject> mapTestData = new Map<string, sObject>();
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        /***** First list ****/
        List<sObject> firstList = new List<sObject>();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 15,
            sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = true,
            sked_Travel_Time_Included_Fixed_Site__c = '	All Roles',
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Lunch_Break__c = true
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);
        
            Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 25,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
          //  sked_Breakdown_Time_Threshold__c = 15,
          //  sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = true,
                sked_Lunch_Break__c = true
          //  sked_Unpaid_Lunch_Break_Duration__c = 30
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 3,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 1,
            sked_VP_HH_Capacity__c = 2.2,
           // sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 15,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix);
        
        // fixed site
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_WB_Hourly_Capacity__c = 2.1,
            sked_Platelet_Hourly_Capacity__c = 0.67,
            sked_Plasma_Hourly_Capacity__c = 1.17,
            sked_2RBC_Hourly_Capacity__c = 1,
            /* sked_2RBC_Staff_Capacity__c = 1.6,
sked_Charge_Capacity__c = 1.1,
sked_Charge_Threshold__c = 36,
sked_Driver_Capacity__c = 2.2,
sked_Driver_Support_Capacity__c = 2.2,
sked_Team_Supervisor_Threshold__c = 36,
sked_VP_HH_Capacity__c = 2.2,*/
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix2);
        
        sked_Lunch_Break_Setting__c lunchBreakSetting30 = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        firstList.add(lunchBreakSetting30);
        
        Account mobileAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='TEst_Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId()
        );
        firstList.add(mobileAccount);
        mapTestData.put('mobileAccount', mobileAccount);
        
        // fixed site account
        Account fixedSiteAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='TEst_Account1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()
        );
        firstList.add(fixedSiteAccount);
        mapTestData.put('fixedSiteAccount', fixedSiteAccount);
        
        // added
        //fixed site account - non integrated WB
        Account nonIntegratedWBAccount = new Account(
            Name = 'Test Account Non Integrate',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='TEst_Account1 2',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()
        );
        // fifthList.add(nonIntegratedWBAccount);
        mapTestData.put('nonIntegratedWBAccount', nonIntegratedWBAccount);

        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(usCitizenTag);
        mapTestData.put('usCitizenTag', usCitizenTag);
        
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(spanishTag);
        mapTestData.put('spanishTag', spanishTag);
        
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(liftGateTag);
        mapTestData.put('liftGateTag', liftGateTag);
        
        
        sked__Tag__c personTag = new sked__Tag__c(
            Name = 'Sample Person Tag',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(personTag);
        mapTestData.put('personTag', personTag);
        
        sked__Tag__c vehicleTag = new sked__Tag__c(
            Name = 'Sample Vehicle Tag',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(vehicleTag);
        mapTestData.put('vehicleTag', vehicleTag);
        
        sked__Tag__c equipmentTag = new sked__Tag__c(
            Name = 'Sample Equipment Tag',
            sked_Resource_Type__c = 'Equipment'
        );
        firstList.add(equipmentTag);        
        mapTestData.put('equipmentTag', equipmentTag);
        
        insert firstList;
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = Userinfo.getUserId() ;
        atm.AccountId = mobileAccount.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        /***** Second list ****/
        List<sObject> secondList = new List<sObject>();
        
        Opportunity parentOpp = new Opportunity(
            AccountId = mobileAccount.Id,
            Name = 'parent',
            StageName = 'Discovery', 
            CloseDate = testDataFactory.summary.startDate,
            Is_Template__c = TRUE,
            Source__c = 'Calendar Build',
            Web_Sched_Offset_from_CO_Global_Settings__c = True
        );
        secondList.add(parentOpp);
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        mapTestData.put('testRegion1', testRegion1);

        sked__Region__c testRegion2 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation2.Id
        );
        secondList.add(testRegion2);
        mapTestData.put('testRegion2', testRegion2);
        
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id
        );
        secondList.add(collectionOperationSdm);
        // fixed site
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id
        );
        secondList.add(collectionOperationSdm2);
        
        sked_Lunch_Break_Definition__c setting30definition1 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 2,
            sked_Min_Number_of_Staff__c = 0,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition1);
        
      /*  sked_Lunch_Break_Definition__c setting30definition2 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 9,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 3,
            sked_Min_Number_of_Staff__c = 3,
            sked_Slot_Reduction__c = 3.33
        );
        secondList.add(setting30definition2); */
        
        /*  sked_Lunch_Break_Definition__c setting30definition3 = new sked_Lunch_Break_Definition__c(
sked_Lunch_Break_Duration__c = 120,
sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
sked_Max_Number_of_Staff__c = 8,
sked_Min_Number_of_Staff__c = 4,
sked_Slot_Reduction__c = 5
);
secondList.add(setting30definition3); */
        
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 15,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 16,
            sked_Min_Number_of_Staff__c = 9,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 12,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 9,
            sked_Min_Number_of_Staff__c = 17,
            
            sked_Slot_Reduction__c = 6.67
        );
        secondList.add(setting30definition5);
        
        //  skedFixedSiteProcedureProjectionHandler.bypassInsertTrigger = true;
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'WB',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection1);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = '2RBC',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection2);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection3 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Platelet',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection3);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Plasma',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection4);
        // added
        sked__Account_Tag__c mobileAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        fifthList.add(mobileAccountTag1);
        /*
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = spanishTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag2);
        
        sked__Account_Tag__c fixedSiteAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = personTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(fixedSiteAccountTag1);
        
        sked__Account_Tag__c fixedSiteAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = equipmentTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(fixedSiteAccountTag2);*/
        
        sked__Account_Tag__c fixedSiteAccountTag3 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = true,
            //sked_Minimum_Quantity__c = 1,
            sked__Weighting__c = 10
           // ,sked_Minimum_Quantity__c = 1
        );
        secondList.add(fixedSiteAccountTag3);
       // added 
        // sked__Account_Tag__c fixedSiteAccountTag4 = new sked__Account_Tag__c(
        //     sked__Account__c = nonIntegratedWBAccount.Id,
        //     sked__Tag__c = vehicleTag.Id,
        //     sked__Required__c = true,
        //     //sked_Minimum_Quantity__c = 1,
        //     sked__Weighting__c = 10
        //    // ,sked_Minimum_Quantity__c = 1
        // );
        // sixthList.add(fixedSiteAccountTag4);
        // mapTestData.put('fixedSiteAccountTag4', fixedSiteAccountTag4);

        insert secondList;
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        insert testChapter;
        
        /***** Third list ****/
        List<sObject> thirdList = new List<sObject>();
        
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
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
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET', 
            sked_City__c = 'Test City', 
            sked_County__c = 'Test', 
            sked_State__c = 'PA', 
            sked_Zip_Code__c = '18411'
        );
        thirdList.add(testLocation1);
        mapTestData.put('testLocation1', testLocation1);
        
        for (integer i = 1; i <= 5; i++) {
            sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ' + i,
                sked__Primary_Region__c = testRegion2.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE
            );
            thirdList.add(testVehicle);
            mapTestData.put('testVehicle' + i, testVehicle);
        }
        
        for (integer i = 1; i <= 10; i++) {
            sked__Resource__c test2rbcAsset = new sked__Resource__c(
                Name = 'Test 2RBC ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Equipment', 
                sked_Equipment_Subtype__c = '2RBC Asset',
                sked__Is_Active__c = TRUE
            );
            thirdList.add(test2rbcAsset);
            mapTestData.put('test2rbcAsset' + i, test2rbcAsset);
        }
        
        // fixed site
        sked__Location__c testLocation2 = new sked__Location__c(
            Name = 'Test Location 1',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId(),
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET',
            sked_City__c = 'Test City',
            sked_County__c = 'Test',
            sked_State__c = 'PA',
            sked_Zip_Code__c = '18411',
            Operation_Type__c = 'Non Integrated APH'
        );
        thirdList.add(testLocation2);
        mapTestData.put('testLocation2', testLocation2);
              
        insert thirdList;
        
        sked_Site_Collection_Operation__c siteCollectionOperationForMobile = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = mapTestData.get('testLocation1').Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id);
        insert siteCollectionOperationForMobile;
        
        /***** Fifth list ****/
        List<sObject> fifthList = new List<sObject>();
        
        sked_Staging_Location__c stagingLocation = new sked_Staging_Location__c(Name = 'Test Staging Location 1', sked_Timezone__c = 'America/New_York', sked_Zip_Code__c = '18411',
                                                                               sked_GeoLocation__Latitude__s = 38.7631899,
            																	sked_GeoLocation__Longitude__s = -90.3815903);
        fifthList.add(stagingLocation);
        mapTestData.put('stagingLocation', stagingLocation);
        insert fifthList;
        
        List<sObject> seventhList = new List<sObject>();
        sked_Collection_Op_Staging_Location__c colOppStagingLocation = new sked_Collection_Op_Staging_Location__c();
        colOppStagingLocation.sked_Collection_Operation__c = testCollectionOperation1.Id;
        colOppStagingLocation.sked_Staging_Location__c = stagingLocation.Id;
        colOppStagingLocation.sked_Start_Date__c = Date.newInstance(2020,01,01);
        colOppStagingLocation.sked_End_Date__c = Date.newInstance(4000,12,31);
        //colOppStagingLocation.sked_Staging_Location__c = stagingLocation.Id;
        
        seventhList.add(colOppStagingLocation);
        mapTestData.put('colOppStagingLocation', colOppStagingLocation);
        insert seventhList;
        
        List<sked_Travel_Time_Index_Item__c> travelTimeIndexItemList = new List<sked_Travel_Time_Index_Item__c>();
        
        sked_Travel_Time_Index_Item__c travelTimeCoToSite = new sked_Travel_Time_Index_Item__c();
        travelTimeCoToSite.sked_From__Latitude__s = 38.7631899;
        travelTimeCoToSite.sked_From__Longitude__s = -90.3815903;
        travelTimeCoToSite.sked_To__Latitude__s = 37.7450046;
        travelTimeCoToSite.sked_To__Longitude__s = -122.4816244;
        travelTimeCoToSite.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]';
        
        travelTimeIndexItemList.add(travelTimeCoToSite);
        
        sked_Travel_Time_Index_Item__c travelTimeSiteToCO = new sked_Travel_Time_Index_Item__c();
        travelTimeSiteToCO.sked_From__Latitude__s = 37.7450046;
        travelTimeSiteToCO.sked_From__Longitude__s = -122.4816244;
        travelTimeSiteToCO.sked_To__Latitude__s = 38.7631899;
        travelTimeSiteToCO.sked_To__Longitude__s = -90.3815903;
        travelTimeSiteToCO.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"}]';
        
        travelTimeIndexItemList.add(travelTimeSiteToCO);
        
        insert travelTimeIndexItemList;        

        List<sked_Resource_Biomed_Collection_Op__c> skdBioCollectionList = new List<sked_Resource_Biomed_Collection_Op__c>();

        for(integer i = 1; i <= 5; i++){
            sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle'+i);
            sked_Resource_Biomed_Collection_Op__c skdBioCollection = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c =testVehicle1.Id,
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id,
            sked_Start_Date__c = system.today()-5,
            sked_End_Date__c = system.today()+10
        );
        skdBioCollectionList.add(skdBioCollection);
        }
        insert skdBioCollectionList;
     
        /***** Forth list ****/
        List<sObject> forthList = new List<sObject>();
        
        
        // sked_Location_Tag__c driveSiteTag1 = new sked_Location_Tag__c(
        //     sked_Location__c = testLocation1.Id,
        //     sked_Tag__c = liftGateTag.Id,
        //     sked_Minimum_Quantity__c = 5,
        //     sked_Required__c = FALSE
        // );
        // forthList.add(driveSiteTag1);  
        
        sked_Site_Collection_Operation__c siteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = testLocation1.Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id
            //sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]',
            //sked_Travel_Time_Breakdown_JSON_2__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]'
        );
        forthList.add(siteCollectionOperation);
        
        sked_Role_Time_Variance__c driverVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Driving roles', 
            sked_Variance_Applies_to__c = 'Setup Time', 
            sked_Variation_Amount__c = 15, 
            sked_Variation_Type__c = 'Safety Video'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        );
        forthList.add(driverVariance);
        
        sked_Role_Time_Variance__c fixSiteVariance1 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Staff roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From', 
            sked_Variation_Amount__c = 15,
            sked_Variation_Type__c = 'Loading/ unloading area'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance1);
        
        sked_Role_Time_Variance__c fixSiteVariance2 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Subtract', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Supervisory roles', 
            sked_Variance_Applies_to__c = 'Lead Time;Wrap-up Time', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance2);
        
        sked_Role_Time_Detail__c fixSiteRoleTime1 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Resource_Role_Group__c	= 'Staff roles',
            sked_Lead_Time__c = 60,
            sked_Setup_Time__c = 45,
            sked_Breakdown_Time__c = 45,
            sked_Wrap_up_Time__c = 60,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Fixed_Site_Operation_Type__c = 'Integrated'
        );
        forthList.add(fixSiteRoleTime1);
        
        sked_Role_Time_Detail__c fixSiteRoleTime2 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Collection Operation',
            sked_Drive_Type__c = 'Mobile',
            sked_Resource_Role_Group__c	= 'Staff roles;Supervisory roles',
            sked_Lead_Time__c = 60,
            sked_Setup_Time__c = 60,
            sked_Breakdown_Time__c = 60,
            sked_Wrap_up_Time__c = 60,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        forthList.add(fixSiteRoleTime2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp1 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Supervisory roles',
            sked_Resource_Roles__c	= 'Apheresis Charge;Charge;Drive Lead;Team Supervisor'
        );
        //forthList.add(fixSiteRoleGrp1);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp2 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Resource_Roles__c	= 'Apheresis;2RBC;2RBC Sign-off;Post Collections'
        );
        //forthList.add(fixSiteRoleGrp2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp3 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c	= 'Driver'
        );
        //  forthList.add(fixSiteRoleGrp3);
        
        System.debug( 'testLocation1.Id==' + testLocation1.Id );
        
        insert forthList;
        
        
        
        /***** Sixth list ****/
        List<sObject> sixthList = new List<sObject>();
        
        // Mobile Opp
        Opportunity mobileOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = mobileAccount.Id,
            Anticipated_Registered_Donors__c = 200,
            CloseDate = system.today(),
            Drive_Date__c = Date.NewInstance(2030,08,01),
            Drive_Site__c = testLocation1.Id,
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(6, 0, 0, 0), 
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Type_of_Drive__c = 'Mobile',
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830',
            Source__c = 'Calendar Build',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No'
        );
        
        System.debug( 'mobileOpportunity==' + mobileOpportunity );
        sixthList.add(mobileOpportunity);
        mapTestData.put('mobileOpportunity', mobileOpportunity);
        
        //Fixed Site Opp
        Opportunity fixedSiteOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = fixedSiteAccount.Id,
            Anticipated_Registered_Donors__c = 100,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate+2,
            End_Time__c = Time.newInstance(23, 0, 0, 0),
            StageName = 'Solicitation',
            Drive_Site__c = testLocation2.Id,
            Start_Time__c = Time.newInstance(0, 0, 0, 0),
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Plasma_Pheresis_Projected_Procedures__c = 15,
            Platelet_Projected_Procedures__c = 15,
            Type_of_Drive__c = 'Fixed Site',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Number_of_2RBC_Assets__c = 2,
            Source__c = 'Calendar Build',
            Number_of_Plasma_Assets__c = 2,
            Number_of_Platelet_Assets__c = 2,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830'
        );
        sixthList.add(fixedSiteOpportunity);
        mapTestData.put('fixedSiteOpportunity', fixedSiteOpportunity);
                
        insert sixthList;
        
        return mapTestData;
    }

    @isTest
    public static Map<string, sObject> testSetupForErrorMessage()
    {
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
         Map<string, sObject> mapTestData = new Map<string, sObject>();
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        /***** First list ****/
        List<sObject> firstList = new List<sObject>();
        
        // Collection Operation - 1
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 0,
            sked_Setup_Time_Threshold__c = 0,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Travel_Time_Included_Fixed_Site__c = '	All Roles',
            sked_Unpaid_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break__c = true
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);
        
        	// Collection Operation - 2
            Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 25,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
          	sked_Breakdown_Time_Threshold__c = 15,
          	sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Lunch_Break__c = true,
          	sked_Unpaid_Lunch_Break_Duration__c = 30
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);
        
        // Staffing Decision matrix - Mobile
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 1,
            sked_VP_HH_Capacity__c = 2.2,
           // sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 15,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix);
        
        // Staffing Decision matrix - fixed site
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            //sked_WB_Hourly_Capacity__c = 2.1,
            //sked_Platelet_Hourly_Capacity__c = 0.67,
            //sked_Plasma_Hourly_Capacity__c = 1.17,
            //sked_2RBC_Hourly_Capacity__c = 1,
            /* sked_2RBC_Staff_Capacity__c = 1.6,
			sked_Charge_Capacity__c = 1.1,
			sked_Charge_Threshold__c = 36,
			sked_Driver_Capacity__c = 2.2,
			sked_Driver_Support_Capacity__c = 2.2,
			sked_Team_Supervisor_Threshold__c = 36,
			sked_VP_HH_Capacity__c = 2.2,*/
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix2);
        
        // Lunch Break Setting
        sked_Lunch_Break_Setting__c lunchBreakSetting30 = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        firstList.add(lunchBreakSetting30);
        
        // Mobile Account
        Account mobileAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='TEst_Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId()
        );
        firstList.add(mobileAccount);
        mapTestData.put('mobileAccount', mobileAccount);
        
        // Fixed Site Account
        Account fixedSiteAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='TEst_Account1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()
        );
        firstList.add(fixedSiteAccount);
        mapTestData.put('fixedSiteAccount', fixedSiteAccount);
        
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(usCitizenTag);
        mapTestData.put('usCitizenTag', usCitizenTag);
        
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(spanishTag);
        mapTestData.put('spanishTag', spanishTag);
        
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(liftGateTag);
        mapTestData.put('liftGateTag', liftGateTag);
        
        
        sked__Tag__c personTag = new sked__Tag__c(
            Name = 'Sample Person Tag',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(personTag);
        mapTestData.put('personTag', personTag);
        
        sked__Tag__c vehicleTag = new sked__Tag__c(
            Name = 'Sample Vehicle Tag',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(vehicleTag);
        mapTestData.put('vehicleTag', vehicleTag);
        
        sked__Tag__c equipmentTag = new sked__Tag__c(
            Name = 'Sample Equipment Tag',
            sked_Resource_Type__c = 'Equipment'
        );
        firstList.add(equipmentTag);        
        mapTestData.put('equipmentTag', equipmentTag);
        
        insert firstList;
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = Userinfo.getUserId() ;
        atm.AccountId = mobileAccount.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        /***** Second list ****/
        List<sObject> secondList = new List<sObject>();
        
        // Template Opp
        Opportunity parentOpp = new Opportunity(
            AccountId = mobileAccount.Id,
            Name = 'parent',
            StageName = 'Discovery', 
            CloseDate = testDataFactory.summary.startDate,
            Is_Template__c = TRUE,
            Source__c = 'Calendar Build',
            Web_Sched_Offset_from_CO_Global_Settings__c = True
        );
        secondList.add(parentOpp);
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        mapTestData.put('testRegion1', testRegion1);
        
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id
        );
        secondList.add(collectionOperationSdm);
        
        // fixed site
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id
        );
        secondList.add(collectionOperationSdm2);
        
        sked_Lunch_Break_Definition__c setting30definition1 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 2,
            sked_Min_Number_of_Staff__c = 0,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition1);
        
      /*  sked_Lunch_Break_Definition__c setting30definition2 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 9,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 3,
            sked_Min_Number_of_Staff__c = 3,
            sked_Slot_Reduction__c = 3.33
        );
        secondList.add(setting30definition2); */
        
        /*  sked_Lunch_Break_Definition__c setting30definition3 = new sked_Lunch_Break_Definition__c(
sked_Lunch_Break_Duration__c = 120,
sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
sked_Max_Number_of_Staff__c = 8,
sked_Min_Number_of_Staff__c = 4,
sked_Slot_Reduction__c = 5
);
secondList.add(setting30definition3); */
        
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 15,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 16,
            sked_Min_Number_of_Staff__c = 9,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 12,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 9,
            sked_Min_Number_of_Staff__c = 17,
            
            sked_Slot_Reduction__c = 6.67
        );
        secondList.add(setting30definition5);
        
        //  skedFixedSiteProcedureProjectionHandler.bypassInsertTrigger = true;
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            //sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'WB',
            sked_Productive_Procedure_Goal__c = 5
            //sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection1);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            //sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = '2RBC',
            sked_Productive_Procedure_Goal__c = 5
            //sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection2);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection3 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            //sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Platelet',
            sked_Productive_Procedure_Goal__c = 5
            //sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection3);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            //sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Plasma',
            sked_Productive_Procedure_Goal__c = 5
            //sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection4);
        
        /*sked__Account_Tag__c mobileAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(mobileAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = spanishTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag2);
        
        sked__Account_Tag__c fixedSiteAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = personTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(fixedSiteAccountTag1);
        
        sked__Account_Tag__c fixedSiteAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = equipmentTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(fixedSiteAccountTag2);*/
        
        sked__Account_Tag__c fixedSiteAccountTag3 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = true,
            //sked_Minimum_Quantity__c = 1,
            sked__Weighting__c = 10
           // ,sked_Minimum_Quantity__c = 1
        );
        secondList.add(fixedSiteAccountTag3);
        
        insert secondList;
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        insert testChapter;
        
        /***** Third list ****/
        List<sObject> thirdList = new List<sObject>();
        
        // Mobile site
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
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
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET',
            sked_City__c = 'Test City',
            sked_County__c = 'Test',
            sked_State__c = 'PA',
            sked_Zip_Code__c = '18411'
        );
        thirdList.add(testLocation1);
        mapTestData.put('testLocation1', testLocation1);
        
        for (integer i = 1; i <= 5; i++) {
            sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE
            );
            thirdList.add(testVehicle);
            mapTestData.put('testVehicle' + i, testVehicle);
        }
        
        for (integer i = 1; i <= 10; i++) {
            sked__Resource__c test2rbcAsset = new sked__Resource__c(
                Name = 'Test 2RBC ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Equipment', 
                sked_Equipment_Subtype__c = '2RBC Asset',
                sked__Is_Active__c = TRUE
            );
            thirdList.add(test2rbcAsset);
            mapTestData.put('test2rbcAsset' + i, test2rbcAsset);
        }
        
        // Fixed Site
        sked__Location__c testLocation2 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Even',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId(),
            Operation_Type__c = 'Integrated',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET',
            sked_City__c = 'Test City',
            sked_County__c = 'Test',
            sked_State__c = 'PA',
            sked_Zip_Code__c = '18411'
        );
        thirdList.add(testLocation2);
        mapTestData.put('testLocation2', testLocation2);
        
        insert thirdList;
        System.debug( 'site_location_id==' + testLocation1.Id );
        
        /***** Forth list ****/
        List<sObject> forthList = new List<sObject>();
        
        sked_Location_Tag__c driveSiteTag1 = new sked_Location_Tag__c(
            sked_Location__c = testLocation1.Id,
            sked_Tag__c = liftGateTag.Id,
            sked_Minimum_Quantity__c = 5,
            sked_Required__c = FALSE
        );
        forthList.add(driveSiteTag1);  
        
        /*sked_Site_Collection_Operation__c siteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(70),
            sked_Site__c = testLocation2.Id,
            sked_Start_Date__c = system.today().addDays(20),//testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id,
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]',
            sked_Travel_Time_Breakdown_JSON_2__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]'
        );
        forthList.add(siteCollectionOperation);*/
        
        sked_Role_Time_Variance__c driverVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Driving roles', 
            sked_Variance_Applies_to__c = 'Setup Time', 
            sked_Variation_Amount__c = 15, 
            sked_Variation_Type__c = 'Safety Video',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        );
        forthList.add(driverVariance);
        
        sked_Role_Time_Variance__c fixSiteVariance1 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Staff roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance1);
        
        sked_Role_Time_Variance__c fixSiteVariance2 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Subtract', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Supervisory roles', 
            sked_Variance_Applies_to__c = 'Lead Time;Wrap-up Time', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance2);
        
        sked_Role_Time_Detail__c fixSiteRoleTime1 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Resource_Role_Group__c	= 'Staff roles',
            sked_Lead_Time__c = 0,
            sked_Setup_Time__c = 45,
            sked_Breakdown_Time__c = 45,
            sked_Wrap_up_Time__c = 0,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Fixed_Site_Operation_Type__c = 'Integrated'
        );
        forthList.add(fixSiteRoleTime1);
        
        sked_Role_Time_Detail__c fixSiteRoleTime2 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Collection Operation',
            sked_Drive_Type__c = 'Mobile',
            sked_Resource_Role_Group__c	= 'Supervisory roles',
            sked_Lead_Time__c = 10,
            sked_Setup_Time__c = 60,
            sked_Breakdown_Time__c = 60,
            sked_Wrap_up_Time__c = 10,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        forthList.add(fixSiteRoleTime2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp1 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Supervisory roles',
            sked_Resource_Roles__c	= 'Apheresis Charge;Charge;Drive Lead;Team Supervisor'
        );
        //forthList.add(fixSiteRoleGrp1);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp2 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Resource_Roles__c	= 'Apheresis;2RBC;2RBC Sign-off;Post Collections'
        );
        //forthList.add(fixSiteRoleGrp2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp3 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c	= 'Driver'
        );
        //  forthList.add(fixSiteRoleGrp3);
        
        insert forthList;
        
        /***** Sixth list ****/
        List<sObject> sixthList = new List<sObject>();
        
        //Fixed Site Opp
        Opportunity fixedSiteOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = fixedSiteAccount.Id,
            Anticipated_Registered_Donors__c = 100,
            CloseDate = system.today(), //testDataFactory.summary.startDate,
            Drive_Date__c = system.today().addDays(40),//testDataFactory.summary.startDate+2,
            Drive_Site__c = testLocation2.Id,
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Plasma_Pheresis_Projected_Procedures__c = 15,
            Platelet_Projected_Procedures__c = 15,
            Type_of_Drive__c = 'Fixed Site',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Number_of_2RBC_Assets__c = 2,
            Source__c = 'Calendar Build',
            Number_of_Plasma_Assets__c = 2,
            Number_of_Platelet_Assets__c = 2,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830'
        );
        sixthList.add(fixedSiteOpportunity);
        mapTestData.put('fixedSiteOpportunity', fixedSiteOpportunity);
        
        insert sixthList;        
        return mapTestData;
    }
    
    // test data for generating mobile drives
    @isTest
    public static Map<string, sObject> testSetupForMobileDriveV2()
    {
        Map<string, sObject> mapTestData = new Map<string, sObject>();
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        /***** First list ****/
        List<sObject> firstList = new List<sObject>();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 15,
            sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Travel_Time_Included_Fixed_Site__c = 'Drivers Only',
            sked_Travel_Time_Included_Mobile__c = 'All Roles',
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Lunch_Break__c = true
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);
        
            Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 25,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
          //  sked_Breakdown_Time_Threshold__c = 15,
          //  sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Lunch_Break__c = true,
            sked_Travel_Time_Included_Fixed_Site__c = 'Drivers Only',
            sked_Travel_Time_Included_Mobile__c = 'All Roles'
          //  sked_Unpaid_Lunch_Break_Duration__c = 30
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 1,
            sked_VP_HH_Capacity__c = 2.2,
           // sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 15,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix);
        
        // fixed site
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_WB_Hourly_Capacity__c = 2.1,
            sked_Platelet_Hourly_Capacity__c = 0.67,
            sked_Plasma_Hourly_Capacity__c = 1.17,
            sked_2RBC_Hourly_Capacity__c = 1,
            /* sked_2RBC_Staff_Capacity__c = 1.6,
sked_Charge_Capacity__c = 1.1,
sked_Charge_Threshold__c = 36,
sked_Driver_Capacity__c = 2.2,
sked_Driver_Support_Capacity__c = 2.2,
sked_Team_Supervisor_Threshold__c = 36,
sked_VP_HH_Capacity__c = 2.2,*/
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix2);
        
        sked_Lunch_Break_Setting__c lunchBreakSetting30 = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        firstList.add(lunchBreakSetting30);
        
        Account mobileAccount = new Account(
            Name = 'Test Account',
            Internal_Name__c ='TEST',
            District_Manager__c = UserInfo.getUserId(),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId()
        );
        firstList.add(mobileAccount);
        mapTestData.put('mobileAccount', mobileAccount);
        
        Account fixedSiteAccount = new Account(
            Name = 'Test Account',
            Internal_Name__c ='TEST',
            District_Manager__c = UserInfo.getUserId(),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()
        );
        firstList.add(fixedSiteAccount);
        mapTestData.put('fixedSiteAccount', fixedSiteAccount);
        
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(usCitizenTag);
        mapTestData.put('usCitizenTag', usCitizenTag);
        
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(spanishTag);
        mapTestData.put('spanishTag', spanishTag);
        
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(liftGateTag);
        mapTestData.put('liftGateTag', liftGateTag);
        
        
        sked__Tag__c personTag = new sked__Tag__c(
            Name = 'Sample Person Tag',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(personTag);
        mapTestData.put('personTag', personTag);
        
        sked__Tag__c vehicleTag = new sked__Tag__c(
            Name = 'Sample Vehicle Tag',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(vehicleTag);
        mapTestData.put('vehicleTag', vehicleTag);
        
        sked__Tag__c equipmentTag = new sked__Tag__c(
            Name = 'Sample Equipment Tag',
            sked_Resource_Type__c = 'Equipment'
        );
        firstList.add(equipmentTag);        
        mapTestData.put('equipmentTag', equipmentTag);
        
        insert firstList;
        
        sked_Staging_Location__c stagingLocation = new sked_Staging_Location__c(Name = 'Test Staging Location 1', sked_Timezone__c = 'America/New_York', sked_Zip_Code__c = '18411',
                                                                               sked_GeoLocation__Latitude__s = 38.7631899,
            																	sked_GeoLocation__Longitude__s = -90.3815903);
        //fifthList.add(stagingLocation);
        mapTestData.put('stagingLocation', stagingLocation);
        insert stagingLocation;
        
        //List<sObject> seventhList = new List<sObject>();
        sked_Collection_Op_Staging_Location__c colOppStagingLocation = new sked_Collection_Op_Staging_Location__c();
        colOppStagingLocation.sked_Collection_Operation__c = testCollectionOperation1.Id;
        colOppStagingLocation.sked_Staging_Location__c = stagingLocation.Id;
        colOppStagingLocation.sked_Start_Date__c = Date.newInstance(2020,01,01);
        colOppStagingLocation.sked_End_Date__c = Date.newInstance(4000,12,31);
        //colOppStagingLocation.sked_Staging_Location__c = stagingLocation.Id;
        
        //seventhList.add(colOppStagingLocation);
        //mapTestData.put('colOppStagingLocation', colOppStagingLocation);
        insert colOppStagingLocation;
        
        List<sked_Travel_Time_Index_Item__c> travelTimeIndexItemList = new List<sked_Travel_Time_Index_Item__c>();
        
        sked_Travel_Time_Index_Item__c travelTimeCoToSite = new sked_Travel_Time_Index_Item__c();
        travelTimeCoToSite.sked_From__Latitude__s = 38.7631899;
        travelTimeCoToSite.sked_From__Longitude__s = -90.3815903;
        travelTimeCoToSite.sked_To__Latitude__s = 37.7450046;
        travelTimeCoToSite.sked_To__Longitude__s = -122.4816244;
        travelTimeCoToSite.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]';
        
        travelTimeIndexItemList.add(travelTimeCoToSite);
        
        sked_Travel_Time_Index_Item__c travelTimeSiteToCO = new sked_Travel_Time_Index_Item__c();
        travelTimeSiteToCO.sked_From__Latitude__s = 37.7450046;
        travelTimeSiteToCO.sked_From__Longitude__s = -122.4816244;
        travelTimeSiteToCO.sked_To__Latitude__s = 38.7631899;
        travelTimeSiteToCO.sked_To__Longitude__s = -90.3815903;
        travelTimeSiteToCO.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"}]';
        
        travelTimeIndexItemList.add(travelTimeSiteToCO);
        
        insert travelTimeIndexItemList;        
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = Userinfo.getUserId() ;
        atm.AccountId = mobileAccount.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        /***** Second list ****/
        List<sObject> secondList = new List<sObject>();
        
        Opportunity parentOpp = new Opportunity(
            AccountId = mobileAccount.Id,
            Name = 'parent',
            StageName = 'Discovery', 
            CloseDate = testDataFactory.summary.startDate,
            Is_Template__c = TRUE,
            Source__c = 'Calendar Build',
            Web_Sched_Offset_from_CO_Global_Settings__c = True
        );
        secondList.add(parentOpp);
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        mapTestData.put('testRegion1', testRegion1);
        
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id
        );
        secondList.add(collectionOperationSdm);
        // fixed site
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id
        );
        secondList.add(collectionOperationSdm2);
        
        sked_Lunch_Break_Definition__c setting30definition1 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 2,
            sked_Min_Number_of_Staff__c = 0,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition1);
        
      /*  sked_Lunch_Break_Definition__c setting30definition2 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 9,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 3,
            sked_Min_Number_of_Staff__c = 3,
            sked_Slot_Reduction__c = 3.33
        );
        secondList.add(setting30definition2); */
        
        /*  sked_Lunch_Break_Definition__c setting30definition3 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 120,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 8,
            sked_Min_Number_of_Staff__c = 4,
            sked_Slot_Reduction__c = 5
            );
            secondList.add(setting30definition3); */
        
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 15,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 16,
            sked_Min_Number_of_Staff__c = 9,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 12,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 9,
            sked_Min_Number_of_Staff__c = 17,
            
            sked_Slot_Reduction__c = 6.67
        );
        secondList.add(setting30definition5);
        
        //  skedFixedSiteProcedureProjectionHandler.bypassInsertTrigger = true;
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'WB',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection1);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = '2RBC',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection2);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection3 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Platelet',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection3);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Plasma',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection4);
        
        /*sked__Account_Tag__c mobileAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(mobileAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = spanishTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag2);
        
        sked__Account_Tag__c fixedSiteAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = personTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(fixedSiteAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag2);*/
        
        sked__Account_Tag__c mobileAccountTag3 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = true,
            sked__Weighting__c = 10
           // ,sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag3);
        
        insert secondList;
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        insert testChapter;
        
        /***** Third list ****/
        List<sObject> thirdList = new List<sObject>();
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = false,
            sked__Weighting__c = 10,
           sked_Minimum_Quantity__c = 1
        );
        thirdList.add(mobileAccountTag2);
        
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId(),
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
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
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Non Integrated WB',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET',
            sked_City__c = 'Test City',
            sked_County__c = 'Test',
            sked_State__c = 'PA',
            sked_Zip_Code__c = '18411'
        );
        thirdList.add(testLocation1);
        mapTestData.put('testLocation1', testLocation1);
        
        for (integer i = 1; i <= 5; i++) {
            sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE
            );
            thirdList.add(testVehicle);
            mapTestData.put('testVehicle' + i, testVehicle);
        }
        
        
        for (integer i = 1; i <= 10; i++) {
            sked__Resource__c test2rbcAsset = new sked__Resource__c(
                Name = 'Test 2RBC ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Equipment', 
                sked_Equipment_Subtype__c = '2RBC Asset',
                sked__Is_Active__c = TRUE
            );
            thirdList.add(test2rbcAsset);
            mapTestData.put('test2rbcAsset' + i, test2rbcAsset);
        }
        
        insert thirdList;
        System.debug( 'site_location_id==' + testLocation1.Id );
        
        /***** Forth list ****/
        List<sObject> forthList = new List<sObject>();
        
        Id firstTestVehicleIdFromMap = mapTestData.get('testVehicle1').Id;
        sked_Resource_Biomed_Collection_Op__c secondaryColOpp = new sked_Resource_Biomed_Collection_Op__c (
        		sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id,
            	sked_Resource__c = firstTestVehicleIdFromMap,
            	sked_Start_Date__c = testDataFactory.summary.startDate,
            	sked_End_Date__c = testDataFactory.summary.endDate,
				sked_Start__c =system.now(),
            	sked_End__c = system.now().addDays(100),
            	sked_Start_Time__c = Time.newInstance(6, 0, 0, 0),
            	sked_End_Time__c = Time.newInstance(17, 0, 0, 0)
        );
        forthList.add(secondaryColOpp);
        
        sked__Location__c testLocation2 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Even',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET',
            sked_City__c = 'Test City',
            sked_County__c = 'Test',
            sked_State__c = 'PA',
            sked_Zip_Code__c = '18411'
        );
        forthList.add(testLocation2);
        mapTestData.put('testLocation2', testLocation2);
        
        sked_Location_Tag__c driveSiteTag1 = new sked_Location_Tag__c(
            sked_Location__c = testLocation1.Id,
            sked_Tag__c = liftGateTag.Id,
            sked_Minimum_Quantity__c = 5,
            sked_Required__c = FALSE
        );
        forthList.add(driveSiteTag1);  
        
        sked_Site_Collection_Operation__c siteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = testLocation1.Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id,
            External_Id__c = 'Bio_Collection_BSF_SiteCo'+'_'+testLocation1.Id+'_'+testDataFactory.summary.startDate,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_SiteCo_Backend_External_Id',
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]',
            sked_Travel_Time_Breakdown_JSON_2__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]'
        
        );
        forthList.add(siteCollectionOperation);
        
        sked_Role_Time_Variance__c driverVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Driving roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Site Logistics Back;Site Logistics To', 
            sked_Variation_Amount__c = 15, 
            sked_Variation_Type__c = 'Safety Video',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        );
        forthList.add(driverVariance);
        
        sked_Role_Time_Variance__c fixSiteVariance1 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Staff roles;Supervisory roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From;Site Logistics Back;Site Logistics To;Lead Time;Wrap-up Time;', 
            sked_Variation_Amount__c = 25,
            sked_Variation_Type__c = 'Loading/ unloading area',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance1);
        
        sked_Role_Time_Variance__c fixSiteVariance2 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Subtract', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Supervisory roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From;Lead Time;Wrap-up Time;Site Logistics Back;Site Logistics To', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance2);
        
        sked_Role_Time_Detail__c fixSiteRoleTime1 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Resource_Role_Group__c	= 'Staff roles',
            sked_Lead_Time__c = 0,
            sked_Setup_Time__c = 15,
            sked_Breakdown_Time__c = 45,
            sked_Wrap_up_Time__c = 90,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        forthList.add(fixSiteRoleTime1);
        
        sked_Role_Time_Detail__c fixSiteRoleTime2 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Collection Operation',
            sked_Drive_Type__c = 'Mobile',
            sked_Resource_Role_Group__c	= 'Staff roles;Supervisory roles',
            sked_Lead_Time__c = 20,
            sked_Setup_Time__c = 20,
            sked_Breakdown_Time__c = 120,
            sked_Wrap_up_Time__c = 120,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        forthList.add(fixSiteRoleTime2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp1 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Supervisory roles',
            sked_Resource_Roles__c	= 'Apheresis Charge;Charge;Drive Lead;Team Supervisor'
        );
        //forthList.add(fixSiteRoleGrp1);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp2 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Resource_Roles__c	= 'Apheresis;2RBC;2RBC Sign-off;Post Collections'
        );
        //forthList.add(fixSiteRoleGrp2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp3 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c	= 'Driver'
        );
        //forthList.add(fixSiteRoleGrp3);
        
        Triggerhandler.bypass('OpportunitySplitTriggerHandler');
        Opportunity mobileOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = mobileAccount.Id,
            Anticipated_Registered_Donors__c = 200,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate,
            Drive_Site__c = testLocation1.Id,
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(5, 0, 0, 0), 
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Type_of_Drive__c = 'Mobile',
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830',
            Source__c = 'Calendar Build',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Red_Cross_Volunteer_Required__c = true,
            Red_Cross_Volunteer_Quantity__c = 1
        );
        forthList.add(mobileOpportunity);
        mapTestData.put('mobileOpportunity', mobileOpportunity);
       
        Opportunity fixedSiteOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = fixedSiteAccount.Id,
            Anticipated_Registered_Donors__c = 100,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate,
            Drive_Site__c = testLocation1.Id,
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Plasma_Pheresis_Projected_Procedures__c = 15,
            Platelet_Projected_Procedures__c = 15,
            Type_of_Drive__c = 'Fixed Site',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Number_of_2RBC_Assets__c = 2,
            Source__c = 'Calendar Build',
            Number_of_Plasma_Assets__c = 2,
            Number_of_Platelet_Assets__c = 2,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830'
        );
        forthList.add(fixedSiteOpportunity);
        mapTestData.put('fixedSiteOpportunity', fixedSiteOpportunity);
        
        insert forthList;
        
        TriggerHandler.clearAllBypasses();
        return mapTestData;
        
    }
       
    // test data for generating error messages for mobile drives
    @isTest
    public static Map<string, sObject> testSetupForErrorMsgMobileDrive()
    {
        Map<string, sObject> mapTestData = new Map<string, sObject>();
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        /***** First list ****/
        List<sObject> firstList = new List<sObject>();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            //sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 15,
            sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Travel_Time_Included_Fixed_Site__c = '	All Roles',
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Lunch_Break__c = true
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);
        
            Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 25,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
          //  sked_Breakdown_Time_Threshold__c = 15,
          //  sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Lunch_Break__c = true
          //  sked_Unpaid_Lunch_Break_Duration__c = 30
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 1,
            sked_VP_HH_Capacity__c = 2.2,
           // sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 15,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix);
        
        // fixed site
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_WB_Hourly_Capacity__c = 2.1,
            sked_Platelet_Hourly_Capacity__c = 0.67,
            sked_Plasma_Hourly_Capacity__c = 1.17,
            sked_2RBC_Hourly_Capacity__c = 1,
            //sked_2RBC_Staff_Capacity__c = 1.6,
			/*sked_Charge_Capacity__c = 1.1,
			sked_Charge_Threshold__c = 36,*/
			sked_Driver_Capacity__c = 2.2,
			sked_Driver_Support_Capacity__c = 2.2,
			sked_Team_Supervisor_Threshold__c = 36,
			sked_VP_HH_Capacity__c = 2.2,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix2);
        
        sked_Lunch_Break_Setting__c lunchBreakSetting30 = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        firstList.add(lunchBreakSetting30);
        
        Account mobileAccount = new Account(
            Name = 'Test Account',
            Internal_Name__c ='TEST',
            District_Manager__c = UserInfo.getUserId(),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId()
        );
        firstList.add(mobileAccount);
        mapTestData.put('mobileAccount', mobileAccount);
        
        Account fixedSiteAccount = new Account(
            Name = 'Test Account',
            Internal_Name__c ='TEST',
            District_Manager__c = UserInfo.getUserId(),
            Type = 'Education',
            Industry_Code__c = 'High School',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()
        );
        firstList.add(fixedSiteAccount);
        mapTestData.put('fixedSiteAccount', fixedSiteAccount);
        
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(usCitizenTag);
        mapTestData.put('usCitizenTag', usCitizenTag);
        
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(spanishTag);
        mapTestData.put('spanishTag', spanishTag);
        
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(liftGateTag);
        mapTestData.put('liftGateTag', liftGateTag);
        
        
        sked__Tag__c personTag = new sked__Tag__c(
            Name = 'Sample Person Tag',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(personTag);
        mapTestData.put('personTag', personTag);
        
        sked__Tag__c vehicleTag = new sked__Tag__c(
            Name = 'Sample Vehicle Tag',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(vehicleTag);
        mapTestData.put('vehicleTag', vehicleTag);
        
        sked__Tag__c equipmentTag = new sked__Tag__c(
            Name = 'Sample Equipment Tag',
            sked_Resource_Type__c = 'Equipment'
        );
        firstList.add(equipmentTag);        
        mapTestData.put('equipmentTag', equipmentTag);
        
        insert firstList;
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = Userinfo.getUserId() ;
        atm.AccountId = mobileAccount.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        /***** Second list ****/
        List<sObject> secondList = new List<sObject>();
        
        Opportunity parentOpp = new Opportunity(
            AccountId = mobileAccount.Id,
            Name = 'parent',
            StageName = 'Discovery', 
            CloseDate = testDataFactory.summary.startDate,
            Is_Template__c = TRUE,
            Source__c = 'Calendar Build',
            Web_Sched_Offset_from_CO_Global_Settings__c = True
        );
        secondList.add(parentOpp);
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        mapTestData.put('testRegion1', testRegion1);
        
        /*sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id
        );
        secondList.add(collectionOperationSdm);
        // fixed site
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id
        );
        secondList.add(collectionOperationSdm2);*/
        
        sked_Lunch_Break_Definition__c setting30definition1 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 2,
            sked_Min_Number_of_Staff__c = 0,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition1);
        
      sked_Lunch_Break_Definition__c setting30definition2 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 9,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 3,
            sked_Min_Number_of_Staff__c = 3,
          	
            sked_Slot_Reduction__c = 3.33
        );
        secondList.add(setting30definition2); 
        
        sked_Lunch_Break_Definition__c setting30definition3 = new sked_Lunch_Break_Definition__c(
			sked_Lunch_Break_Duration__c = 120,
			sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
			sked_Max_Number_of_Staff__c = 8,
			sked_Min_Number_of_Staff__c = 4,            
			sked_Slot_Reduction__c = 5);
		secondList.add(setting30definition3);
        
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 15,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 16,
            sked_Min_Number_of_Staff__c = 9,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 12,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 9,
            sked_Min_Number_of_Staff__c = 17,
            
            sked_Slot_Reduction__c = 6.67
        );
        secondList.add(setting30definition5);
        
        //  skedFixedSiteProcedureProjectionHandler.bypassInsertTrigger = true;
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'WB',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection1);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = '2RBC',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection2);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection3 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Platelet',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection3);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Plasma',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection4);
        
        /*sked__Account_Tag__c mobileAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(mobileAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = spanishTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag2);
        
        sked__Account_Tag__c fixedSiteAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = fixedSiteAccount.Id,
            sked__Tag__c = personTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        secondList.add(fixedSiteAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag2);*/
        
        sked__Account_Tag__c mobileAccountTag3 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = true,
            sked__Weighting__c = 10
           // ,sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag3);
        
        insert secondList;
        
        /***** Third list ****/
        List<sObject> thirdList = new List<sObject>();
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = false,
            sked__Weighting__c = 10,
           sked_Minimum_Quantity__c = 1
        );
        thirdList.add(mobileAccountTag2);
        
        /*sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId(),
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            //sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            //sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
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
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Non Integrated WB',
            sked_Chapter__c = 'Test Chapter'
            ,sked_Address_1__c = 'ABC STREET'
            , sked_City__c = 'Test City'
            , sked_County__c = 'Test'
            , sked_State__c = 'PA'
            , sked_Zip_Code__c = '18411'
        );
        thirdList.add(testLocation1);
        mapTestData.put('testLocation1', testLocation1);*/
        
        /*for (integer i = 1; i <= 5; i++) {
            sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE
            );
            thirdList.add(testVehicle);
            mapTestData.put('testVehicle' + i, testVehicle);
        }*/
        
        
        for (integer i = 1; i <= 10; i++) {
            sked__Resource__c test2rbcAsset = new sked__Resource__c(
                Name = 'Test 2RBC ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Equipment', 
                sked_Equipment_Subtype__c = '2RBC Asset',
                sked__Is_Active__c = TRUE
            );
            thirdList.add(test2rbcAsset);
            mapTestData.put('test2rbcAsset' + i, test2rbcAsset);
        }
        
        insert thirdList;
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        insert testChapter;
        
        /***** Forth list ****/
        List<sObject> forthList = new List<sObject>();
        
        //Id firstTestVehicleIdFromMap = mapTestData.get('testVehicle1').Id;
        /*sked_Resource_Biomed_Collection_Op__c secondaryColOpp = new sked_Resource_Biomed_Collection_Op__c (
        		sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id,
            	sked_Resource__c = firstTestVehicleIdFromMap,
            	sked_Start_Date__c = testDataFactory.summary.startDate,
            	sked_End_Date__c = testDataFactory.summary.endDate,
				sked_Start__c =system.now(),
            	sked_End__c = system.now().addDays(100),
            	sked_Start_Time__c = Time.newInstance(6, 0, 0, 0),
            	sked_End_Time__c = Time.newInstance(17, 0, 0, 0)
        );
        forthList.add(secondaryColOpp);*/
        
        sked__Location__c testLocation2 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Even',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET',
            sked_City__c = 'Test City',
            sked_County__c = 'Test',
            sked_State__c = 'PA',
            sked_Zip_Code__c = '18411'
        );
        forthList.add(testLocation2);
        mapTestData.put('testLocation2', testLocation2);
        
        /*sked_Location_Tag__c driveSiteTag1 = new sked_Location_Tag__c(
            sked_Location__c = testLocation1.Id,
            sked_Tag__c = liftGateTag.Id,
            sked_Minimum_Quantity__c = 5,
            sked_Required__c = FALSE
        );
        forthList.add(driveSiteTag1);  */
        
        insert forthList;
        
        /*sked_Site_Collection_Operation__c siteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = testLocation2.Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id,
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]',
            sked_Travel_Time_Breakdown_JSON_2__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]'
        
        );
        insert siteCollectionOperation;*/
        
        /*sked_Role_Time_Variance__c driverVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation2.Id,
            sked_Resource_Role_Group__c = 'Driving roles', 
            sked_Variance_Applies_to__c = 'Setup Time', 
            sked_Variation_Amount__c = 15, 
            sked_Variation_Type__c = 'Safety Video'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        );
        forthList.add(driverVariance);*/
        
        /*sked_Role_Time_Variance__c fixSiteVariance1 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Staff roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance1);*/
        
        /*sked_Role_Time_Variance__c fixSiteVariance2 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Subtract', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Supervisory roles', 
            sked_Variance_Applies_to__c = 'Lead Time;Wrap-up Time', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        forthList.add(fixSiteVariance2);*/
        
        sked_Role_Time_Detail__c fixSiteRoleTime1 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Resource_Role_Group__c	= 'Staff roles',
            sked_Lead_Time__c = 0,
            sked_Setup_Time__c = 45,
            sked_Breakdown_Time__c = 45,
            sked_Wrap_up_Time__c = 0,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        //forthList.add(fixSiteRoleTime1);
        
        sked_Role_Time_Detail__c fixSiteRoleTime2 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Collection Operation',
            sked_Drive_Type__c = 'Mobile',
            sked_Resource_Role_Group__c	= 'Supervisory roles',
            sked_Lead_Time__c = 10,
            sked_Setup_Time__c = 60,
            sked_Breakdown_Time__c = 60,
            sked_Wrap_up_Time__c = 10,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        //forthList.add(fixSiteRoleTime2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp1 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Supervisory roles',
            sked_Resource_Roles__c	= 'Apheresis Charge;Charge;Drive Lead;Team Supervisor'
        );
        //forthList.add(fixSiteRoleGrp1);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp2 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Resource_Roles__c	= 'Apheresis;2RBC;2RBC Sign-off;Post Collections'
        );
        //forthList.add(fixSiteRoleGrp2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp3 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c	= 'Driver'
        );
        //  forthList.add(fixSiteRoleGrp3);
        
        Triggerhandler.bypass('OpportunitySplitTriggerHandler');
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity mobileOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = mobileAccount.Id,
            Anticipated_Registered_Donors__c = 200,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate,
            Drive_Site__c = testLocation2.Id,
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(6, 0, 0, 0), 
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Type_of_Drive__c = 'Mobile',
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830',
            Source__c = 'Calendar Build',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No'
        );
        
        oppList.add(mobileOpportunity);
        mapTestData.put('mobileOpportunity', mobileOpportunity);
        
        //test.startTest();
        /*Opportunity fixedSiteOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = fixedSiteAccount.Id,
            Anticipated_Registered_Donors__c = 100,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate,
            Drive_Site__c = testLocation1.Id,
            End_Time__c = Time.newInstance(23, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Plasma_Pheresis_Projected_Procedures__c = 15,
            Platelet_Projected_Procedures__c = 15,
            Type_of_Drive__c = 'Fixed Site',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Number_of_2RBC_Assets__c = 2,
            Source__c = 'Calendar Build',
            Number_of_Plasma_Assets__c = 2,
            Number_of_Platelet_Assets__c = 2,
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830'
        );
        forthList.add(fixedSiteOpportunity);
        mapTestData.put('fixedSiteOpportunity', fixedSiteOpportunity);*/
        
        insert oppList;
        TriggerHandler.clearAllBypasses();
        return mapTestData;
        
    }
    
    // test data for generating mobile drives
    @isTest
    public static Map<string, sObject> testSetupForMilitaryMobileDrive()
    {
        Map<string, sObject> mapTestData = new Map<string, sObject>();
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        /***** First list ****/
        List<sObject> firstList = new List<sObject>();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 15,
            sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Travel_Time_Included_Fixed_Site__c = '	All Roles',
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Lunch_Break__c = true
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);
        
            Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 25,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
          //  sked_Breakdown_Time_Threshold__c = 15,
          //  sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Lunch_Break__c = true
          //  sked_Unpaid_Lunch_Break_Duration__c = 30
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 1,
            sked_VP_HH_Capacity__c = 2.2,
           // sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 15,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix);
        
        // fixed site
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_WB_Hourly_Capacity__c = 2.1,
            sked_Platelet_Hourly_Capacity__c = 0.67,
            sked_Plasma_Hourly_Capacity__c = 1.17,
            sked_2RBC_Hourly_Capacity__c = 1,
            /* sked_2RBC_Staff_Capacity__c = 1.6,
sked_Charge_Capacity__c = 1.1,
sked_Charge_Threshold__c = 36,
sked_Driver_Capacity__c = 2.2,
sked_Driver_Support_Capacity__c = 2.2,
sked_Team_Supervisor_Threshold__c = 36,
sked_VP_HH_Capacity__c = 2.2,*/
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix2);
        
        sked_Lunch_Break_Setting__c lunchBreakSetting30 = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        firstList.add(lunchBreakSetting30);
        
        Account mobileAccount = new Account(
            Name = 'Test Account',
            Internal_Name__c ='TEST',
            Type = 'Military',
            District_Manager__c = UserInfo.getUserId(),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId()
        );
        firstList.add(mobileAccount);
        mapTestData.put('mobileAccount', mobileAccount);
        
        
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(usCitizenTag);
        mapTestData.put('usCitizenTag', usCitizenTag);
        
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(spanishTag);
        mapTestData.put('spanishTag', spanishTag);
        
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(liftGateTag);
        mapTestData.put('liftGateTag', liftGateTag);
        
        
        sked__Tag__c personTag = new sked__Tag__c(
            Name = 'Sample Person Tag',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(personTag);
        mapTestData.put('personTag', personTag);
        
        sked__Tag__c vehicleTag = new sked__Tag__c(
            Name = 'Sample Vehicle Tag',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(vehicleTag);
        mapTestData.put('vehicleTag', vehicleTag);
        
        sked__Tag__c equipmentTag = new sked__Tag__c(
            Name = 'Sample Equipment Tag',
            sked_Resource_Type__c = 'Equipment'
        );
        firstList.add(equipmentTag);        
        mapTestData.put('equipmentTag', equipmentTag);
        
        insert firstList;
        
        sked_Staging_Location__c stagingLocation = new sked_Staging_Location__c(Name = 'Test Staging Location 1', sked_Timezone__c = 'America/New_York', sked_Zip_Code__c = '18411',
                                                                               sked_GeoLocation__Latitude__s = 38.7631899,
            																	sked_GeoLocation__Longitude__s = -90.3815903);
        //fifthList.add(stagingLocation);
        mapTestData.put('stagingLocation', stagingLocation);
        insert stagingLocation;
        
        //List<sObject> seventhList = new List<sObject>();
        sked_Collection_Op_Staging_Location__c colOppStagingLocation = new sked_Collection_Op_Staging_Location__c();
        colOppStagingLocation.sked_Collection_Operation__c = testCollectionOperation1.Id;
        colOppStagingLocation.sked_Staging_Location__c = stagingLocation.Id;
        colOppStagingLocation.sked_Start_Date__c = Date.newInstance(2020,01,01);
        colOppStagingLocation.sked_End_Date__c = Date.newInstance(4000,12,31);
        //colOppStagingLocation.sked_Staging_Location__c = stagingLocation.Id;
        
        //seventhList.add(colOppStagingLocation);
        //mapTestData.put('colOppStagingLocation', colOppStagingLocation);
        insert colOppStagingLocation;
        
        List<sked_Travel_Time_Index_Item__c> travelTimeIndexItemList = new List<sked_Travel_Time_Index_Item__c>();
        
        sked_Travel_Time_Index_Item__c travelTimeCoToSite = new sked_Travel_Time_Index_Item__c();
        travelTimeCoToSite.sked_From__Latitude__s = 38.7631899;
        travelTimeCoToSite.sked_From__Longitude__s = -90.3815903;
        travelTimeCoToSite.sked_To__Latitude__s = 37.7450046;
        travelTimeCoToSite.sked_To__Longitude__s = -122.4816244;
        travelTimeCoToSite.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":13,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]';
        
        travelTimeIndexItemList.add(travelTimeCoToSite);
        
        sked_Travel_Time_Index_Item__c travelTimeSiteToCO = new sked_Travel_Time_Index_Item__c();
        travelTimeSiteToCO.sked_From__Latitude__s = 37.7450046;
        travelTimeSiteToCO.sked_From__Longitude__s = -122.4816244;
        travelTimeSiteToCO.sked_To__Latitude__s = 38.7631899;
        travelTimeSiteToCO.sked_To__Longitude__s = -90.3815903;
        travelTimeSiteToCO.sked_Travel_Time_Breakdown_JSON__c  = '[{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Friday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Saturday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Sunday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Monday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Tuesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Wednesday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":12,"travelDistance":6635,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"Site to CO"},{"weekday":"Thursday","travelTime":15,"travelDistance":6635,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000BvyzkEAB","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"Site to CO"}]';
        
        travelTimeIndexItemList.add(travelTimeSiteToCO);
        
        insert travelTimeIndexItemList;        
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = Userinfo.getUserId() ;
        atm.AccountId = mobileAccount.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        /***** Second list ****/
        List<sObject> secondList = new List<sObject>();
        
        Opportunity parentOpp = new Opportunity(
            AccountId = mobileAccount.Id,
            Name = 'parent',
            StageName = 'Discovery', 
            CloseDate = testDataFactory.summary.startDate,
            Is_Template__c = TRUE,
            Source__c = 'Calendar Build',
            Web_Sched_Offset_from_CO_Global_Settings__c = True
        );
        secondList.add(parentOpp);
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        mapTestData.put('testRegion1', testRegion1);
        
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id
        );
        secondList.add(collectionOperationSdm);
        // fixed site
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id
        );
        secondList.add(collectionOperationSdm2);
        
        sked_Lunch_Break_Definition__c setting30definition1 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 2,
            sked_Min_Number_of_Staff__c = 0,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition1);
        
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 15,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 16,
            sked_Min_Number_of_Staff__c = 9,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 12,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 9,
            sked_Min_Number_of_Staff__c = 17,
            
            sked_Slot_Reduction__c = 6.67
        );
        secondList.add(setting30definition5);
        
        
        sked__Account_Tag__c mobileAccountTag3 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = true,
            sked__Weighting__c = 10
           // ,sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag3);
        
        insert secondList;
        
        /***** Third list ****/
        List<sObject> thirdList = new List<sObject>();
        
        sked__Account_Tag__c mobileAccountTag2 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccount.Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = false,
            sked__Weighting__c = 10,
           sked_Minimum_Quantity__c = 1
        );
        thirdList.add(mobileAccountTag2);
        
        
        for (integer i = 1; i <= 5; i++) {
            sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE
            );
            thirdList.add(testVehicle);
            mapTestData.put('testVehicle' + i, testVehicle);
        }
        
        
        for (integer i = 1; i <= 10; i++) {
            sked__Resource__c test2rbcAsset = new sked__Resource__c(
                Name = 'Test 2RBC ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Equipment', 
                sked_Equipment_Subtype__c = '2RBC Asset',
                sked__Is_Active__c = TRUE
            );
            thirdList.add(test2rbcAsset);
            mapTestData.put('test2rbcAsset' + i, test2rbcAsset);
        }
        
        insert thirdList;
       // System.debug( 'site_location_id==' + testLocation1.Id );
       
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        insert testChapter;
        
        /***** Forth list ****/
        List<sObject> forthList = new List<sObject>();
        
        Id firstTestVehicleIdFromMap = mapTestData.get('testVehicle1').Id;
        sked_Resource_Biomed_Collection_Op__c secondaryColOpp = new sked_Resource_Biomed_Collection_Op__c (
        		sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id,
            	sked_Resource__c = firstTestVehicleIdFromMap,
            	sked_Start_Date__c = testDataFactory.summary.startDate,
            	sked_End_Date__c = testDataFactory.summary.endDate,
				sked_Start__c =system.now(),
            	sked_End__c = system.now().addDays(100),
            	sked_Start_Time__c = Time.newInstance(6, 0, 0, 0),
            	sked_End_Time__c = Time.newInstance(17, 0, 0, 0)
        );
        forthList.add(secondaryColOpp);
        
        sked__Location__c testLocation2 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = testDataFactory.summary.startDate,
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Even',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET',
            sked_City__c = 'Test City',
            sked_County__c = 'Test',
            sked_State__c = 'PA',
            sked_Zip_Code__c = '18411'
        );
        forthList.add(testLocation2);
        mapTestData.put('testLocation2', testLocation2);
        
        insert forthList;
        
        List<sObject> finalList = new List<sObject>();
        sked_Site_Collection_Operation__c siteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = mapTestData.get('testLocation2').Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id,
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]',
            sked_Travel_Time_Breakdown_JSON_2__c = '[{"weekday":"Sunday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Sunday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Monday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Tuesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Wednesday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Thursday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":33,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":34,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Friday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":32,"travelDistance":22725,"startOfWindow":"00:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"08:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":33,"travelDistance":22725,"startOfWindow":"08:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"16:00:00.000Z","direction":"CO to Site"},{"weekday":"Saturday","travelTime":31,"travelDistance":22725,"startOfWindow":"16:00:00.000Z","siteId":"a1L5c00000B2izBEAR","siteCollectionOperationIds":null,"endOfWindow":"23:59:00.000Z","direction":"CO to Site"}]'
        
        );
        finalList.add(siteCollectionOperation);
        
        sked_Role_Time_Variance__c driverVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = mapTestData.get('testLocation2').Id,
            sked_Resource_Role_Group__c = 'Driving roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Site Logistics Back;Site Logistics To', 
            sked_Variation_Amount__c = 15, 
            sked_Variation_Type__c = 'Safety Video'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        );
        finalList.add(driverVariance);
        
        sked_Role_Time_Variance__c fixSiteVariance1 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = mapTestData.get('testLocation2').Id,
            sked_Resource_Role_Group__c = 'Staff roles;Supervisory roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From;Site Logistics Back;Site Logistics To;Lead Time;Wrap-up Time;', 
            sked_Variation_Amount__c = 25,
            sked_Variation_Type__c = 'Loading/ unloading area'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        finalList.add(fixSiteVariance1);
        
        sked_Role_Time_Variance__c fixSiteVariance2 = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Subtract', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = mapTestData.get('testLocation2').Id,
            sked_Resource_Role_Group__c = 'Supervisory roles', 
            sked_Variance_Applies_to__c = 'Setup Time;Breakdown Time;Travel Time To;Travel Time From;Lead Time;Wrap-up Time;Site Logistics Back;Site Logistics To', 
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Loading/ unloading area'
            //sked_Roles__c = '2RBC;Apheresis;Drive Lead;Charge;Volunteer Donor Ambassador',
            
        ); 
        
        finalList.add(fixSiteVariance2);
       
        
        sked_Role_Time_Detail__c fixSiteRoleTime2 = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Collection Operation',
            sked_Drive_Type__c = 'Mobile',
            sked_Resource_Role_Group__c	= 'Staff roles;Supervisory roles',
            sked_Lead_Time__c = 20,
            sked_Setup_Time__c = 20,
            sked_Breakdown_Time__c = 120,
            sked_Wrap_up_Time__c = 120,
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate,
            sked_Mobile_Type__c = 'Inside',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        finalList.add(fixSiteRoleTime2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp1 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Supervisory roles',
            sked_Resource_Roles__c	= 'Apheresis Charge;Charge;Drive Lead;Team Supervisor'
        );
        //forthList.add(fixSiteRoleGrp1);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp2 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Resource_Roles__c	= 'Apheresis;2RBC;2RBC Sign-off;Post Collections'
        );
        //forthList.add(fixSiteRoleGrp2);
        
        sked_Resource_Role_Group__c fixSiteRoleGrp3 = new sked_Resource_Role_Group__c(
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Resource_Roles__c	= 'Driver'
        );
        //forthList.add(fixSiteRoleGrp3);
        
        //System.debug( 'testLocation1.Id==' + testLocation1.Id );
        Triggerhandler.bypass('OpportunitySplitTriggerHandler');
        Opportunity mobileOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = mobileAccount.Id,
            Anticipated_Registered_Donors__c = 200,
            CloseDate = testDataFactory.summary.startDate,
            Drive_Date__c = testDataFactory.summary.startDate,
            Drive_Site__c = mapTestData.get('testLocation2').Id,
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(5, 0, 0, 0), 
            WB_Projected_Procedures__c = 5,
            X2RBC_Projected_Procedures__c = 5,
            Type_of_Drive__c = 'Mobile',
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830',
            Source__c = 'Calendar Build',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No'
        );
        
        finalList.add(mobileOpportunity);
        mapTestData.put('mobileOpportunity', mobileOpportunity);
        
        //test.startTest();
        
        insert finalList;
        
        TriggerHandler.clearAllBypasses();
        return mapTestData;
        
    }
       
}