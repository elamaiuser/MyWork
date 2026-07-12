public class skedStaffingBudgetHandler extends skedTriggerHub {
    public override void onAfterUpdate() {
        updateAvailabilityBiddingType(this.context.newRecords, (Map<Id, sked_Staffing_Budget__c>)this.context.oldMap);
        //autoFillWaitlistSlots(this.context.newRecords, (Map<Id, sked_Staffing_Budget__c>) this.context.oldMap);
    }

    ///////// Private Methods /////////
    private void updateAvailabilityBiddingType(List<sked_Staffing_Budget__c> newRecords, Map<Id, sked_Staffing_Budget__c> oldMap) {
        Set<Id> staffingBudgetIdsToProcess = new Set<Id>();
        for (sked_Staffing_Budget__c record : newRecords) {
            sked_Staffing_Budget__c oldRecord = oldMap.get(record.Id);
            if (record.sked_Request_Type__c != oldRecord.sked_Request_Type__c) {
                staffingBudgetIdsToProcess.add(record.Id);
            }
        }

        if (!staffingBudgetIdsToProcess.isEmpty()) {
            skedStaffingBudgetUtils.updateAvailabilityBiddingTypeByStaffingBudgets(staffingBudgetIdsToProcess);
        }
    }

    // private void autoFillWaitlistSlots(List<sked_Staffing_Budget__c> newRecords, Map<Id, sked_Staffing_Budget__c> oldMap) {
    //     Set<Id> affectedStaffingBudgetIds = new Set<Id>();
    //     for (sked_Staffing_Budget__c record : newRecords) {
    //         sked_Staffing_Budget__c oldRecord = oldMap.get(record.Id);

    //         if (record.sked_Request_Type__c == skedConstants.STAFFING_BUDGET_REQUEST_TYPE_STANDARD &&
    //                 record.sked_Available_Slots__c > oldRecord.sked_Available_Slots__c) {
    //             affectedStaffingBudgetIds.add(record.Id);
    //         }
    //     }

    //     if (!affectedStaffingBudgetIds.isEmpty()) {
    //         skedStaffingBudgetUtils.publishAutofillEvent(affectedStaffingBudgetIds);
    //     }
    // }
}