global class skedAutoApprovePTOBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    private Set<Id> recordIds;

    global skedAutoApprovePTOBatch(Set<Id> recordIds) {
        this.recordIds = recordIds;
    }
    
    global List<sObject> start(Database.BatchableContext BC) {
        List<sked_Staffing_Budget__c> staffingBudgets = [SELECT Id
                                                        FROM sked_Staffing_Budget__c
                                                        WHERE Id IN :this.recordIds];
        return staffingBudgets;
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Staffing_Budget__c> newRecords) {
        List<sked__Availability__c> availabilities = [SELECT Id, sked_Ranking__c, sked_Staffing_Budget__c, CreatedDate, sked_Custom_Status__c,
                                                      sked_Recurring_Schedule__c, sked__Resource__r.sked_Seniority_Rank__c,
                                                      sked_Staffing_Budget__r.sked_Bidding_End_Date__c
                                                      FROM sked__Availability__c
                                                      WHERE sked_Staffing_Budget__c IN :newRecords
                                                      AND sked__Is_Available__c = FALSE
                                                      AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO
                                                      AND (sked_Custom_Status__c = :skedConstants.AVAILABILITY_STATUS_WAITLIST OR sked_Custom_Status__c = :skedConstants.AVAILABILITY_STATUS_PENDING)
                                                      AND sked_Staffing_Budget__r.sked_Request_Type__c = :skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT
                                                      ORDER BY sked_Staffing_Budget__c ASC, 
                                                      sked__Resource__r.sked_Seniority_Rank__c ASC NULLS LAST, 
                                                      sked_Recurring_Schedule__c ASC NULLS LAST];
        
        Map<Id, List<sked__Availability__c>> mapStaffingBudget_Availabilities = new Map<Id, List<sked__Availability__c>>();
        for (sked__Availability__c availability : availabilities) {
            List<sked__Availability__c> budgetAvailabilities = mapStaffingBudget_Availabilities.get(availability.sked_Staffing_Budget__c);
            if (budgetAvailabilities == NULL) {
                budgetAvailabilities = new List<sked__Availability__c>();
            }
            budgetAvailabilities.add(availability);
            mapStaffingBudget_Availabilities.put(availability.sked_Staffing_Budget__c, budgetAvailabilities);
        }

        List<sked__Availability__c> updatedAvailabilities = new List<sked__Availability__c>();
        for (List<sked__Availability__c> budgetAvailabilities : mapStaffingBudget_Availabilities.values()) {
            Integer index = 0;
            for (Integer i = 0; i < budgetAvailabilities.size(); i++) {
                sked__Availability__c availability = budgetAvailabilities.get(i);
                if (availability.CreatedDate.date() > availability.sked_Staffing_Budget__r.sked_Bidding_End_Date__c) {
                    availability.sked_Custom_Status__c =  skedConstants.AVAILABILITY_STATUS_DECLINED;
                }
                else {
                    budgetAvailabilities.get(i).sked_Ranking__c = index + 1;
                    index++;
                }
            }
            updatedAvailabilities.addAll(budgetAvailabilities);
        }

        update updatedAvailabilities;
    }
    
    global void finish(Database.BatchableContext BC) {
    }

}