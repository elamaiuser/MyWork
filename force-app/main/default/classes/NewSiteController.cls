/**
 * HRP-11484 -Anil K-Check if a drive/opp site collection area is falling in non collection area
 */

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
    
    @AuraEnabled(cacheable=true)
    //HRP-11484
    public static Boolean checkSiteCollectionOpForNoncollectionArea(Id recordId){
        System.debug('Incoming recordId:'+recordId);
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        Boolean isNonCollectionArea=false;
        
        if('sked_Drive__c' == sObjName){
            sked_Drive__c docRecord = [select sked_Drive_Site__c, sked_Drive_Date__c  from sked_Drive__c where id=:recordId limit 1]; 
            AggregateResult[] ar = [select count(id)recordCount from  sked_Site_Collection_Operation__c where sked_Site__c=:docRecord.sked_Drive_Site__c and 
                                   sked_Start_Date__c <= :docRecord.sked_Drive_Date__c and sked_End_Date__c >=  :docRecord.sked_Drive_Date__c 
                                   and sked_Collection_Operation__r.name=:Label.NonCollectionArea_Label];
            if(ar.size()>0 && (Integer)ar.get(0).get('recordCount')>0){
                isNonCollectionArea = true;
            }
            
        }else if('Opportunity' == sObjName){
            Opportunity opp = [select Drive_Site__c ,Drive_Date__c  from Opportunity where id=:recordId];
            System.debug('opp drive site and dates->'+opp.Drive_Site__c+','+opp.Drive_Date__c);
            AggregateResult[] ar = [select count(id)recordCount from  sked_Site_Collection_Operation__c where sked_Site__c=:opp.Drive_Site__c and 
                                   sked_Start_Date__c <= :opp.Drive_Date__c and sked_End_Date__c >=  :opp.Drive_Date__c
                                   and sked_Collection_Operation__r.name=:Label.NonCollectionArea_Label];
            if(ar.size()>0 && (Integer)ar.get(0).get('recordCount')>0){
                isNonCollectionArea = true;
            }
            
        }
        
        return isNonCollectionArea;
    }
    
    
}