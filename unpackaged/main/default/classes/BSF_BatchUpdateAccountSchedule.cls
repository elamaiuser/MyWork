global with sharing class BSF_BatchUpdateAccountSchedule implements schedulable {
	global integer batchSize = 200;
    
    public BSF_BatchUpdateAccountSchedule(integer batchSize){
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    global void execute(SchedulableContext sc)
    {
        BSF_BatchUpdateAccountForZipCode batch = new BSF_BatchUpdateAccountForZipCode();
        database.executebatch(batch,batchSize);
    }
}