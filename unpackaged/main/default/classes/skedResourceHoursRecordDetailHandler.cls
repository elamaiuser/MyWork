public class skedResourceHoursRecordDetailHandler extends skedTriggerHub {
    public override void onAfterInsert() {
        calculateResourceHoursRecordTotalWorkingDays(this.context.newRecords);
    }

    public override void onAfterDelete() {
        calculateResoruceHoursRecordTotalWorkingDays(this.context.oldRecords);
    }

    /*********************************************************** Privated Methods ***********************************************************/
    private void calculateResourceHoursRecordTotalWorkingDays(List<sked_Resource_Hours_Record_Detail__c> newRecords) {
        skedResourceHoursRecordUtils.countTotalWorkingDays(new List<Id>(getResourceHoursRecordIds(newRecords)));
    }

    private void calculateResoruceHoursRecordTotalWorkingDays(List<sked_Resource_Hours_Record_Detail__c> oldRecords) {
        skedResourceHoursRecordUtils.countTotalWorkingDays(new List<Id>(getResourceHoursRecordIds(oldRecords)));
    }

    private Set<Id> getResourceHoursRecordIds(List<sked_Resource_Hours_Record_Detail__c> records) {
        Set<Id> resourceHoursRecordIds = new Set<Id>();

        for (sked_Resource_Hours_Record_Detail__c record : records) {
            resourceHoursRecordIds.add(record.sked_Resource_Hours_Record__c);
        }

        return resourceHoursRecordIds;
    }
}