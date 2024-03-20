global with sharing class BSF_BatchUpdateOpportunitySchedule implements schedulable {
	global integer batchSize = 200;
    
    public BSF_BatchUpdateOpportunitySchedule(integer batchSize){
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    global void execute(SchedulableContext sc)
    {
        BSF_BatchUpdateOpportunityForZipCode batch = new BSF_BatchUpdateOpportunityForZipCode();
        database.executebatch(batch,batchSize);
    }
}