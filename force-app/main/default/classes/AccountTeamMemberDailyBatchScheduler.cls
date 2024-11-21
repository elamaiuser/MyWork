global with sharing class AccountTeamMemberDailyBatchScheduler implements schedulable{
    global void execute(SchedulableContext sc)
    {
        UpdateAccountTeamMemberDailyBatch batch = new UpdateAccountTeamMemberDailyBatch();
        database.executebatch(batch);
    }
}