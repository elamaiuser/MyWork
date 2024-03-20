public class skedInitialiseTravelTimeIndexBatch implements Database.Batchable<sked_Site_Collection_Operation__c>, Database.stateful {
    
    protected string lastId = '';
    
    public skedInitialiseTravelTimeIndexBatch() {
        this.lastId = '';
    }
    
    public skedInitialiseTravelTimeIndexBatch(string lastId) { 
        this.lastId = lastId;
    }

    public List<sked_Site_Collection_Operation__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked_Collection_Operation__c, sked_Site__r.sked__Geolocation__c,
                sked_Site__r.sked__GeoLocation__Latitude__s, sked_Site__r.sked__GeoLocation__Longitude__s, 
                sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c,
                sked_Travel_Distance_1__c, sked_Travel_Distance_2__c,
                sked_Site__r.sked_Timezone__c, LastModifiedDate
            FROM sked_Site_Collection_Operation__c
            WHERE sked_End_Date__c >= TODAY
            AND sked_Site__r.sked__Geolocation__Latitude__s != NULL
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 5000
        ];
    }

    public void execute(Database.BatchableContext BC, List<sked_Site_Collection_Operation__c> scos) {
        Set<Id> collectionOpIds = new Set<Id>();
        for (sked_Site_Collection_Operation__c sco : scos) {
            collectionOpIds.add(sco.sked_Collection_Operation__c);
        }

        Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOp = new Map<Id, Biomed_Collection_Op_Center__c>([
            SELECT Id, Name,
            (SELECT Id, sked_Staging_Location__r.sked_Timezone__c, sked_Staging_Location__r.sked_GeoLocation__c, 
             sked_Staging_Location__r.sked_GeoLocation__Latitude__s, 
             sked_Staging_Location__r.sked_GeoLocation__Longitude__s
             FROM sked_Collection_Op_Staging_Locations__r
             WHERE sked_Staging_Location__r.sked_GeoLocation__Latitude__s != NULL)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id IN :collectionOpIds
        ]);
        
        Map<String, sked_Travel_Time_Index_Item__c> ttiisToCreateByKey = new Map<String, sked_Travel_Time_Index_Item__c>();
        
        for (sked_Site_Collection_Operation__c sco : scos) {
            Biomed_Collection_Op_Center__c collectionOp = mapCollectionOp.get(sco.sked_Collection_Operation__c);
            if (collectionOp != NULL) {
                for (sked_Collection_Op_Staging_Location__c coStagingLoc : collectionOp.sked_Collection_Op_Staging_Locations__r) {
                    Location coLoc = coStagingLoc.sked_Staging_Location__r.sked_GeoLocation__c;
                    Location siteLoc = sco.sked_Site__r.sked__GeoLocation__c;
                    
                    string coToSiteKey = skedTravelTimeIndexItemUtils.getKey(coLoc, siteLoc);
                    string siteToCoKey = skedTravelTimeIndexItemUtils.getKey(siteLoc, coLoc);
                    
                    string timezoneSidId = coStagingLoc.sked_Staging_Location__r.sked_Timezone__c;
                    timezoneSidId = string.isBlank(timezoneSidId) ? UserInfo.getTimezone().getID() : timezoneSidId;
                    
                    if (!ttiisToCreateByKey.containsKey(coToSiteKey)) {
                        sked_Travel_Time_Index_Item__c newIndexItem = new sked_Travel_Time_Index_Item__c(
                            sked_Key__c = coToSiteKey,
                            sked_From__Latitude__s = coLoc.latitude,
                            sked_From__Longitude__s = coLoc.longitude,
                            sked_To__Latitude__s = siteLoc.latitude,
                            sked_To__Longitude__s = siteLoc.longitude,
                            sked_Travel_Time_Breakdown_JSON__c = sco.sked_Travel_Time_Breakdown_JSON__c,
                            sked_Travel_Distance__c = sco.sked_Travel_Distance_1__c,
                            sked_Timezone__c = timezoneSidId,
                            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_CO_TO_SITE + coLoc.latitude + ':' + coLoc.longitude
                        );
                        if (sco.sked_Travel_Time_Breakdown_JSON__c != NULL) {
                            newIndexItem.sked_Last_Refresh_Date__c = sco.LastModifiedDate;
                        }
                        
                        ttiisToCreateByKey.put(newIndexItem.sked_Key__c, newIndexItem);
                    }
                    
                    if (!ttiisToCreateByKey.containsKey(siteToCoKey)) {
                        sked_Travel_Time_Index_Item__c newIndexItem = new sked_Travel_Time_Index_Item__c(
                            sked_Key__c = siteToCoKey,
                            sked_From__Latitude__s = siteLoc.latitude,
                            sked_From__Longitude__s = siteLoc.longitude,
                            sked_To__Latitude__s = coLoc.latitude,
                            sked_To__Longitude__s = coLoc.longitude,
                            sked_Travel_Time_Breakdown_JSON__c = sco.sked_Travel_Time_Breakdown_JSON_2__c,
                            sked_Travel_Distance__c = sco.sked_Travel_Distance_2__c,
                            sked_Timezone__c = timezoneSidId,
                            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + coLoc.latitude + ':' + coLoc.longitude
                        );
                        if (sco.sked_Travel_Time_Breakdown_JSON_2__c != NULL) {
                            newIndexItem.sked_Last_Refresh_Date__c = sco.LastModifiedDate;
                        }
                        ttiisToCreateByKey.put(newIndexItem.sked_Key__c, newIndexItem);
                    }
                }
            }
        }

        if (!ttiisToCreateByKey.isEmpty()) {
            List<sked_Travel_Time_Index_Item__c> existingRecords = [SELECT Id, sked_Key__c
                                                                    FROM sked_Travel_Time_Index_Item__c
                                                                    WHERE sked_Key__c IN :ttiisToCreateByKey.keySet()];
            
            Set<string> existingKeys = new Set<string>();
            for (sked_Travel_Time_Index_Item__c existingRecord : existingRecords) {
                existingKeys.add(existingRecord.sked_Key__c);
            }
            
			List<sked_Travel_Time_Index_Item__c> recordsToInsert = new List<sked_Travel_Time_Index_Item__c>();
            
            for (sked_Travel_Time_Index_Item__c record : ttiisToCreateByKey.values()) {
                if (!existingKeys.contains(record.sked_Key__c)) {
                    recordsToInsert.add(record);
                }
            }
            
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
        }
        
        this.lastId = scos.get(scos.size() - 1).Id;
    }

    public void finish(Database.BatchableContext BC) {
        List<sked_Site_Collection_Operation__c> remainRecordQuery = [
            SELECT Id
            FROM sked_Site_Collection_Operation__c
            WHERE sked_End_Date__c >= TODAY
            AND sked_Site__r.sked__Geolocation__Latitude__s != NULL
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];
    
        if (!remainRecordQuery.isEmpty()) {
            if (!Test.isRunningTest()) {
                Database.executeBatch(new skedInitialiseTravelTimeIndexBatch(this.lastId), 200);
            }
        }
    }
    
}