global class UpdateAllOpportunityForCollectionZip implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        DateTime dt = System.Now().addHours(-3);
        String Kishore;
        String Name = '\'%'+Kishore+'%\'';
        String query = 'select id,name,Drive_Date__c,Drive_Site__c,Collections_Zip_Code__c,Collection_Operation__c from opportunity';
        system.debug('entered1');
        return Database.getQueryLocator(query); 
        
    }
    global void execute(Database.BatchableContext bc, List<Opportunity> listOfOppties){
        System.debug('listOfOppties '+listOfOppties.size());
        Set<Id> siteIds=new set<Id>();
        set<Id> OppIdsSet=new set<Id>();
        for(Opportunity o:listOfOppties){
            siteIds.add(o.Drive_Site__c);
            
        }
        Map<Id,List<sked_Site_Collection_Operation__c>> mapOfSiteCollectionOperation = new Map<Id,List<sked_Site_Collection_Operation__c>>();
        
        for(sked_Site_Collection_Operation__c scollection : [select id,sked_Start_Date__c,sked_End_Date__c,sked_Site__c,sked_Collections_Zip_Code__c from sked_Site_Collection_Operation__c where sked_Site__c In:siteIds]){
            system.debug('entered2'+scollection.sked_Site__c);
            if( !mapOfSiteCollectionOperation.containsKey( scollection.sked_Site__c ) ){
                mapOfSiteCollectionOperation.put( scollection.sked_Site__c, new List<sked_Site_Collection_Operation__c>() ) ;
            }
            mapOfSiteCollectionOperation.get( scollection.sked_Site__c ).add( scollection );
        } 
        
        List<Opportunity> listOfOppToUpdate=new List<Opportunity>();
        List<String> errorLog = new List<String>();
        for(Opportunity op: listOfOppties){
            if(mapOfSiteCollectionOperation.containsKey(Op.Drive_Site__c)){
                List<sked_Site_Collection_Operation__c> lsitOf= mapOfSiteCollectionOperation.get(op.Drive_Site__c);//sitezip
                system.debug('entered6'+lsitOf);
                for(sked_Site_Collection_Operation__c ctr:lsitOf){
                    if(op.Drive_Date__c >= ctr.sked_Start_Date__c && ctr.sked_End_Date__c >= op.Drive_Date__c ){
                        system.debug('ctr all1 '+ctr);
                        //if(op.Collections_Zip_Code__c!=ctr.sked_Collections_Zip_Code__c){
                        system.debug('ctr all2 '+ctr);
                        op.Collections_Zip_Code__c=ctr.sked_Collections_Zip_Code__c; 
                        //op.Online_Scheduling_Enabled__c='No';
                        listOfOppToUpdate.add(op);
                        OppIdsSet.add(op.Id);
                        break;
                        //}
                    }
                }
            }
            if(!OppIdsSet.contains(op.Id)){
                op.Collections_Zip_Code__c=null;
                listOfOppToUpdate.add(op);
            }
        }
        if(!listOfOppToUpdate.isEmpty()){
            system.debug('entered7'+listOfOppToUpdate.size()+' '+listOfOppToUpdate);
            Database.SaveResult[] FinalList=Database.update(listOfOppToUpdate,false);
           
        }
       
    }
    
    
    
    global void finish(Database.BatchableContext BC){
        
    }
}