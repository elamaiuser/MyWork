@isTest(SeeAllData = false)
private class BSFVehiclePlanningController_Test {
    
    @testSetup
    static void prepareTestData() {
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'Bio_Collection_BSF_12345',
            Biomed_Collection_Op_Code_Center_ID__c = '12345',
            sked_IMPACT_Start_Date__c = Date.today().addDays(-500),
            sked_IMPACT_End_Date__c = Date.today().addDays(500)
        );
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Id vkRecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId();
        sked__Resource__c resourceVehicle = new sked__Resource__c(
            recordTypeId = vkRecordTypeId,
            sked__Primary_Region__c = testRegion1.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked__Resource_Type__c = 'Asset',
            sked_Element_Unit__c = '23456765',
            sked__Is_Active__c = true,
            sked_Long_Desc__c = 'toyota 4x',
            sked_Short_Desc__c = 'XUV4',
            sked__Category__c = 'ProMaster',
            sked_ULID__c = 'ULID124',
            sked_Timezone__c = 'America/Los_Angeles',
            sked_Primary_Phone_Type__c = 'Home Phone',
            sked_Home_Phone__c = '123-123-4322',
            sked__Primary_Phone__c = '123-123-4322',
            sked_Address_Referenced_for_Scheduling__c = 'Work',
            sked_Mobile_Type__c = 'Inside',
            sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
            sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
            sked_Work_Country__c = 'USA',
            sked_Work_City__c = 'Sylmar',
            sked_Work_State__c = 'CA',
            sked_Work_Address_1__c = '11970 Gager St',
            sked_Work_Zip_Code__c = '91342'
        );

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        triggerHandler.bypass('ResourceTriggerHandler');
        insert resourceVehicle;
        
        List<sked__Activity__c> testActivities = new List<sked__Activity__c>();
        sked__Activity__c testActivity;
        testActivity = new sked__Activity__c(
            sked__Resource__c = resourceVehicle.Id,
            sked__Type__c = 'Administrative',
            sked_Activity_Title__c = 'Administrative 1',
            sked_Start_Date__c =  Date.today(),
            sked_End_Date__c =  Date.today(),
            sked_Start_Time__c = Datetime.now().time(),
            sked_End_Time__c = Datetime.now().addMinutes(66).time(),
            sked__Start__c = Datetime.now(),
            sked__End__c = Datetime.now().addMinutes(66),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Region__c = testRegion1.Id,
            sked__Address__c = 'Test Address',
            sked__Notes__c = 'Test notes',
            sked_Is_Group_Activity__c = true
        );
        testActivities.add(testActivity);
        
        testActivity = new sked__Activity__c(
            sked__Resource__c = resourceVehicle.Id,
            sked__Type__c = 'Administrative',
            sked_Activity_Title__c = 'Administrative 2',
            sked_Start_Date__c =  Date.today(),
            sked_End_Date__c =  Date.today().addDays(2),
            sked_Start_Time__c = Datetime.now().time(),
            sked_End_Time__c = Datetime.now().addMinutes(66).time(),
            sked__Start__c = Datetime.now(),
            sked__End__c = Datetime.now().addDays(2).addMinutes(66),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Region__c = testRegion1.Id,
            sked__Address__c = 'Test Address 2',
            sked__Notes__c = 'Test notes 2',
            sked_Is_Group_Activity__c = true
        );
        testActivities.add(testActivity);
        insert testActivities;
        
        List<sked__Activity_Resource__c> testActResources = new List<sked__Activity_Resource__c>();
        sked__Activity_Resource__c testActivityResource;
        testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivities[0].Id,
            sked__Resource__c = resourceVehicle.Id,
            sked_Start_Date__c = Date.today(),
            sked_End_Date__c = Date.today()
        );
        testActResources.add(testActivityResource);
        
        testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivities[1].Id,
            sked__Resource__c = resourceVehicle.Id,
            sked_Start_Date__c = Date.today(),
            sked_End_Date__c = Date.today().addDays(2)
        );
        testActResources.add(testActivityResource);
        insert testActResources;
        
        List<String> availabilityType = Custom_Report_Config__mdt.getInstance('Vehicle_Availability_Type').Value__c.split(',');
        List<sked__Availability__c> testAvailabilities = new List<sked__Availability__c>();
        sked__Availability__c testAvailability;
        testAvailability = new sked__Availability__c(
            sked__Resource__c = resourceVehicle.Id,
            sked__Is_Available__c = false,
            sked__Status__c = 'Approved',
            sked__Start__c = DateTime.now(),
            sked__Finish__c =Datetime.now().addMinutes(66),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c =  Date.today(),
            sked_Finish_Date__c =  Date.today(),
            sked__Type__c = availabilityType[0],
            sked_Start_Time__c = Datetime.now().time(),
            sked_Finish_Time__c = Datetime.now().addMinutes(66).time()
        );
        testAvailabilities.add(testAvailability);
        
        testAvailability = new sked__Availability__c(
            sked__Resource__c = resourceVehicle.Id,
            sked__Is_Available__c = false,
            sked__Status__c = 'Approved',
            sked__Start__c = DateTime.now(),
            sked__Finish__c = Datetime.now().addDays(2).addMinutes(66),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c =  Date.today(),
            sked_Finish_Date__c =  Date.today().addDays(2),
            sked__Type__c = availabilityType[1],
            sked_Start_Time__c = Datetime.now().time(),
            sked_Finish_Time__c = Datetime.now().addMinutes(66).time()
        );
        testAvailabilities.add(testAvailability);
        insert testAvailabilities;
        
        //set up drive data
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('SiteTriggerHandler');
        Triggerhandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('JobTriggerHandler');
        TriggerHandler.bypass('JobAllocationTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
         
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 

        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
         
        // insert mobile site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Active__c = true;
        testMobileSite.sked_Start_Date__c = system.today().addDays(-30);
        testMobileSite.sked_End_Date__c = system.today().addDays(30);
        testMobileSite.National_Name_Status__c = 'Second Review Pending';
        testMobileSite.sked_Zip_Code__c = '12344';
        insert testMobileSite;
         
        // insert template
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.accountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
         
        // insert mobile Opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Drive_Date__c = system.today();
        testMobileOpp.CloseDate = system.today().addDays(-20);
        testMobileOpp.Parent_Template_Id__c = testTemplate.id;
        insert testMobileOpp;

        //insert mobile drive
        sked_Drive__c testMobileDrive = new sked_Drive__c(
            Name = 'Test Mobile Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Date__c = System.today(),
            sked_Drive_Site__c = testMobileSite.Id,
            sked_Opportunity__c = testMobileOpp.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testMobileAccount.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_2RBC_Projected_Procedures__c = 20,
            sked_WB_Projected_Procedures__c = 20,
            sked_Status__c = BSF_Constants.DOC_STATUS_DRAFT
        );
        insert testMobileDrive;
        
        sked__Job__c testVehicleJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = DateTime.now().addHours(11).addMinutes(15),
            sked__Finish__c = DateTime.now().addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testMobileDrive.Id,
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Asset_Type__c = 'Vehicle',
            sked__Job_Allocation_Time_Source__c = FALSE
        );
        insert testVehicleJob;
        
        sked__Job_Allocation__c testVehicleJob_Allocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob.Id,
            sked__Resource__c = resourceVehicle.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
       	);
        insert testVehicleJob_Allocation1;
        
        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void testVehiclePlanningControllerWithValidParameters() {
        String collOpIds = [SELECT Id, Name, sked_territory__c FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1].Id;
            
        Test.startTest();
        
        try {
            PageReference pr = Page.BSFWeeklyStaffScheduleReportPDF;
            pr.getParameters().put('startdate', String.valueOf(Date.Today()));
            pr.getParameters().put('enddate', String.valueOf(Date.Today().addMonths(6)));
            pr.getParameters().put('collopids', collOpIds);
            pr.getParameters().put('renderas','pdf');
            pr.getParameters().put('force_download','true');
            Test.setCurrentPage(pr);
            
            BSFVehiclePlanningController testVehiclePlanningControllerInstance = new BSFVehiclePlanningController(); 
        } catch(AuraHandledException ex) {}
        
        Test.stopTest();
    }
    
    static testMethod void testVehiclePlanningControllerWithInvalidParameters() {      
        Test.startTest();
        
        try {
            PageReference pr = Page.BSFWeeklyStaffScheduleReportPDF;
            pr.getParameters().put('startdate', null);
            pr.getParameters().put('enddate', null);
            pr.getParameters().put('collopids', '');
            pr.getParameters().put('renderas','');
            Test.setCurrentPage(pr);
            
            BSFVehiclePlanningController testVehiclePlanningControllerInstance = new BSFVehiclePlanningController(); 
        } catch(AuraHandledException ex) {
            Assert.isTrue(ex.getMessage().contains('Script-thrown exception'));
        }
        
        Test.stopTest();
    }

}