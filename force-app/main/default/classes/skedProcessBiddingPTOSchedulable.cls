global class skedProcessBiddingPTOSchedulable implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        expireOutdatedRequests();
        processBiddingRanking();
        convertBiddingToStandard();
        runAutofillPTOSlotsBatch();
    }

    private void convertBiddingToStandard() {
        List<sked_Staffing_Budget__c> sbs = [
            SELECT Id, sked_Request_Type__c
            FROM sked_Staffing_Budget__c
            WHERE sked_Convert_to_Standard_On__c = YESTERDAY
        ];

        for (sked_Staffing_Budget__c sb : sbs) {
            sb.sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_STANDARD;
        }

        update sbs;
    }

    private void runAutofillPTOSlotsBatch() {
        Set<Id> staffingBudgetIds = new Set<Id>();

        for (sked_Staffing_Budget_Availability__c sba : [
            SELECT Id, sked_Staffing_Budget__c
            FROM sked_Staffing_Budget_Availability__c
            WHERE sked_Availability__r.sked__Status__c IN :skedConstants.AVAILABILITY_PENDING_STATUSES
            AND sked_Staffing_Budget__r.sked_Request_Type__c = :skedConstants.STAFFING_BUDGET_REQUEST_TYPE_STANDARD
            AND sked_Availability__r.sked_Workday_Sync_Status__c NOT IN (:skedConstants.AVAILABILITY_APPROVAL_REASON_WORKDAY_SYNC_FAILURE, :skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_MANUAL)
            LIMIT :skedSetting.instance.Admin.nightlyMaxAutoApprovalRequests
        ]) {
            staffingBudgetIds.add(sba.sked_Staffing_Budget__c);
        }

        if (!staffingBudgetIds.isEmpty()) {
            Database.executeBatch(new skedNightlyAutofillPTOSlotsBatch(staffingBudgetIds), 1);
        }
    }
    
    public void processBiddingRanking() {
        Set<Id> staffingBudgetIds = new Set<Id>();
        List<sked_Staffing_Budget__c> staffingBudgets = [
            SELECT Id
            FROM sked_Staffing_Budget__c
            WHERE sked_Request_Type__c = :skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT
            AND sked_Bidding_End_Date__c = YESTERDAY
        ];
        for (sked_Staffing_Budget__c staffingBudget : staffingBudgets) {
            staffingBudgetIds.add(staffingBudget.Id);
        }
        if (!staffingBudgetIds.isEmpty()) {
            skedAutoApprovePTOBatch ptoBatch = new skedAutoApprovePTOBatch(staffingBudgetIds);
            Database.executeBatch(ptoBatch, 10);
        }
    }

    public void expireOutdatedRequests() {
        Date dateToAutoExpire = System.today().addDays(-skedSetting.instance.Admin.numAutoExpireDays);
        Set<String> unavailabilityTypes = skedWorkdayUtils.getUnavailabilityTypesToSync();

        List<sked__Availability__c> availabilitiesToUpdate = [
            SELECT Id, sked_Custom_Status__c
            FROM sked__Availability__c
            WHERE sked__Is_Available__c = FALSE
            AND sked__Type__c IN :unavailabilityTypes
            AND (sked_Custom_Status__c IN :skedConstants.AVAILABILITY_PENDING_STATUSES)
            AND (sked_Workday_Sync_Status__c NOT IN (:skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_FAILED, :skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_MANUAL))
            AND CreatedDate <= :dateToAutoExpire
            AND sked__Start__c >= TODAY
            AND sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c != null
            ORDER BY CreatedDate ASC
        ];

        for (sked__Availability__c avail : availabilitiesToUpdate) {
            avail.sked_Custom_Status__c = avail.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_WAITLIST ?
                skedConstants.AVAILABILITY_STATUS_WAITLIST_EXPIRED : skedConstants.AVAILABILITY_STATUS_PENDING_EXPIRED;
        }

        if (!availabilitiesToUpdate.isEmpty()) {
            update availabilitiesToUpdate;
        }
    }
}