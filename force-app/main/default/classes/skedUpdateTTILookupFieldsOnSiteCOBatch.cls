global class skedUpdateTTILookupFieldsOnSiteCOBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    global String query;
    global Boolean isRunningForSiteCO = false;

    global skedUpdateTTILookupFieldsOnSiteCOBatch(Boolean isRunningForSiteCO) {
        if(isRunningForSiteCO) {
            this.isRunningForSiteCO = true;
            this.query = 'SELECT Id, sked_Collection_Operation__c, sked_Site__r.sked__GeoLocation__c, '+
                         'sked_Travel_Time_Index_CO2Site__c, sked_Travel_Time_Index_Site2CO__c '+
                         'FROM sked_Site_Collection_Operation__c '+
                         'WHERE sked_Site__r.sked_Active__c = TRUE '+
                         'AND sked_Site__r.sked__GeoLocation__Latitude__s != NULL '+
                         'AND sked_End_Date__c >= TODAY '+
                         'AND (sked_Travel_Time_Index_CO2Site__c = NULL OR sked_Travel_Time_Index_Site2CO__c = NULL) '+
                         'AND sked_Collection_Operation__c IN (SELECT sked_Collection_Operation__c FROM sked_Collection_Op_Staging_Location__c)';
        } else {
            this.query = 'SELECT Id, sked_Timezone__c, sked_Ordering_Key__c, '+
                         'sked_From__Latitude__s, sked_From__Longitude__s, '+
                         'sked_To__Latitude__s, sked_To__Longitude__s, '+
                         'sked_From__c, sked_To__c, sked_Key__c '+
                         'FROM sked_Travel_Time_Index_Item__c '+
                         'WHERE CreatedDate >= YESTERDAY';
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new skedUpdateTTILookupFieldsOnSiteCOBatch(false), 200);
    }

    global Database.queryLocator start(Database.BatchableContext BC) {
        return Database.getqueryLocator(this.query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> listToBeProcessed) {
        if(!this.isRunningForSiteCO) {
            skedTravelTimeIndexItemHandler.populateTTILokkupFieldsOnSiteCO(skedSObjectUtils.getRecordIds(listToBeProcessed));
        } else {
            List<sked_Site_Collection_Operation__c> siteCOToBeUpdatedList = (List<sked_Site_Collection_Operation__c>)listToBeProcessed;
            Set<Id> collectionOperationIds = new Set<Id>();
            Map<Id, List<String>> map_siteCOId_siteCOAndCoslKey = new Map<Id, List<String>>();
            List<String> ttiKeys = new List<String>();

            for(sked_Site_Collection_Operation__c siteCO : siteCOToBeUpdatedList) {
                collectionOperationIds.add(siteCO.sked_Collection_Operation__c);
            }

            List<sked_Collection_Op_Staging_Location__c> coslList = 
                [
                    SELECT Id, sked_Collection_Operation__c, sked_Staging_Location__r.sked_GeoLocation__c,
                    sked_Staging_Location__r.sked_GeoLocation__latitude__s,
                    sked_Staging_Location__r.sked_GeoLocation__longitude__s 
                    FROM sked_Collection_Op_Staging_Location__c 
                    WHERE sked_Collection_Operation__c IN :collectionOperationIds
                    AND sked_Staging_Location__r.sked_GeoLocation__latitude__s != NULL
                ];
            if(coslList != NULL && !coslList.isEmpty()) {
                for(sked_Site_Collection_Operation__c siteCO : siteCOToBeUpdatedList) {
                    for(sked_Collection_Op_Staging_Location__c cosl : coslList) {
                        if(cosl.sked_Collection_Operation__c == siteCO.sked_Collection_Operation__c) {
                            if(!map_siteCOId_siteCOAndCoslKey.containsKey(siteCo.Id)) {
                                map_siteCOId_siteCOAndCoslKey.put(siteCo.Id, new List<String>());
                            }
                            List<String> siteCoAndCoslKeys = map_siteCOId_siteCOAndCoslKey.get(siteCo.Id);
                            siteCoAndCoslKeys.add(skedTravelTimeIndexItemUtils.getKey(siteCo.sked_Site__r.sked__GeoLocation__c, cosl.sked_Staging_Location__r.sked_GeoLocation__c));
                            siteCoAndCoslKeys.add(skedTravelTimeIndexItemUtils.getKey(cosl.sked_Staging_Location__r.sked_GeoLocation__c, siteCo.sked_Site__r.sked__GeoLocation__c));
                            ttiKeys.addAll(siteCoAndCoslKeys);
                        }
                    }
                }
            }

            List<sked_Travel_Time_Index_Item__c> travelTimeIndexItems = [
                SELECT Id, sked_Timezone__c, sked_Ordering_Key__c,
                sked_From__Latitude__s, sked_From__Longitude__s,
                sked_To__Latitude__s, sked_To__Longitude__s,
                sked_From__c, sked_To__c, sked_Key__c
                FROM sked_Travel_Time_Index_Item__c
                WHERE sked_Key__c IN :ttiKeys
            ];

            Map<String, sked_Travel_Time_Index_Item__c> map_ttiKey_ttiRecord = new Map<String, sked_Travel_Time_Index_Item__c>();
            for(sked_Travel_Time_Index_Item__c tti : travelTimeIndexItems) {
                map_ttiKey_ttiRecord.put(tti.sked_Key__c, tti);
            }

            for(sked_Site_Collection_Operation__c siteCO : siteCOToBeUpdatedList) {
                List<String> siteCOAndCoslKeys = new List<String>(map_siteCOId_siteCOAndCoslKey.get(siteCO.Id));
                for(String siteCOAndCoslKey : siteCOAndCoslKeys) {
                    if(map_ttiKey_ttiRecord.containsKey(siteCOAndCoslKey)) {
                        sked_Travel_Time_Index_Item__c tti = map_ttiKey_ttiRecord.get(siteCOAndCoslKey);
                        if(tti.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_SITE_TO_CO)) {
                            siteCO.sked_Travel_Time_Index_Site2CO__c = tti.Id;
                        } else {
                            siteCO.sked_Travel_Time_Index_CO2Site__c = tti.Id;
                        }
                    }
                }
            }

            Database.SaveResult[] updateResult = Database.Update(siteCOToBeUpdatedList, false);
            List<BSF_Error_Log__c> errorLogsToInsert = BSF_Utilities.createErrorLogWithObjectId(
                updateResult,
                'TTI Lookup update on Site CO',
                'skedUpdateTTILookupFieldsOnSiteCOBatch',
                'execute',
                'Error',
                'Update Site CO'
            );
            insert errorLogsToInsert;
        }
    }

    global void finish(Database.BatchableContext BC) {}

}