//@Description: this Queueable is triggered from portfolioAssignmentService.publishPlarformEventsOnAfterInsert, when dml limits hits while publishing events for account team update
/* 
* created by Balaji N @7/28/2023
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 08/05/2024				 Balaji N 					 Logic for HRP-13028(Changed PortfolioAssignmentUpdateEvent to PortfolioAssignmentEvent__e)
* *
*****************************************************************************
*/
public class AccTeamUpdatePortfolioAssignQueue implements Queueable
{
    List<PortfolioAssignmentEvent__e> publishEvents = new List<PortfolioAssignmentEvent__e>();
    List<PortfolioAssignmentEvent__e> publishEventLimitList = new List<PortfolioAssignmentEvent__e>();
    @testvisible
    List<PortfolioAssignmentEvent__e> publishEventNextList = new List<PortfolioAssignmentEvent__e>();
    
    public AccTeamUpdatePortfolioAssignQueue(List<PortfolioAssignmentEvent__e> publishEvents)
    {
        this.publishEvents = publishEvents;
    }
    
    public void execute(QueueableContext context) 
    {
        
        //if more than 10k spliting
        if(this.publishEvents.size()>10000)
        {
            for(PortfolioAssignmentEvent__e eve: this.publishEvents)
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