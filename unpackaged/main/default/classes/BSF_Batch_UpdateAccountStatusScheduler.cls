global with sharing class BSF_Batch_UpdateAccountStatusScheduler implements schedulable 
{
 global integer batchSize = 200;
    public BSF_Batch_UpdateAccountStatusScheduler(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        BSF_Batch_UpdateAccountStatus batch = new BSF_Batch_UpdateAccountStatus();
        database.executebatch(batch,batchSize);
    }
}