global class BatchAcctsOpptyUpdateOnCZipCodeSchedule implements schedulable {
    global integer batchSize = 200;
    public BatchAcctsOpptyUpdateOnCZipCodeSchedule(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
     
    global void execute(SchedulableContext sc)
    {
        BatchAccoutsOpptyUpdateOnCZipCode batch = new BatchAccoutsOpptyUpdateOnCZipCode();
        database.executebatch(batch,batchSize);
    }
}