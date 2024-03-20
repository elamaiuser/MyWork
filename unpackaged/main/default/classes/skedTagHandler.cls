public class skedTagHandler extends skedTriggerHub {

    public override void onBeforeInsert() {
        validate(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        validate(this.context.newRecords);
    }
    
    public override void onBeforeDelete() {
        validate(this.context.oldMap.values());
    }
    
    /**************************************** Private methods ********************************************/
    private void validate(List<sked__Tag__c> newRecords) {
        if (!skedTriggerHub_Cache.isAdminUser) {
            for (sked__Tag__c newRecord : newRecords) {
                newRecord.addError('Insufficient Privileges: You do not have the level of access necessary to perform this action.');
            }
        }
    }
    
}