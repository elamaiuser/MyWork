public class skedNightlyRefreshTravelTimeIndexBatch extends skedRefreshTravelTimeIndexBatchBase {
    private Set<Id> processedCollectionOperationIds = new Set<Id>();
    private Set<String> coOrderingKeys = new Set<String>();

    public skedNightlyRefreshTravelTimeIndexBatch(boolean refreshTravelTime) {
        super(null, refreshTravelTime);
    }

    public skedNightlyRefreshTravelTimeIndexBatch() {
        super();
    }

    protected override void executeSchedule() {
        Database.executeBatch(new skedNightlyRefreshTravelTimeIndexBatch(), 200);
    }

    protected override Database.QueryLocator getQueryLocator() {
        Integer maxTravelTimeIndexItemsForPeriodicRefresh = skedSetting.instance.TravelTime.maxTravelTimeIndexItemsForPeriodicRefresh;

        List<Biomed_Collection_Op_Center__c> cosDueForRefresh = [
            SELECT Id,
            (SELECT sked_Staging_Location__r.sked_GeoLocation__Latitude__s,
                    sked_Staging_Location__r.sked_GeoLocation__Longitude__s
             FROM sked_Collection_Op_Staging_Locations__r
             WHERE sked_End_Date__c >= TODAY
             AND sked_Staging_Location__r.sked_GeoLocation__Latitude__s != NULL)
            FROM Biomed_Collection_Op_Center__c
            WHERE sked_Next_Travel_Time_Refresh_Date__c <= TODAY
            OR sked_Next_Travel_Time_Refresh_Date__c = NULL
        ];

        for (Biomed_Collection_Op_Center__c co : cosDueForRefresh) {
            processedCollectionOperationIds.add(co.Id);
            for (sked_Collection_Op_Staging_Location__c cosl : co.sked_Collection_Op_Staging_Locations__r) {
                Location coLoc = Location.newInstance(
                    cosl.sked_Staging_Location__r.sked_GeoLocation__Latitude__s,
                    cosl.sked_Staging_Location__r.sked_GeoLocation__Longitude__s
                );
                coOrderingKeys.add(skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_CO_TO_SITE, coLoc));
            }
        }

        return Database.getQueryLocator([
            SELECT Id, sked_Timezone__c, sked_Ordering_Key__c, User_Override__c, sked_From__c, sked_Last_Refresh_Date__c,
            sked_To__c, sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_Backup__c,
            sked_Collection_Operation__c, sked_Collection_Operation__r.sked_Next_Travel_Time_Refresh_Date__c,
            (SELECT sked_Collection_Operation__c FROM Site_Collection_Operations__r WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY),
            (SELECT sked_Collection_Operation__c FROM sked_Site_Collection_Operations__r WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY)
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Is_Sync_Refresh_Required__c = TRUE
            AND (sked_Last_Refresh_Request__c = NULL
                 OR sked_Last_Refresh_Request__r.sked_Status__c IN ('Completed', 'Error'))
            AND sked_Timezone__c != NULL
            AND sked_Ordering_Key__c IN :coOrderingKeys
            ORDER BY sked_Collection_Operation__r.sked_Next_Travel_Time_Refresh_Date__c ASC NULLS LAST, sked_Ordering_Key__c ASC, Id ASC
            LIMIT :maxTravelTimeIndexItemsForPeriodicRefresh
        ]);
    }

    protected override void postProcess() {
        if (!processedCollectionOperationIds.isEmpty()) {
            Map<Id, Integer> pendingCountPerCO = new Map<Id, Integer>();
            for (Id coId : processedCollectionOperationIds) {
                pendingCountPerCO.put(coId, 0);
            }

            for (AggregateResult ar : [
                SELECT sked_Collection_Operation__c coId, COUNT(Id) cnt
                FROM sked_Travel_Time_Index_Item__c
                WHERE sked_Is_Sync_Refresh_Required__c = TRUE
                AND (sked_Last_Refresh_Request__c = NULL
                    OR sked_Last_Refresh_Request__r.sked_Status__c IN ('Completed', 'Error'))
                AND sked_Timezone__c != NULL
                AND sked_Ordering_Key__c IN :coOrderingKeys
                GROUP BY sked_Collection_Operation__c
            ]) {
                Id coId = (Id) ar.get('coId');
                Integer cnt = (Integer) ar.get('cnt');
                pendingCountPerCO.put(coId, cnt);
            }

            Date nextRefreshDate = Date.today().addDays(skedSetting.instance.TravelTime.refreshInterval);
            List<Biomed_Collection_Op_Center__c> cosToUpdate = new List<Biomed_Collection_Op_Center__c>();
            for (Id coId : processedCollectionOperationIds) {
                if (pendingCountPerCO.get(coId) == 0) {
                    cosToUpdate.add(new Biomed_Collection_Op_Center__c(
                        Id = coId,
                        sked_Next_Travel_Time_Refresh_Date__c = nextRefreshDate
                    ));
                }
            }

            if (!cosToUpdate.isEmpty()) {
                update cosToUpdate;
            }
        }
    }
}