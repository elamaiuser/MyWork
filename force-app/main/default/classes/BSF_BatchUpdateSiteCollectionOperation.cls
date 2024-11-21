/**
* ***************************************************************************************************************************************************************************
* @Description: This batch is used to populate collection operations on site records.
* @developer:   Barnojit Sharma
* ***************************************************************************************************************************************************************************
* Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 01/31/2024			Barnojit Sharma			Batch for Collection Operation field to update on Site.(HRP-11708)
* 06/18/2024			Ankit Kundu			    Update timezone on Site.(HRP-12508)
* ***************************************************************************************************************************************************************************
**/
global without sharing class BSF_BatchUpdateSiteCollectionOperation implements Schedulable, Database.Batchable<sObject>{
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(System.label.BSF_BatchUpdateSiteCollectionOperation_SOQL);
	}
	global void execute(Database.BatchableContext BC, List<sked__Location__c> scope){
        if(!scope.isEmpty()){
            doExecute(scope);
        }
	}
	global void execute(SchedulableContext scon){
		Database.executeBatch(new BSF_BatchUpdateSiteCollectionOperation(),200);
	}
	global void finish(Database.BatchableContext BC){}

    global void doExecute(List<sked__Location__c> siteList){
        Set<Id> siteIds = new Set<Id>(new Map<Id, sked__Location__c>(siteList).keySet());
        Map<Id,sked_Site_Collection_Operation__c> siteCollectionOpMap = new Map<Id,sked_Site_Collection_Operation__c>();
        List<sked__Location__c> sitesToUpdate = new List<sked__Location__c>();
		List<sked_Site_Collection_Operation__c> siteCollectionOperationsList = [SELECT Id, 
                                                                                        sked_Collection_Operation__c, 
                                                                                        sked_Region__c,
                                                                                        sked_Region__r.sked__Timezone__c,//added for HRP-12508
                                                                                        sked_Site__c 
                                                                                FROM sked_Site_Collection_Operation__c 
                                                                                WHERE sked_Site__c IN: siteIds
                                                                                AND sked_Collection_Operation__c != null
                                                                                AND sked_Start_Date__c != null
                                                                                AND sked_End_Date__c != null
                                                                                AND sked_Start_Date__c <= TODAY
                                                                                AND sked_End_Date__c >= TODAY];
        System.debug('siteCollectionOperationsList size : '+siteCollectionOperationsList.size());
        for(sked_Site_Collection_Operation__c sco : siteCollectionOperationsList){
            siteCollectionOpMap.put(sco.sked_Site__c,sco);
        }
        for(sked__Location__c site : siteList){
            Id collOpId;
            Id regionId;
            String timeZone;//added for HRP-12508
            if(!siteCollectionOpMap.isEmpty() && siteCollectionOpMap.containsKey(site.Id)){
                collOpId = siteCollectionOpMap.get(site.Id).sked_Collection_Operation__c;
                regionId = siteCollectionOpMap.get(site.Id).sked_Region__c;
                timeZone = siteCollectionOpMap.get(site.Id).sked_Region__r.sked__Timezone__c;//added for HRP-12508
            }
            System.debug('siteId : '+site.Id+' collOpId : '+collOpId+' regionId : '+regionId);
            if(site.sked_Collection_Operation__c != collOpId || site.sked__Region__c != regionId || site.sked_Timezone__c != timeZone ){
                sitesToUpdate.add(new sked__Location__c(Id = site.Id, 
                                                        sked_Collection_Operation__c = collOpId, 
                                                        sked__Region__c = regionId,
                                                        sked_Timezone__c = timeZone));//added for HRP-12508
            }
        }
        System.debug('sitesToUpdate size : '+sitesToUpdate.size());
        if(!sitesToUpdate.isEmpty()) {
            List<BSF_Error_Log__c> errList = new List<BSF_Error_Log__c>();
            Database.SaveResult[] srList;
            try {
                srList = Database.update(sitesToUpdate,false);
            }catch(DmlException expt) {
                errList.add(BSF_Utilities.getErrorLog(null,'BSF_BatchUpdateSiteCollectionOperation','execute()','Error','Error Updaing Site',expt.getMessage()));
            }
            for(Integer i=0; i < srList.size(); i++){
                if(!srList.get(i).isSuccess()) {
                    for(Database.Error err : srList.get(i).getErrors()) {
                        errList.add(BSF_Utilities.getErrorLog(null,'BSF_BatchUpdateSiteCollectionOperation','execute()','Error','Error Updaing Site : '+srList.get(i).getId(),err.getMessage()+String.join(err.getFields(),',')));
                    }
                }
            }
            System.debug('errList : '+errList);
            if(!errList.isEmpty()){
                try{
                    Database.insert(errList,false);
                }catch(Exception excptn){
                    System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                }
            }
        }
	}
}