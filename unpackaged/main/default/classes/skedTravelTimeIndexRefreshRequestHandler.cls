public class skedTravelTimeIndexRefreshRequestHandler extends skedTriggerHub {
    
    public override void onAfterInsert() {
        updateRelatedIndexItems(this.context.newRecords);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void updateRelatedIndexItems(List<sked_Travel_Time_Index_Refresh_Request__c> newRecords) {
        Map<Id, sked_Travel_Time_Index_Item__c> mapIndexItemsToUpdate = new Map<Id, sked_Travel_Time_Index_Item__c>();
        for (sked_Travel_Time_Index_Refresh_Request__c request : newRecords) {
            if (request.sked_Request_Type__c == 'Travel Time') {
                List<string> indexItemIds = request.sked_Record_Ids__c.split(';');
                for (string indexItemId : indexItemIds) {
                    sked_Travel_Time_Index_Item__c indexItem = new sked_Travel_Time_Index_Item__c(
                        Id = indexItemId,
                        sked_Last_Refresh_Request__c = request.Id
                    );
                    mapIndexItemsToUpdate.put(indexItem.Id, indexItem);
                }
            }
        }
        if (!mapIndexItemsToUpdate.isEmpty()) {
            update mapIndexItemsToUpdate.values();
        }
    }

}