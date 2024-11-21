Global with sharing class UpdateATMDailyBatchScheduler implements schedulable {
    global integer batchSize = 200;
    public UpdateATMDailyBatchScheduler(integer batchSize)
    {
        If(batchSize!=0)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        UpdateAccountTeamMemberDailyBatch batch = new UpdateAccountTeamMemberDailyBatch();
        database.executebatch(batch,batchSize);
    }
}