global class BSF_Batch_UpdateTaskType implements Database.Batchable<sObject>{
	public String query;
    public Map<String,String> subjectVsTypeMap = new Map<String,String>();
	global BSF_Batch_UpdateTaskType(Map<String,String> subjectVsTypeMap, Datetime dueDate){
        if(subjectVsTypeMap != null && !subjectVsTypeMap.isEmpty()){
            String query = 'SELECT Id, Subject, Type FROM Task WHERE Subject IN (\''+String.join(new List<String>(subjectVsTypeMap.keySet()), '\',\'')+'\')';
            if(dueDate != null){
                query += ' AND ActivityDate >= '+dueDate.format('yyyy-MM-dd');
            }
            this.subjectVsTypeMap = subjectVsTypeMap;
            this.query=query;
        }
	}
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<sObject> scope){
		List<Task> tasksToUpdate = new List<Task>();
        for(sObject sobj : scope){
            Task tsk = (Task)sobj;
            if(subjectVsTypeMap.containsKey(tsk.Subject)){
                tsk.Type = subjectVsTypeMap.get(tsk.Subject);
                tasksToUpdate.add(tsk);
            }
        }
        if(!tasksToUpdate.isEmpty()){
            Database.update(tasksToUpdate, false);
        }
	}
	global void finish(Database.BatchableContext BC){
		/*Map<String,String> subjectVsTypeMap = new Map<String,String>();
        subjectVsTypeMap.put('Recruitment Planning Meeting','Recruitment Planning Meeting');
        subjectVsTypeMap.put('Sponsor Planning Meeting','Sponsor Planning Meeting');
        subjectVsTypeMap.put('72 Hour Check-In','72 Hour Check-In');
        String updateQuery = 'Subject IN (\''+String.join(new List<String>(subjectVsTypeMap.keySet()), '\',\'')+'\')';
        System.debug('updateQuery-->'+updateQuery);*/
	}
}