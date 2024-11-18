public without sharing class TravelTimeIndexItemTriggerHandler extends TriggerHandler{
    public override void afterInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('updateOverrideFlagOnSiteCO') == -1) { 
        	updateOverrideFlagOnSiteCO((List<sked_Travel_Time_Index_Item__c>)trigger.new, null);
        }
    }
    public override void afterUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('updateOverrideFlagOnSiteCO') == -1) {
        	updateOverrideFlagOnSiteCO((List<sked_Travel_Time_Index_Item__c>)trigger.new, (Map<Id,sked_Travel_Time_Index_Item__c>)trigger.oldMap);
        }
    }
    public override void afterDelete(){
        if(super.getTriggerMethodsToBypass().indexOf('updateOverrideFlagOnSiteCO') == -1) {
        	updateOverrideFlagOnSiteCO((List<sked_Travel_Time_Index_Item__c>)trigger.old, null);
        }
    }
    public static void updateOverrideFlagOnSiteCO(List<sked_Travel_Time_Index_Item__c> newList, Map<Id,sked_Travel_Time_Index_Item__c> oldMap){
        if(newList == null || newList.isEmpty() ){
            return;
        }
        List<sked_Travel_Time_Index_Item__c> ttToCheck = new List<sked_Travel_Time_Index_Item__c>();
        List<sked_Site_Collection_Operation__c> siteCollectionOperationsToCheck = new List<sked_Site_Collection_Operation__c>();

        for(sked_Travel_Time_Index_Item__c ttData : newList){
            if(oldMap == null && ttData.sked_From__latitude__s != null && ttData.sked_From__longitude__s != null
                    && ttData.sked_To__latitude__s != null && ttData.sked_To__longitude__s != null){
                        ttToCheck.add(ttData);
            }else if(oldMap != null && !oldMap.isEmpty() && oldMap.containsKey(ttData.Id)
                    && ttData.sked_From__latitude__s != null && ttData.sked_From__longitude__s != null
                    && ttData.sked_To__latitude__s != null && ttData.sked_To__longitude__s != null
                    && ttData.User_Override__c !=  oldMap.get(ttData.Id).User_Override__c){
                        ttToCheck.add(ttData);
            }
        }
        if(!ttToCheck.isEmpty()){
            siteCollectionOperationsToCheck = getSiteCollectionOperationRecords(ttToCheck);
        }
        if(!siteCollectionOperationsToCheck.isEmpty()){
            for(sked_Site_Collection_Operation__c siteCO : siteCollectionOperationsToCheck){
                Boolean updateFlag = siteCO.User_Override__c;
                siteCO.User_Override__c = !updateFlag;
            }
            update siteCollectionOperationsToCheck;
        }
    }
    public static List<sked_Site_Collection_Operation__c> getSiteCollectionOperationRecords(List<sked_Travel_Time_Index_Item__c> indexItemList){

        List<sked_Site_Collection_Operation__c> siteCollectionOperationsList = new List<sked_Site_Collection_Operation__c>();
        List<sked__Location__c> siteList = new List<sked__Location__c>();
        List<sked_Staging_Location__c> stagingLocationList = new List<sked_Staging_Location__c>();
        Map<Id,Set<Id>> stagingLocationCOMap = new Map<Id,Set<Id>>();
        Map<String, Id> geolocationVsSiteMap = new Map<String, Id>();
        Map<String, Id> geolocationVsStagingLocationMap = new Map<String, Id>();
        Set<Location> allGeolocations = new Set<Location>();
        Set<String> siteCOPair = new Set<String>();
        Set<Id> stagingLocationIds = new Set<Id>();
        

        if(indexItemList == null || indexItemList.isEmpty() ){
            return siteCollectionOperationsList;
        }

        for(sked_Travel_Time_Index_Item__c ttData : indexItemList){
            allGeolocations.add(Location.newInstance(ttData.sked_From__latitude__s,ttData.sked_From__longitude__s));
            allGeolocations.add(Location.newInstance(ttData.sked_To__latitude__s,ttData.sked_To__longitude__s));
        }

        if(!allGeolocations.isEmpty()){
            String siteQuerryPrefix = 'SELECT Id, sked__GeoLocation__latitude__s, sked__GeoLocation__longitude__s FROM sked__Location__c WHERE ';
            String stagingLocationQuerryPrefix = 'SELECT Id, sked_GeoLocation__latitude__s, sked_GeoLocation__longitude__s FROM sked_Staging_Location__c WHERE ';

            String siteQuerryWhereClause = '';
            String stagingLocationQuerryWhereClause = '';
            for(Location loc : allGeolocations){
                String whereClauseSite = '( sked__GeoLocation__latitude__s = '+loc.getLatitude()+' AND sked__GeoLocation__longitude__s = '+loc.getLongitude()+' )';
                String whereClauseSL = '( sked_GeoLocation__latitude__s = '+loc.getLatitude()+' AND sked_GeoLocation__longitude__s = '+loc.getLongitude()+' )';
                
                if(String.isNotBlank(siteQuerryWhereClause)){
                    siteQuerryWhereClause = siteQuerryWhereClause +' OR '+ whereClauseSite;
                }else{
                    siteQuerryWhereClause = siteQuerryWhereClause + whereClauseSite;
                }

                if(String.isNotBlank(stagingLocationQuerryWhereClause)){
                    stagingLocationQuerryWhereClause = stagingLocationQuerryWhereClause +' OR '+ whereClauseSL;
                }else{
                    stagingLocationQuerryWhereClause = stagingLocationQuerryWhereClause + whereClauseSL;
                }
            }
            System.debug('Site SOQL : '+siteQuerryPrefix+siteQuerryWhereClause);
            System.debug('Staging Location SOQL : '+stagingLocationQuerryPrefix+stagingLocationQuerryWhereClause);

            siteList = Database.query(siteQuerryPrefix+siteQuerryWhereClause,AccessLevel.SYSTEM_MODE);
            System.debug('Site SOQL Data: '+siteList.size());

            stagingLocationList = Database.query(stagingLocationQuerryPrefix+stagingLocationQuerryWhereClause,AccessLevel.SYSTEM_MODE);
            System.debug('Staging Location SOQL Data: '+stagingLocationList.size());

            for(sked_Staging_Location__c sl : stagingLocationList){
                stagingLocationIds.add(sl.Id);
                geolocationVsStagingLocationMap.put(String.valueOf(sl.sked_GeoLocation__latitude__s)+String.valueOf(sl.sked_GeoLocation__longitude__s),sl.Id);
            }
            System.debug('geolocationVsStagingLocationMap: '+geolocationVsStagingLocationMap);

            for(sked__Location__c site : siteList){
                geolocationVsSiteMap.put(String.valueOf(site.sked__GeoLocation__latitude__s)+String.valueOf(site.sked__GeoLocation__longitude__s),site.Id);
            }
            System.debug('geolocationVsSiteMap: '+geolocationVsSiteMap);
        }
        if(!stagingLocationIds.isEmpty()){
            List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocationList = [SELECT Id,
                                                                                                    sked_Collection_Operation__c,
                                                                                                    sked_Staging_Location__c
                                                                                            FROM sked_Collection_Op_Staging_Location__c
                                                                                            WHERE sked_Staging_Location__c IN :stagingLocationIds WITH SYSTEM_MODE];
            System.debug('CO Staging Location Data: '+collectionOpStagingLocationList.size());
            for(sked_Collection_Op_Staging_Location__c cosl : collectionOpStagingLocationList){
                if(stagingLocationCOMap.isEmpty() || !stagingLocationCOMap.containsKey(cosl.sked_Staging_Location__c)){
                    stagingLocationCOMap.put(cosl.sked_Staging_Location__c, new Set<Id>());
                }
                stagingLocationCOMap.get(cosl.sked_Staging_Location__c).add(cosl.sked_Collection_Operation__c);
            }
        }
        if(!stagingLocationCOMap.isEmpty() && !geolocationVsStagingLocationMap.isEmpty() && !geolocationVsSiteMap.isEmpty()){
            for(sked_Travel_Time_Index_Item__c indexItem : indexItemList){
                String fromLocation = String.valueOf(indexItem.sked_From__latitude__s)+String.valueOf(indexItem.sked_From__longitude__s);
                String toLocation = String.valueOf(indexItem.sked_To__latitude__s)+String.valueOf(indexItem.sked_To__longitude__s);

                System.debug('geolocationVsSiteMap.containsKey(toLocation) : '+geolocationVsSiteMap.containsKey(toLocation));
                System.debug('geolocationVsSiteMap.containsKey(fromLocation) : '+geolocationVsSiteMap.containsKey(fromLocation));
                System.debug('geolocationVsStagingLocationMap.containsKey(toLocation) : '+geolocationVsStagingLocationMap.containsKey(toLocation));
                System.debug('geolocationVsStagingLocationMap.containsKey(fromLocation) : '+geolocationVsStagingLocationMap.containsKey(fromLocation));
                System.debug('stagingLocationCOMap : '+stagingLocationCOMap);
                
                if(geolocationVsSiteMap.containsKey(toLocation) && geolocationVsStagingLocationMap.containsKey(fromLocation) 
                        && stagingLocationCOMap.containsKey(geolocationVsStagingLocationMap.get(fromLocation))){
                            System.debug('Match Site to CO');
                            for(Id coId : stagingLocationCOMap.get(geolocationVsStagingLocationMap.get(fromLocation))){
                                siteCOPair.add(geolocationVsSiteMap.get(toLocation)+'-'+coId);
                            }
                            
                }
                if(geolocationVsSiteMap.containsKey(fromLocation) && geolocationVsStagingLocationMap.containsKey(toLocation)
                        && stagingLocationCOMap.containsKey(geolocationVsStagingLocationMap.get(toLocation))){
                            System.debug('Match CO to Site');
                            for(Id coId : stagingLocationCOMap.get(geolocationVsStagingLocationMap.get(toLocation))){
                                siteCOPair.add(geolocationVsSiteMap.get(fromLocation)+'-'+coId);
                            }
                }
            }
        }
        if(!siteCOPair.isEmpty()){
            System.debug('siteCOPair: '+siteCOPair);
            String siteCOQuerryPrefix = 'SELECT Id, User_Override__c, sked_Collection_Operation__c, sked_Site__c FROM sked_Site_Collection_Operation__c WHERE ';
            String siteCOQuerryWhereClause = '';
            for(String siteCOIdPair : siteCOPair){
                String whereClause = '( sked_Site__c = \''+siteCOIdPair.substringBefore('-')+'\' AND sked_Collection_Operation__c = \''+siteCOIdPair.substringAfter('-')+'\' )';
                
                if(String.isNotBlank(siteCOQuerryWhereClause)){
                    siteCOQuerryWhereClause = siteCOQuerryWhereClause +' OR '+ whereClause;
                }else{
                    siteCOQuerryWhereClause = siteCOQuerryWhereClause + whereClause;
                }
            }
            System.debug('Site CO SOQL : '+siteCOQuerryPrefix+siteCOQuerryWhereClause);
            siteCollectionOperationsList = Database.query(siteCOQuerryPrefix+siteCOQuerryWhereClause,AccessLevel.SYSTEM_MODE);
            System.debug('Site CO SOQL Data: '+siteCollectionOperationsList.size());
        }
        return siteCollectionOperationsList;
    }
}