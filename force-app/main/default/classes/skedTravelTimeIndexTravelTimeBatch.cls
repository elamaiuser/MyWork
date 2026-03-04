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
                ORDER BY sked_Priority__c ASC NULLS LAST, CreatedDate ASC
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
            sked_From__c, sked_To__c, sked_Ordering_Key__c,
            (SELECT sked_Collection_Operation__c
             FROM Site_Collection_Operations__r
             WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY),
            (SELECT sked_Collection_Operation__c
             FROM sked_Site_Collection_Operations__r
             WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY)
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

        Set<string> collectionOperationIds = new Set<string>();
        for (List<sked_Travel_Time_Index_Item__c> indexItems : map_requestId_indexItems.values()) {
            if (!indexItems.isEmpty()) {
                Id coId = getCollectionOperationId(indexItems[0]);
                if (coId != null) {
                    collectionOperationIds.add(coId);
                }
            }
        }

        Map<string, List<sked_Travel_Time_Slot__c>> map_collectionOpId_travelTimeSlots = new Map<string, List<sked_Travel_Time_Slot__c>>();
        if (!collectionOperationIds.isEmpty()) {
            List<sked_Travel_Time_Slot__c> allTravelTimeSlots = [
                SELECT sked_Collection_Operation__c, sked_Weekday__c, sked_Start_Time__c, sked_End_Time__c
                FROM sked_Travel_Time_Slot__c
                WHERE sked_Collection_Operation__c IN :collectionOperationIds
                ORDER BY sked_Collection_Operation__c, sked_Weekday__c, sked_Start_Time__c
            ];

            for (sked_Travel_Time_Slot__c slot : allTravelTimeSlots) {
                if (!map_collectionOpId_travelTimeSlots.containsKey(slot.sked_Collection_Operation__c)) {
                    map_collectionOpId_travelTimeSlots.put(slot.sked_Collection_Operation__c, new List<sked_Travel_Time_Slot__c>());
                }
                map_collectionOpId_travelTimeSlots.get(slot.sked_Collection_Operation__c).add(slot);
            }
        }

        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            try {
                List<sked_Travel_Time_Index_Item__c> indexItems = map_requestId_indexItems.get(request.Id);

                skedSkeduloApiManager apiManager = new skedSkeduloApiManager();

                Id collectionOperationId = getCollectionOperationId(indexItems[0]);
                List<string> timeBlocks;

                List<sked_Travel_Time_Slot__c> travelTimeSlots = collectionOperationId != null ? map_collectionOpId_travelTimeSlots.get(collectionOperationId) : null;
                if (travelTimeSlots != null && !travelTimeSlots.isEmpty()) {
                    timeBlocks = buildTimeBlocksFromSlots(travelTimeSlots, indexItems[0].sked_Timezone__c);
                } else {
                    timeBlocks = apiManager.getTravelTimeSetting(indexItems[0].sked_Timezone__c);
                }
                
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
                request.sked_Time_Slots__c = timeBlocks != null && !timeBlocks.isEmpty() ? JSON.serialize(timeBlocks) : null;
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

    private Id getCollectionOperationId(sked_Travel_Time_Index_Item__c ttii) {
        if (ttii.sked_Ordering_Key__c != null) {
            if (ttii.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_CO_TO_SITE)) {
                if (!ttii.Site_Collection_Operations__r.isEmpty()) {
                    return ttii.Site_Collection_Operations__r[0].sked_Collection_Operation__c;
                }
            } else if (ttii.sked_Ordering_Key__c.startsWithIgnoreCase(skedConstants.TTII_DIRECTION_SITE_TO_CO)) {
                if (!ttii.sked_Site_Collection_Operations__r.isEmpty()) {
                    return ttii.sked_Site_Collection_Operations__r[0].sked_Collection_Operation__c;
                }
            }
        }
        return null;
    }

    private List<string> buildTimeBlocksFromSlots(List<sked_Travel_Time_Slot__c> slots, string timezoneSidId) {
        Map<string, List<sked_Travel_Time_Slot__c>> mapWeekdayToSlots = new Map<string, List<sked_Travel_Time_Slot__c>>();
        for (sked_Travel_Time_Slot__c slot : slots) {
            if (!mapWeekdayToSlots.containsKey(slot.sked_Weekday__c)) {
                mapWeekdayToSlots.put(slot.sked_Weekday__c, new List<sked_Travel_Time_Slot__c>());
            }
            mapWeekdayToSlots.get(slot.sked_Weekday__c).add(slot);
        }

        List<string> timeBlocks = new List<string>();
        Date currentDate = System.today();

        for (integer i = 0; i < 7; i++) {
            currentDate = currentDate.addDays(1);
            Datetime currentDateTime = skedDateTimeUtils.newDateTimeInstance(currentDate, 0, timezoneSidId);
            String dayOfWeek = currentDateTime.format('EEEE', timezoneSidId);

            List<sked_Travel_Time_Slot__c> weekdaySlots = mapWeekdayToSlots.get(dayOfWeek);

            if (weekdaySlots != null && !weekdaySlots.isEmpty()) {
                for (sked_Travel_Time_Slot__c slot : weekdaySlots) {
                    DateTime startDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)slot.sked_Start_Time__c, timezoneSidId);
                    DateTime endDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)slot.sked_End_Time__c, timezoneSidId);

                    string startDtString = JSON.serialize(startDt).replace('"', '');
                    startDtString = startDtString.replace('.000Z', '');
                    string endDtString = JSON.serialize(endDt).replace('"', '');
                    endDtString = endDtString.replace('.000Z', '');

                    timeBlocks.add(startDtString + ',' + endDtString);
                }
            }
        }

        return timeBlocks;
    }

}