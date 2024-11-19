/********************************************************************************************
@ Component Name : BSF_Batch_CreatePublicityTasksOnOrders 
@ Developed By: Exavalu / ARC 
@ purpose: Create Publicity Tasks on Orders when it's created with publicity approved = false 
					and related opp is moved to Closed stage with No Publicity Needed = false 

**********************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 05/03/2023                   	 Exavalu / ARC                HRP - 10023 Created
* 03/22/2024					 Balaji N				  	  logic for HRP-12333 (Method: Execute method, changes in parameter and Hierarchy logic, Changes on the method calls OpportunityService.getTaskOwner)
* 08/13/2024					 Apurba Bhattacharjee		  HRP-12700 Add Drive Date to task list
**********************************************************************************************/

global class BSF_Batch_CreatePublicityTasksOnOrders implements Database.Batchable<sObject> , Schedulable
{
    
    // retreiving orders based on initial conditions
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        
        String query = 'select id, Publicity_Approved__c, OpportunityId, Opportunity.StageName, Opportunity.No_Publicity_Needed__c,'+
            			'Opportunity.Drive_Date__c from Order '+
            			'where Publicity_Approved__c = false and '+
            			'Opportunity.No_Publicity_Needed__c = false and '+
            			'Opportunity.StageName = \'Closed\' and '+
            			'Opportunity.Drive_Date__c >= TODAY';
        
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.BatchableContext BC, List<Order> scope) 
    {
        // Create a set of Id to store eligible orders' opportunityId
        Set<Id> oppIdsRelatedToOrders = new Set<Id>();
       
        // Create a set of Id to store non-eligible orders' Id to exclude them for further processing
        Set<Id> notEligibleOrderIds = new Set<Id>();
        
        // Create a List of task to store pre existing publicity tasks
        List<Task> preExistingTaskList = new List<Task>(); 
        
        Map<Id,Order> orderMap = new Map<Id,Order>();

        // Create a List of order to store eligible orders
        List<Order> eligibleOrdersList = new List<Order>();
        
        // Create a List of task to store publicity tasks to be created
        List<Task> publicityReviewTasksList = new List<Task>();     
                
        // Create a Map to store OpportunityTeamMembers by OpportunityId
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
      
      	for(Order orders : scope)
      	{                
           	if(orders.Opportunity.Drive_Date__c - BSF_Constants.PUBLICITY_REVIEW_DAYS_CONFIGURATION <= system.today())
           	{
                 orderMap.put(orders.Id,orders);
           	}
      	}
        // checking for existing tasks to avoid generating duplicate tasks 
        if(orderMap != null)
        {		       
            preExistingTaskList = [select Id ,whatId, subject from Task where whatId IN :orderMap.keySet() and subject =:BSF_Constants.PUBLICITY_REVIEW_NEEDED_TASK];
            
            for(Task t : preExistingTaskList)
            {
               notEligibleOrderIds.add(t.whatId);
            }
            
            for(Order orderObj : orderMap.values())
            {
                if(notEligibleOrderIds.isEmpty() || !notEligibleOrderIds.contains(orderObj.Id))
                {
                    eligibleOrdersList.add(orderObj);
                    oppIdsRelatedToOrders.add(orderObj.OpportunityId);
                }
            }
        }
        Map<Id,Opportunity> oppRelatedToOrderMap = new Map<Id,Opportunity>([select Id, Drive_Date__c, Account_Manager__c, OwnerId from Opportunity
                                                                           where Id IN :oppIdsRelatedToOrders]);
        
        
        //part of HRP-9562 --> Start
        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :oppRelatedToOrderMap.keySet()
                                                                ];       
        
        
        if(allOpportunityTeamMembers != null)
        {
            for (OpportunityTeamMember oppTeamMembers : allOpportunityTeamMembers) {
                if (!oppTeamMembersMap.containsKey(oppTeamMembers.OpportunityId)) {
                    oppTeamMembersMap.put(oppTeamMembers.OpportunityId, new List<OpportunityTeamMember>());
                }
                oppTeamMembersMap.get(oppTeamMembers.OpportunityId).add(oppTeamMembers);
            }
        }
        
        //part of HRP-9562 --> End
        
        for(Order orderObj : eligibleOrdersList)
        {
            if(oppRelatedToOrderMap!= null && oppRelatedToOrderMap.keyset().contains(orderObj.OpportunityId))
            {
            		Opportunity opp = oppRelatedToOrderMap.get(orderObj.OpportunityId);            
                    Task publicityTask = new Task();
                    publicityTask.Subject = BSF_Constants.PUBLICITY_REVIEW_NEEDED_TASK;
                    publicityTask.Status = BSF_Constants.STATUS_NOT_STARTED;
                    publicityTask.Priority = BSF_Constants.HIGH_PRIORITY_TASK;
                    publicityTask.WhatId = orderObj.Id;
                    publicityTask.OwnerId = OpportunityService.getTaskOwner(opp, oppTeamMembersMap,Task_Reassignment_Matrix__mdt.getInstance('Publicity_Review_Needed').Assigned_To__c); //HRP-9562;//HRP-12333 added 3rd paarameter
                    publicityTask.Drive_Date__c = opp.Drive_Date__c; //HRP-12700;
                    Date dueDate = opp.Drive_Date__c - BSF_Constants.PUBLICITY_REVIEW_DAYS_CONFIGURATION;
                    /*String myDateString = Datetime.newInstance(dueDate.year(),dueDate.month(),dueDate.day()).format('EEE');
                    if('Sat'.equals(myDateString)){
                        publicityTask.ActivityDate = dueDate - 1;
                    }
                    else if('Sun'.equals(myDateString)){
                        publicityTask.ActivityDate = dueDate - 2;
                    }
                    else{
                        publicityTask.ActivityDate = dueDate;
                    }*/
                    publicityTask.ActivityDate = BSF_Utilities.getTaskDueDate(dueDate, 'EEE');
                    publicityReviewTasksList.add(publicityTask);
            }
            
          }
        if(publicityReviewTasksList.size()>0)
    	{
      		Database.SaveResult[] srList = Database.insert(publicityReviewTasksList, false);
      		List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Publicity Review Task Creation','BSF_Batch_CreatePublicityTasksOnOrders','execute','Error','Error in Task Creation');
            InsertBsfErrorLog.insertBsfErrors(logList);       
 		}       
        
    }
    
    global void finish(Database.BatchableContext BC) 
    {
       
    }
    
    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new BSF_Batch_CreatePublicityTasksOnOrders());
    } 

}