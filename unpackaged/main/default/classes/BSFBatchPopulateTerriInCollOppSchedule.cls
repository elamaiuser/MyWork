Global with sharing class BSFBatchPopulateTerriInCollOppSchedule implements schedulable
{
    global integer batchSize = 200;
    public BSFBatchPopulateTerriInCollOppSchedule(integer batchSize)
    {
        If(batchSize!=0)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        BSF_Batch_PopulateTerritoryInCollOpp batch = new BSF_Batch_PopulateTerritoryInCollOpp();
        database.executebatch(batch,batchSize);
    }
}