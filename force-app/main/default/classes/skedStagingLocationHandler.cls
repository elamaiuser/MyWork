public class skedStagingLocationHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateTaxonomyData(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            revertAccidientallyChangedGeolocation(this.context.newRecords, (Map<Id, sked_Staging_Location__c>)this.context.oldMap);
        }
        validateUpdate(this.context.newRecords, (Map<Id, sked_Staging_Location__c>)this.context.oldMap);
        populateTaxonomyData(this.context.newRecords, (Map<Id, sked_Staging_Location__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void populateTaxonomyData(List<sked_Staging_Location__c> newRecords, Map<Id, sked_Staging_Location__c> oldMap) {
        List<sked_Staging_Location__c> recordsToPopulate = new List<sked_Staging_Location__c>();
        for (sked_Staging_Location__c newRecord : newRecords) {
            sked_Staging_Location__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Zip_Code__c != oldData.sked_Zip_Code__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            skedTriggerUtils.populateTimezoneFromTaxonomy(recordsToPopulate, 'sked_Zip_Code__c', 'sked_Timezone__c');
        }
    }
    
    private void populateTaxonomyData(List<sked_Staging_Location__c> newRecords) {
        skedTriggerUtils.populateTimezoneFromTaxonomy(newRecords, 'sked_Zip_Code__c', 'sked_Timezone__c');
    }

    private void validateUpdate(List<sked_Staging_Location__c> newRecords, Map<Id, sked_Staging_Location__c> oldMap) {
        for (sked_Staging_Location__c sl : newRecords) {
            sked_Staging_Location__c oldSl = oldMap.get(sl.Id);
            if (oldSl.sked_Address__c != null && sl.sked_Address__c != oldSl.sked_Address__c && sl.sked_COSL_Count__c > 0) {
                sl.addError('Unable to edit Address for a Staging Location with existing links to a Collection Operation');
            }
        }
    }
    
    private void revertAccidientallyChangedGeolocation(List<sked_Staging_Location__c> newRecords, Map<Id, sked_Staging_Location__c> oldMap) {
        for (sked_Staging_Location__c newRecord : newRecords) {
            sked_Staging_Location__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.revertAccidientallyChangedGeolocation(newRecord, oldData, 'sked_Address__c', 'sked_GeoLocation__Latitude__s', 'sked_GeoLocation__Longitude__s');
        }
    }

}