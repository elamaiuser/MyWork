public class skedCOGroupTravelTimeIndexRefreshBatch extends skedRefreshTravelTimeIndexBatchBase {
    private Map<Id, Set<String>> mapGroupIdToCoFromKeys;
    private List<Id> refreshGroupIds;
    private Integer groupIndexToProcess;

    public skedCOGroupTravelTimeIndexRefreshBatch(Map<Id, Set<String>> mapGroupIdToCoFromKeys, Integer refreshRequestPriority, Integer groupIndexToProcess) {
        super(refreshRequestPriority, true);
        this.mapGroupIdToCoFromKeys = mapGroupIdToCoFromKeys;
        this.refreshGroupIds = new List<Id>(mapGroupIdToCoFromKeys.keySet());
        this.groupIndexToProcess = groupIndexToProcess;
    }

    protected override Database.QueryLocator getQueryLocator() {        
        Set<String> coFromKeys = this.mapGroupIdToCoFromKeys.get(this.refreshGroupIds[this.groupIndexToProcess]);
        return Database.getQueryLocator([
            SELECT Id, sked_Timezone__c, sked_Ordering_Key__c,
            sked_From__c, sked_To__c, User_Override__c,
            sked_Travel_Time_Breakdown_JSON__c,
            sked_Travel_Time_Breakdown_JSON_Backup__c,
            (SELECT sked_Collection_Operation__c FROM Site_Collection_Operations__r WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY),
            (SELECT sked_Collection_Operation__c FROM sked_Site_Collection_Operations__r WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY)
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Ordering_Key__c LIKE 'COToSite%'
            AND sked_From_Key__c IN :coFromKeys
            ORDER BY sked_Ordering_Key__c ASC, Id ASC
        ]);
    }

    protected override sked_Travel_Time_Index_Refresh_Request__c createNewTravelTimeIndexRefreshRequest(Set<Id> indexItemIds,
             Set<String> origins, Set<String> destinations, String requestType) {
        return new sked_Travel_Time_Index_Refresh_Request__c(
            sked_Record_Ids__c = string.join(indexItemIds, ';'),
            sked_Origins__c = string.join(origins, ';'),
            sked_Destinations__c = string.join(destinations, ';'),
            sked_Request_Type__c = requestType,
            sked_Status__c = 'Pending',
            sked_Priority__c = this.refreshRequestPriority,
            sked_Travel_Time_Index_Refresh_Group__c = this.refreshGroupIds[this.groupIndexToProcess]
        );
    }

    protected override void postProcess() {
        sked_Travel_Time_Index_Refresh_Group__c refreshGroup = new sked_Travel_Time_Index_Refresh_Group__c(
            Id = this.refreshGroupIds[this.groupIndexToProcess],
            sked_Status__c = skedConstants.TRAVEL_TIME_INDEX_REFRESH_GROUP_STATUS_PENDING
        );
        update refreshGroup;

        if (this.groupIndexToProcess < this.refreshGroupIds.size() - 1) {
            Database.executeBatch(new skedCOGroupTravelTimeIndexRefreshBatch(this.mapGroupIdToCoFromKeys, this.refreshRequestPriority, this.groupIndexToProcess + 1), 200);
        }
    }
}