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
      static testmethod void testCheckSiteCollectionOpForNoncollectionAreaForDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked_Drive__c dr = (sked_Drive__c)mapTestData.get('testDrive1');
		Boolean isNonCollectionArea = NewSiteController.checkSiteCollectionOpForNoncollectionArea(dr.id);
        System.assert(isNonCollectionArea == false);  
        sked_Site_Collection_Operation__c siteCollOp = (sked_Site_Collection_Operation__c)mapTestData.get('testLocation1_testCollectionOperation1');
        Biomed_Collection_Op_Center__c   collOp=new Biomed_Collection_Op_Center__c(id=siteCollOp.sked_Collection_Operation__c);
        collOp.name=Label.NonCollectionArea_Label;
        update   collOp;
        Boolean isNonCollectionAreaOne = NewSiteController.checkSiteCollectionOpForNoncollectionArea(dr.id);
        System.assert(isNonCollectionAreaOne == true);

  
    }
    
    static testmethod void testCheckSiteCollectionOpForOpportunities() {
         Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity opp = (Opportunity)mapTestData.get('mobileOpportunity');
		Boolean isNonCollectionArea = NewSiteController.checkSiteCollectionOpForNoncollectionArea(opp.id);
        System.assert(isNonCollectionArea == false);  
    }
}