public class skedAsyncJobHandler extends skedTriggerHub {
    
    public override void onAfterInsert() {
        processTravelTimeResponse(this.context.newRecords);
    }
    
    public static void processTravelTimeRefreshRequest() {
        Database.executeBatch(new skedTravelTimeIndexTravelTimeBatch());
    }
    
    public void processTravelTimeResponse(List<sked__Async_Job__c> newRecords) {
        sked__Async_Job__c asyncJob = newRecords.get(0);
        
        List<sked_Travel_Time_Index_Refresh_Request__c> requestQuery = [SELECT Id, sked_Record_Ids__c, sked_Run_Id__c,
                                                                        sked_Origins__c, sked_Destinations__c, sked_Status__c
                                                                        FROM sked_Travel_Time_Index_Refresh_Request__c 
                                                                        WHERE sked_Run_Id__c = :asyncJob.sked_Run_Id__c];
        if (!requestQuery.isEmpty()) {
            sked_Travel_Time_Index_Refresh_Request__c request = requestQuery.get(0);
            
            if (asyncJob.sked__Status__c == 'Error') {
                request.sked_Status__c = 'Error';
                request.sked_Error_Message__c = asyncJob.sked_API_Response__c;
            }
            else if (asyncJob.sked__Status__c == 'Complete') {
                try {
                    List<Id> indexItemIds = request.sked_Record_Ids__c.split(';');
                    
                    string jsonResult = asyncJob.sked_API_Response__c;
                    
                    List<skedSkeduloApiData.distanceMatrixAsyncModel> results = 
                        (List<skedSkeduloApiData.distanceMatrixAsyncModel>)Json.deserialize(jsonResult, List<skedSkeduloApiData.distanceMatrixAsyncModel>.class);
                    
                    List<string> originKeys = request.sked_Origins__c.split(';');
                    List<string> destinationKeys = request.sked_Destinations__c.split(';');
                    
                    Set<string> indexItemKeys = new Set<string>();
                    for (string originKey : originKeys) {
                        for (string destinationKey : destinationKeys) {
                            string indexItemKey = originKey + ':' + destinationKey;
                            indexItemKeys.add(indexItemKey);
                        }
                    }
                    
                    Map<String, sked_Travel_Time_Index_Item__c> mapIndexItemByKey = new Map<String, sked_Travel_Time_Index_Item__c>([
                        SELECT Id, sked_Key__c, sked_Timezone__c
                        FROM sked_Travel_Time_Index_Item__c
                        WHERE sked_Key__c IN :indexItemKeys
                    ]);
                    string timezoneSidId = mapIndexItemByKey.values().get(0).sked_Timezone__c;
                    
                    Map<string, List<skedTravelTimeBreakdownModel>> map_key_models = new Map<string, List<skedTravelTimeBreakdownModel>>();
                    for (skedSkeduloApiData.distanceMatrixAsyncModel result : results) {
                        string weekday = result.fromTime.format('EEEE');
                        
                        for (integer i = 0; i < result.values.size(); i++) {
                            List<skedSkeduloApiData.distanceModel> distanceItems = result.values.get(i);
                            for (integer j = 0; j < distanceItems.size(); j++) {
                                string originKey = originKeys.get(i);
                                string destinationKey = destinationKeys.get(j);
                                string indexItemKey = originKey + ':' + destinationKey;
                                
                                skedSkeduloApiData.distanceModel distanceItem = distanceItems.get(j);
                                if (distanceItem != NULL && distanceItem.status == 'OK') {
                                    string fromHour = result.fromTime.format('HH', timezoneSidId);
                                    string fromMinute = result.fromTime.format('mm', timezoneSidId);
                                    string toHour = result.toTime.format('HH', timezoneSidId);
                                    string toMinute = result.toTime.format('mm', timezoneSidId);
                                    skedTravelTimeBreakdownModel model = new skedTravelTimeBreakdownModel();
                                    model.weekday = weekday;
                                    model.endOfWindow = Time.newInstance(Integer.valueOf(toHour), Integer.valueOf(toMinute), 0, 0);
                                    model.startOfWindow = Time.newInstance(Integer.valueOf(fromHour), Integer.valueOf(fromMinute), 0, 0);
                                    if (distanceItem.distance != NULL) {
                                        model.travelDistance = distanceItem.distance;
                                    }
                                    if (distanceItem.duration != NULL) {
                                        model.travelTime = Math.ceil((distanceItem.duration / 60));
                                    }
                                    
                                    List<skedTravelTimeBreakdownModel> models = map_key_models.get(indexItemKey);
                                    if (models == NULL) {
                                        models = new List<skedTravelTimeBreakdownModel>();
                                        map_key_models.put(indexItemKey, models);
                                    }
                                    models.add(model);
                                }
                            }
                        }
                    }
                    
                    for (sked_Travel_Time_Index_Item__c indexItem : mapIndexItemByKey.values()) {
                        List<skedTravelTimeBreakdownModel> models = map_key_models.get(indexItem.sked_Key__c);

                        indexItem.sked_Last_Refresh_Date__c = system.now();
                        indexItem.sked_Travel_Time_Breakdown_JSON__c = skedConstants.NO_TRAVEL_TIME_DATA;
                        if (models != null && !models.isEmpty()) {
                            indexItem.sked_Travel_Time_Breakdown_JSON__c = JSON.serialize(models);
                            
                            Decimal travelDistance;
                            for (skedTravelTimeBreakdownModel model : models) {
                                if (model.travelDistance != null) {
                                    travelDistance = model.travelDistance;
                                    break;
                                }
                            }
                            if (travelDistance != null) {
                                indexItem.sked_Travel_Distance__c = travelDistance / skedConstants.METTER_PER_MILE;
                            }
                        }

                        if (indexItem.sked_Travel_Time_Breakdown_JSON__c != skedConstants.NO_TRAVEL_TIME_DATA) {
                            decimal totalTravelTime = 0;
                            for (skedTravelTimeBreakdownModel model : models) {
                                totalTravelTime += (model.travelTime != NULL ? model.travelTime : 0);
                            }
                            decimal averageTravelTime = totalTravelTime / models.size();
                            indexItem.sked_Average_Travel_Time__c = Math.round(averageTravelTime);
                        }
                    }
                    update mapIndexItemByKey.values();
                    
                    request.sked_Status__c = 'Completed';
                }
                catch (Exception ex) {
                    string error = '';
                    error += ex.getMessage();
                    error += '----' + ex.getStackTraceString();
                    
                    request.sked_Status__c = 'Error';
                    request.sked_Error_Message__c = error;
                }
            }
            
            update request;
            
            skedAsyncJobHandler.processTravelTimeRefreshRequest();
        }
    }
}