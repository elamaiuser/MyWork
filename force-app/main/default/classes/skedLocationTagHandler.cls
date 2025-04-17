/*------------------------------------------------------------
Author:        	Jack Kittridge
Company:       	Skedulo
Description:   	Trigger Handler for Location Tag custom object
Test Class:     skedLocationTagHandler_Test
------------------------------------------------------------*/
public class skedLocationTagHandler extends skedTriggerHub {
    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            addToJobsAndDriveShifts(this.context.newRecords);
            updateRealIDFlagOnLocations(this.context.newRecords, true);
        }
    }

    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            updateTagsOnRelatedObjects(this.context.newRecords, (Map<Id, sked_Location_Tag__c>) this.context.oldMap);
        }
    }

    public override void onAfterDelete() {
        if (!skedSetting.instance.Admin.migrationMode) {
            removeTagsFromRelatedObjects(this.context.oldMap.values());
            updateRealIDFlagOnLocations(this.context.oldMap.values(), false);
        }
    }

    /*********************************************************** Privated Methods ***********************************************************/
    private void addToJobsAndDriveShifts(List<sked_Location_Tag__c> newRecords) {
        Database.executeBatch(new skedLocationTagInsertBatch(newRecords), 1);
    }

    private void updateTagsOnRelatedObjects(List<sked_Location_Tag__c> newRecords, Map<Id, sked_Location_Tag__c> oldMap) {
        Database.executeBatch(new skedLocationTagUpdateBatch(newRecords, oldMap), 1);
    }

    private void removeTagsFromRelatedObjects(List<sked_Location_Tag__c> oldValues) {
        Database.executeBatch(new skedLocationTagDeleteBatch(oldValues), 1);
    }

    private void updateRealIDFlagOnLocations(List<sked_Location_Tag__c> locationTags, Boolean isInsert) {        
        Set<Id> locationIdsToProcess = new Set<Id>();
        Map<Id, Boolean> locationIdToRealIDMap = new Map<Id, Boolean>();
        
        for (sked_Location_Tag__c locationTag : locationTags) {            
            if (locationTag.sked_Tag__c != null && getTagName(locationTag.sked_Tag__c) == skedConstants.TAG_REAL_ID) {
                locationIdsToProcess.add(locationTag.sked_Location__c);
                locationIdToRealIDMap.put(locationTag.sked_Location__c, isInsert);
            }
        }        
        List<sked__Location__c> locationsToUpdate = new List<sked__Location__c>();
        for (Id locationId : locationIdToRealIDMap.keySet()) {
            locationsToUpdate.add(new sked__Location__c(
                Id = locationId,
                sked_Real_ID_Required__c = locationIdToRealIDMap.get(locationId)
            ));
        }
        if (!locationsToUpdate.isEmpty()) {
            update locationsToUpdate;
        }
    }

    private String getTagName(Id tagId) {
        try{
            return [SELECT Name FROM sked__Tag__c WHERE Id = :tagId AND sked__Type__c = :skedConstants.TAG_TYPE_CERTIFICATION].Name;
        }
        catch (Exception e) {
            return '';
        }
    }
}