public class skedTravelTimeIndexRefreshRequestHandler extends skedTriggerHub {
    
    public override void onAfterInsert() {
        updateRelatedIndexItems(this.context.newRecords);
    }

    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            updateRefreshGroupStatus(this.context.newRecords, (Map<Id, sked_Travel_Time_Index_Refresh_Request__c>)this.context.oldMap);
        }
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

    private void updateRefreshGroupStatus(List<sked_Travel_Time_Index_Refresh_Request__c> newRecords, Map<Id, sked_Travel_Time_Index_Refresh_Request__c> oldMap) {
        markRefreshGroupsAsComplete(newRecords, oldMap);
        markRefreshGroupsAsProcessing(newRecords, oldMap);
    }

    private void markRefreshGroupsAsComplete(List<sked_Travel_Time_Index_Refresh_Request__c> newRecords, Map<Id, sked_Travel_Time_Index_Refresh_Request__c> oldMap) {
        Set<Id> groupIds = new Set<Id>();
        List<String> includedStatuses = new List<String>{'Completed', 'Error'};
        for (sked_Travel_Time_Index_Refresh_Request__c request : newRecords) {
            sked_Travel_Time_Index_Refresh_Request__c oldData = oldMap.get(request.Id);
            if (request.sked_Request_Type__c == 'Travel Time' &&
                oldData.sked_Status__c != request.sked_Status__c &&
                includedStatuses.contains(request.sked_Status__c) &&
                request.sked_Travel_Time_Index_Refresh_Group__c != NULL
            ) {
                groupIds.add(request.sked_Travel_Time_Index_Refresh_Group__c);
            }
        }

        if (!groupIds.isEmpty()) {
            Set<Id> groupsHavingUncompletedRequest = new Set<Id>();
            for (sked_Travel_Time_Index_Refresh_Request__c request : [
                SELECT Id, sked_Travel_Time_Index_Refresh_Group__c
                FROM sked_Travel_Time_Index_Refresh_Request__c
                WHERE sked_Travel_Time_Index_Refresh_Group__c IN :groupIds
                AND sked_Status__c NOT IN :includedStatuses
            ]) {
                groupsHavingUncompletedRequest.add(request.sked_Travel_Time_Index_Refresh_Group__c);
            }

            List<sked_Travel_Time_Index_Refresh_Group__c> groupsToComplete = new List<sked_Travel_Time_Index_Refresh_Group__c>();
            for (Id groupId : groupIds) {
                if (!groupsHavingUncompletedRequest.contains(groupId)) {
                    sked_Travel_Time_Index_Refresh_Group__c groupToComplete = new sked_Travel_Time_Index_Refresh_Group__c(
                        Id = groupId,
                        sked_Status__c = skedConstants.TRAVEL_TIME_INDEX_REFRESH_GROUP_STATUS_COMPLETED
                    );
                    groupsToComplete.add(groupToComplete);
                }
            }

            if (!groupsToComplete.isEmpty()) {
                update groupsToComplete;
            }
        }
    }

    private void markRefreshGroupsAsProcessing(List<sked_Travel_Time_Index_Refresh_Request__c> newRecords, Map<Id, sked_Travel_Time_Index_Refresh_Request__c> oldMap) {
        Set<Id> groupIds = new Set<Id>();
        for (sked_Travel_Time_Index_Refresh_Request__c request : newRecords) {
            sked_Travel_Time_Index_Refresh_Request__c oldData = oldMap.get(request.Id);
            if (request.sked_Request_Type__c == 'Travel Time' &&
                oldData.sked_Status__c != request.sked_Status__c &&
                request.sked_Status__c == 'In Progress' &&
                request.sked_Travel_Time_Index_Refresh_Group__c != NULL
            ) {
                groupIds.add(request.sked_Travel_Time_Index_Refresh_Group__c);
            }
        }

        if (!groupIds.isEmpty()) {
            List<sked_Travel_Time_Index_Refresh_Group__c> groupsToBeMarked = new List<sked_Travel_Time_Index_Refresh_Group__c>();
            for (sked_Travel_Time_Index_Refresh_Group__c pendingGroup : [
                SELECT Id
                FROM sked_Travel_Time_Index_Refresh_Group__c
                WHERE Id IN :groupIds
                AND sked_Status__c = :skedConstants.TRAVEL_TIME_INDEX_REFRESH_GROUP_STATUS_PENDING
            ]) {
                pendingGroup.sked_Status__c = skedConstants.TRAVEL_TIME_INDEX_REFRESH_GROUP_STATUS_PROCESSING;
                groupsToBeMarked.add(pendingGroup);
            }

            if (!groupsToBeMarked.isEmpty()) {
                update groupsToBeMarked;
            }
        }
    }
}