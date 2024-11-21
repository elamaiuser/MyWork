global with sharing class UpdateCallListRecipientBatchSchedule implements schedulable {
	global integer batchSize = 200;
    
    public UpdateCallListRecipientBatchSchedule(integer batchSize){
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    global void execute(SchedulableContext sc)
    {
        UpdateCallListRecipientBatch batch = new UpdateCallListRecipientBatch();
        database.executebatch(batch,batchSize);
    }
}