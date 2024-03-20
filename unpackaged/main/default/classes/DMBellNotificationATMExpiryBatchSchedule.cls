//Schedule class for Batch:DMBellNotificationForATMExpiryBatch(notify DM for ATM expiry before 3 days)
global with sharing class DMBellNotificationATMExpiryBatchSchedule implements schedulable {
    global integer batchSize = 200;
    public DMBellNotificationATMExpiryBatchSchedule(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        DMBellNotificationForATMExpiryBatch batch = new DMBellNotificationForATMExpiryBatch();
        database.executebatch(batch,batchSize);
        
        
    }
}