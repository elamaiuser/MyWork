public class skedTravelTimeIndexItemHandler extends skedTriggerHub implements callable {
    
    public override void onBeforeInsert() {
        setKey(this.context.newRecords);
    }

    public override void onBeforeUpdate() {
        updateTravelTimeBreakdownJSONData(this.context.newRecords, (Map<Id, sked_Travel_Time_Index_Item__c>)this.context.oldMap);    
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureTravelTimeImpact(this.context.newRecords, (Map<Id, sked_Travel_Time_Index_Item__c>)this.context.oldMap);
        }
    }

    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            refreshTravelTimeIndexData(this.context.newMap.keySet());
        }

        skedFutureCallPostCommitEventHandler.publishFutureCallEvent(
            skedTravelTimeIndexItemHandler.class.getName(),
            'populateTTILokkupFieldsOnSiteCO',
            skedSObjectUtils.getRecordIds(this.context.newRecords)   
        );

    }

    /******************************************** Callable Interface ********************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'populateTTILokkupFieldsOnSiteCO' {
                    populateTTILokkupFieldsOnSiteCO((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));

                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedTravelTimeIndexItemHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void setKey(List<sked_Travel_Time_Index_Item__c> newRecords) {
        for (sked_Travel_Time_Index_Item__c ttii : newRecords) {
            if (ttii.sked_Key__c == NULL) {
                Location fromLoc = Location.newInstance(ttii.sked_From__Latitude__s, ttii.sked_From__Longitude__s);
                Location toLoc = Location.newInstance(ttii.sked_To__Latitude__s, ttii.sked_To__Longitude__s);
                
                ttii.sked_Key__c = skedTravelTimeIndexItemUtils.getKey(fromLoc, toLoc);
            }
        }
    }

    private void updateTravelTimeBreakdownJSONData(List<sked_Travel_Time_Index_Item__c> newRecords, Map<Id, sked_Travel_Time_Index_Item__c> oldMap) {        
        String todayStr = Date.today().format();
        String systemOverrideComment = skedConstants.SYSTEM_TTBD_OVERRIDE_COMMENT.replace('{0}',todayStr);
        for (sked_Travel_Time_Index_Item__c newRecord : newRecords) {
            sked_Travel_Time_Index_Item__c oldData = oldMap.get(newRecord.Id);            
            if (newRecord.sked_Travel_Time_Breakdown_JSON__c != oldData.sked_Travel_Time_Breakdown_JSON__c
            && newRecord.sked_Travel_Time_Breakdown_JSON__c != NULL && String.isNotBlank(newRecord.sked_Travel_Time_Breakdown_JSON__c)
            && newRecord.sked_Travel_Time_Breakdown_JSON__c == skedConstants.NO_TRAVEL_TIME_DATA
            && newRecord.sked_Travel_Time_Breakdown_JSON_Backup__c != NULL && String.isNotBlank(newRecord.sked_Travel_Time_Breakdown_JSON_Backup__c)) {
                newRecord.sked_Travel_Time_Breakdown_JSON__c = newRecord.sked_Travel_Time_Breakdown_JSON_Backup__c;
                newRecord.User_Override__c = true;
                newRecord.Override_Comment__c = systemOverrideComment;
            }
        }
    }
    
    private void captureTravelTimeImpact(List<sked_Travel_Time_Index_Item__c> newRecords, Map<Id, sked_Travel_Time_Index_Item__c> oldMap) {
        Set<Id> impactedIndexIds = new Set<Id>();
        for (sked_Travel_Time_Index_Item__c newRecord : newRecords) {
            sked_Travel_Time_Index_Item__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.User_Override__c == false
                && newRecord.sked_Average_Travel_Time__c != oldData.sked_Average_Travel_Time__c
               	&& newRecord.sked_Average_Travel_Time__c!= NULL) {
                    if(oldData.sked_Average_Travel_Time__c == NULL) {
                        impactedIndexIds.add(newRecord.Id);
                    }else {
                        decimal beforeAfterGap = Math.abs(oldData.sked_Average_Travel_Time__c - newRecord.sked_Average_Travel_Time__c);
                        if (beforeAfterGap >= skedSetting.instance.TravelTime.driveImpactThreshold) {
                            impactedIndexIds.add(newRecord.Id);
                        }
                    }
                }
            }
        if (!impactedIndexIds.isEmpty()) {
            if (!System.isBatch() && !Test.isRunningTest()) {
                Database.executeBatch(new skedCreateDCRForTravelTimeChangeBatch(impactedIndexIds, new Set<Id>()), 200);
            }
        }
    }
    
    private void refreshTravelTimeIndexData(Set<Id> indexIds) {
        if (!System.isBatch() && !Test.isRunningTest()) {
            Database.executeBatch(new skedImmediateRefreshTravelTimeIndexBatch(new List<Id>(indexIds), skedSetting.instance.TravelTime.newIndexPriority), 200);
        }
    }

    public static void populateTTILokkupFieldsOnSiteCO(Set<Id> newTravelTimeIndexItemIds) {
        try {
            List<sked_Travel_Time_Index_Item__c> newItems = [
                SELECT Id, sked_Timezone__c, sked_Ordering_Key__c,
                sked_From__Latitude__s, sked_From__Longitude__s,
                sked_To__Latitude__s, sked_To__Longitude__s,
                sked_From__c, sked_To__c, sked_Key__c
                FROM sked_Travel_Time_Index_Item__c
                WHERE ID IN :newTravelTimeIndexItemIds
            ];
            Set<Double> siteLatitudes = new Set<Double>();
            Set<Double> siteLongitudes = new Set<Double>();
            Set<Double> coslLatitudes = new Set<Double>();
            Set<Double> coslLongitudes = new Set<Double>();

            for (sked_Travel_Time_Index_Item__c tti : newItems) {
                siteLatitudes.add(
                    tti.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_SITE_TO_CO) 
                    ? tti.sked_From__Latitude__s
                    : tti.sked_To__Latitude__s
                );

                siteLongitudes.add(
                    tti.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_SITE_TO_CO) 
                    ? tti.sked_From__Longitude__s
                    : tti.sked_To__Longitude__s
                );
                coslLatitudes.add(
                    tti.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_CO_TO_SITE) 
                    ? tti.sked_From__Latitude__s
                    : tti.sked_To__Latitude__s
                );

                coslLongitudes.add(
                    tti.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_CO_TO_SITE) 
                    ? tti.sked_From__Longitude__s
                    : tti.sked_To__Longitude__s
                );
            }

            List<sked_Site_Collection_Operation__c> siteCoList = 
            [
                SELECT Id, sked_Collection_Operation__c, sked_Site__r.sked__GeoLocation__c,
                sked_Travel_Time_Index_CO2Site__c, sked_Travel_Time_Index_Site2CO__c
                FROM sked_Site_Collection_Operation__c
                WHERE sked_Site__r.sked_Active__c = TRUE
                AND sked_Site__r.sked__GeoLocation__latitude__s IN :siteLatitudes
                AND sked_Site__r.sked__GeoLocation__longitude__s IN :siteLongitudes
                AND sked_End_Date__c >= TODAY
            ];

            Map<Id, List<String>> map_siteCOId_siteCOAndCoslKey = new Map<Id, List<String>>();

            if(siteCoList != NULL && !siteCoList.isEmpty()) {
                Set<Id> collectionOperationIds = new Set<Id>();
                for(sked_Site_Collection_Operation__c siteCo : siteCoList) {
                    collectionOperationIds.add(siteCo.sked_Collection_Operation__c);
                }

                List<sked_Collection_Op_Staging_Location__c> coslList = 
                [
                    SELECT Id, sked_Collection_Operation__c,
                    sked_Staging_Location__r.sked_GeoLocation__c 
                    FROM sked_Collection_Op_Staging_Location__c 
                    WHERE sked_Staging_Location__r.sked_GeoLocation__latitude__s IN :coslLatitudes
                    AND sked_Staging_Location__r.sked_GeoLocation__longitude__s IN :coslLongitudes
                    AND sked_Collection_Operation__c IN :collectionOperationIds
                ];

                for(sked_Site_Collection_Operation__c siteCo : siteCoList) {
                    for(sked_Collection_Op_Staging_Location__c cosl : coslList) {
                        if(siteCo.sked_Collection_Operation__c == cosl.sked_Collection_Operation__c) {
                            if(!map_siteCOId_siteCOAndCoslKey.containsKey(siteCo.Id)) {
                                map_siteCOId_siteCOAndCoslKey.put(siteCo.Id, new List<String>());
                            }
                            List<String> siteCoAndCoslKeys = map_siteCOId_siteCOAndCoslKey.get(siteCo.Id);
                            siteCoAndCoslKeys.add(skedTravelTimeIndexItemUtils.getKey(siteCo.sked_Site__r.sked__GeoLocation__c, cosl.sked_Staging_Location__r.sked_GeoLocation__c));
                            siteCoAndCoslKeys.add(skedTravelTimeIndexItemUtils.getKey(cosl.sked_Staging_Location__r.sked_GeoLocation__c, siteCo.sked_Site__r.sked__GeoLocation__c));
                        }
                    }
                }
            }

            Map<Id, sked_Site_Collection_Operation__c> map_siteCOId_siteCORecord = new Map<Id, sked_Site_Collection_Operation__c>();
            for(sked_Travel_Time_Index_Item__c tti : newItems) {
                for (sked_Site_Collection_Operation__c siteCo : siteCoList) {
                    List<String> siteCOAndCoslKey = new List<String>(map_siteCOId_siteCOAndCoslKey.get(siteCo.Id));
                    if(siteCOAndCoslKey.contains(tti.sked_Key__c)) {
                        if(map_siteCOId_siteCORecord.containsKey(siteCo.Id)) {
                             siteCo = map_siteCOId_siteCORecord.get(siteCo.Id);
                        }
                        if (tti.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_SITE_TO_CO)) {
                            siteCo.sked_Travel_Time_Index_Site2CO__c = tti.Id;
                        } else {
                            siteCo.sked_Travel_Time_Index_CO2Site__c = tti.Id;
                        }  
                    }
                    if(!map_siteCOId_siteCORecord.containsKey(siteCo.Id)) {
                        map_siteCOId_siteCORecord.put(siteCo.Id, siteCo);
                    }
                }
            }

            if(!map_siteCOId_siteCORecord.values().isEmpty()) {
                Database.SaveResult[] updateResult = Database.Update(map_siteCOId_siteCORecord.values(), false);
                List<BSF_Error_Log__c> errorLogsToInsert = BSF_Utilities.createErrorLogWithObjectId(
                    updateResult,
                    'TTI Lookup update on Site CO',
                    'skedTravelTimeIndexItemHandler',
                    'populateTTILokkupFieldsOnSiteCO',
                    'Error',
                    'Update Site CO'
                );
                insert errorLogsToInsert;
            }
        }catch(Exception ex) {
            system.debug('ex '+ex);
            BSF_Error_Log__c errorLogToInsert = BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'skedTravelTimeIndexItemHandler',
                'populateTTILokkupFieldsOnSiteCO',
                'TTI Lookup update on Site CO',
                'Update Site CO',
                '',
                ''
            );
            insert errorLogToInsert;
        }
    }
}