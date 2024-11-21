global with sharing class createPublicityTask 
{
    global class getValues {
        @InvocableVariable(required=true)
        global Id orderId;
        
        @InvocableVariable(required=true)
        global Id accountManagerId;
        
        @InvocableVariable(required=true)
        global Date driveDate;
        
        @InvocableVariable(required=true)
        global String stageName;
    } 
    
    @InvocableMethod(label='Publicity Review Needed Task Creation')
    global static void stageCheckAndTaskCreation(List<getValues> listOfValues)
    {
      List<Task> publicityReviewTask = new List<Task>();
      Task t = new Task(); 
      for(getValues val: listOfValues)
      {  
      	List<Order> orderList = [select id , OpportunityId, Opportunity.StageName from Order where id = :val.orderId];
        if(orderList.size()>0)
        {
        	String stageNameOfRelatedOpp = orderList[0].Opportunity.StageName;
        	if(stageNameOfRelatedOpp == 'Closed')
        	{
          		t.Subject = 'Publicity Review Needed';
            	t.Status = 'Not Started';
            	t.Priority = 'High';
            	t.WhatId = val.orderId;
            	t.OwnerId = val.accountManagerId;
            	Date dueDate = val.driveDate - Integer.valueOf(system.Label.Publicity_Review_Days_Configuration);
            	String myDateString = Datetime.newInstance(dueDate.year(),dueDate.month(),dueDate.day()).format('EEE');
            	if('Sat'.equals(myDateString)){
                	t.ActivityDate=dueDate - 1;
            	}
            	else if('Sun'.equals(myDateString)){
                	t.ActivityDate = dueDate - 2;
            	}
            	else{
                	t.ActivityDate = dueDate;
            	}
            	publicityReviewTask.add(t);
        	}
      	}
    }
    	if(publicityReviewTask.size()>0)
    	{
      		Database.SaveResult[] srList = Database.insert(publicityReviewTask, true);
      		for (Database.SaveResult sr : srList) 
      		{
                for(Database.Error err : sr.getErrors())
                 {
    					if (!sr.isSuccess()) 
        				{
           					System.debug('The following error occured - '+err.getMessage());
           					System.debug('Fields that affected this error: ' + err.getFields()); 
        				}
                 }
    		}
       
 		}
        
    }
}