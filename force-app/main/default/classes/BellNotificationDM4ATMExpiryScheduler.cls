global class BellNotificationDM4ATMExpiryScheduler implements schedulable {
    global integer batchSize = 200;
    public BellNotificationDM4ATMExpiryScheduler(integer batchSize)
    {
        if(batchSize!=0)
        {
            this.batchSize=batchSize;
        }
    }
    
    global void execute(SchedulableContext sc)
    {
        SendBellNotificationDM4ATMExpiring3days batch = new SendBellNotificationDM4ATMExpiring3days();
        database.executebatch(batch,batchSize);
    }
}