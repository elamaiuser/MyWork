global class BatchAccoutsOpptyUpdateOnCZipCode implements Database.Batchable<sObject> {
   
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
        
        
        List<Opportunity> listOfOppties=[select Id,Drive_Date__c,opportunity.account.BillingPostalCode,Drive_Site__r.sked_Zip_Code__c,AccountId from Opportunity where Drive_Site__r.sked_Zip_Code__c In:mapOfCollectionTerritory.KeySet()];//updatedAcctids-sitezip
        system.debug('entered5'+listOfOppties);
        List<Opportunity> listOfOppToUpdate=new List<Opportunity>();
        for(Opportunity op: listOfOppties){
            if(mapOfCollectionTerritory.containsKey(Op.Drive_Site__r.sked_Zip_Code__c)){
                List<Collections_Territory__c> lsitOf= mapOfCollectionTerritory.get(op.Drive_Site__r.sked_Zip_Code__c);//sitezip
                system.debug('entered6'+lsitOf);
                for(Collections_Territory__c ctr:lsitOf){
                    if(op.Drive_Date__c >= ctr.sked_Start_Date__c && ctr.sked_End_Date__c >= op.Drive_Date__c ){
                        op.Collections_Zip_Code__c=ctr.id;
                        listOfOppToUpdate.add(op);
                        break;
                        
                    }
                }
            }
            
            if(!listOfOppToUpdate.isEmpty()){
                system.debug('entered7'+listOfOppToUpdate);
                update listOfOppToUpdate;
            }
        }
        
    }   
    
    
    
    global void finish(Database.BatchableContext BC){
        
    }

}