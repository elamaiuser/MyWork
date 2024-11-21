public class skedOppDriveSyncSchedulable implements Schedulable {
    
    public void execute(SchedulableContext SC) {
        string oppDOCSyncErrorEmail = skedSetting.instance.Email.bitTechnicalSupport;
        if (string.isBlank(oppDOCSyncErrorEmail)) {
            oppDOCSyncErrorEmail = 'hemaspherebussup@redcross.org';
        }
        Database.executeBatch(new skedOppDriveSyncBatch(new List<String>{oppDOCSyncErrorEmail}), 20);
    }
    
}