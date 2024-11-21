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
}