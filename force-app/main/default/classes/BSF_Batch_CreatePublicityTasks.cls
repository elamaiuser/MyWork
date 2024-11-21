/********************************************************************************************
@ Component Name : BSF_Batch_CreatePublicityTasks 
@ Developed By: Exavalu / ARC 
@ purpose: 1.Create "Publicity order not created" task on opportunity when no order is present 
		   2.Create "Publicity Review Meeting" task on opportunity in Closed stage with No Publicity Needed = false and the order publicity approved = false

**********************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 10/07/2024					 Balaji N				  	    HRP-12583 Created
**********************************************************************************************/
global class BSF_Batch_CreatePublicityTasks implements Database.Batchable<Sobject>,Schedulable
{
    public static Task_Reassignment_Matrix__mdt publicityReview = Task_Reassignment_Matrix__mdt.getInstance('Publicity_Review_Needed');
    public static Task_Reassignment_Matrix__mdt publicityOrder = Task_Reassignment_Matrix__mdt.getInstance('Publicity_Order_Not_Created');
    public static Date dateUntil=system.today()+Integer.valueof(publicityOrder.Creation_Date_Offset__c);
    
    public static Database.queryLocator Start(Database.BatchableContext bc)
    {
        String query = 'SELECT Id,Drive_Date__c,Account_Manager__c,OwnerId from Opportunity '+
                       'WHERE Drive_Date__c >= Today AND Drive_Date__c<=:dateUntil AND is_template__c=false AND Opportunity.StageName = \'Closed\'';
        return Database.getQueryLocator(query);
    }
    
    public static void execute(Database.BatchableContext bc, List<Opportunity> oppList)
    {
        Set<Id> OppIdSet = new Set<Id>();
        for(Opportunity Opp : oppList)
        {
            OppIdSet.add(Opp.Id);
        }
        
        //Preparing List of Orders mapped to Opportunity Ids
       	Map<Id,List<Order>> oppIdOrderListMap = new Map<Id,List<Order>>();
        for(Order ord:[SELECT Id,OpportunityId,Publicity_Approved__c from Order where OpportunityId IN :OppIdSet AND Opportunity.No_Publicity_Needed__c = false])
        {
            if(!oppIdOrderListMap.containsKey(ord.OpportunityId))
            oppIdOrderListMap.put(ord.OpportunityId,new List<Order>());
            
            oppIdOrderListMap.get(ord.OpportunityId).add(ord);
        }
        
        //Preparing a set of existing order whatId (OpportunityId,OrderId)
        List<Task> existingTaskList =[SELECT Id,WhatId,Subject,OwnerId,Related_Order__c FROM Task WHERE WhatId IN:OppIdSet AND Subject IN(:publicityOrder.Task_Subject__c,:publicityReview.Task_Subject__c)];
        Map<Id,Set<String>> oppIdTaskSubjMap = new Map<Id,Set<String>>();
        Set<Id> publicityOrderOppSet = new Set<Id>();
        Set<Id> publicityReviewOppSet = new Set<Id>();
        for(Task tsk : existingTaskList)
        {
            if(publicityOrder.Task_Subject__c == tsk.Subject)
            {
                publicityOrderOppSet.add(tsk.WhatId);
            }
            else if(publicityReview.Task_Subject__c == tsk.Subject)
            {
                publicityReviewOppSet.add(tsk.Related_Order__c);
            }
        }
        
        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :OppIdSet];       
        
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
        if(allOpportunityTeamMembers != null)
        {
            for (OpportunityTeamMember oppTeamMembers : allOpportunityTeamMembers) {
                if (!oppTeamMembersMap.containsKey(oppTeamMembers.OpportunityId)) {
                    oppTeamMembersMap.put(oppTeamMembers.OpportunityId, new List<OpportunityTeamMember>());
                }
                oppTeamMembersMap.get(oppTeamMembers.OpportunityId).add(oppTeamMembers);
            }
        }
        
        Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('General Task').getRecordTypeId();
        List<Task> taskListToInsert = new List<Task>();
        for(Opportunity Opp : oppList)
        {
            Boolean pastpublicityOrder = System.today().daysBetween(Opp.Drive_Date__c) <= Integer.valueof(publicityOrder.Creation_Date_Offset__c)?True:False;
            Boolean pastpublicityReview = System.today().daysBetween(Opp.Drive_Date__c) <= Integer.valueof(publicityReview.Creation_Date_Offset__c)?True:False;
            
            if(pastpublicityOrder && !publicityOrderOppSet.contains(Opp.Id) && !oppIdOrderListMap.containsKey(opp.Id))
            {
                	Task pubOrder = new Task();
                    pubOrder.Subject = publicityOrder.Task_Subject__c;
                    pubOrder.Status = BSF_Constants.STATUS_NOT_STARTED;
                    pubOrder.Priority = BSF_Constants.HIGH_PRIORITY_TASK;
                    pubOrder.WhatId = Opp.Id;
                    pubOrder.OwnerId = OpportunityService.getTaskOwner(opp, oppTeamMembersMap,publicityOrder.Assigned_To__c); //HRP-9562;//HRP-12333 added 3rd paarameter
                    pubOrder.Drive_Date__c = opp.Drive_Date__c; //HRP-12700;
                    Date dueDate = opp.Drive_Date__c - Integer.ValueOf(publicityOrder.Due_Date_Offset__c);
                    pubOrder.ActivityDate = BSF_Utilities.getTaskDueDate(dueDate, 'EEE');
                	pubOrder.recordtypeId=recTypeId;
                	taskListToInsert.add(pubOrder);
            }
            if(pastpublicityReview && oppIdOrderListMap.containsKey(opp.Id))
            {
                if(oppIdOrderListMap.get(opp.Id)!=null)
                {
                    for(Order ord : oppIdOrderListMap.get(opp.Id))
                    {
                        if(!ord.Publicity_Approved__c && !publicityReviewOppSet.contains(ord.id))
                        {
                            Task pubReview = new Task();
                            pubReview.Subject = publicityReview.Task_Subject__c;
                            pubReview.Status = BSF_Constants.STATUS_NOT_STARTED;
                            pubReview.Priority = BSF_Constants.HIGH_PRIORITY_TASK;
                            pubReview.WhatId = Opp.Id;
                            pubReview.OwnerId = OpportunityService.getTaskOwner(opp, oppTeamMembersMap,publicityReview.Assigned_To__c); //HRP-9562;//HRP-12333 added 3rd paarameter
                            pubReview.Drive_Date__c = opp.Drive_Date__c; //HRP-12700;
                            Date dueDate = opp.Drive_Date__c - Integer.ValueOf(publicityReview.Due_Date_Offset__c);
                            pubReview.ActivityDate = BSF_Utilities.getTaskDueDate(dueDate, 'EEE');
                            pubReview.Related_Order__c=ord.Id;
                            pubReview.recordtypeId=recTypeId;
                            taskListToInsert.add(pubReview);
                        }
                    }
                }
            }
        }
        
        if(!taskListToInsert.isEmpty())
        {
            
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.Insert(taskListToInsert,false), 'Publicity Review Task Creation','BSF_Batch_CreatePublicityTasks','execute','Error','Error in Task Creation');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
        
    }
    
    public static void finish(Database.BatchableContext bc)
    {
        System.debug('BSF_Batch_CreatePublicityTasks Finish');
    }
    
    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new BSF_Batch_CreatePublicityTasks());
    } 
}