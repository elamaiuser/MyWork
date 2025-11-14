public class skedTravelTimeIndexRefreshGroupHandler extends skedTriggerHub {
    public override void onBeforeInsert() {
        validate(this.context.newRecords);
        populateData(this.context.newRecords);
    }

    public override void onAfterInsert() {
        generateRefreshRequests(this.context.newRecords);
    }

    /*********************************************************** Privated Methods ***********************************************************/
    private void validate(List<sked_Travel_Time_Index_Refresh_Group__c> newRecords) {
        Set<String> coNames = new Set<String>();
        for (sked_Travel_Time_Index_Refresh_Group__c requestGroup : newRecords) {
            List<String> duplicatedProcessedCoNames = new List<String>();
            if (requestGroup.sked_Collection_Operations_To_Refresh__c != NULL) {
                List<String> requestGroupCoNames = requestGroup.sked_Collection_Operations_To_Refresh__c.split(';');
                for (String coName : requestGroupCoNames) {
                    if (coNames.contains(coName)) {
                        duplicatedProcessedCoNames.add(coName);
                    }
                }

                if (!duplicatedProcessedCoNames.isEmpty()) {
                    requestGroup.addError('The following collection operations are duplicated: ' + String.join(duplicatedProcessedCoNames, ', '));
                }

                coNames.addAll(requestGroupCoNames);
            }
        }

        skedQueryBuilder queryBuilder = new skedQueryBuilder();
        queryBuilder.setFromClause('sked_Travel_Time_Index_Refresh_Group__c');
        queryBuilder.addFields(new List<String>{
            'Id', 'sked_Collection_Operations_To_Refresh__c'
        });
        queryBuilder.addCondition(queryBuilder.generateMSPCondition('sked_Collection_Operations_To_Refresh__c INCLUDES {0}', new List<string>(coNames)));
        queryBuilder.addCondition('sked_Status__c != {0}', skedConstants.TRAVEL_TIME_INDEX_REFRESH_GROUP_STATUS_COMPLETED);

        List<sked_Travel_Time_Index_Refresh_Group__c> processingGroups = Database.query(queryBuilder.toString());

        for (sked_Travel_Time_Index_Refresh_Group__c requestGroup : newRecords) {
            List<String> coNamesToRefresh = requestGroup.sked_Collection_Operations_To_Refresh__c.split(';');
            Set<String> duplicatedRefreshCoNames = new Set<String>();
            for (sked_Travel_Time_Index_Refresh_Group__c processingGroup : processingGroups) {
                List<String> processingCoNames = processingGroup.sked_Collection_Operations_To_Refresh__c.split(';');
                for (String coNameToRefresh : coNamesToRefresh) {
                    if (processingCoNames.contains(coNameToRefresh)) {
                        duplicatedRefreshCoNames.add(coNameToRefresh);
                    }
                }
            }

            if (!duplicatedRefreshCoNames.isEmpty()) {
                requestGroup.addError('The following collection operations are already being processed: ' + String.join(new List<String>(duplicatedRefreshCoNames), ', '));
            }
        }
    }

    private void populateData(List<sked_Travel_Time_Index_Refresh_Group__c> newRecords) {
        for (sked_Travel_Time_Index_Refresh_Group__c newRequestGroup : newRecords) {
            newRequestGroup.sked_Status__c = skedConstants.TRAVEL_TIME_INDEX_REFRESH_GROUP_STATUS_GENERATING_REFRESH_REQUEST;
        }
    }

    private void generateRefreshRequests(List<sked_Travel_Time_Index_Refresh_Group__c> newRecords) {
        Map<String, Id> mapCoNameToGroupId = new Map<String, Id>();
        for (sked_Travel_Time_Index_Refresh_Group__c requestGroup : newRecords) {
            for (String coName : requestGroup.sked_Collection_Operations_To_Refresh__c.split(';')) {
                mapCoNameToGroupId.put(coName, requestGroup.Id);
            }
        }

        Map<Id, Set<String>> mapGroupIdToCoFromKeys = new Map<Id, Set<String>>();
        for (sked_Collection_Op_Staging_Location__c coStagingLocation : [
            SELECT Id, sked_Staging_Location__r.sked_GeoLocation__c, sked_Collection_Operation__r.Name
            FROM sked_Collection_Op_Staging_Location__c
            WHERE sked_Collection_Operation__r.Name IN :mapCoNameToGroupId.keySet()
            AND (sked_End_Date__c = NULL OR sked_End_Date__c > TODAY)
        ]) {
            Id refreshGroupId = mapCoNameToGroupId.get(coStagingLocation.sked_Collection_Operation__r.Name);
            if (!mapGroupIdToCoFromKeys.containsKey(refreshGroupId)) {
                mapGroupIdToCoFromKeys.put(refreshGroupId, new Set<String>());
            }
            mapGroupIdToCoFromKeys.get(refreshGroupId).add(skedTravelTimeIndexItemUtils.getKey(coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__c));
        }

        if (!mapGroupIdToCoFromKeys.isEmpty()) {
            Database.executeBatch(new skedCOGroupTravelTimeIndexRefreshBatch(mapGroupIdToCoFromKeys, skedSetting.instance.TravelTime.coGroupIndexRefreshPriority, 0), 200);
        }
    }
}