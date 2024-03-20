public class skedTravelTimeIndexTravelTimeBatch implements Database.Batchable<sked_Travel_Time_Index_Refresh_Request__c>, Database.AllowsCallouts, Database.stateful {

    public skedTravelTimeIndexTravelTimeBatch() {}
    
    public List<sked_Travel_Time_Index_Refresh_Request__c> start(Database.BatchableContext BC) {
        List<sked_Travel_Time_Index_Refresh_Request__c> inProgressRequests = [SELECT Id
                                                                              FROM sked_Travel_Time_Index_Refresh_Request__c
                                                                              WHERE sked_Request_Type__c = 'Travel Time'
                                                                              AND sked_Status__c = 'In Progress'];
        integer noOfRequestsToExecute = skedSetting.instance.TravelTime.numberOfParallelRequests - inProgressRequests.size();
        noOfRequestsToExecute = noOfRequestsToExecute >= 0 ? noOfRequestsToExecute : 0;
        
        return [SELECT Id, sked_Record_Ids__c, sked_Run_Id__c
                FROM sked_Travel_Time_Index_Refresh_Request__c
                WHERE sked_Request_Type__c = 'Travel Time'
                AND sked_Status__c = 'Pending'
                LIMIT :noOfRequestsToExecute];
    }
    
    public void execute(Database.BatchableContext BC, List<sked_Travel_Time_Index_Refresh_Request__c> requests) {
        Set<Id> allIndexItemIds = new Set<Id>();
        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            List<Id> indexItemIds = request.sked_Record_Ids__c.split(';');
            allIndexItemIds.addAll(indexItemIds);
        }
        
        Map<Id, sked_Travel_Time_Index_Item__c> mapIndexItem = new Map<Id, sked_Travel_Time_Index_Item__c>([
            SELECT Id, sked_Key__c, sked_Timezone__c,
            sked_From__c, sked_To__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE Id IN :allIndexItemIds
        ]);
        
        Map<Id, List<sked_Travel_Time_Index_Item__c>> map_requestId_indexItems = new Map<Id, List<sked_Travel_Time_Index_Item__c>>();
        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            List<sked_Travel_Time_Index_Item__c> indexItems = new List<sked_Travel_Time_Index_Item__c>();
            
            List<Id> indexItemIds = request.sked_Record_Ids__c.split(';');
            for (Id indexItemId : indexItemIds) {
                sked_Travel_Time_Index_Item__c indexItem = mapIndexItem.get(indexItemId);
                indexItems.add(indexItem);
            }
            
            map_requestId_indexItems.put(request.Id, indexItems);
        }
        
        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            try {
                List<sked_Travel_Time_Index_Item__c> indexItems = map_requestId_indexItems.get(request.Id);
                
                skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
                List<string> timeBlocks = apiManager.getTravelTimeSetting(indexItems[0].sked_Timezone__c);
                
                Set<string> fromGeocodeKeys = new Set<string>();
                Set<string> toGeocodeKeys = new Set<string>();
                
                List<Location> fromGeocodes = new List<Location>();
                List<Location> toGeocodes = new List<Location>();
                
                for (sked_Travel_Time_Index_Item__c indexItem : indexItems) {
                    string fromGeocodeKey = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_From__c);
                    if (!fromGeocodeKeys.contains(fromGeocodeKey)) {
                        fromGeocodeKeys.add(fromGeocodeKey);
                        fromGeocodes.add(indexItem.sked_From__c);
                    }
                    
                    string toGeocodeKey = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_To__c);
                    if (!toGeocodeKeys.contains(toGeocodeKey)) {
                        toGeocodeKeys.add(toGeocodeKey);
                        toGeocodes.add(indexItem.sked_To__c);
                    }
                }
                
                skedSkeduloApiData.distanceMatrixAsyncResult distanceMatrixAsyncResult = apiManager.distanceMatrixAsync(timeBlocks, fromGeocodes,  toGeocodes);
                request.sked_Run_Id__c = distanceMatrixAsyncResult.id;
                request.sked_Status__c = 'In Progress';
            }
            catch (Exception ex) {
                string error = '';
                error += ex.getMessage();
                error += '----' + ex.getStackTraceString();
                
                request.sked_Status__c = 'Error';
                request.sked_Error_Message__c = error;
            }
        }
            
        update requests;
    }
    
    public void finish(Database.BatchableContext BC) { }
    
}