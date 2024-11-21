/*------------------------------------------------------------
Author:        	Jack Kittridge
Company:       	Skedulo
Description:   	Trigger Handler for Account Tag custom object
Test Class:     skedAccountTagHandler_Test
------------------------------------------------------------*/
public class skedAccountTagHandler extends skedTriggerHub {
    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            addToJobsAndDriveShifts(this.context.newRecords);
        }
    }

    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            updateTagsOnRelatedObjects(this.context.newRecords, (Map<Id, sked__Account_Tag__c>) this.context.oldMap);
        }
    }

    public override void onAfterDelete() {
        if (!skedSetting.instance.Admin.migrationMode) {
            removeTagsFromRelatedObjects(this.context.oldMap.values());
        }
    }

    /*********************************************************** Privated Methods ***********************************************************/
    private void addToJobsAndDriveShifts(List<sked__Account_Tag__c> newRecords) {
        Database.executeBatch(new skedAccountTagInsertBatch(newRecords), 1);
    }

    private void updateTagsOnRelatedObjects(List<sked__Account_Tag__c> newRecords, Map<Id, sked__Account_Tag__c> oldMap) {
        Database.executeBatch(new skedAccountTagUpdateBatch(newRecords, oldMap), 1);
    }

    private void removeTagsFromRelatedObjects(List<sked__Account_Tag__c> oldValues) {
        Database.executeBatch(new skedAccountTagDeleteBatch(oldValues), 1);
    }
}