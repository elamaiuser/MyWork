public class skedNightlyRefreshTravelTimeIndexBatch extends skedRefreshTravelTimeIndexBatchBase {
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
        DateTime thresholdToRefresh = System.Now().addDays(-skedSetting.instance.TravelTime.refreshInterval);
        Integer maxTravelTimeIndexItemsForPeriodicRefresh = skedSetting.instance.TravelTime.maxTravelTimeIndexItemsForPeriodicRefresh;
        return Database.getQueryLocator([
            SELECT Id, sked_Timezone__c, sked_Ordering_Key__c, User_Override__c,
            sked_From__c, sked_To__c, sked_Travel_Time_Breakdown_JSON__c,
            sked_Travel_Time_Breakdown_JSON_Backup__c,
            (SELECT sked_Collection_Operation__c FROM Site_Collection_Operations__r WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY),
            (SELECT sked_Collection_Operation__c FROM sked_Site_Collection_Operations__r WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY)
            FROM sked_Travel_Time_Index_Item__c
            WHERE (sked_Last_Refresh_Date__c = NULL
                   OR sked_Last_Refresh_Date__c < :thresholdToRefresh)
            AND (sked_Last_Refresh_Request__c = NULL
                 OR sked_Last_Refresh_Request__r.sked_Status__c IN ('Completed', 'Error'))
            AND sked_Timezone__c != NULL
            AND sked_Ordering_Key__c LIKE 'COToSite%'
            ORDER BY sked_Ordering_Key__c ASC, Id ASC
            LIMIT :maxTravelTimeIndexItemsForPeriodicRefresh
        ]);
    }
}