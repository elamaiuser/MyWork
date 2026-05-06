global with sharing class BSF_Batch_UpdateAccountStatusScheduler implements schedulable 
{
 // HRP-16781 fix: Reduced batch size to 200 to 50 to prevent the Too many quey rows: 50001 error.   
 global integer batchSize = 50;
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