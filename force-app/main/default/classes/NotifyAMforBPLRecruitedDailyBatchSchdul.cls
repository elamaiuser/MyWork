global with sharing class NotifyAMforBPLRecruitedDailyBatchSchdul implements schedulable{
    
        global integer batchSize = 200;
    public NotifyAMforBPLRecruitedDailyBatchSchdul(integer batchSize)
    {
        if(batchSize!=0)
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