/**
 * @description: This is the Test class for BSF_TravelTimePanelController Apex Class.
 * @createdby: Barnojit Sharma
**/
@isTest
private class BSF_TravelTimePanelControllerTest {
    @TestSetup
    static void prepareDataset(){

        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last',
            Email = 'DRDProfile000@amamama.com',
            Username = 'drduser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        skedHubBase.BypassInsertTriggers = true;
        insert DRDAMUser;
        Assert.isNotNull(DRDAMUser.Id);

        Account accObj;
        accObj = new Account();
        accObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId();
        accObj.Name = 'Exavalu';
        accObj.BillingPostalCode = '30622';
        accObj.Internal_Name__c ='Exavalu'; 

        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
        insert accObj;
        Assert.isNotNull(accObj.Id);

        Contact conObj = new Contact();
        conObj.AccountId = accObj.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'test.barno@mailinator.com';
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.Original_Service_Date__c = Date.Today().addDays(-1000);
        conObj.HomePhone = '222-222-3333';
        conObj.MobilePhone = '222-222-3333';
        conObj.OtherPhone = '222-222-3333';

        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('ContactTriggerHandler');
        insert conObj;
        Assert.isNotNull(conObj.Id);

        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile_Site').getRecordTypeId();
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
        siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conObj.Id;
        siteObj.sked_Site_Main_Phone__c = '758-771-0091';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Date_Site_Inspection_Completed__c = Date.today();
        siteObj.sked__GeoLocation__latitude__s = 36.7450046;
        siteObj.sked__GeoLocation__longitude__s = -120.4816244;

        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;
        Assert.isNotNull(siteObj.Id);

        Biomed_Collection_Op_Center__c testCollectionOp = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 38.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            sked_Maximum_Shift_Length_Threshold__c = 480
        );

        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCollectionOp;
        Assert.isNotNull(testCollectionOp.Id);

        sked_Staging_Location__c testStagingLocation = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 38.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Timezone__c = 'America/Chicago'
        );
        skedHubBase.BypassInsertTriggers = true;
        insert testStagingLocation;
        Assert.isNotNull(testStagingLocation.Id);

        sked_Collection_Op_Staging_Location__c testCosl = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        skedHubBase.BypassInsertTriggers = true;
        insert testCosl;
        Assert.isNotNull(testCosl.Id);

        sked_Site_Collection_Operation__c testSCO = new sked_Site_Collection_Operation__c(
            sked_Site__c = siteObj.Id,
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Start_Date__c = System.today().addDays(-100),
            sked_End_Date__c = System.today().addDays(100)
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteCollectionOperationTriggerHandler');
        insert testSCO;
        Assert.isNotNull(testSCO.Id);

        List<sked_Travel_Time_Index_Item__c> testTtiList = new List<sked_Travel_Time_Index_Item__c>();

        sked_Travel_Time_Index_Item__c testTtii1 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = 36.7450046,
            sked_From__Longitude__s = -120.4816244,
            sked_To__Latitude__s = 38.7450046,
            sked_To__Longitude__s = -122.4816244,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + 36.7450046 + ':' + -120.4816244,
            sked_Timezone__c = 'America/New_York',
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Wednesday","travelTime":99,"travelDistance":119213,"startOfWindow":"00:00:00.000Z","siteId":null,"endOfWindow":"08:00:00.000Z","direction":null}]'
        );
        testTtiList.add(testTtii1);

        sked_Travel_Time_Index_Item__c testTtii2 = new sked_Travel_Time_Index_Item__c(
            sked_To__Latitude__s = 36.7450046,
            sked_To__Longitude__s = -120.4816244,
            sked_From__Latitude__s = 38.7450046,
            sked_From__Longitude__s = -122.4816244,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_CO_TO_SITE + 38.7450046 + ':' + -122.4816244,
            sked_Timezone__c = 'America/New_York',
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Wednesday","travelTime":99,"travelDistance":119213,"startOfWindow":"12:00:00.000Z","siteId":null,"endOfWindow":"20:00:00.000Z","direction":null}]'
        );
        testTtiList.add(testTtii2);
        
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('TravelTimeIndexItemTriggerHandler');
        insert testTtiList;
        Assert.isNotNull(testTtiList[0].Id);
    }

    @isTest
    private static void testMethodOne(){

        Date startDate = System.today().addDays(-100);
        sked_Site_Collection_Operation__c siteCO = [SELECT Id FROM sked_Site_Collection_Operation__c WHERE sked_Start_Date__c =: startDate LIMIT 1];
        Assert.isNotNull(siteCO.Id);

        List<BSF_TravelTimePanelController.BSF_TravelTimeDataWrapper> classRef;
        Test.startTest();
            Boolean result = BSF_TravelTimePanelController.isEditable();
            classRef = BSF_TravelTimePanelController.getData(siteCO.Id);
        Test.stopTest();
        Assert.isNotNull(classRef);
    }

    @isTest
    private static void testMethodTwo(){

        Date startDate = System.today().addDays(-100);
        sked_Site_Collection_Operation__c siteCO = [SELECT Id FROM sked_Site_Collection_Operation__c WHERE sked_Start_Date__c =: startDate LIMIT 1];
        Assert.isNotNull(siteCO.Id);

        List<BSF_TravelTimePanelController.BSF_TravelTimeDataWrapper> classRef;
        Test.startTest();
            classRef = BSF_TravelTimePanelController.getData(siteCO.Id);
            classRef[0].travelTimeBreakdownData[0].travelTime = 9;
            classRef[0].userOverride = true;
            classRef[0].overrideComment = 'Test';
            skedHubBase.BypassUpdateTriggers = true;
            TriggerHandler.bypass('TravelTimeIndexItemTriggerHandler');
            BSF_TravelTimePanelController.saveUpdatedRecords(classRef);
        Test.stopTest();
        Assert.isNotNull(classRef);
    }

    @isTest
    private static void testMethodThree(){

        Date startDate = System.today().addDays(-100);
        sked_Site_Collection_Operation__c siteCO = [SELECT Id FROM sked_Site_Collection_Operation__c WHERE sked_Start_Date__c =: startDate LIMIT 1];
        Assert.isNotNull(siteCO.Id);

        Biomed_Collection_Op_Center__c collOp = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Assert.isNotNull(collOp.Id);

        sked_Staging_Location__c stgl = [SELECT Id FROM sked_Staging_Location__c WHERE sked_Timezone__c = 'America/Chicago' LIMIT 1];
        Assert.isNotNull(stgl.Id);

        User drduser = [SELECT Id FROM User WHERE Email = 'DRDProfile000@amamama.com' LIMIT 1];
        Assert.isNotNull(drduser.Id);

        sked_Collection_Op_Staging_Location__c testCosl = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = collOp.Id,
            sked_Staging_Location__c = stgl.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        skedHubBase.BypassInsertTriggers = true;
        insert testCosl;
        Assert.isNotNull(testCosl.Id);

        List<BSF_TravelTimePanelController.BSF_TravelTimeDataWrapper> classRef;
        Test.startTest();
            System.runAs(drduser){
                Boolean result = BSF_TravelTimePanelController.isEditable();
            }
            classRef = BSF_TravelTimePanelController.getData(siteCO.Id);
        Test.stopTest();
        Assert.isNotNull(classRef);
    }
    
     @isTest
    private static void testMethodfour(){

        Date startDate = System.today().addDays(-100);
        String siteToCoKey = skedConstants.TTII_DIRECTION_SITE_TO_CO + 36.7450046 + ':' + -120.4816244;
        String cOToSiteKey = skedConstants.TTII_DIRECTION_CO_TO_SITE + 38.7450046 + ':' + -122.4816244;
        sked_Site_Collection_Operation__c siteCO = [SELECT Id FROM sked_Site_Collection_Operation__c WHERE sked_Start_Date__c =: startDate LIMIT 1];
        Assert.isNotNull(siteCO.Id);
        sked_Travel_Time_Index_Item__c tti = [SELECT Id, sked_Travel_Time_Breakdown_JSON__c FROM sked_Travel_Time_Index_Item__c WHERE sked_Ordering_Key__c =: siteToCoKey LIMIT 1 ];
        tti.sked_Travel_Time_Breakdown_JSON__c = 'NO DATA';
        update tti;
        sked_Travel_Time_Index_Item__c tti1 = [SELECT Id, sked_Travel_Time_Breakdown_JSON__c FROM sked_Travel_Time_Index_Item__c WHERE sked_Ordering_Key__c =: cOToSiteKey LIMIT 1 ];
        tti1.sked_Travel_Time_Breakdown_JSON__c = 'NO DATA';
        update tti1;

        List<BSF_TravelTimePanelController.BSF_TravelTimeDataWrapper> classRef;
        Test.startTest();
            Boolean result = BSF_TravelTimePanelController.isEditable();
            classRef = BSF_TravelTimePanelController.getData(siteCO.Id);
        Test.stopTest();
        Assert.isNotNull(classRef);
    }
}