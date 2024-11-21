@isTest
private class UpdateInvalidTravelTimeBatchTest {
    @TestSetup
    static void makeData(){
        UserRole urole  = [select id from userrole where developername ='West_BDM' ];
        Profile drdpr = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'];
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE sObjectType='Account' AND Name = 'Mobile Account'];
        RecordType siteRecType = [SELECT Id FROM RecordType WHERE sObjectType='sked__Location__c' AND Name = 'Mobile Site'];
        RecordType rtt1 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'Division'];
        RecordType rtt2 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'ARC Region'];
        RecordType rtt3 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'District'];

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

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
                                                                                        Name = 'Test Collection Op',
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

        
        
        User DRDAMUser = new User(
             ProfileId = drdpr.Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        User AdminUser = [SELECT id FROM User WHERE Id =:UserInfo.getUserId()];   
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        Account accobj = new Account();
        accobj.RecordTypeId = AccountRecType.Id;
        accobj.Name = 'Exavalu';
        accobj.Phone = '1234567890' ;
        accobj.Type = 'Business';
        accobj.Account_Manager__c = DRDAMUser.id;
        insert accobj;
        
        Contact conObj = new Contact();
        conObj.AccountId = accobj.Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email = 'testContact@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        insert conObj;

        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = siteRecType.Id;
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
        insert siteObj;

        List<sked_Site_Collection_Operation__c> siteCollopList = new List<sked_Site_Collection_Operation__c>();
        sked_Site_Collection_Operation__c siteCollop1 = new sked_Site_Collection_Operation__c();
        siteCollop1.sked_Collection_Operation__c = collopObj.id;
        siteCollop1.sked_Region__c = regionObj.id;
        siteCollop1.sked_Site__c = siteObj.id;
        siteCollop1.sked_Travel_Time_Breakdown_JSON__c = '[{\"weekday\":\"Sunday\",\"travelTime\":0}]';
        siteCollop1.sked_Travel_Time_Breakdown_JSON_2__c = '[{\"weekday\":\"Sunday\",\"travelTime\":0}]';
        siteCollopList.add(siteCollop1);
        sked_Site_Collection_Operation__c siteCollop2 = new sked_Site_Collection_Operation__c();
        siteCollop2.sked_Collection_Operation__c = collopObj.id;
        siteCollop2.sked_Region__c = regionObj.id;
        siteCollop2.sked_Site__c = siteObj.id;
        siteCollop2.sked_Travel_Time_Breakdown_JSON__c = '{\"weekday\":\"Sunday\",\"travelTime\":0}';
        siteCollop2.sked_Travel_Time_Breakdown_JSON_2__c = '0';
        siteCollopList.add(siteCollop2);
        sked_Site_Collection_Operation__c siteCollop3 = new sked_Site_Collection_Operation__c();
        siteCollop3.sked_Collection_Operation__c = collopObj.id;
        siteCollop3.sked_Region__c = regionObj.id;
        siteCollop3.sked_Site__c = siteObj.id;
        siteCollop3.sked_Travel_Time_Breakdown_JSON__c = '{\"weekday\":\"Sunday\",\"travelTime\":4}';
        siteCollopList.add(siteCollop3);
        insert siteCollopList;
    }

    @IsTest
    static void testMethod1(){
        
        Test.startTest();
            UpdateInvalidTravelTimeBatch batchObject = new UpdateInvalidTravelTimeBatch();
            Database.executeBatch(batchObject,200);
        Test.stopTest();
    }
    @IsTest
    static void testMethod2(){
        
        Test.StartTest();
            UpdateInvalidTravelTimeBatch testsche = new UpdateInvalidTravelTimeBatch(100);
            String sch = '0 0 23 * * ?';
            system.schedule('Test Scheduler batch', sch, testsche );
        Test.stopTest();
    }
}