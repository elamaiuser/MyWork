@Istest
private class NewSiteControllerTest {

    @Istest 
    static void predictCollectionOperationTest () {
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244
        );
        insert testCollectionOperation1;
        
        Collections_Territory__c collectionZipcode = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '94116'
        );
        insert collectionZipcode;
        NewSiteController.predictCollectionOperations('94116');
    }
}