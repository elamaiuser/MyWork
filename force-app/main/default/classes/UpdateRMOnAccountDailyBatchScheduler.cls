global with sharing class UpdateRMOnAccountDailyBatchScheduler implements schedulable{
    global integer batchSize = 200;
    public UpdateRMOnAccountDailyBatchScheduler(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }


	global void execute(SchedulableContext sc)
    {
        UpdateRMLookUpOnAccountDailyBatch batch = new UpdateRMLookUpOnAccountDailyBatch();
        database.executebatch(batch);
    }
}