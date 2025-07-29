public class skedAvailabilityPatternHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_PERMISSIONS, new List<String>{'System Administrator'}, false);
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_PERMISSIONS, new List<String>{'System Administrator'}, false);
    }
    
    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.oldRecords, skedConstants.RECORD_CHANGES_INVALID_PERMISSIONS, new List<String>{'System Administrator'}, false);
    }
    
}