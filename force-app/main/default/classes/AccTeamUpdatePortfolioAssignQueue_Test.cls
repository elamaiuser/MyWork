@isTest
public class AccTeamUpdatePortfolioAssignQueue_Test 
{
	
    
    @isTest static void testMethod1()
     {
         List<PortfolioAssignmentEvent__e> publishEvent =new List<PortfolioAssignmentEvent__e>();
         for(integer i=0;i<=10000;i++)
        {
                        PortfolioAssignmentEvent__e eve = new PortfolioAssignmentEvent__e();
                        eve.Id__c = 'teamMember'+i ;
                    	publishEvent.add(eve);
        }
		
         test.startTest();
         AccTeamUpdatePortfolioAssignQueue accTeamQueue =new AccTeamUpdatePortfolioAssignQueue(publishEvent);
         System.enqueueJob(accTeamQueue);
         test.stopTest();
         
        Assert.isNotNull(accTeamQueue.publishEventNextList);
     }
    
    @isTest static void testMethod2()
     {
         List<PortfolioAssignmentEvent__e> publishEvent =new List<PortfolioAssignmentEvent__e>();
         for(integer i=0;i<10000;i++)
        {
                        PortfolioAssignmentEvent__e eve = new PortfolioAssignmentEvent__e();
                        eve.Id__c = 'teamMember'+i ;
                        publishEvent.add(eve);
        }
		
         test.startTest();
         AccTeamUpdatePortfolioAssignQueue accTeamQueue =new AccTeamUpdatePortfolioAssignQueue(publishEvent);
         System.enqueueJob(accTeamQueue);
         test.stopTest();
         
        Assert.istrue(accTeamQueue.publishEventNextList.size()==0);
     }
}