public without sharing class SiteCollectionOperationTriggerHandler extends TriggerHandler{
    public override void afterInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('updateOverrideFlagOnSite') == -1) { 
        	updateOverrideFlagOnSite((List<sked_Site_Collection_Operation__c>)trigger.new, null);
        }
    }
    public override void beforeUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('updateOverrideFlagOnSite') == -1) {
        	updateOverrideFlagOnSiteCO((List<sked_Site_Collection_Operation__c>)trigger.new, (Map<Id,sked_Site_Collection_Operation__c>)trigger.oldMap);
        }
    }
    public override void afterUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('updateOverrideFlagOnSite') == -1) {
            updateOverrideFlagOnSite((List<sked_Site_Collection_Operation__c>)trigger.new, (Map<Id,sked_Site_Collection_Operation__c>)trigger.oldMap);
        }
    }
    public override void afterDelete(){
        if(super.getTriggerMethodsToBypass().indexOf('updateOverrideFlagOnSite') == -1) {
        	updateOverrideFlagOnSite((List<sked_Site_Collection_Operation__c>)trigger.old, null);
        }
    }
    public static void updateOverrideFlagOnSite(List<sked_Site_Collection_Operation__c> newList, Map<Id,sked_Site_Collection_Operation__c> oldMap){
        if(newList == null || newList.isEmpty() ){
            return;
        }
        Set<Id> siteIds = new Set<Id>();
        for(sked_Site_Collection_Operation__c siteCo : newList){
            if(oldMap == null && siteCo.sked_Site__c != null){
                siteIds.add(siteCo.sked_Site__c);
            }else if(oldMap != null && !oldMap.isEmpty() && oldMap.containsKey(siteCo.Id) && siteCo.sked_Site__c != null
                    && siteCo.User_Override__c != oldMap.get(siteCo.Id).User_Override__c){
                        siteIds.add(siteCo.sked_Site__c);
            }
        }
        List<sked__Location__c> sitesToUpdate = new List<sked__Location__c>();
        if(!siteIds.isEmpty()){
            List<sked__Location__c> siteList = [SELECT Id, 
                                                        User_Override__c,
                                                        (SELECT Id, 
                                                                User_Override__c 
                                                        FROM sked_Site_Collection_Operations__r
                                                        WHERE User_Override__c = true)
                                                FROM sked__Location__c 
                                                WHERE Id IN :siteIds WITH SYSTEM_MODE];
            System.debug('updateOverrideFlagOnSite siteList: '+siteList);
            for(sked__Location__c site : siteList){
                System.debug('updateOverrideFlagOnSite site.sked_Site_Collection_Operations__r: '+site.sked_Site_Collection_Operations__r);
                if((site.sked_Site_Collection_Operations__r == null || site.sked_Site_Collection_Operations__r.isEmpty()) && site.User_Override__c){
                    sitesToUpdate.add(new sked__Location__c(Id = site.Id, User_Override__c = false));
                }else if(site.sked_Site_Collection_Operations__r != null && !site.sked_Site_Collection_Operations__r.isEmpty() && !site.User_Override__c){
                    sitesToUpdate.add(new sked__Location__c(Id = site.Id, User_Override__c = true));
                }
            }
        }
        System.debug('updateOverrideFlagOnSite sitesToUpdate: '+sitesToUpdate.size());
        if(!sitesToUpdate.isEmpty()){
            update sitesToUpdate;
        }
    }
    public static void updateOverrideFlagOnSiteCO(List<sked_Site_Collection_Operation__c> siteCollectionOperationsList, Map<Id,sked_Site_Collection_Operation__c> oldMap){

        Set<Id> siteIds = new Set<Id>();
        Set<Id> coIds = new Set<Id>();
        Map<Id,sked__Location__c> siteMap = new Map<Id,sked__Location__c>();
        List<sked_Travel_Time_Index_Item__c> indexItemList = new List<sked_Travel_Time_Index_Item__c>();
        Map<Id,Set<Id>> coStagingLocationMap = new Map<Id,Set<Id>>();
        Map<Id,Location> stagingGeoLocationMap = new Map<Id,Location>();


        if(siteCollectionOperationsList == null || siteCollectionOperationsList.isEmpty() || oldMap == null || oldMap.isEmpty()){
            return;
        }

        for(sked_Site_Collection_Operation__c siteCO : siteCollectionOperationsList){
            if(oldMap.containsKey(siteCO.Id) && siteCO.User_Override__c != oldMap.get(siteCO.Id).User_Override__c
                    && siteCO.sked_Site__c != null && siteCO.sked_Collection_Operation__c != null){
                        siteIds.add(siteCO.sked_Site__c);
                        coIds.add(siteCO.sked_Collection_Operation__c);
            }
        }

        if(!siteIds.isEmpty()){
            siteMap = new Map<Id,sked__Location__c>([SELECT Id, 
                                                            sked__GeoLocation__latitude__s, 
                                                            sked__GeoLocation__longitude__s 
                                                    FROM sked__Location__c 
                                                    WHERE Id IN :siteIds
                                                    AND  sked__GeoLocation__latitude__s != null
                                                    AND sked__GeoLocation__longitude__s != null
                                                    WITH SYSTEM_MODE]);
        }

        if(!coIds.isEmpty()){
            List<sked_Collection_Op_Staging_Location__c> collectionOpStagingData = [SELECT Id,
                                                                                            sked_Collection_Operation__c,
                                                                                            sked_Staging_Location__c,
                                                                                            sked_Staging_Location__r.sked_GeoLocation__latitude__s,
                                                                                            sked_Staging_Location__r.sked_GeoLocation__longitude__s
                                                                                    FROM sked_Collection_Op_Staging_Location__c 
                                                                                    WHERE sked_Collection_Operation__c IN: coIds
                                                                                    AND sked_Start_Date__c != null 
                                                                                    AND sked_End_Date__c != null
                                                                                    AND sked_Staging_Location__c != null]; 
            for(sked_Collection_Op_Staging_Location__c data : collectionOpStagingData){
                if(stagingGeoLocationMap.isEmpty() || !stagingGeoLocationMap.containsKey(data.sked_Staging_Location__c)){
                    stagingGeoLocationMap.put(data.sked_Staging_Location__c,
                                            Location.newInstance(data.sked_Staging_Location__r.sked_GeoLocation__latitude__s,
                                                                    data.sked_Staging_Location__r.sked_GeoLocation__longitude__s));
                }
                if(coStagingLocationMap.isEmpty() || !coStagingLocationMap.containsKey(data.sked_Collection_Operation__c)){
                    coStagingLocationMap.put(data.sked_Collection_Operation__c, new Set<Id>());
                }
                coStagingLocationMap.get(data.sked_Collection_Operation__c).add(data.sked_Staging_Location__c);
            }
        }
        if(!stagingGeoLocationMap.isEmpty() && !coStagingLocationMap.isEmpty()){
            String indexItemQuerry = 'SELECT Id, sked_From__latitude__s, sked_From__longitude__s, sked_To__latitude__s, '
                                        +'sked_To__longitude__s, User_Override__c FROM sked_Travel_Time_Index_Item__c WHERE ';
            String indexItemWhereCl = '';
            for(sked_Site_Collection_Operation__c siteCO : siteCollectionOperationsList){
                if(siteCO.sked_Site__c == null || siteCO.sked_Site__c == null || !siteMap.containsKey(siteCO.sked_Site__c) 
                        || !coStagingLocationMap.containsKey(siteCO.sked_Collection_Operation__c)){
                            continue;
                }
                sked__Location__c site = siteMap.get(siteCO.sked_Site__c);
                Set<Id> slIds = coStagingLocationMap.get(siteCO.sked_Collection_Operation__c);
                String indexItemWhereCl_COtoSite = ' sked_To__latitude__s = '+site.sked__GeoLocation__latitude__s
                                                    +' AND sked_To__longitude__s = '+site.sked__GeoLocation__longitude__s;
                String indexItemWhereCl_SitetoCO = ' sked_From__latitude__s = '+site.sked__GeoLocation__latitude__s
                                                    +' AND sked_From__longitude__s = '+site.sked__GeoLocation__longitude__s;
                String indexItemWhereCl_COtoSite_StagingL = ' AND (';
                String indexItemWhereCl_SitetoCO_StagingL = ' AND (';
                for(Id slId : slIds){
                    Location loc = stagingGeoLocationMap.get(slId);
                    String indexStr_COtoSite = '( sked_From__latitude__s = '+loc.getLatitude();
                    indexStr_COtoSite = indexStr_COtoSite + ' AND sked_From__longitude__s = '+loc.getLongitude();
                    indexStr_COtoSite = indexStr_COtoSite + ' )';

                    String indexStr_SitetoCO = '( sked_To__latitude__s = '+loc.getLatitude();
                    indexStr_SitetoCO = indexStr_SitetoCO + ' AND sked_To__longitude__s = '+loc.getLongitude();
                    indexStr_SitetoCO = indexStr_SitetoCO + ' )';

                    if(indexItemWhereCl_COtoSite_StagingL.length() == 6){
                        indexItemWhereCl_COtoSite_StagingL = indexItemWhereCl_COtoSite_StagingL + indexStr_COtoSite;
                    }else{
                        indexItemWhereCl_COtoSite_StagingL = indexItemWhereCl_COtoSite_StagingL + ' OR ' + indexStr_COtoSite;
                    }

                    if(indexItemWhereCl_SitetoCO_StagingL.length() == 6){
                        indexItemWhereCl_SitetoCO_StagingL = indexItemWhereCl_SitetoCO_StagingL + indexStr_SitetoCO;
                    }else{
                        indexItemWhereCl_SitetoCO_StagingL = indexItemWhereCl_SitetoCO_StagingL + ' OR ' + indexStr_SitetoCO;
                    }
                }
                indexItemWhereCl_COtoSite_StagingL = indexItemWhereCl_COtoSite_StagingL + ' )';
                indexItemWhereCl_SitetoCO_StagingL = indexItemWhereCl_SitetoCO_StagingL + ' )';

                String indexItemQuerryWl = '('+indexItemWhereCl_COtoSite + indexItemWhereCl_COtoSite_StagingL+' ) OR ('
                                            +indexItemWhereCl_SitetoCO + indexItemWhereCl_SitetoCO_StagingL+' )';
                if(String.isNotBlank(indexItemWhereCl)){
                    indexItemWhereCl = indexItemWhereCl +' OR '+indexItemQuerryWl;
                }else{
                    indexItemWhereCl = indexItemQuerryWl;
                }
            } 
            System.debug('Index Item SOQL : '+indexItemQuerry+indexItemWhereCl);  
            indexItemList = Database.query(indexItemQuerry+indexItemWhereCl,AccessLevel.SYSTEM_MODE);      
            System.debug('Index Item SOQL Data: '+indexItemList.size());             
        }
        
        if(!indexItemList.isEmpty()){
            Map<String,Boolean> indexItemOverrideMap = new Map<String,Boolean>();
            for(sked_Travel_Time_Index_Item__c ttData : indexItemList){
                String key = String.valueOf(ttData.sked_From__latitude__s)
                            +String.valueOf(ttData.sked_From__longitude__s)
                            +String.valueOf(ttData.sked_To__latitude__s)
                            +String.valueOf(ttData.sked_To__longitude__s);
                indexItemOverrideMap.put(key,ttData.User_Override__c);
            }
            for(sked_Site_Collection_Operation__c siteCO : siteCollectionOperationsList){
                if(siteCO.sked_Site__c == null || siteCO.sked_Site__c == null || !siteMap.containsKey(siteCO.sked_Site__c) 
                        || !coStagingLocationMap.containsKey(siteCO.sked_Collection_Operation__c)){
                            continue;
                }
                Boolean updateFlag = false;
                String siteKeystr = String.valueOf(siteMap.get(siteCO.sked_Site__c).sked__GeoLocation__latitude__s) 
                                    + String.valueOf(siteMap.get(siteCO.sked_Site__c).sked__GeoLocation__longitude__s);
                Set<String> keySet = new Set<String>();
                for(Id slId : coStagingLocationMap.get(siteCO.sked_Collection_Operation__c)){
                    String locKeystr = String.valueOf(stagingGeoLocationMap.get(slId).getLatitude()) 
                                    + String.valueOf(stagingGeoLocationMap.get(slId).getLongitude());
                    keySet.add(siteKeystr+locKeystr);
                    keySet.add(locKeystr+siteKeystr);
                }
                for(String key : keySet){
                    if(indexItemOverrideMap.containsKey(key) && indexItemOverrideMap.get(key)){
                        updateFlag = true;
                    }
                }
                siteCO.User_Override__c = updateFlag;
            }
        }
    }
}