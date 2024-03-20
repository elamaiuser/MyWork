global with sharing class CreateTaskDM_ABMDailyBatchScheduler implements schedulable{
    global integer batchSize = 200;
    public CreateTaskDM_ABMDailyBatchScheduler(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        CreateTaskDM_ABMDailyBatch batch = new CreateTaskDM_ABMDailyBatch();
        database.executebatch(batch,batchSize);
    }
}