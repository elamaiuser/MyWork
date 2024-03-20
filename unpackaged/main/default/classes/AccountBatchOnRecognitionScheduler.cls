global with sharing class AccountBatchOnRecognitionScheduler implements Schedulable {
     global integer batchSize = 200;
    public AccountBatchOnRecognitionScheduler(integer batchSize)
    {
        If(batchSize!=NULL)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        AccountBatchOnRecognition batch = new AccountBatchOnRecognition();
        database.executebatch(batch,batchSize);
    }

}