@IsTest
private class TMSSiteServiceTest {
    
    @TestSetup
    static void setupData() {
       List<Profile> mfgProfiles = [SELECT Id FROM Profile WHERE Name LIKE '%Manufacturing%' LIMIT 1];
        Id profileId =  mfgProfiles[0].Id;
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'MfgUser',
            Email = 'testmfguser@tms.com',
            Username = 'testmfguser' + DateTime.now().getTime() + '@tms.com',
            Alias = 'tmfg',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileId,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Email = 'testmfguser@tms.com' LIMIT 1];
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
    static void testTMSSiteDefaultsAndValid() {
        TMS_Site__c site1 = new TMS_Site__c(Name = 'Valid Site');
        
        Test.startTest();
        TMSSiteService.handleTMSSiteBeforeSave(new List<TMS_Site__c>{ site1 }, null);
        Test.stopTest();
        
        System.assertEquals(System.today(), site1.Effective_Date__c, 'Effective Date should default to today.');
        System.assertEquals(Date.newInstance(4000, 12, 31), site1.End_Date__c, 'End Date should default to 12/31/4000.');
        System.assertEquals(false, site1.hasErrors(), 'There should be no errors for a valid site.');
    }

    @IsTest
    static void testTMSSiteOverlapBatch() {
        TMS_Site__c site1 = new TMS_Site__c(Name = 'Batch Site', Effective_Date__c = Date.today(), End_Date__c = Date.today().addDays(10));
        TMS_Site__c site2 = new TMS_Site__c(Name = 'Batch Site', Effective_Date__c = Date.today().addDays(5), End_Date__c = Date.today().addDays(15));
        
        Test.startTest();
        TMSSiteService.handleTMSSiteBeforeSave(new List<TMS_Site__c>{ site1, site2 }, null);
        Test.stopTest();
        
        System.assertEquals(true, site1.hasErrors(), 'First site in batch should process cleanly.');
        System.assertEquals(false, site2.hasErrors(), 'Second site should catch the batch overlap error.');
    }

    @IsTest
    static void testTMSSiteOverlapExisting() {
        TMS_Site__c existingSite = new TMS_Site__c(Name = 'Existing Site', Effective_Date__c = Date.today(), End_Date__c = Date.today().addDays(10));
        insert existingSite;
        
        TMS_Site__c newSite = new TMS_Site__c(Name = 'Existing Site', Effective_Date__c = Date.today().addDays(5), End_Date__c = Date.today().addDays(15));
        
        Test.startTest();
        TMSSiteService.handleTMSSiteBeforeSave(new List<TMS_Site__c>{ newSite }, null);
        Test.stopTest();
        
        System.assertEquals(true, newSite.hasErrors(), 'New site should catch the existing overlap error.');
        System.assert(newSite.getErrors()[0].getMessage().contains('Date range overlaps with an existing TMS Site'), 'Should show correct existing error message.');
    }
    
    @IsTest
    static void testTMSSiteUpdateOverlap() {
        TMS_Site__c site1 = new TMS_Site__c(Name = 'Update Site', Effective_Date__c = Date.today(), End_Date__c = Date.today().addDays(10));
        TMS_Site__c site2 = new TMS_Site__c(Name = 'Update Site', Effective_Date__c = Date.today().addDays(15), End_Date__c = Date.today().addDays(20));
        insert new List<TMS_Site__c>{ site1, site2 };
        
        TMS_Site__c oldSite2 = [SELECT Id, Name, Effective_Date__c, End_Date__c FROM TMS_Site__c WHERE Id = :site2.Id];
        TMS_Site__c newSite2 = oldSite2.clone(true, true, true, true);
        newSite2.Effective_Date__c = Date.today().addDays(5);
        
        Test.startTest();
        TMSSiteService.handleTMSSiteBeforeSave(
            new List<TMS_Site__c>{ newSite2 }, 
            new Map<Id, TMS_Site__c>{ oldSite2.Id => oldSite2 }
        );
        Test.stopTest();
        
        System.assertEquals(true, newSite2.hasErrors(), 'Updating to an overlapping date should throw an error.');
    }

    @IsTest
    static void testAssignmentMultipleDefaultBatch() {
        User u = getTestUser();
        
        TMS_Site_User_Assignment__c assignment1 = new TMS_Site_User_Assignment__c(User__c = u.Id, Is_Default__c = true);
        TMS_Site_User_Assignment__c assignment2 = new TMS_Site_User_Assignment__c(User__c = u.Id, Is_Default__c = true);
        
        Test.startTest();
        TMSSiteService.handleAssignmentBeforeSave(new List<TMS_Site_User_Assignment__c>{ assignment1, assignment2 }, null);
        Test.stopTest();
        
        System.assertEquals(false, assignment1.hasErrors(), 'First assignment processes cleanly.');
        System.assertEquals(true, assignment2.hasErrors(), 'Second assignment should fail validation.');
        System.assert(assignment2.getErrors()[0].getMessage().contains('Only one default TMS Site can be selected for a User.'), 'Correct batch default error should display.');
    }

    @IsTest
    static void testAssignmentMultipleDefaultExisting() {
        User u = getTestUser();
        
        TMS_Site__c tmsSite = new TMS_Site__c(Name = 'Test Site');
        insert tmsSite;
        
        System.runAs(u) {
            TMS_Site_User_Assignment__c existingAssignment = new TMS_Site_User_Assignment__c(
                User__c = u.Id, 
                Assigned_TMS_Site__c = tmsSite.Id, 
                Is_Default__c = true
            );
            insert existingAssignment;
            
            TMS_Site_User_Assignment__c newAssignment = new TMS_Site_User_Assignment__c(
                User__c = u.Id, 
                Assigned_TMS_Site__c = tmsSite.Id, 
                Is_Default__c = true
            );
            
            Test.startTest();
            TMSSiteService.handleAssignmentBeforeSave(new List<TMS_Site_User_Assignment__c>{ newAssignment }, null);
            Test.stopTest();
            
            System.assertEquals(true, newAssignment.hasErrors(), 'New assignment should fail because a default already exists.');
            System.assert(newAssignment.getErrors()[0].getMessage().contains('already has an active default TMS Site assigned'), 'Correct existing default error should display.');
        }
    }
    
    @IsTest
    static void testAssignmentUpdateToDefault() {
        User u = getTestUser();
        TMS_Site__c tmsSite = new TMS_Site__c(Name = 'Test Site');
        insert tmsSite;
        
        System.runAs(u) {
            TMS_Site_User_Assignment__c defaultAssignment = new TMS_Site_User_Assignment__c(User__c = u.Id, Assigned_TMS_Site__c = tmsSite.Id, Is_Default__c = true);
            TMS_Site_User_Assignment__c nonDefaultAssignment = new TMS_Site_User_Assignment__c(User__c = u.Id, Assigned_TMS_Site__c = tmsSite.Id, Is_Default__c = false);
            insert new List<TMS_Site_User_Assignment__c>{ defaultAssignment, nonDefaultAssignment };
            
            TMS_Site_User_Assignment__c oldAssign = [SELECT Id, User__c, Is_Default__c FROM TMS_Site_User_Assignment__c WHERE Id = :nonDefaultAssignment.Id];
            TMS_Site_User_Assignment__c newAssign = oldAssign.clone(true, true, true, true);
            newAssign.Is_Default__c = true;
            
            Test.startTest();
            TMSSiteService.handleAssignmentBeforeSave(
                new List<TMS_Site_User_Assignment__c>{ newAssign },
                new Map<Id, TMS_Site_User_Assignment__c>{ oldAssign.Id => oldAssign }
            );
            Test.stopTest();
            
            System.assertEquals(true, newAssign.hasErrors(), 'Updating a second record to Default should fail.');
        }
    }

    @IsTest
    static void testLocationMappingBatchConflict() {
        TMS_Site__c tmsSite = new TMS_Site__c(Name = 'Test TMS Site');
        insert tmsSite;
        
        sked__Location__c loc1 = new sked__Location__c(Name = 'Loc 1', sked_Active__c = true, TMS_Site__c = tmsSite.Id);
        sked__Location__c loc2 = new sked__Location__c(Name = 'Loc 2', sked_Active__c = true, TMS_Site__c = tmsSite.Id);
        
        Test.startTest();
        TMSSiteService.validateTMSSiteBeforeSave(new List<sked__Location__c>{ loc1, loc2 }, null);
        Test.stopTest();
        
        System.assertEquals(false, loc1.hasErrors(), 'First location processed successfully.');
        System.assertEquals(true, loc2.hasErrors(), 'Second location must catch the batch mapping error.');
        System.assert(loc2.getErrors()[0].getMessage().contains('Another active BSF Site in this batch is already attempting to map'), 'Correct batch message.');
    }

    @IsTest
    static void testLocationMappingExistingConflict() {
         String mobileAccRecType = 'Mobile Account';
        String mobileSiteRecType = 'Mobile Site';  
        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);

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
        
        TMS_Site__c tmsSite = new TMS_Site__c(Name = 'Test TMS Site');
        insert tmsSite;
        sked__Location__c existingLoc = new sked__Location__c();
        existingLoc.RecordTypeId = siteRecTypeId;
        existingLoc.Name = 'Existing Loc';
        existingLoc.sked_Address_1__c = '123 Test Ave';
        existingLoc.sked__Address__c = 'Test Site Address';
        existingLoc.sked_City__c = 'New York';
        existingLoc.sked_State__c = 'Test Site State';
        existingLoc.sked_Zip_Code__c = '4001';
        existingLoc.sked_County__c = 'USA';
        existingLoc.sked_Site_Building_Name__c = 'Test Site Building';
        existingLoc.sked_Floor_Description__c = 'Test Site Floor Description';
        existingLoc.sked_Room_Name__c = 'Room 15';
        existingLoc.sked_National_Name__c = 'AMERICA';
        existingLoc.sked_Physical_Location_Type__c = 'Outside';
        existingLoc.sked_Site_Inspection_Completed_By__c = getTestUser().Id;
        existingLoc.sked_Automation_Suitability__c = 'Suitable';
        existingLoc.sked_Outside_stairs__c = 1;
        existingLoc.sked_Inside_stairs__c = 2;
        existingLoc.sked_Base_Description__c = 'test base description';
        existingLoc.sked_Travel_Time_to_Staging_Location__c = 45;
        existingLoc.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        existingLoc.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        existingLoc.sked_Site_Contact__c = conObj.Id;
        existingLoc.sked_Site_Main_Phone__c = '758-771-0091';
        existingLoc.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        existingLoc.sked_Pay_for_Parking__c = 'Other';
        existingLoc.sked_Pay_for_Parking_Details__c = 'Test Pay';
        existingLoc.sked_Wireless_Policy__c = 'Accepted';
        existingLoc.Source__c = 'Custom New Form';
        existingLoc.sked_Date_Site_Inspection_Completed__c = Date.today();
        existingLoc.sked_Active__c = true;
        existingLoc.TMS_Site__c = tmsSite.Id;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert existingLoc;
        
        sked__Location__c newLoc = new sked__Location__c(Name = 'New Loc', sked_Active__c = true, TMS_Site__c = tmsSite.Id);
        
        Test.startTest();
        TMSSiteService.validateTMSSiteBeforeSave(new List<sked__Location__c>{ newLoc }, null);
        Test.stopTest();
        
        System.assertEquals(true, newLoc.hasErrors(), 'New location must fail because the TMS site is already mapped to an active BSF Site.');
        System.assert(newLoc.getErrors()[0].getMessage().contains('An active BSF Site is already mapped to this TMS Site'), 'Correct existing database message.');
    }

    @IsTest
    static void testLocationMappingUpdateConflict() {
        String mobileAccRecType = 'Mobile Account';
        String mobileSiteRecType = 'Mobile Site';  
        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        
        TMS_Site__c tmsSite = new TMS_Site__c(Name = 'Test TMS Site');
        insert tmsSite;

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

        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Active Loc';
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
        siteObj.sked_Site_Inspection_Completed_By__c = getTestUser().Id;
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
        siteObj.sked_Active__c = true;
        siteObj.TMS_Site__c = tmsSite.Id;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;

        sked__Location__c siteObj1 = new sked__Location__c();
        siteObj1.RecordTypeId = siteRecTypeId;
        siteObj1.Name = 'Inactive Loc';
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
        siteObj1.sked_Site_Inspection_Completed_By__c = getTestUser().Id;
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
        siteObj1.sked_Active__c = false;
        siteObj1.TMS_Site__c = tmsSite.Id;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj1;

        
        sked__Location__c oldLoc = [SELECT Id, TMS_Site__c, sked_Active__c FROM sked__Location__c WHERE Id = :siteObj1.Id];
        sked__Location__c newLoc = oldLoc.clone(true, true, true, true);
        newLoc.sked_Active__c = true; 
        
        Test.startTest();
        TMSSiteService.validateTMSSiteBeforeSave(
            new List<sked__Location__c>{ newLoc },
            new Map<Id, sked__Location__c>{ oldLoc.Id => oldLoc }
        );
        Test.stopTest();
        
        System.assertEquals(true, newLoc.hasErrors(), 'Changing the location to Active should throw an error if the TMS Site is already taken.');
    }
}