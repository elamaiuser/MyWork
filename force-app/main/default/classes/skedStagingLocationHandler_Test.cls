@isTest
private class skedStagingLocationHandler_Test {

    static testmethod void mainTest() {
        insert new Taxonomy__c(
            Zip_Code__c = '61149',
            Time_Zone__c = 'Europe/Berlin',
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(1)
        );

        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea',
            sked_Zip_Code__c = '61149'
        );

        insert testStagingLocation1;
        
        Test.startTest();
        
        testStagingLocation1.sked_Geolocation__Latitude__s = 37.7450046123;
        update testStagingLocation1;
        
        insert new Taxonomy__c(
            Zip_Code__c = '61150',
            Time_Zone__c = 'Europe/Berlin',
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(1)
        );
        
        testStagingLocation1.sked_Zip_Code__c = '61150';
        update testStagingLocation1;
        
        Test.stopTest();
    }
}