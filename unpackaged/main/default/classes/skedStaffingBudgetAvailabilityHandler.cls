public class skedStaffingBudgetAvailabilityHandler extends skedTriggerHub {
    public override void onAfterInsert() {
        updateAvailabilityBiddingType(this.context.newRecords);
    }

    public override void onAfterUpdate() {
        updateAvailabilityBiddingType(this.context.newRecords);
    }

    public override void onAfterDelete() {
        updateAvailabilityBiddingType(this.context.oldRecords);
    }

    ////////////////////////// PRIVATE METHODS //////////////////////////
    private void updateAvailabilityBiddingType(List<sked_Staffing_Budget_Availability__c> records) {
        Set<Id> affectedAvailabilityIds = new Set<Id>();
        for (sked_Staffing_Budget_Availability__c record : records) {
            affectedAvailabilityIds.add(record.sked_Availability__c);
        }

        skedStaffingBudgetUtils.updateAvailabilityBiddingType(affectedAvailabilityIds);
    }

}