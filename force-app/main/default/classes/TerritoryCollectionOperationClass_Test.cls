/* The following test class is covering the below mentioned two apex classes and one trigger
 * 1. TerritoryCollectionOperationService
 * 2. TerritoryCollOpTriggerHandler
 * 3. TerritoryCollectionOperation
 * */

@isTest
public class TerritoryCollectionOperationClass_Test {
 
    @testSetup static void prepareDataset()
    {    
       BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
       Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // create territory
        sked_Territory__c territory = (sked_Territory__c)mapTestData.get('SKED_TERRITORY_DIVISON') ;
        insert territory;
        
        // create collection operation
        Biomed_Collection_Op_Center__c collectionOpp = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP') ;
        insert collectionOpp;
        
        // create sked_Territory_Collection_Operation__c        
        List<sked_Territory_Collection_Operation__c> territoryColOppList = new List<sked_Territory_Collection_Operation__c>();
        sked_Territory_Collection_Operation__c territoryColOpp = new sked_Territory_Collection_Operation__c();
        territoryColOpp.sked_Collection_Operation__c = collectionOpp.id;
        territoryColOpp.sked_Territory__c = territory.id;
        territoryColOpp.sked_Start_Date__c = System.today();
        territoryColOpp.sked_End_Date__c = System.today().addDays(10);
        territoryColOppList.add(territoryColOpp);        
        insert territoryColOppList;        
    }
    
    @isTest static void testDateHandle()
    {
        List<sked_Territory_Collection_Operation__c> updateColOppList = new list<sked_Territory_Collection_Operation__c>(); 
        Map<id,sked_Territory_Collection_Operation__c>territoryColOldMap = new map<id,sked_Territory_Collection_Operation__c>();
        sked_Territory_Collection_Operation__c obj = [select id , sked_Start_Date__c, sked_End_Date__c from sked_Territory_Collection_Operation__c]; 
        territoryColOldMap.put(obj.id,obj);
        
        //updateColOppList.add(obj);
   
        obj.sked_Start_Date__c = null;
        
        update obj;
        updateColOppList.add(obj);
        Test.startTest();
        TerritoryCollectionOperationService.DateHandlingOnUpdate(territoryColOldMap,updateColOppList);
        test.stopTest();
       
    }
}