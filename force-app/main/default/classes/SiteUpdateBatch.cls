global class SiteUpdateBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Date currDate = System.today();
        String today = String.valueOf(currDate);
        
        //Retrieve site collection operation records that cover the current day
        String query = 'SELECT Id, sked_region__c, sked_Collection_Operation__c, sked_Site__c FROM sked_Site_Collection_Operation__c WHERE sked_Start_Date__c <= ' + today + ' AND sked_End_Date__c >= ' + today;
        
        return Database.getQueryLocator(query);   
    }
    
	global void execute(Database.BatchableContext bc, List<sked_Site_Collection_Operation__c> lstSiteColOp) {
        
        system.debug('### inside execute: ' + lstSiteColOp.size());
        
        Map<Id,sked_Site_Collection_Operation__c> siteColOpMap = new Map<Id,sked_Site_Collection_Operation__c>();
		List<sked__Location__c> sitesToUpdateLst = new List<sked__Location__c>();
        
        if(lstSiteColOp != null && lstSiteColOp.size() > 0) {
			for(sked_Site_Collection_Operation__c scoRec : lstSiteColOp) {
				siteColOpMap.put(scoRec.sked_Site__c, scoRec);
			}
        }
        
		List<sked__Location__c> sitesLst = [SELECT id, sked_Collection_Operation__c, sked__Region__c FROM sked__Location__c WHERE id IN: siteColOpMap.keySet()];
        
        for(sked__Location__c loc : sitesLst){
			if(siteColOpMap.containsKey(loc.id)){
				if(siteColOpMap.get(loc.id).sked_Collection_Operation__c != null){
					loc.sked_Collection_Operation__c = siteColOpMap.get(loc.id).sked_Collection_Operation__c;
				}
				if(siteColOpMap.get(loc.id).sked_Region__c != null){
					loc.sked__Region__c = siteColOpMap.get(loc.id).sked_Region__c;
				}
				sitesToUpdateLst.add(loc);
			}
		}
        
		if(sitesToUpdateLst.size() > 0){
            Database.update(sitesToUpdateLst, false);
		}
    }

    global void finish(Database.BatchableContext bc) {
       
    }
    
	global void execute(SchedulableContext scon) {
		Database.executeBatch(new SiteUpdateBatch(), 200);
   }
}