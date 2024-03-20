global class skedTravelTimeIndexTravelDistanceBatch implements Database.Batchable<sked_Travel_Time_Index_Refresh_Request__c>, Database.AllowsCallouts, Database.stateful {

    public skedTravelTimeIndexTravelDistanceBatch() {}
    
    global List<sked_Travel_Time_Index_Refresh_Request__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Record_Ids__c, sked_Run_Id__c
                FROM sked_Travel_Time_Index_Refresh_Request__c
                WHERE sked_Request_Type__c = 'Travel Distance'
                AND sked_Status__c = 'Pending'];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Travel_Time_Index_Refresh_Request__c> requests) {
        //Chunk size will be one, as a request is used to handle 100 records.
        sked_Travel_Time_Index_Refresh_Request__c request = requests.get(0);
        
        List<Id> indexItemIds = request.sked_Record_Ids__c.split(';');
        List<sked_Travel_Time_Index_Item__c> indexItems = [SELECT Id, sked_Key__c, sked_Timezone__c,
                                                           sked_From__c, sked_To__c
                                                           FROM sked_Travel_Time_Index_Item__c
                                                           WHERE Id IN :indexItemIds
                                                           ORDER BY Id ASC];
        
        List<skedSkeduloApiData.latlng> fromGeocodes = new List<skedSkeduloApiData.latlng>();
        List<skedSkeduloApiData.latlng> toGeocodes = new List<skedSkeduloApiData.latlng>();
        
        Set<string> fromGeocodeKeys = new Set<string>();
        Set<string> toGeocodeKeys = new Set<string>();
        
        Map<string, sked_Travel_Time_Index_Item__c> mapIndexItemByKey = new Map<string, sked_Travel_Time_Index_Item__c>();
        for (sked_Travel_Time_Index_Item__c indexItem : indexItems) {
            mapIndexItemByKey.put(indexItem.sked_Key__c, indexItem);
            
            string fromGeocodeKey = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_From__c);
            if (!fromGeocodeKeys.contains(fromGeocodeKey)) {
                fromGeocodeKeys.add(fromGeocodeKey);
                
                Location fromLoc = indexItem.sked_From__c;
                
                skedSkeduloApiData.latlng fromGeocode = new skedSkeduloApiData.latlng();
                fromGeocode.lat = fromLoc.latitude;
                fromGeocode.lng = fromLoc.longitude;
                fromGeocodes.add(fromGeocode);
            }
            
            string toGeocodeKey = skedTravelTimeIndexItemUtils.getKey(indexItem.sked_To__c);
            if (!toGeocodeKeys.contains(toGeocodeKey)) {
                toGeocodeKeys.add(toGeocodeKey);
                
                Location toLoc = indexItem.sked_To__c;
                
                skedSkeduloApiData.latlng toGeocode = new skedSkeduloApiData.latlng();
                toGeocode.lat = toLoc.latitude;
                toGeocode.lng = toLoc.longitude;
                toGeocodes.add(toGeocode);
            }
        }
        
        skedSkeduloApiData.distanceMatrixResult distanceMatrixResult;
        try {
            Map<Id, sked_Travel_Time_Index_Item__c> mapItemToUpdate = new Map<Id, sked_Travel_Time_Index_Item__c>();
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            distanceMatrixResult = apiManager.calculateDistanceMatrix(fromGeocodes, toGeocodes);
            for (integer i = 0; i < distanceMatrixResult.result.matrix.size(); i++) {
             	List<skedSkeduloApiData.Element> elements = distanceMatrixResult.result.matrix.get(i);
                for (integer j = 0; j < elements.size(); j++) {
                    skedSkeduloApiData.Element element = elements.get(j);
                    
                    if (element.distance != NULL) {
                        skedSkeduloApiData.latlng fromGeocode = fromGeocodes.get(i);
                        skedSkeduloApiData.latlng toGeocode = toGeocodes.get(j);
                        
                        Location fromLoc = Location.newInstance(fromGeocode.lat, fromGeocode.lng);
                        Location toLoc = Location.newInstance(toGeocode.lat, toGeocode.lng);
                        
                        string indexItemKey = skedTravelTimeIndexItemUtils.getKey(fromLoc, toLoc);
                        
                        if (mapIndexItemByKey.containsKey(indexItemKey)) {
                            sked_Travel_Time_Index_Item__c indexItem = mapIndexItemByKey.get(indexItemKey);
                            indexItem.sked_Travel_Distance__c = element.distance.distanceInMeters / skedConstants.METTER_PER_MILE;
                            mapItemToUpdate.put(indexItem.Id, indexItem);
                        }
                    }
                }
            }
            if (!mapItemToUpdate.isEmpty()) {
                update mapItemToUpdate.values();
            }
            
            request.sked_Run_Id__c = 'Travel Distance';
            request.sked_Status__c = 'Completed';
        }
        catch (Exception ex) {
            string error = '';
            error += ex.getMessage();
            error += '----' + ex.getStackTraceString();
            
            request.sked_Status__c = 'Error';
            request.sked_Error_Message__c = error;
        }
        
        update request;
    }
    
    global void finish(Database.BatchableContext BC) { 
        
    }
    
}