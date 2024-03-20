public without sharing class NewSiteController {

    @AuraEnabled
    public static String predictCollectionOperations(String zipCode) {
       String CollectionOprName ='';
        if (String.isNotBlank(zipCode)) {
            Collections_Territory__c collectionZipCode = [SELECT Id,Name, Collection_Operation__c,Collection_Operation__r.Name, sked_End_Date__c, sked_Start_Date__c, Zip__c
                                                                 FROM Collections_Territory__c
                                                                 WHERE Zip__c =:zipCode
                                                                 AND sked_Start_Date__c <= :system.today() AND sked_End_Date__c >= :system.today() LIMIT 1];
                                                 
            if (collectionZipCode != NULL) {
                CollectionOprName = collectionZipCode.Collection_Operation__r.Name != NULL ? collectionZipCode.Collection_Operation__r.Name : '';
            }
        } 
        return CollectionOprName;
    }
}