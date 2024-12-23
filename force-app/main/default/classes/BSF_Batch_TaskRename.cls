global class BSF_Batch_TaskRename implements Database.Batchable<sObject>{
	public String query;
    public Map<String,String> subjectRenameMap;
	/*public List<String> statusToExclude = new List<String>{'Completed','Inactive'};
	public List<String> whatIds = new List<String>{'123456789012345'};
	public Map<String,String> renameMap = new Map<String,String>{
		'123456789012345' => 'New Task Name'
	};*/
	global BSF_Batch_TaskRename(List<String> statusToExclude, List<String> whatIds, Map<String,String> renameMap){
		if(renameMap != null && !renameMap.isEmpty()){
            this.query = 'SELECT Id, Subject FROM Task WHERE Subject IN (\''+String.join(new List<String>(renameMap.keySet()),'\',\'')+'\')';
            this.subjectRenameMap = renameMap;
            if(statusToExclude != null && !statusToExclude.isEmpty()){
                this.query = this.query + ' AND Status NOT IN (\''+String.join(statusToExclude,'\',\'')+'\')';
            }
            if(whatIds != null && !whatIds.isEmpty()){
                this.query = this.query + ' AND WhatId IN (\''+String.join(whatIds,'\',\'')+'\')';
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