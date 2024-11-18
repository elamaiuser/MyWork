public class skedNightlyAutofillPTOSlotsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    Set<Id> staffingBudgetIds;

    public skedNightlyAutofillPTOSlotsBatch(Set<Id> staffingBudgetIds) {
        this.staffingBudgetIds = staffingBudgetIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM sked_Staffing_Budget__c
            WHERE Id IN :staffingBudgetIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<sked_Staffing_Budget__c> staffingBudgets) {
        Set<Id> staffingBudgetBatchIds = new Set<Id>();
        for(sked_Staffing_Budget__c staffingBudget : staffingBudgets){
            staffingBudgetBatchIds.add(staffingBudget.Id);            
        }
        skedStaffingBudgetUtils.autofillStaffingBudgetSlotsFromWaitlist(staffingBudgetBatchIds);
    }

    public void finish(Database.BatchableContext bc) {}
}