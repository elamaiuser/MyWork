/* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 12/02/2024					 Barnojit Sharma		  Tasks being assigned for cancelled drives and for fixed sites(Logic for HRP-13850)
************************************************************************************************************************************************
*/
global class BSF_Batch_RecruitmentTaskCreation implements Schedulable ,Database.Batchable<sObject> {
  Date currentDate;
  Date dueDate;
  Task_Reassignment_Matrix__mdt metadata;
  User drdSystemUser;
  global BSF_Batch_RecruitmentTaskCreation(){
    currentDate = Date.Today();
    metadata = Task_Reassignment_Matrix__mdt.getInstance('Recruitment_Task');
    Integer offsetNew = Integer.valueOf(metadata.Creation_Date_Offset__c);
    dueDate = currentDate.adddays(offsetNew) ;
    
  }
 
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String oppType = 'Mobile Opp';
      String query = 'SELECT ID ,Account_Manager__c,OwnerId, Drive_Date__c ,Is_Template__c, RecordType.Name From Opportunity where RecordType.Name =: oppType AND Drive_Date__c <= :dueDate AND Drive_Date__c >= TODAY AND StageName != \'Cancelled\'';//HRP-13850
     
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> scope)
    { 
        set<id> oppIds = new set<id>();
        for (Opportunity opp : scope) {
            if(opp.Is_Template__c == true){ 
                continue;
            }
            oppIds.add(opp.Id);
        }
        List<task> taskList = new list<task>();
        
        Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Recruitment Meeting').getRecordTypeId();
        
        
        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :oppIds
                                                                ];
        
        
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
        for (OpportunityTeamMember oppteamem : allOpportunityTeamMembers) {
            if (!oppTeamMembersMap.containsKey(oppteamem.OpportunityId)) {
                oppTeamMembersMap.put(oppteamem.OpportunityId, new List<OpportunityTeamMember>());
            }
            oppTeamMembersMap.get(oppteamem.OpportunityId).add(oppteamem);
        }
        
        list<Task> existingRecruitmentTaskList=[select id,whoId,whatId from task where subject = 'Recruitment Planning Meeting' and whatId in:oppIds];
        map<id,task> oppidTaskMap = new map<id,task>();
        for(Task t:existingRecruitmentTaskList)
        {
            oppidTaskMap.put(t.whatId,t);
        }
       
        for (Opportunity opp : scope) {
            if (!oppidTaskMap.containskey(opp.id))
              {
                task recruitmentTask = new task();
                recruitmentTask.RecordTypeId = recTypeId;
                Date taskDueDate = opp.Drive_Date__c.addDays(-50);
                String taskDueDayString = Datetime.newInstance(taskDueDate.year(), taskDueDate.month(),taskDueDate.day()).format('EEE'); 
                if(taskDueDayString.equalsIgnoreCase('Sat')){
                    taskDueDate = taskDueDate.addDays(-1);
                }else if(taskDueDayString.equalsIgnoreCase('Sun')){
                    taskDueDate = taskDueDate.addDays(-2);
                }
                recruitmentTask.ActivityDate = taskDueDate;
                recruitmentTask.OwnerId = opportunityService.getTaskOwner(opp, oppTeamMembersMap,Task_Reassignment_Matrix__mdt.getInstance('Recruitment_Task').Assigned_To__c);//part of ticket HRP-9562;//HRP-12333 added 3rd paarameter
                recruitmentTask.subject = 'Recruitment Planning Meeting';
                recruitmentTask.WhatId = opp.id;
                recruitmentTask.Drive_Date__c = opp.Drive_Date__c;
                taskList.add(recruitmentTask);
              }
            }
        if (!taskList.isEmpty())
        {
            
            
                Database.SaveResult[] srList = Database.insert(taskList, false);
                
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Recruitment Planning Meeting task has been created Successfully inserted account.' + sr.getId());
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Opportunity fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            
            
        }   
    }

    global void execute(SchedulableContext scon){
		Database.executeBatch(new BSF_Batch_RecruitmentTaskCreation(),200);
	}
    
    global void finish(Database.BatchableContext BC) {
        
    }
}