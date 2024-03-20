public class skedRefreshTravelTimeIndexBatch implements System.Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts, Database.stateful {
    
    protected boolean refreshTravelDistance;
    protected boolean refreshTravelTime;
    
    public skedRefreshTravelTimeIndexBatch() {
        this.refreshTravelDistance = true;
        this.refreshTravelTime = true;
    }

    public skedRefreshTravelTimeIndexBatch(boolean refreshTravelTime, boolean refreshTravelDistance) {
        this.refreshTravelDistance = refreshTravelDistance;
        this.refreshTravelTime = refreshTravelTime;
    }
    
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new skedRefreshTravelTimeIndexBatch(true, true), 200);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime thresholdToRefresh = System.Now().addDays(-skedSetting.instance.TravelTime.refreshInterval);
        
        return Database.getQueryLocator([
            SELECT Id, sked_Timezone__c, sked_Ordering_Key__c,
            sked_From__c, sked_To__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE (sked_Last_Refresh_Date__c = NULL
                   OR sked_Last_Refresh_Date__c < :thresholdToRefresh)
            AND (sked_Last_Refresh_Request__c = NULL 
                 OR sked_Last_Refresh_Request__r.sked_Status__c = 'Completed')
            AND sked_Timezone__c != NULL
            ORDER BY sked_Ordering_Key__c ASC, Id ASC
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<sked_Travel_Time_Index_Item__c> ttiis = (List<sked_Travel_Time_Index_Item__c>) scope;
        
        Map<String, List<sked_Travel_Time_Index_Item__c>> mapTtiiByOrderingKey = new Map<String, List<sked_Travel_Time_Index_Item__c>>();

        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            List<sked_Travel_Time_Index_Item__c> ttiisByOrderingKey = mapTtiiByOrderingKey.get(ttii.sked_Ordering_Key__c);
            if (ttiisByOrderingKey == NULL) {
                ttiisByOrderingKey = new List<sked_Travel_Time_Index_Item__c>();
                mapTtiiByOrderingKey.put(ttii.sked_Ordering_Key__c, ttiisByOrderingKey);
            }
            ttiisByOrderingKey.add(ttii);
        }

        List<sked_Travel_Time_Index_Refresh_Request__c> requestsToCreate = new List<sked_Travel_Time_Index_Refresh_Request__c>();
        if (refreshTravelDistance) {
            requestsToCreate.addAll(generateRequests(mapTtiiByOrderingKey, 40, 'Travel Distance'));
        }

        if (refreshTravelTime) {
            requestsToCreate.addAll(generateRequests(mapTtiiByOrderingKey, 40, 'Travel Time'));
        }

        if (!requestsToCreate.isEmpty()) {
            insert requestsToCreate;
        }
    }

    public List<sked_Travel_Time_Index_Refresh_Request__c> generateRequests(Map<String, List<sked_Travel_Time_Index_Item__c>> mapTtiiByOrderingKey, integer requestOriginSize, string requestType) {
        List<sked_Travel_Time_Index_Refresh_Request__c> requests = new List<sked_Travel_Time_Index_Refresh_Request__c>();
        
        for (List<sked_Travel_Time_Index_Item__c> indexItems : mapTtiiByOrderingKey.values()) {
            Set<Id> indexItemIds = new Set<Id>();
            Set<string> origins = new Set<string>();
            Set<string> destinations = new Set<string>();
            for (Integer i = 0; i < indexItems.size(); i++) {
                sked_Travel_Time_Index_Item__c indexItem = indexItems.get(i);
                indexItemIds.add(indexItem.Id);
                
                string origin = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_From__c);
                origins.add(origin);
                
                string destination = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_To__c);
                destinations.add(destination);
                
                if (indexItemIds.size() == requestOriginSize || i == indexItems.size() - 1) {
                    sked_Travel_Time_Index_Refresh_Request__c request = new sked_Travel_Time_Index_Refresh_Request__c(
                        sked_Record_Ids__c = string.join(indexItemIds, ';'),
                        sked_Origins__c = string.join(origins, ';'),
                        sked_Destinations__c = string.join(destinations, ';'),
                        sked_Request_Type__c = requestType,
                        sked_Status__c = 'Pending'
                    );
                    requests.add(request);
                    
                    indexItemIds = new Set<Id>();
                    origins = new Set<string>();
                    destinations = new Set<string>();
                }
            }
        }
        return requests;
    }

    public void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            Database.executeBatch(new skedTravelTimeIndexTravelDistanceBatch(), 1);
            skedAsyncJobHandler.processTravelTimeRefreshRequest();
        }
    }

}