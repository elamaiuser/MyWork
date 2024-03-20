//@Description: this Queueable is triggered from portfolioAssignmentService.updateEndDateOfAccountTeamMembers, when dml limits hits while publishing events for account team update
/* 
* created by Balaji N @7/28/2023
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 
* *
*****************************************************************************
*/
public class AccTeamUpdatePortfolioAssignQueue implements Queueable
{
    List<PortfolioAssignmentUpdateEvent__e> publishEvents = new List<PortfolioAssignmentUpdateEvent__e>();
    List<PortfolioAssignmentUpdateEvent__e> publishEventLimitList = new List<PortfolioAssignmentUpdateEvent__e>();
    @testvisible
    List<PortfolioAssignmentUpdateEvent__e> publishEventNextList = new List<PortfolioAssignmentUpdateEvent__e>();
    
    public AccTeamUpdatePortfolioAssignQueue(List<PortfolioAssignmentUpdateEvent__e> publishEvents)
    {
        this.publishEvents = publishEvents;
    }
    
    public void execute(QueueableContext context) 
    {
        
        //if more than 10k spliting
        if(this.publishEvents.size()>10000)
        {
            for(PortfolioAssignmentUpdateEvent__e eve: this.publishEvents)
            {
                if(publishEventLimitList.size()<10000)
                {
                    publishEventLimitList.add(eve);
                }
                else
                {
                    publishEventNextList.add(eve);//second list for next chained queueable
                }
            }
        }
        else
        {
            publishEventLimitList.addall(this.publishEvents);
        }
        
        
        if(!publishEventLimitList.isEmpty())
        {
            EventBus.publish(publishEventLimitList);
        }
        
        if(!publishEventNextList.isEmpty() && !Test.isRunningTest())
        {
            System.enqueueJob(new AccTeamUpdatePortfolioAssignQueue(publishEventNextList));
        }
    }
}