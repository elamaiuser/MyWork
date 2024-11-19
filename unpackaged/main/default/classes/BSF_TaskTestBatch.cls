global class BSF_TaskTestBatch implements Database.Batchable<sObject>{
	public static String taskSubject = 'Recruitment Planning Meeting';
	public String query = 'SELECT Id, Subject FROM Task WHERE Subject = \'Recruitment Task - System Generated\'';
    global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<Task> scope){
		for(Task t : scope) { t.Subject = taskSubject; }
		skedHubBase.BypassInsertTriggers = true;
		skedHubBase.BypassUpdateTriggers = true;
		triggerHandler.bypass('TaskTriggerHandler');
		update scope;
	}
	global void finish(Database.BatchableContext BC){}
}