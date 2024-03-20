global with sharing class UpdateAMAndDMPortfDailyBatchScheduler implements schedulable{
    global void execute(SchedulableContext sc)
    {
        UpdateAMAndDMPortfolioDailyBatch batch = new UpdateAMAndDMPortfolioDailyBatch();
        database.executebatch(batch);
    }
}