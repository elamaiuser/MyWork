public class skedCancelAvailabilityPatternBatch  implements Database.Batchable<sked__Availability__c>, Database.Stateful {
    private static final Set<String> cancelledStatuses = new Set<String>{skedConstants.AVAILABILITY_STATUS_DECLINED, skedConstants.AVAILABILITY_STATUS_CANCELLED};
    String bulkAction;
    sked__Availability__c cancelledAvailability;
    Id recurringScheduleId;
    Id initiatedById;

    public skedCancelAvailabilityPatternBatch(sked__Availability__c cancelledAvailability, Id recurringScheduleId, String bulkAction, Id initiatedById) {
        this.cancelledAvailability = cancelledAvailability;
        this.recurringScheduleId = recurringScheduleId;
        this.bulkAction = bulkAction;
        this.initiatedById = initiatedById;
    }

    public List<sked__Availability__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked_Start_Date__c, sked_Workday_Sync_Status__c, sked_Integrate_With_Workday__c, sked_Approval_Reason__c
            FROM sked__Availability__c
            WHERE (sked_Recurring_Schedule__c = :recurringScheduleId OR Id = :cancelledAvailability.Id)
            AND sked__Status__c NOT IN :cancelledStatuses
            LIMIT 2000
        ];
    }

    public void execute(Database.BatchableContext BC, List<sked__Availability__c> availabilities) {
        List<sked__Availability__c> availabilitiesToUpdate = new List<sked__Availability__c>();
        for(sked__Availability__c availability : availabilities){
            Boolean cancelAvailability = false;
            if (bulkAction == 'following_events') {
                if (availability.sked_Start_Date__c >= cancelledAvailability.sked_Start_Date__c) {
                    cancelAvailability = true;
                }
            } else if (bulkAction == 'same_weekday'){
                if (Math.mod(availability.sked_Start_Date__c.daysBetween(cancelledAvailability.sked_Start_Date__c), 7) == 0){
                    cancelAvailability = true;
                }
            } else if (bulkAction == 'all_events') {
                cancelAvailability = true;
            }

            if (cancelAvailability) {
                if (availability.sked_Workday_Sync_Status__c == skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_MANUAL && !skedTriggerUtils.isUserAPS(this.initiatedById)) {
                    availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PENDING;
                    availability.sked_Approval_Reason__c = skedConstants.AVAILABILITY_APPROVAL_REASON_WORKDAY_CANCELLATION_REQUIRED;
                } else if (availability.sked_Integrate_With_Workday__c && availability.sked_Workday_Sync_Status__c == skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_SUCCESS) {
                    availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PROCESSING_CANCELLATION;
                } else {
                    availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_CANCELLED;
                }
                availabilitiesToUpdate.add(availability);
            }
        }

        if (!availabilitiesToUpdate.isEmpty()) {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            update availabilitiesToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        String subject = 'Process Completed';
        String htmlBody = 'Dear ' + UserInfo.getName() + ',' +
        '\n\nA batch process cancelling availability records has completed. Please see the Resource Availability Console to review all changes';
        skedEmailService.emailModel emailModel = new skedEmailService.emailModel();
        emailModel.htmlBody = htmlBody;
        emailModel.subject = subject;
        emailModel.toList = new List<String>{UserInfo.getUserEmail()};
        skedEmailService service = new skedEmailService();
        if (!Test.isRunningTest()) {
            service.sendEmails(new List<skedEmailService.emailModel>{emailModel});
        }
    }
}