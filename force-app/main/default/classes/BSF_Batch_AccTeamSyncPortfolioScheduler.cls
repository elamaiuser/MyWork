//@Description: Schedule class for Batch Apex BSF_Batch_AccTeamSyncPortfolio 
/* 
* Modification Log 
* Date                       Developer Name              Comments
* ***********************************************************************************************************************************************
* 01/24/2024                  Balaji N                   Implementation of the class
*                                                     
* *
*************************************************************************************************************************************************
*/
global class BSF_Batch_AccTeamSyncPortfolioScheduler implements schedulable 
{

    global integer batchSize = 200;
    public BSF_Batch_AccTeamSyncPortfolioScheduler(integer batchSize)
    {
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    
    public BSF_Batch_AccTeamSyncPortfolioScheduler()
    {
    }
    global void execute(SchedulableContext sc)
    {
        BSF_Batch_AccTeamSyncPortfolio batch = new BSF_Batch_AccTeamSyncPortfolio();
        database.executebatch(batch,batchSize);
    }
}