@isTest
private class UpdateInvalidTravelTimeBatchTest {
    @TestSetup
    static void makeData() {
        Profile drdpr = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'];
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE sObjectType='Account' AND Name = 'Mobile Account'];
        RecordType siteRecType = [SELECT Id FROM RecordType WHERE sObjectType='sked__Location__c' AND Name = 'Mobile Site'];
        RecordType rtt1 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'Division'];
        RecordType rtt2 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'ARC Region'];
        RecordType rtt3 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'District'];

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');

        sked_Territory__c territoryObj1 = new sked_Territory__c(
            Name = 'Test Territory',
            recordTypeId = rtt1.Id
        );
        insert territoryObj1;

        sked_Territory__c territoryObj2 = new sked_Territory__c(
            Name = 'Test Territory',
            recordTypeId = rtt2.Id,
            sked_Parent__c = territoryObj1.Id
        );
        insert territoryObj2;

        sked_Territory__c territoryObj3 = new sked_Territory__c(
            Name = 'Test Territory',
            recordTypeId = rtt3.Id,
            sked_Parent__c = territoryObj2.Id
        );
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

        sked__Region__c regionObj = new sked__Region__c(
            sked__Timezone__c = 'America/Los_Angeles',
            Name = 'Test',
            sked__Description__c = 'Test',
            sked_External_Id__c = 'Bio_Collection_Test_America/Los_Angeles',
            sked_Biomed_Collection_Op_Center__c = collopObj.Id,
            sked_Territory__c = territoryObj3.Id
        );

        insert regionObj;

        sked__Tag__c tagObj = new sked__Tag__c(
            Name = 'Inside',
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
             LocaleSidKey = 'en_US'
        );  
        System.runAs( new User(Id = UserInfo.getUserId()) ) {
            insert DRDAMUser;
        }
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        testMobileAccount.Phone = '1234567890' ;
        testMobileAccount.Type = 'Business';
        testMobileAccount.Account_Manager__c = DRDAMUser.Id;
        insert testMobileAccount;
        
        //insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id ;
        insert testContact;
        
        //insert mobile site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Travel_Time_to_Staging_Location__c = 45;
        testMobileSite.sked_Site_Contact__c = testContact.Id;
		insert testMobileSite;
 		
        //insert SCOs
        List<sked_Site_Collection_Operation__c> siteCollopList = new List<sked_Site_Collection_Operation__c>();
        
        sked_Site_Collection_Operation__c siteCollop1;
        siteCollop1 = new sked_Site_Collection_Operation__c();
        siteCollop1.sked_Collection_Operation__c = collopObj.id;
        siteCollop1.sked_Region__c = regionObj.id;
        siteCollop1.sked_Site__c = testMobileSite.id;
        siteCollop1.sked_Travel_Time_Breakdown_JSON__c = '[{\"weekday\":\"Sunday\",\"travelTime\":0}]';
        siteCollop1.sked_Travel_Time_Breakdown_JSON_2__c = '[{\"weekday\":\"Sunday\",\"travelTime\":0}]';
        siteCollopList.add(siteCollop1);
        
        siteCollop1 = new sked_Site_Collection_Operation__c();
        siteCollop1.sked_Collection_Operation__c = collopObj.id;
        siteCollop1.sked_Region__c = regionObj.id;
        siteCollop1.sked_Site__c = testMobileSite.id;
        siteCollop1.sked_Travel_Time_Breakdown_JSON__c = '{\"weekday\":\"Sunday\",\"travelTime\":0}';
        siteCollop1.sked_Travel_Time_Breakdown_JSON_2__c = '0';
        siteCollopList.add(siteCollop1);
        
        siteCollop1 = new sked_Site_Collection_Operation__c();
        siteCollop1.sked_Collection_Operation__c = collopObj.id;
        siteCollop1.sked_Region__c = regionObj.id;
        siteCollop1.sked_Site__c = testMobileSite.id;
        siteCollop1.sked_Travel_Time_Breakdown_JSON__c = '{\"weekday\":\"Sunday\",\"travelTime\":4}';
        siteCollopList.add(siteCollop1);
        insert siteCollopList;
    }

    @isTest
    static void testMethod1() {
        Test.startTest();
        
        UpdateInvalidTravelTimeBatch batchObject = new UpdateInvalidTravelTimeBatch();
        Database.executeBatch(batchObject, 200);
        
        Test.stopTest();
        List<sked_Site_Collection_Operation__c> testSiteCos = [SELECT Id, Is_Travel_Time_Invalid__c FROM sked_Site_Collection_Operation__c];
        Assert.isTrue(testSiteCos[1].Is_Travel_Time_Invalid__c == true);
    }
    
    @isTest
    static void testMethod2() {  
        Test.StartTest();
        
        UpdateInvalidTravelTimeBatch testsche = new UpdateInvalidTravelTimeBatch(100);
        String sch = '0 0 23 * * ?';
        system.schedule('Test Scheduler batch', sch, testsche);
        
        Test.stopTest();
        Assert.isTrue([SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name = 'Test Scheduler batch'].size() == 1);
    }
}