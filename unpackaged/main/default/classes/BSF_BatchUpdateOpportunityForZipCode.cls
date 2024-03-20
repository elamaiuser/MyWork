global class BSF_BatchUpdateOpportunityForZipCode implements Database.Batchable<sObject> {//BSF_BatchUpdateAccountForZipCode
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        String query = 'select Id,name,sked_Site__c,sked_Collections_Zip_Code__c,sked_Start_Date__c,sked_End_Date__c from sked_Site_Collection_Operation__c WHERE LastModifiedDate >= YESTERDAY  ALL ROWS';//drive site,AND LastModifiedDate <= TODAY
        system.debug('entered1');
        return Database.getQueryLocator(query); 
        
    }
    
    global void execute(Database.BatchableContext bc, List<sked_Site_Collection_Operation__c> listOfSiteCollections){
        system.debug('check'+listOfSiteCollections);
        Map<Id,List<sked_Site_Collection_Operation__c>> mapOfSiteCollectionOperation = new Map<Id,List<sked_Site_Collection_Operation__c>>();//siteid,
        system.debug('mapOfSiteCollectionOperation');
        
        
        for(sked_Site_Collection_Operation__c scollection : listOfSiteCollections){
            system.debug('entered2'+scollection.sked_Site__c);
            if( !mapOfSiteCollectionOperation.containsKey( scollection.sked_Site__c ) ){
                mapOfSiteCollectionOperation.put( scollection.sked_Site__c, new List<sked_Site_Collection_Operation__c>() ) ;
            }
            mapOfSiteCollectionOperation.get( scollection.sked_Site__c ).add( scollection );
        }
        
        List<Opportunity> listOfOppties=[select Id,Drive_Date__c,Drive_Site__c,Collections_Zip_Code__c from Opportunity where Drive_Site__c In:mapOfSiteCollectionOperation.KeySet()];//updatedAcctids-sitezip
        system.debug('entered5 '+listOfOppties.size()+' '+listOfOppties);
        
        Map<Id,List<sked_Site_Collection_Operation__c>> mapOfSiteCollectionOperationNewList = new Map<Id,List<sked_Site_Collection_Operation__c>>();
        for(sked_Site_Collection_Operation__c scollection1 : [select id,sked_Start_Date__c,sked_End_Date__c,sked_Site__c,sked_Collections_Zip_Code__c from sked_Site_Collection_Operation__c where sked_Site__c IN:mapOfSiteCollectionOperation.KeySet()]){
            system.debug('entered22'+scollection1.sked_Site__c);
            if( !mapOfSiteCollectionOperationNewList.containsKey( scollection1.sked_Site__c ) ){
                mapOfSiteCollectionOperationNewList.put( scollection1.sked_Site__c, new List<sked_Site_Collection_Operation__c>() ) ;
            }
            mapOfSiteCollectionOperationNewList.get( scollection1.sked_Site__c ).add( scollection1 );
        }
        
        List<Opportunity> listOfOppToUpdate=new List<Opportunity>();
        for(Opportunity op: listOfOppties){
            if(mapOfSiteCollectionOperationNewList.containsKey(Op.Drive_Site__c)){
                List<sked_Site_Collection_Operation__c> lsitOf= mapOfSiteCollectionOperationNewList.get(op.Drive_Site__c);//sitezip
                system.debug('entered6'+lsitOf);
                for(sked_Site_Collection_Operation__c ctr:lsitOf){
                    if(op.Drive_Date__c >= ctr.sked_Start_Date__c && ctr.sked_End_Date__c >= op.Drive_Date__c ){
                        system.debug('ctr all1 '+ctr);
                        if(op.Collections_Zip_Code__c!=ctr.sked_Collections_Zip_Code__c){
                            system.debug('ctr all2 '+ctr);
                            op.Collections_Zip_Code__c=ctr.sked_Collections_Zip_Code__c; 
                            //op.Online_Scheduling_Enabled__c='No';
                            listOfOppToUpdate.add(op);
                            break;
                        }
                    }
                }
            }
        }
        if(!listOfOppToUpdate.isEmpty()){
            system.debug('entered7'+listOfOppToUpdate.size()+' '+listOfOppToUpdate);
            update listOfOppToUpdate;
        }
        
    }   
    
    global void finish(Database.BatchableContext BC){
        
    }
    
}