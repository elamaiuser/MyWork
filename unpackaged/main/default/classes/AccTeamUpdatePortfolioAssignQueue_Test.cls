@isTest
public class AccTeamUpdatePortfolioAssignQueue_Test 
{
	
    
    @isTest static void testMethod1()
     {
         List<PortfolioAssignmentUpdateEvent__e> publishEvent =new List<PortfolioAssignmentUpdateEvent__e>();
         for(integer i=0;i<=10000;i++)
        {
                        PortfolioAssignmentUpdateEvent__e eve = new PortfolioAssignmentUpdateEvent__e();
                        eve.AccountTeamMemberId__c = 'teamMember'+i ;
                        eve.StartDate__c=system.today().addDays(i);
                        eve.EndDate__c=eve.StartDate__c.addDays(i+i); 
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
         List<PortfolioAssignmentUpdateEvent__e> publishEvent =new List<PortfolioAssignmentUpdateEvent__e>();
         for(integer i=0;i<10000;i++)
        {
                        PortfolioAssignmentUpdateEvent__e eve = new PortfolioAssignmentUpdateEvent__e();
                        eve.AccountTeamMemberId__c = 'teamMember'+i ;
                        eve.StartDate__c=system.today().addDays(i);
                        eve.EndDate__c=eve.StartDate__c.addDays(i+i); 
                    	publishEvent.add(eve);
        }
		
         test.startTest();
         AccTeamUpdatePortfolioAssignQueue accTeamQueue =new AccTeamUpdatePortfolioAssignQueue(publishEvent);
         System.enqueueJob(accTeamQueue);
         test.stopTest();
         
        Assert.istrue(accTeamQueue.publishEventNextList.size()==0);
     }
}