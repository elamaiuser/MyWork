public virtual class skedRefreshTravelTimeIndexBatchBase implements System.Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts, Database.stateful {
    protected Integer refreshRequestPriority;
    private Boolean refreshTravelTime;
    private Map<String, sked_Travel_Time_Index_Item__c> map_key_reversedDirectionTravelTimeIndexItem;

    public skedRefreshTravelTimeIndexBatchBase(Integer refreshRequestPriority, Boolean refreshTravelTime) {
        this.refreshRequestPriority = refreshRequestPriority;
        this.refreshTravelTime = refreshTravelTime;
    }

    public skedRefreshTravelTimeIndexBatchBase() {
        this.refreshTravelTime = true;
        this.refreshRequestPriority = null;
    }
    
    public void execute(SchedulableContext SC) {
        this.executeSchedule();
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return this.getQueryLocator();
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<sked_Travel_Time_Index_Item__c> ttiis = (List<sked_Travel_Time_Index_Item__c>) scope;
        this.map_key_reversedDirectionTravelTimeIndexItem = fetchReversedDirectionTravelTimeIndexItem(ttiis);
        
        Map<String, List<sked_Travel_Time_Index_Item__c>> mapTtiiByOrderingKey = new Map<String, List<sked_Travel_Time_Index_Item__c>>();

        updateRefreshDateForUserOverridedTTIIs(ttiis);
        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            List<sked_Travel_Time_Index_Item__c> ttiisByOrderingKey = mapTtiiByOrderingKey.get(ttii.sked_Ordering_Key__c);
            if (ttiisByOrderingKey == NULL) {
                ttiisByOrderingKey = new List<sked_Travel_Time_Index_Item__c>();
                mapTtiiByOrderingKey.put(ttii.sked_Ordering_Key__c, ttiisByOrderingKey);
            }
            ttiisByOrderingKey.add(ttii);
        }


        List<sked_Travel_Time_Index_Refresh_Request__c> requestsToCreate = new List<sked_Travel_Time_Index_Refresh_Request__c>();
        if (refreshTravelTime) {
            requestsToCreate.addAll(generateRequests(mapTtiiByOrderingKey, 40, 'Travel Time'));
        }

        if (!requestsToCreate.isEmpty()) {
            insert requestsToCreate;
        }
    }

    public void updateRefreshDateForUserOverridedTTIIs(List<sked_Travel_Time_Index_Item__c> ttiis) {
        List<sked_Travel_Time_Index_Item__c> ttiisToUpdate = new List<sked_Travel_Time_Index_Item__c>();
        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            if (ttii.User_Override__c == true) {
                ttii.sked_Last_Refresh_Date__c = System.now();
                ttiisToUpdate.add(ttii);
            }
        }
        update ttiisToUpdate;
    }

    public List<sked_Travel_Time_Index_Refresh_Request__c> generateRequests(Map<String, List<sked_Travel_Time_Index_Item__c>> mapTtiiByOrderingKey, integer requestOriginSize, string requestType) {
        List<sked_Travel_Time_Index_Refresh_Request__c> requests = new List<sked_Travel_Time_Index_Refresh_Request__c>();
        
        for (List<sked_Travel_Time_Index_Item__c> indexItems : mapTtiiByOrderingKey.values()) {
            Set<Id> indexItemIds = new Set<Id>();
            Set<string> origins = new Set<string>();
            Set<string> destinations = new Set<string>();
            List<sked_Travel_Time_Index_Item__c> reversedDirectionIndexItems = new List<sked_Travel_Time_Index_Item__c>();
            for (Integer i = 0; i < indexItems.size(); i++) {
                sked_Travel_Time_Index_Item__c indexItem = indexItems.get(i);

                if (indexItem.User_Override__c == false) {
                    indexItemIds.add(indexItem.Id);
                
                    string origin = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_From__c);
                    origins.add(origin);
                    
                    string destination = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_To__c);
                    destinations.add(destination);
                }

                String reversedDirectionKey = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_To__c, indexItem.sked_From__c);
                sked_Travel_Time_Index_Item__c reversedDirectionIndexItem = this.map_key_reversedDirectionTravelTimeIndexItem.get(reversedDirectionKey);
                if (reversedDirectionIndexItem != null && reversedDirectionIndexItem.User_Override__c == false) {
                    reversedDirectionIndexItems.add(reversedDirectionIndexItem);
                }
                
                if (indexItemIds.size() == requestOriginSize || i == indexItems.size() - 1) {
                    if (!indexItemIds.isEmpty()) {
                        requests.add(createNewTravelTimeIndexRefreshRequest(indexItemIds, origins, destinations, requestType));
                    }

                    if (!reversedDirectionIndexItems.isEmpty()) {
                        requests.add(createNewReversedDirectionTravelTimeIndexRefreshRequest(reversedDirectionIndexItems, requestType));
                    }


                    indexItemIds = new Set<Id>();
                    origins = new Set<string>();
                    destinations = new Set<string>();
                    reversedDirectionIndexItems = new List<sked_Travel_Time_Index_Item__c>();
                }
            }
        }
        return requests;
    }

    public void finish(Database.BatchableContext BC) {
        postProcess();
        if (!Test.isRunningTest()) {
            skedAsyncJobHandler.processTravelTimeRefreshRequest();
        }
    }

    protected virtual void postProcess() {}

    protected virtual sked_Travel_Time_Index_Refresh_Request__c createNewTravelTimeIndexRefreshRequest(Set<Id> indexItemIds,
             Set<String> origins, Set<String> destinations, String requestType) {
        System.debug('@@@indexItemIds: ' + indexItemIds);
        return new sked_Travel_Time_Index_Refresh_Request__c(
            sked_Record_Ids__c = string.join(indexItemIds, ';'),
            sked_Origins__c = string.join(origins, ';'),
            sked_Destinations__c = string.join(destinations, ';'),
            sked_Request_Type__c = requestType,
            sked_Status__c = 'Pending',
            sked_Priority__c = this.refreshRequestPriority
        );
    }

    protected virtual void executeSchedule() {}

    protected virtual Database.QueryLocator getQueryLocator() {
        return null;
    }

    //////////////////////////////////////////// Private Methods ////////////////////////////////////////////
    private Map<String, sked_Travel_Time_Index_Item__c> fetchReversedDirectionTravelTimeIndexItem(List<sked_Travel_Time_Index_Item__c> ttiis) {
        Map<String, sked_Travel_Time_Index_Item__c> map_key_reversedDirectionTravelTimeIndexItem = new Map<String, sked_Travel_Time_Index_Item__c>();
        List<String> reversedDirectionKeys = new List<String>();
        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            String reversedDirectionKey = skedTravelTimeIndexItemUtils.getKey(ttii.sked_To__c, ttii.sked_From__c);
            reversedDirectionKeys.add(reversedDirectionKey);
        }
        
        for (sked_Travel_Time_Index_Item__c reversedTtii : [
            SELECT Id, sked_Key__c, sked_Timezone__c, sked_From__c, sked_To__c, User_Override__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Key__c IN :reversedDirectionKeys
            AND sked_Timezone__c != NULL
        ]) {
            map_key_reversedDirectionTravelTimeIndexItem.put(reversedTtii.sked_Key__c, reversedTtii);
        }

        return map_key_reversedDirectionTravelTimeIndexItem;
    }

    private sked_Travel_Time_Index_Refresh_Request__c createNewReversedDirectionTravelTimeIndexRefreshRequest(List<sked_Travel_Time_Index_Item__c> ttiis, String requestType) {
        Set<Id> indexItemIds = new Set<Id>();
        Set<string> origins = new Set<string>();
        Set<string> destinations = new Set<string>();
        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            indexItemIds.add(ttii.Id);
            origins.add(skedTravelTimeIndexItemUtils.getKey(ttii.sked_From__c));
            destinations.add(skedTravelTimeIndexItemUtils.getKey(ttii.sked_To__c));
        }

        return createNewTravelTimeIndexRefreshRequest(indexItemIds, origins, destinations, requestType);
    }
}