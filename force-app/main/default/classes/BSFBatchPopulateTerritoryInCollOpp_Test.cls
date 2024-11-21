@isTest
public class BSFBatchPopulateTerritoryInCollOpp_Test 
{
	 @testSetup static void prepareDataset()
    {    
       BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
       Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // create territory
        list<sked_Territory__c> territoryList = new list<sked_Territory__c>();
        sked_Territory__c territoryDivision = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_DIVISON') ;
        territoryList.add(territoryDivision);
        sked_Territory__c territoryRegion = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_ARC_REGION') ;
        territoryList.add(territoryRegion);
        sked_Territory__c territoryDistrict = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_DISTRICT') ;
        territoryDistrict.Name='Test Dis';
        territoryList.add(territoryDistrict);
        insert territoryList;
        
        sked_Territory__c districtTerritory = new sked_Territory__c(
            Name= 'Alabama North 02',
            RecordTypeId =  sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('District').getRecordTypeId(),  
            sked_High_Drive_Productivity_Threshold__c= 0.800000,
            sked_Mid_Drive_Productivity_Threshold__c= 0.600000,
            sked_Parent__c = territoryRegion.id
        );
        insert districtTerritory;
        
        // create collection operation
        Biomed_Collection_Op_Center__c collectionOpp = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP') ;
        collectionOpp.Name='Test CollOp';
        collectionOpp.sked_Territory__c=territoryDistrict.id;
        insert collectionOpp;
        
        // create sked_Territory_Collection_Operation__c        
        List<sked_Territory_Collection_Operation__c> territoryColOppList = new List<sked_Territory_Collection_Operation__c>();
        sked_Territory_Collection_Operation__c territoryColOpp = new sked_Territory_Collection_Operation__c();
        territoryColOpp.sked_Collection_Operation__c = collectionOpp.id;
        territoryColOpp.sked_Territory__c = territoryDistrict.id;
        territoryColOpp.sked_Start_Date__c = System.today();
        territoryColOpp.sked_End_Date__c = System.today().addDays(10);
        territoryColOppList.add(territoryColOpp);        
        
        
        insert territoryColOppList;        
    }
    
    @isTest static void testDateHandle()
    {
        List<sked_Territory_Collection_Operation__c> updateColOppList = new list<sked_Territory_Collection_Operation__c>(); 
       
        sked_Territory_Collection_Operation__c obj = [select id ,sked_Territory__c, sked_Start_Date__c, sked_End_Date__c from sked_Territory_Collection_Operation__c ]; 
        obj.sked_Start_Date__c =System.today().addDays(10);
        obj.sked_Start_Date__c =System.today().addDays(20);
        update obj;
        
        
        Biomed_Collection_Op_Center__c collecOpp = [select id,sked_Territory__c from Biomed_Collection_Op_Center__c where Name='Test CollOp'];
        sked_Territory_Collection_Operation__c territoryColOpp = new sked_Territory_Collection_Operation__c();
        territoryColOpp.sked_Collection_Operation__c = collecOpp.id;
        territoryColOpp.sked_Territory__c = [select id  from sked_Territory__c where Name='Alabama North 02'].id;
        territoryColOpp.sked_Start_Date__c = System.today();
        territoryColOpp.sked_End_Date__c = System.today().addDays(10);
        insert  territoryColOpp;
        //updateColOppList.add(obj);
   
       system.debug(collecOpp.sked_Territory__c);
       system.debug(obj.sked_Territory__c);
        system.assertEquals(collecOpp.sked_Territory__c, obj.sked_Territory__c);
        
        Test.startTest();
        BSF_Batch_PopulateTerritoryInCollOpp batch = new BSF_Batch_PopulateTerritoryInCollOpp(true);
        database.executebatch(batch);
        test.stopTest();
       system.assertNotEquals([select id,sked_Territory__c from Biomed_Collection_Op_Center__c where Name='Test CollOp'].sked_Territory__c, obj.sked_Territory__c);
    }
    
    @isTest static void scheduleClassTestMethod()
    {
        Test.StartTest();
		BSFBatchPopulateTerriInCollOppSchedule testsche = new BSFBatchPopulateTerriInCollOppSchedule(200);
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
    }
}