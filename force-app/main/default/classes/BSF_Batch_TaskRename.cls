global class BSF_Batch_TaskRename implements Database.Batchable<sObject>{
	public String query;
    private final Date activityDate;
    public Map<String,String> subjectRenameMap;
	global BSF_Batch_TaskRename(List<String> statusToExclude, List<String> whatIds, Map<String,String> renameMap, Date activityDate){
		if(renameMap != null && !renameMap.isEmpty()){
            this.query = 'SELECT Id, Subject FROM Task WHERE Subject IN (\''+String.join(new List<String>(renameMap.keySet()),'\',\'')+'\')';
            this.subjectRenameMap = renameMap;
            if(statusToExclude != null && !statusToExclude.isEmpty()){
                this.query = this.query + ' AND Status NOT IN (\''+String.join(statusToExclude,'\',\'')+'\')';
            }
            if(whatIds != null && !whatIds.isEmpty()){
                this.query = this.query + ' AND WhatId IN (\''+String.join(whatIds,'\',\'')+'\')';
            }
            if(activityDate != null){
                this.activityDate = activityDate;
                this.query = this.query + ' AND ActivityDate >= :activityDate';
            }            
        }
	}
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(this.query);
	}
	global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Task> tasksToUpdate = new List<Task>();
		for(sObject obj:scope){
			Task thisTask = (Task)obj;
            if(this.subjectRenameMap != null && !this.subjectRenameMap.isEmpty() && this.subjectRenameMap.containsKey(thisTask.Subject)){
                thisTask.Subject = this.subjectRenameMap.get(thisTask.Subject);
                tasksToUpdate.add(thisTask);
            }
        }
        if(!tasksToUpdate.isEmpty()){
            skedHubBase.BypassUpdateTriggers = true;
            TriggerHandler.bypass('TaskTriggerHandler');
            Database.update(tasksToUpdate,false); 
        }
	}
	global void finish(Database.BatchableContext BC){}
}