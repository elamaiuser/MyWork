public class skedTravelTimeIndexItemHandler extends skedTriggerHub  {
    
    public override void onBeforeInsert() {
        setKey(this.context.newRecords);
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureTravelTimeImpact(this.context.newRecords, (Map<Id, sked_Travel_Time_Index_Item__c>)this.context.oldMap);
        }
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
            if (newRecord.sked_Average_Travel_Time__c != oldData.sked_Average_Travel_Time__c
                && newRecord.sked_Average_Travel_Time__c != NULL
                && oldData.sked_Average_Travel_Time__c != NULL) {
                    decimal beforeAfterGap = Math.abs(oldData.sked_Average_Travel_Time__c - newRecord.sked_Average_Travel_Time__c);
                    if (beforeAfterGap >= skedSetting.instance.TravelTime.driveImpactThreshold) {
                        impactedIndexIds.add(newRecord.Id);
                    }
                }
        }
        if (!impactedIndexIds.isEmpty()) {
            if (!System.isBatch() && !Test.isRunningTest()) {
                Database.executeBatch(new skedCreateDCRForTravelTimeChangeBatch(impactedIndexIds), 200);
            }
        }
    }
    
}