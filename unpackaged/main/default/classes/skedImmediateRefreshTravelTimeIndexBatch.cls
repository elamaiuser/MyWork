public class skedImmediateRefreshTravelTimeIndexBatch extends skedRefreshTravelTimeIndexBatchBase {
    private List<Id> travelTimeIndexIds;
    private Id siteCollectionOperationId;

    public skedImmediateRefreshTravelTimeIndexBatch(List<Id> travelTimeIndexIds, Integer refreshRequestPriority) {
        super(refreshRequestPriority, true);
        this.travelTimeIndexIds = travelTimeIndexIds;
    }

    public skedImmediateRefreshTravelTimeIndexBatch(List<Id> travelTimeIndexIds, Integer refreshRequestPriority, String siteCollectionOperationId) {
        super(refreshRequestPriority, true);
        this.travelTimeIndexIds = travelTimeIndexIds;
        this.siteCollectionOperationId = siteCollectionOperationId;
    }

    protected override Database.QueryLocator getQueryLocator() {        
        return Database.getQueryLocator([
            SELECT Id, sked_Timezone__c, sked_Ordering_Key__c,
            sked_From__c, sked_To__c, User_Override__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE Id IN :travelTimeIndexIds
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
            sked_Manual_Refresh_SCO_Id__c = this.siteCollectionOperationId
        );
    }
}