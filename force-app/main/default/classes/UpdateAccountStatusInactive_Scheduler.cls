global class UpdateAccountStatusInactive_Scheduler implements schedulable {
    global integer batchSize = 200;
    public UpdateAccountStatusInactive_Scheduler()
   {
        /* if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }*/
    }
    
    global void execute(SchedulableContext sc)
    {
        BSF_Batch_UpdateAccountStatusInactive batch = new BSF_Batch_UpdateAccountStatusInactive();
        database.executebatch(batch,batchSize);
    }

}