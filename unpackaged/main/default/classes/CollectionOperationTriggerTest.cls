@isTest
private class CollectionOperationTriggerTest {
    @TestSetup
    static void makeData(){
        Group gp = new Group(
                            name = 'Test Collection Operation : Test',
                            type = 'Queue'
                        );
        Biomed_Collection_Op_Center__c testCo = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id1'
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCo;
        //skedHubBase.BypassUpdateTriggers = false;
        //skedHubBase.BypassDeleteTriggers = false;
        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'adminuser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        System.runAs( AdminUser ){
            insert gp;
        }

    }
    
    @isTest 
    static void testInsertTriggers1() {
        Test.startTest();
            Biomed_Collection_Op_Center__c testCo = new Biomed_Collection_Op_Center__c(
                Name = 'Test Collection Op',
                sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                sked_Lunch_Break_Duration_Mobile__c = '30',
                sked_Hold_Threshold__c = 100,
                Staging_Location_Geolocation__Latitude__s = 37.7450046,
                Staging_Location_Geolocation__Longitude__s = -122.4816244,
                sked_Work_Week_First_Day__c = 'Sunday',
                External_Id__c = 'external-id2'
            );
            insert testCo;
        Test.stopTest();
    }

    @isTest 
    static void testUpdateTriggers1() {
        Biomed_Collection_Op_Center__c testCo = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Op',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id2'
        );
        insert testCo;
        Test.startTest();
            testCo.Name = 'Collection Op';
            update testCo;
        Test.stopTest();
    }

    @isTest 
    static void testDeleteTriggers1() {
        List<Biomed_Collection_Op_Center__c> collectionList = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c];
        Test.startTest();
            delete collectionList;
        Test.stopTest();
    }
}