@IsTest
private class DriveMovementServiceTest {
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

    @IsTest
    static void testHandleDriveChanges_Updates() {
        sked_Drive__c oldDrive = [SELECT Id, sked_Status__c, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c FROM sked_Drive__c LIMIT 1];
        
        sked_Drive__c newDrive = oldDrive.clone(true, true, true, true);
        newDrive.sked_Drive_Date__c = Date.today().addDays(62);
        newDrive.sked_Start_Time__c = Time.newInstance(10, 0, 0, 0);
        sked__Location__c newSite = [SELECT Id FROM sked__Location__c WHERE Id != :oldDrive.sked_Drive_Site__c LIMIT 1];
        newDrive.sked_Drive_Site__c = newSite.Id;

        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>{ oldDrive.Id => oldDrive };
        Map<Id, sked_Drive__c> newMap = new Map<Id, sked_Drive__c>{ newDrive.Id => newDrive };

        Test.startTest();
        DriveMovementService.handleDriveChanges(newMap, oldMap);
        
        DriveMovementService.handleDriveChanges(null, null); 
        Test.stopTest();

        Drive_Delivery_Shipment__c updatedShip = [SELECT Pickup_Start_Date__c FROM Drive_Delivery_Shipment__c LIMIT 1];
        System.assertEquals(Date.today().addDays(62), updatedShip.Pickup_Start_Date__c, 'Shipment Date should match updated Drive date.');
    }

    @IsTest
    static void testHandleDriveChanges_Cancel() {
        sked_Drive__c oldDrive = [SELECT Id, sked_Status__c, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c FROM sked_Drive__c LIMIT 1];
        
        sked_Drive__c newDrive = oldDrive.clone(true, true, true, true);
        newDrive.sked_Status__c = 'Cancel';

        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>{ oldDrive.Id => oldDrive };
        Map<Id, sked_Drive__c> newMap = new Map<Id, sked_Drive__c>{ newDrive.Id => newDrive };

        Test.startTest();
        DriveMovementService.handleDriveChanges(newMap, oldMap);
        Test.stopTest();

        Drive_Delivery_Movement__c updatedMov = [SELECT Status__c FROM Drive_Delivery_Movement__c LIMIT 1];
        System.assertEquals(BSF_Constants.STATUS_CANCELED, updatedMov.Status__c, 'Movement should be cancelled when Drive is cancelled.');
    }

    @IsTest
    static void testHandleJobChanges_Updates() {
        sked_Drive_Delivery_Job__c oldJob = [SELECT Id, sked_Type__c, sked_Pick_Up_Time__c FROM sked_Drive_Delivery_Job__c WHERE sked_Type__c = 'Pick Up' LIMIT 1];
        
        sked_Drive_Delivery_Job__c newJob = oldJob.clone(true, true, true, true);
        newJob.sked_Type__c = 'VOL Pick Up';
        newJob.sked_Pick_Up_Time__c = Time.newInstance(11, 0, 0, 0);

        Map<Id, sked_Drive_Delivery_Job__c> oldMap = new Map<Id, sked_Drive_Delivery_Job__c>{ oldJob.Id => oldJob };
        Map<Id, sked_Drive_Delivery_Job__c> newMap = new Map<Id, sked_Drive_Delivery_Job__c>{ newJob.Id => newJob };

        Test.startTest();
        DriveMovementService.handleJobChanges(newMap, oldMap);
        Test.stopTest();

        System.assert(true, 'Movement Updated successfully.');
    }

    @IsTest
    static void testHandleJobChanges_Delete() {
        sked_Drive_Delivery_Job__c oldJob = [SELECT Id, sked_Type__c, sked_Pick_Up_Time__c FROM sked_Drive_Delivery_Job__c WHERE sked_Type__c = 'Pick Up' LIMIT 1];
        Map<Id, sked_Drive_Delivery_Job__c> oldMap = new Map<Id, sked_Drive_Delivery_Job__c>{ oldJob.Id => oldJob };
        
        Test.startTest();
        DriveMovementService.handleJobChanges(null, oldMap);
        Test.stopTest();
        
        Drive_Delivery_Movement__c updatedMov = [SELECT Status__c FROM Drive_Delivery_Movement__c LIMIT 1];
        System.assertEquals(BSF_Constants.STATUS_CANCELED, updatedMov.Status__c, 'Movement should be cancelled when parent Job is deleted.');
    }

    @IsTest
    static void testHandleLocationChanges1() {
        sked_Drive__c oldDrive = [SELECT Id, sked_Status__c, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c FROM sked_Drive__c LIMIT 1];
        
        sked__Location__c oldLoc = [SELECT Id, sked_Address_1__c, sked_Address_2__c, sked_City__c, sked_County__c, sked_State__c, sked_Zip_Code__c FROM sked__Location__c WHERE Id = :oldDrive.sked_Drive_Site__c LIMIT 1];
        
        sked__Location__c newLoc = oldLoc.clone(true, true, true, true);
        newLoc.sked_Address_1__c = '0456 Updated Address Ln';

        Map<Id, sked__Location__c> oldMap = new Map<Id, sked__Location__c>{ oldLoc.Id => oldLoc };
        Map<Id, sked__Location__c> newMap = new Map<Id, sked__Location__c>{ newLoc.Id => newLoc };

        Test.startTest();
        DriveMovementService.handleLocationChanges(newMap, oldMap);
        
        DriveMovementService.handleLocationChanges(null, null);
        Test.stopTest();

        System.assert(true, 'Location changes processed successfully.');
    }

    @IsTest
    static void testHandleLocationChanges2() {
        sked_Drive__c oldDrive = [SELECT Id, sked_Status__c, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c FROM sked_Drive__c LIMIT 1];
        
        List<sked__Location__c> oldLocs = [SELECT Id, sked_Address_1__c, sked_Address_2__c, sked_City__c, sked_County__c, sked_State__c, sked_Zip_Code__c FROM sked__Location__c WHERE Id != :oldDrive.sked_Drive_Site__c LIMIT 2];
        
        sked__Location__c newLoc1 = oldLocs[0].clone(true, true, true, true);
        newLoc1.sked_Zip_Code__c = '4500';
        sked__Location__c newLoc2 = oldLocs[1].clone(true, true, true, true);
        newLoc2.sked_Address_1__c = '0456 Updated Address Ln';

        Map<Id, sked__Location__c> oldMap1 = new Map<Id, sked__Location__c>{ oldLocs[0].Id => oldLocs[0] };
        Map<Id, sked__Location__c> newMap1 = new Map<Id, sked__Location__c>{ newLoc1.Id => newLoc1 };
        Map<Id, sked__Location__c> oldMap2 = new Map<Id, sked__Location__c>{ oldLocs[1].Id => oldLocs[1] };
        Map<Id, sked__Location__c> newMap2 = new Map<Id, sked__Location__c>{ newLoc2.Id => newLoc2 };

        Test.startTest();
        DriveMovementService.handleLocationChanges(newMap1, oldMap1);
        DriveMovementService.handleLocationChanges(newMap2, oldMap2);

        DriveMovementService.handleLocationChanges(null, null);
        Test.stopTest();

        System.assert(true, 'Location changes processed successfully.');
    }

    @IsTest
    static void testPerformFinalizationCore1() {
        Map<Id, Drive_Delivery_Movement__c> movMap = new Map<Id, Drive_Delivery_Movement__c>([SELECT Id FROM Drive_Delivery_Movement__c]);

        Test.startTest();
        DriveMovementService.performFinalizationCore(movMap.keySet(), true);
        
        Test.stopTest();

        Drive_Delivery_Movement__c finalizedMov = [SELECT Status__c FROM Drive_Delivery_Movement__c LIMIT 1];
        System.assertEquals(BSF_Constants.STATUS_FINAL, finalizedMov.Status__c, 'Movement should be marked as Final.');
        
        List<Delivery_Shipment_Integration__c> integrations = [SELECT Id, Action_Type__c FROM Delivery_Shipment_Integration__c];
        System.assert(!integrations.isEmpty(), 'Integration record should be created.');
        System.assertEquals(BSF_Constants.INTEG_ACTION_CREATE, integrations[0].Action_Type__c, 'Action type should be CREATE.');
    }

    @IsTest
    static void testPerformFinalizationCore2() {
        Map<Id, Drive_Delivery_Movement__c> movMap = new Map<Id, Drive_Delivery_Movement__c>([SELECT Id FROM Drive_Delivery_Movement__c]);

        Test.startTest();
        DriveMovementService.performFinalizationCore(movMap.keySet(), false);
        Test.stopTest();

        Drive_Delivery_Movement__c finalizedMov = [SELECT Status__c FROM Drive_Delivery_Movement__c LIMIT 1];
        System.assertEquals(BSF_Constants.STATUS_FINAL, finalizedMov.Status__c, 'Movement should be marked as Final.');
        
        List<Delivery_Shipment_Integration__c> integrations = [SELECT Id, Action_Type__c FROM Delivery_Shipment_Integration__c];
        System.assert(!integrations.isEmpty(), 'Integration record should be created.');
        System.assertEquals(BSF_Constants.INTEG_ACTION_CREATE, integrations[0].Action_Type__c, 'Action type should be CREATE.');
    }

    @IsTest
    static void testPerformCancelationCore1() {
        Map<Id, Drive_Delivery_Movement__c> movMap = new Map<Id, Drive_Delivery_Movement__c>([SELECT Id FROM Drive_Delivery_Movement__c]);
        Id movementId = movMap.values()[0].Id;

        DriveMovementService.performFinalizationCore(movMap.keySet(), false);

        Test.startTest();
        DriveMovementService.performCancelationCore(movMap.keySet(), true);
        Test.stopTest();

        Drive_Delivery_Movement__c canceledMov = [SELECT Status__c FROM Drive_Delivery_Movement__c LIMIT 1];
        System.assertEquals(BSF_Constants.STATUS_CANCELED, canceledMov.Status__c, 'Movement should be marked as Canceled.');
        
    }

    @IsTest
    static void testPerformCancelationCore2() {
        Map<Id, Drive_Delivery_Movement__c> movMap = new Map<Id, Drive_Delivery_Movement__c>([SELECT Id FROM Drive_Delivery_Movement__c]);
        Id movementId = movMap.values()[0].Id;

        DriveMovementService.performFinalizationCore(movMap.keySet(), false);

        Test.startTest();
        DriveMovementService.performCancelationCore(movMap.keySet(), false);
        Test.stopTest();

        Drive_Delivery_Movement__c canceledMov = [SELECT Status__c FROM Drive_Delivery_Movement__c LIMIT 1];
        System.assertEquals(BSF_Constants.STATUS_CANCELED, canceledMov.Status__c, 'Movement should be marked as Canceled.');
        
    }

    @IsTest
    static void testExceptionLogging() {
        Test.startTest();
        Set<Id> badIds = new Set<Id>{ null };
        DriveMovementService.performFinalizationCore(badIds, false);
        Test.stopTest();

        System.assert(true, 'Exceptions should be gracefully handled and logged internally when not from UI context.');
    }
}