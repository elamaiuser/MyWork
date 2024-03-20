global class skedProcessBiddingPTOSchedulable implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        doProcessBiddingPTO();
    }
    
    public void doProcessBiddingPTO() {
        Set<Id> staffingBudgetIds = new Set<Id>();
        List<sked_Staffing_Budget__c> staffingBudgets = [SELECT Id
                                                         FROM sked_Staffing_Budget__c
                                                         WHERE sked_Request_Type__c = :skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT
                                                         AND sked_Bidding_End_Date__c = YESTERDAY];
        for (sked_Staffing_Budget__c staffingBudget : staffingBudgets) {
            staffingBudgetIds.add(staffingBudget.Id);
        }
        if (!staffingBudgetIds.isEmpty()) {
            skedAutoApprovePTOBatch ptoBatch = new skedAutoApprovePTOBatch(staffingBudgetIds);
            Database.executeBatch(ptoBatch, 10);
        }
    }
    
}