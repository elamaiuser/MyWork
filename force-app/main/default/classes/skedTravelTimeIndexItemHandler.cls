public class skedTravelTimeIndexItemHandler extends skedTriggerHub  {
    
    public override void onBeforeInsert() {
        setKey(this.context.newRecords);
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureTravelTimeImpact(this.context.newRecords, (Map<Id, sked_Travel_Time_Index_Item__c>)this.context.oldMap);
        }
    }

    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            refreshTravelTimeIndexData(this.context.newMap.keySet());
        }

        skedFutureCallPostCommitEventHandler.publishFutureCallEvent(
            skedTravelTimeIndexItemHandler.class.getName(),
            'populateTTILokkupFieldsOnSiteCO',
            skedSObjectUtils.getRecordIds(this.context.newRecords)   
        );

    }

    /******************************************** Callable Interface ********************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'populateTTILokkupFieldsOnSiteCO' {
                    populateTTILokkupFieldsOnSiteCO((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));

                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedTravelTimeIndexItemHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void setKey(List<sked_Travel_Time_Index_Item__c> newRecords) {
        for (sked_Travel_Time_Index_Item__c ttii : newRecords) {
            if (ttii.sked_Key__c == NULL) {
                Location fromLoc = Location.newInstance(ttii.sked_From__Latitude__s, ttii.sked_From__Longitude__s);
                Location toLoc = Location.newInstance(ttii.sked_To__Latitude__s, ttii.sked_To__Longitude__s);
                
                ttii.sked_Key__c = skedTravelTimeIndexItemUtils.getKey(fromLoc, toLoc);
            }
        }
    }
    
    private void captureTravelTimeImpact(List<sked_Travel_Time_Index_Item__c> newRecords, Map<Id, sked_Travel_Time_Index_Item__c> oldMap) {
        Set<Id> impactedIndexIds = new Set<Id>();
        for (sked_Travel_Time_Index_Item__c newRecord : newRecords) {
            sked_Travel_Time_Index_Item__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.User_Override__c == false
                && newRecord.sked_Average_Travel_Time__c != oldData.sked_Average_Travel_Time__c
                && newRecord.sked_Average_Travel_Time__c!= NULL) {
                    if(oldData.sked_Average_Travel_Time__c == NULL) {
                        impactedIndexIds.add(newRecord.Id);
                    }else {
                        decimal beforeAfterGap = Math.abs(oldData.sked_Average_Travel_Time__c - newRecord.sked_Average_Travel_Time__c);
                        if (beforeAfterGap >= skedSetting.instance.TravelTime.driveImpactThreshold) {
                            impactedIndexIds.add(newRecord.Id);                         
                        }else {
                            system.debug('### Travel Time Index Item [' + newRecord.Id + '] skipped for beforeAfterGap : '+ beforeAfterGap);
                        }
                    }
                }
            }
        system.debug('### Impacted Travel Time Index Item : '+ impactedIndexIds.toString());
        if (!impactedIndexIds.isEmpty()) {
            if (!System.isBatch() && !Test.isRunningTest()) {
                Database.executeBatch(new skedCreateDCRForTravelTimeChangeBatch(impactedIndexIds, new Set<Id>()), 200);
            }
        }
    }
    
    private void refreshTravelTimeIndexData(Set<Id> indexIds) {
        if (!System.isBatch() && !Test.isRunningTest()) {
            Database.executeBatch(new skedImmediateRefreshTravelTimeIndexBatch(new List<Id>(indexIds), skedSetting.instance.TravelTime.newIndexPriority), 200);
        }
    }
}