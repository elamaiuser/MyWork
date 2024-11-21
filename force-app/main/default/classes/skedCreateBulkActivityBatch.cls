public class skedCreateBulkActivityBatch implements Database.Batchable<skedModels.event>, Database.Stateful {
    skedModels.recurringSchedule recurringSchedule;
    User initByUser;
    Integer offset;
    Integer newOffset;

    public skedCreateBulkActivityBatch(skedModels.recurringSchedule recurringSchedule, Id initByUserId, Integer offset) {
        this.recurringSchedule = recurringSchedule;
        this.initByUser = [SELECT Id, Name, Email FROM User WHERE Id = :initByUserId];
        this.offset = offset;
    }

    public List<skedModels.event> start(Database.BatchableContext BC) {
        List<skedModels.event> activities = new List<skedModels.event>();

        Integer newOffset = this.offset + 200;
        if (newOffset > this.recurringSchedule.events.size()) {
            newOffset = this.recurringSchedule.events.size();
        }

        for (Integer i = this.offset; i < newOffset; i++) {
            activities.add(this.recurringSchedule.events[i]);
        }
        this.newOffset = newOffset;
        return activities;
    }

    public void execute(Database.BatchableContext BC, List<skedModels.event> activities) {
        skedModels.recurringSchedule tempRecurringSchedule = (skedModels.recurringSchedule) JSON.deserialize(JSON.serialize(this.recurringSchedule), skedModels.recurringSchedule.class);
        tempRecurringSchedule.events = activities;

        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        skedActivityService activityService = (skedActivityService) skedServiceFactory.instance.resolve('sked__Activity__c');
        activityService.saveRecurringSchedule(tempRecurringSchedule);
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = FALSE;
    }

    public void finish(Database.BatchableContext BC) {
        if (this.newOffset < this.recurringSchedule.events.size()) {
            Database.executeBatch(new skedCreateBulkActivityBatch(this.recurringSchedule, initByUser.Id, this.newOffset));
        } else {
            String subject = 'Process Completed';
            String htmlBody = 'Dear ' + this.initByUser.Name + ',' +
            '\n\nA batch process creating Activity records has completed. Please see the Resource Availability Console to review all changes';
            skedEmailService.emailModel emailModel = new skedEmailService.emailModel();
            emailModel.htmlBody = htmlBody;
            emailModel.subject = subject;
            emailModel.toList = new List<String>{this.initByUser.Email};
            skedEmailService service = new skedEmailService();
            if (!Test.isRunningTest()) {
                service.sendEmails(new List<skedEmailService.emailModel>{emailModel});
            }
        }
    }
}