global class BSF_BatchUpdateAccountForZipCode implements Database.Batchable<sObject>{
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        String query = 'select Id,Zip__c,name,sked_Start_Date__c,sked_End_Date__c from Collections_Territory__c WHERE LastModifiedDate >= YESTERDAY AND LastModifiedDate <= TODAY';
        system.debug('entered1');
        return Database.getQueryLocator(query); 
        
    }
    
    global void execute(Database.BatchableContext bc, List<Collections_Territory__c> listOfCollectionTerrritory){
        Map<String,List<Collections_Territory__c>> mapOfCollectionTerritory = new Map<String,List<Collections_Territory__c>>(); //mapOfCollectionTerritory
        
        for(Collections_Territory__c czipCodeRecord : listOfCollectionTerrritory){
            system.debug('entered2'+czipCodeRecord.Zip__c);
            if( !mapOfCollectionTerritory.containsKey( czipCodeRecord.Zip__c ) ){
                mapOfCollectionTerritory.put( czipCodeRecord.Zip__c, new List<Collections_Territory__c>() ) ;
            }
            mapOfCollectionTerritory.get( czipCodeRecord.Zip__c ).add( czipCodeRecord ); 
        }
        List<Account> listOfAccountsToUpdate =new List<Account>();  
        Set<id> updatedAcctids=new Set<Id>();
        
        List<Account> listofAccounts=[select id,createdDate,Collections_Territory__c,BillingPostalCode from Account where BillingPostalCode IN:mapOfCollectionTerritory.KeySet()];
        system.debug('entered2.1'+listofAccounts);
        for(Account accRecord : listofAccounts){
            system.debug('entered3'+accRecord);
            if(mapOfCollectionTerritory.containsKey(accRecord.BillingPostalCode)){
                for(Collections_Territory__c ctr : mapOfCollectionTerritory.get(accRecord.BillingPostalCode) ){
                    system.debug('entered4'+ctr);
                    if( System.today() >= ctr.sked_Start_Date__c && ctr.sked_End_Date__c >= System.today()){//system.today
                        system.debug('entered4.0'+ctr.name+' '+ctr.Zip__c);
                        accRecord.Collections_Territory__c = ctr.Id ;
                        updatedAcctids.add(accRecord.id);
                        listOfAccountsToUpdate.add(accRecord);
                        system.debug('entered4.1'+listOfAccountsToUpdate);
                        break;
                    }
                }
            }
            
        }  
        if(!listOfAccountsToUpdate.isEmpty()){
            update listOfAccountsToUpdate;   
        }
    }   
    
    
    global void finish(Database.BatchableContext BC){
        
    }
}