global with sharing class NotifyAM4BPLRecruitedDailyBatchScheduler implements schedulable {
    global integer batchSize = 200;
    public NotifyAM4BPLRecruitedDailyBatchScheduler(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        NotifyAMforBPLRecruitedDailyBatch batch = new NotifyAMforBPLRecruitedDailyBatch();
        database.executebatch(batch,batchSize);
    }
}