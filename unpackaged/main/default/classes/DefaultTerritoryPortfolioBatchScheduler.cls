global with sharing class DefaultTerritoryPortfolioBatchScheduler implements schedulable{
    global integer batchSize = 200;
    public DefaultTerritoryPortfolioBatchScheduler(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    global void execute(SchedulableContext sc)
    {
        CreateDefaultTerritoryPortfolioBatch batch = new CreateDefaultTerritoryPortfolioBatch();
        database.executebatch(batch,batchSize);
    }
}