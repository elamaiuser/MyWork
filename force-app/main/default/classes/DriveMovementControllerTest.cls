@IsTest
private class DriveMovementControllerTest {
    @testSetup
    static void setupTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        String mobileOppRecType = 'Mobile Opp';
        String mobileAccRecType = 'Mobile Account';
        String mobileSiteRecType = 'Mobile Site';  

        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);

        Profile p = [SELECT Id FROM Profile WHERE Name='Global Admin' LIMIT 1];
        User amUser = new User(Alias = 'amusr', 
                                Email='amuser@testtest.com', 
                                EmailEncodingKey='UTF-8', 
                                LastName='TestingAM', 
                                LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', 
                                ProfileId = p.Id, 
                                TimeZoneSidKey='America/Los_Angeles', 
                                UserName='amuser' + DateTime.now().getTime() + '@testtest.com');
        insert amUser;

        Profile mfgProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Manufacturing%' LIMIT 1];
        User mfgUser = new User(alias = 'test123', email='testmfguser@bsf.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileId = mfgProfile.Id, country='United States', IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@skedtest.com');
        insert mfgUser;

        Account accObj;
        accObj = new Account();
        accObj.RecordTypeId = accRecTypeId;
        accObj.Name = 'Test Blood Drive Account';
        accObj.BillingPostalCode = '30622';
        accObj.Internal_Name__c ='Exavalu';  
        accObj.Planning_Path__c = 'Flexible';          
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
        insert accObj;

        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = amUser.Id ;
        atm.AccountId = accObj.Id ;
        atm.TeamMemberRole = 'Account Specialist';
        atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
        atm.End_Date__c = Date.Today().addDays(10);
        atm.Start_Date__c = Date.Today().addDays(-10);
        atmList.add(atm);
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        

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
        conObj.Primary_Phone__c = picklistValues('Contact','Primary_Phone__c');
        conObj.Original_Service_Date__c = Date.Today().addDays(-1000);
        conObj.HomePhone = '222-222-3333';
        conObj.MobilePhone = '222-222-3333';
        conObj.OtherPhone = '222-222-3333';
        triggerHandler.bypass('ContactTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        insert conObj;
        
        sked__Tag__c skedTag = new sked__Tag__c(Name = 'Outside', sked__Type__c = 'Physical Location Type');
        insert skedTag; 

        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site';
        siteObj.sked_Address_1__c = '123 Test Ave';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_City__c = 'New York';
        siteObj.sked_State__c = 'Test Site State';
        siteObj.sked_Zip_Code__c = '4001';
        siteObj.sked_County__c = 'USA';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Site_Inspection_Completed_By__c = amUser.Id;
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
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;

        sked__Location__c siteObj1 = new sked__Location__c();
        siteObj1.RecordTypeId = siteRecTypeId;
        siteObj1.Name = 'Ship From Site';
        siteObj1.sked_Address_1__c = 'Test Site Address';
        siteObj1.sked__Address__c = 'Test Site Address';
        siteObj1.sked_City__c = 'Test Site City';
        siteObj1.sked_State__c = 'Test Site State';
        siteObj1.sked_Zip_Code__c = '4000';
        siteObj1.sked_County__c = 'USA';
        siteObj1.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj1.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj1.sked_Room_Name__c = 'Room 15';
        siteObj1.sked_National_Name__c = 'AMERICA';
        siteObj1.sked_Physical_Location_Type__c = 'Outside';
        siteObj1.sked_Site_Inspection_Completed_By__c = amUser.Id;
        siteObj1.sked_Automation_Suitability__c = 'Suitable';
        siteObj1.sked_Outside_stairs__c = 1;
        siteObj1.sked_Inside_stairs__c = 2;
        siteObj1.sked_Base_Description__c = 'test base description';
        siteObj1.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj1.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj1.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj1.sked_Site_Contact__c = conObj.Id;
        siteObj1.sked_Site_Main_Phone__c = '758-771-0091';
        siteObj1.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj1.sked_Pay_for_Parking__c = 'Other';
        siteObj1.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj1.sked_Wireless_Policy__c = 'Accepted';
        siteObj1.Source__c = 'Custom New Form';
        siteObj1.sked_Date_Site_Inspection_Completed__c = Date.today();
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj1;

        sked__Location__c siteObj2 = new sked__Location__c();
        siteObj2.RecordTypeId = siteRecTypeId;
        siteObj2.Name = 'Ship To Site';
        siteObj2.sked_Address_1__c = 'Test Site Address';
        siteObj2.sked__Address__c = 'Test Site Address';
        siteObj2.sked_City__c = 'Test Site City';
        siteObj2.sked_State__c = 'Test Site State';
        siteObj2.sked_Zip_Code__c = '4002';
        siteObj2.sked_County__c = 'USA';
        siteObj2.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj2.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj2.sked_Room_Name__c = 'Room 15';
        siteObj2.sked_National_Name__c = 'AMERICA';
        siteObj2.sked_Physical_Location_Type__c = 'Outside';
        siteObj2.sked_Site_Inspection_Completed_By__c = amUser.Id;
        siteObj2.sked_Automation_Suitability__c = 'Suitable';
        siteObj2.sked_Outside_stairs__c = 1;
        siteObj2.sked_Inside_stairs__c = 2;
        siteObj2.sked_Base_Description__c = 'test base description';
        siteObj2.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj2.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj2.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj2.sked_Site_Contact__c = conObj.Id;
        siteObj2.sked_Site_Main_Phone__c = '758-771-0091';
        siteObj2.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj2.sked_Pay_for_Parking__c = 'Other';
        siteObj2.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj2.sked_Wireless_Policy__c = 'Accepted';
        siteObj2.Source__c = 'Custom New Form';
        siteObj2.sked_Date_Site_Inspection_Completed__c = Date.today();
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj2;


        Opportunity templateOpp = new Opportunity();
        templateOpp.accountId = accObj.Id;
        templateOpp.CloseDate = Date.today().addDays(30);
        templateOpp.Is_Template__c = true;
        templateOpp.Name = 'Test Template';
        templateOpp.StageName = 'Discovery'; 
        templateOpp.Drive_Status__c = 'Draft';
        templateOpp.WB_Projected_Procedures__c = 1;
        templateOpp.X2RBC_Projected_Procedures__c = 1;
        templateOpp.Anticipated_Registered_Donors__c = 1;
        templateOpp.Type_of_Drive__c = 'Mobile';
        templateOpp.Planning_Path__c = 'Flexible';
        templateOpp.Drive_Site__c = siteObj.Id;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert templateOpp;

        
        Opportunity optyObj ;
        optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = accObj.Id;
        optyObj.Drive_Site__c = siteObj.Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery'; 
        optyObj.Drive_Status__c = 'Draft'; 
        optyObj.Drive_Date__c = Date.today().addDays(60);
        optyObj.CloseDate = Date.today().addDays(30);
        optyObj.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
        optyObj.End_Time__c =  Time.newInstance(18, 30, 2, 20);
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        optyObj.Account_Manager__c = amUser.Id;
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.Planning_Path__c = 'Flexible';
        optyObj.Parent_Template_Id__c = templateOpp.Id;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert optyObj;

        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
         skedHubBase.BypassInsertTriggers = true;
        insert testCollectionOperation1;

        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = testCollectionOperation1.Id,
                                                        sked_Drive_Date__c = Date.today().addDays(60),
                                                        sked_Drive_Site__c = siteObj.Id,
                                                        sked_Opportunity__c = optyObj.Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = accObj.Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
                                                         sked_2RBC_Projected_Procedures__c = 2);
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('DriveTriggerHandler');
        insert testDrive1;

        sked_Drive_Delivery_Job__c drivejob = new sked_Drive_Delivery_Job__c(
            sked_Drive__c = testDrive1.Id,
            sked_Type__c = 'Pick Up',
            sked_Pick_Up_Time__c = Time.newInstance(8, 0, 0, 0));
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('skedDriveDeliveryJobHandler');
        insert drivejob;
        sked_Drive_Delivery_Job__c drivejob1 = new sked_Drive_Delivery_Job__c(
            sked_Drive__c = testDrive1.Id,
            sked_Type__c = 'VOL Pick Up',
            sked_Pick_Up_Time__c = Time.newInstance(8, 0, 0, 0));
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('skedDriveDeliveryJobHandler');
        insert drivejob1;
        sked__Region__c reg = new sked__Region__c(Name = 'ABCD',
                                                    sked__Timezone__c = 'America/New_York');
        skedHubBase.BypassInsertTriggers = true;
        insert reg;

        TMS_Site__c tmsSite = new TMS_Site__c(
            Name = 'Test TMS Site',
            Effective_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(10)
        );
        insert tmsSite;

        TMS_Site_User_Assignment__c userAssignment = new TMS_Site_User_Assignment__c(
            User__c = mfgUser.Id,
            Assigned_TMS_Site__c = tmsSite.Id,
            Is_Default__c = true,
            Is_Active__c = true
        );
        insert userAssignment;

        String jsonstr = '[ { "assignedTmsSites": [ { "label": "Test Site", "value": "'+siteObj.Id+'" }, { "label": "Ship From Site", "value": "'+siteObj1.Id
                  +'" }, { "label": "Ship To Site", "value": "'+siteObj2.Id+'" } ], "defaultTmsSiteId": "'+siteObj.Id+'", "defaultTmsSiteName": "Test Site", "driveDateStr": "'
                  +String.valueOf(Date.today().addDays(60))+'", "driveId": "'+testDrive1.Id+'", "driveName": "Test Drive", "driveSiteId": "'+siteObj.Id
                  +'", "driveSiteName": "Test Site", "id": "new_mov_0", "isDriveDisabled": true, "isJobDisabled": false, "isReadOnly": false, "isRoundTrip": true, "jobOptions":'
                  +' [ { "label": "DDJ-214208 - Pick Up - 06:05:00", "value": "'+drivejob.Id+'", "type": "Pick Up", "pickupTime": "09:00" }, { "label": "DDJ-214209 - VOL Pick Up - 07:17:00", "value": "'
                  +drivejob1.Id+'", "type": "VOL Pick Up", "pickupTime": "08:00" } ], "movementNumber": "M-010000_XXXXX_Attica_OH_12345", "status": "Draft", "stops": [ { "canAdd": false, "canRemove": false,'
                  +' "isFirstStop": true, "isLastStop": false, "isSecondStop": false, "isSiteDisabled": false, "sequence": 1, "siteId": "'+siteObj.Id+'", "siteName": "Test Site", "siteType": "Blood Drive Site",'
                  +' "departStartStr": "06:05", "departEndStr": "06:35" }, { "canAdd": true, "canRemove": false, "isFirstStop": false, "isLastStop": false, "isSecondStop": true, "isSiteDisabled": false, "sequence": 2, "siteId": "'
                  +siteObj2.Id+'", "siteName": "Ship To Site", "siteType": "Blood Drive Site", "departStartStr": "07:30:00.000", "departEndStr": "08:00" }, { "canAdd": true, "canRemove": false, "isFirstStop": false, "isLastStop": '
                  +'false, "isSecondStop": true, "isSiteDisabled": false, "sequence": 3, "siteId": "'+siteObj1.Id+'", "siteName": "Ship From Site", "siteType": "Blood Drive Site", "departStartStr": "08:30:00.000", "departEndStr":'
                  +' "08:00" }, { "canAdd": false, "canRemove": false, "isFirstStop": false, "isLastStop": true, "isSecondStop": false, "isSiteDisabled": true, "sequence": 4, "siteId": "'+siteObj.Id
                  +'", "siteName": "Test Site", "siteType": "Blood Drive Site" } ], "selectedJobId": "'+drivejob.Id+'", "carrier": "Redcross Employee", "isCarrierDisabled": true } ]';

        DriveMovementController.UIResponse res = DriveMovementController.saveMovements(jsonstr);

    }

    private static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }

    private static String picklistValues(String objectName, String fieldName) {
        String result;
        List<Schema.DescribeSobjectResult> sobjectlist = Schema.describeSObjects(new List<String>{objectName});
        
        for(Schema.DescribeSobjectResult sobj : sobjectlist) {
            for (Schema.PicklistEntry entry : sobj.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    result = entry.getValue();
                    break;
                }
            }
        }
        return result;
    }
    private static User getMfgUser() {
        return [SELECT Id FROM User WHERE Email = 'testmfguser@bsf.com' LIMIT 1];
    }
    @IsTest
    static void testGetInitialData_NewFromDrive() {
        sked_Drive__c drive = [SELECT Id FROM sked_Drive__c LIMIT 1];

        Test.startTest();
        DriveMovementController.UIResponse res = DriveMovementController.getInitialData(
            null, drive.Id, BSF_Constants.ACTION_NEW, 'sked_Drive__c'
        );
        Test.stopTest();

        System.assert(res.isSuccess, 'Initialization should succeed');
        System.assertEquals(1, res.movements.size(), 'Should return one wrapper');
        System.assertEquals(drive.Id, res.movements[0].driveId, 'Drive ID should match');
        System.assertEquals(BSF_Constants.STATUS_DRAFT, res.movements[0].status, 'New movement should be in Draft status');
    }
    @IsTest
    static void testGetInitialData_NewFromJob() {
        sked_Drive_Delivery_Job__c job = [SELECT Id FROM sked_Drive_Delivery_Job__c LIMIT 1];

        Test.startTest();
        DriveMovementController.UIResponse res = DriveMovementController.getInitialData(
            null, job.Id, BSF_Constants.ACTION_NEW, 'sked_Drive_Delivery_Job__c'
        );
        Test.stopTest();

        System.assert(res.isSuccess, 'Initialization should succeed');
        System.assertEquals(job.Id, res.movements[0].selectedJobId, 'Job ID should be locked and selected');
        System.assert(res.movements[0].isJobDisabled, 'Job selection should be disabled');
    }
    @IsTest
    static void testGetInitialData_EditFromMovement() {
        Drive_Delivery_Movement__c mov = [SELECT Id FROM Drive_Delivery_Movement__c LIMIT 1];

        Test.startTest();
        DriveMovementController.UIResponse res = DriveMovementController.getInitialData(
            mov.Id, null, BSF_Constants.ACTION_EDIT, 'Drive_Delivery_Movement__c'
        );
        Test.stopTest();

        System.assert(res.isSuccess, 'Initialization should succeed');
        System.assertEquals(mov.Id, res.movements[0].movementRecordId, 'Movement ID should match');
        System.assert(res.movements[0].stops.size() > 0, 'Shipments should be translated into stops');
    }
    @IsTest
    static void testGetInitialData_NewActionRedirectsToEdit() {
        Drive_Delivery_Movement__c mov = [SELECT Id FROM Drive_Delivery_Movement__c LIMIT 1];

        Test.startTest();
        DriveMovementController.UIResponse res = DriveMovementController.getInitialData(
            null, mov.Id, BSF_Constants.ACTION_NEW, 'Drive_Delivery_Movement__c'
        );
        Test.stopTest();

        System.assert(res.isSuccess, 'Override initialization should succeed');
        System.assertEquals(mov.Id, res.movements[0].movementRecordId, 'Should pull existing Movement data');
    }
    @IsTest
    static void testGetInitialData_Exception() {
        Test.startTest();
        DriveMovementController.UIResponse res = DriveMovementController.getInitialData(
            'invalid_id', null, BSF_Constants.ACTION_EDIT, 'Drive_Delivery_Movement__c'
        );
        Test.stopTest();

        System.assert(!res.isSuccess, 'Should catch exception and return false');
        System.assert(res.message.contains('Init Error:'), 'Error message should be populated');
    }
    @IsTest
    static void testSearchSites() {
        Test.startTest();
        List<Map<String, String>> tmsResults;
        List<Map<String, String>> locResults;
        System.runAs(getMfgUser()) {
            tmsResults = DriveMovementController.searchSites('Test', BSF_Constants.TYPE_TMS_SITE);
            locResults = DriveMovementController.searchSites('Test', BSF_Constants.TYPE_BLOOD_DRIVE);
        }
        Test.stopTest();

        System.assert(!tmsResults.isEmpty(), 'Should find TMS sites');
        System.assert(!locResults.isEmpty(), 'Should find Blood Drive sites');
    }
    @IsTest
    static void testSaveMovements_Success() {
        sked_Drive__c drive = [SELECT Id, sked_Drive_Date__c, sked_Drive_Site__c FROM sked_Drive__c LIMIT 1];
        sked_Drive_Delivery_Job__c job = [SELECT Id FROM sked_Drive_Delivery_Job__c WHERE sked_Type__c = 'Pick Up' LIMIT 1];
        TMS_Site__c tms = [SELECT Id FROM TMS_Site__c LIMIT 1];
        sked__Location__c loc = [SELECT Id FROM sked__Location__c WHERE Id =:drive.sked_Drive_Site__c LIMIT 1];
        
        DriveMovementController.MovementWrapper mw = new DriveMovementController.MovementWrapper();
        mw.driveId = drive.Id;
        mw.selectedJobId = job.Id;
        mw.status = BSF_Constants.STATUS_DRAFT;
        mw.driveDateStr = String.valueOf(drive.sked_Drive_Date__c);
        mw.isRoundTrip = true;
        mw.movementNumber = 'M-NEW-TEST';
        mw.carrier = 'Redcross Employee';
        mw.stops = new List<DriveMovementController.StopWrapper>();

        DriveMovementController.StopWrapper s1 = new DriveMovementController.StopWrapper();
        s1.sequence = 1;
        s1.siteType = BSF_Constants.TYPE_TMS_SITE;
        s1.siteId = tms.Id;
        s1.departStartStr = '08:00';
        s1.departEndStr = '09:00';
        mw.stops.add(s1);

        DriveMovementController.StopWrapper s2 = new DriveMovementController.StopWrapper();
        s2.sequence = 2;
        s2.siteType = BSF_Constants.TYPE_BLOOD_DRIVE;
        s2.siteId = loc.Id;
        s2.arriveStartStr = '10:00';
        s2.arriveEndStr = '11:00';
        mw.stops.add(s2);

        String jsonPayload = JSON.serialize(new List<DriveMovementController.MovementWrapper>{ mw });

        Test.startTest();
        DriveMovementController.UIResponse res;
        System.runAs(getMfgUser()) {
            res = DriveMovementController.saveMovements(jsonPayload);
        }
        Test.stopTest();

        System.assert(res.isSuccess, 'Save should succeed. Error: ' + res.message);
        
        List<Drive_Delivery_Movement__c> insertedMov = [SELECT Id FROM Drive_Delivery_Movement__c WHERE Movement_Number__c = 'M-NEW-TEST'];
        System.assertEquals(1, insertedMov.size(), 'Movement should be created');
    }
    @IsTest
    static void testSaveMovements_Exception() {
        Test.startTest();
        DriveMovementController.UIResponse res;
        System.runAs(getMfgUser()) {
            res = DriveMovementController.saveMovements('[{invalid_json}]');
        }
        Test.stopTest();

        System.assert(!res.isSuccess, 'Should fail gracefully');
        System.assert(res.message.contains('Error Saving:'), 'Error message should mention saving exception');
    }
    @IsTest
    static void testFinalizeMovements_Success() {
        Drive_Delivery_Movement__c mov = [SELECT Id, Primary_Drive__c, Primary_Drive_Delivery_Job__c FROM Drive_Delivery_Movement__c LIMIT 1];

        DriveMovementController.MovementWrapper mw = new DriveMovementController.MovementWrapper();
        mw.movementRecordId = mov.Id;
        mw.selectedJobId = mov.Primary_Drive_Delivery_Job__c;
        mw.driveId = mov.Primary_Drive__c;

        String jsonPayload = JSON.serialize(new List<DriveMovementController.MovementWrapper>{ mw });

        Test.startTest();
        DriveMovementController.UIResponse res;
        System.runAs(getMfgUser()) {
            res = DriveMovementController.finalizeMovements(jsonPayload);
        }
        Test.stopTest();

        System.assert(res.isSuccess, 'Finalization should succeed. Error: ' + res.message);
        System.assertEquals(BSF_Constants.STATUS_FINAL, res.movements[0].status, 'Wrapper status should update to final');
    }
    @IsTest
    static void testFinalizeMovements_Validation_DuplicateInTransaction() {
        sked_Drive_Delivery_Job__c job = [SELECT Id FROM sked_Drive_Delivery_Job__c WHERE sked_Type__c = 'Pick Up' LIMIT 1];

        DriveMovementController.MovementWrapper mw1 = new DriveMovementController.MovementWrapper();
        mw1.selectedJobId = job.Id;
        
        DriveMovementController.MovementWrapper mw2 = new DriveMovementController.MovementWrapper();
        mw2.selectedJobId = job.Id; 

        String jsonPayload = JSON.serialize(new List<DriveMovementController.MovementWrapper>{ mw1, mw2 });

        Test.startTest();
        DriveMovementController.UIResponse res;
        System.runAs(getMfgUser()) {
            res = DriveMovementController.finalizeMovements(jsonPayload);
        }
        Test.stopTest();

        System.assert(!res.isSuccess, 'Finalization should fail due to duplicate jobs in transaction');
    }
    @IsTest
    static void testFinalizeMovements_Validation_ExistingFinal() {
        sked_Drive_Delivery_Job__c job = [SELECT Id,sked_Drive__c FROM sked_Drive_Delivery_Job__c WHERE sked_Type__c = 'Pick Up' LIMIT 1];
        
        Drive_Delivery_Movement__c finalMov = new Drive_Delivery_Movement__c(
            Primary_Drive_Delivery_Job__c = job.Id,
            Status__c = BSF_Constants.STATUS_FINAL,
            Carrier__c = 'Redcross Employee',
            Movement_Number__c = 'M-EXISTING-FINAL',
            Primary_Drive__c = job.sked_Drive__c
        );
        insert finalMov;

        DriveMovementController.MovementWrapper mw = new DriveMovementController.MovementWrapper();
        mw.selectedJobId = job.Id;
        
        String jsonPayload = JSON.serialize(new List<DriveMovementController.MovementWrapper>{ mw });

        Test.startTest();
        DriveMovementController.UIResponse res;
        System.runAs(getMfgUser()) {
            res = DriveMovementController.finalizeMovements(jsonPayload);
        }
        Test.stopTest();

        System.assert(!res.isSuccess, 'Finalization should fail due to existing final movement');
    }
    @IsTest
    static void testWithdrawMovements_Success() {
        Drive_Delivery_Movement__c mov1 = [SELECT Id, Primary_Drive__c, Primary_Drive_Delivery_Job__c FROM Drive_Delivery_Movement__c LIMIT 1];

        DriveMovementController.MovementWrapper mw1 = new DriveMovementController.MovementWrapper();
        mw1.movementRecordId = mov1.Id;
        mw1.selectedJobId = mov1.Primary_Drive_Delivery_Job__c;
        mw1.driveId = mov1.Primary_Drive__c;

        String jsonPayload1 = JSON.serialize(new List<DriveMovementController.MovementWrapper>{ mw1 });

        DriveMovementController.UIResponse res1;
        System.runAs(getMfgUser()) {
            res1 = DriveMovementController.finalizeMovements(jsonPayload1);
        }

        Drive_Delivery_Movement__c mov = [SELECT Id FROM Drive_Delivery_Movement__c WHERE Status__c = 'Final' LIMIT 1];

        DriveMovementController.MovementWrapper mw = new DriveMovementController.MovementWrapper();
        mw.movementRecordId = mov.Id;

        String jsonPayload = JSON.serialize(new List<DriveMovementController.MovementWrapper>{ mw });

        Test.startTest();
        DriveMovementController.UIResponse res;
        System.runAs(getMfgUser()) {
            res = DriveMovementController.withdrawMovements(jsonPayload);
        }
        Test.stopTest();

        System.assert(res.isSuccess, 'Withdrawal should succeed');
        System.assertEquals(BSF_Constants.STATUS_CANCELED, res.movements[0].status, 'Wrapper status should update to canceled');
    }
}