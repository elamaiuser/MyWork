public with sharing class StandardTaskGenerationBatch implements Schedulable, Database.Batchable<SObject>{
    private final String dynamicQuery;
    private final Integer batchSize = Integer.valueOf(Label.BSF_Task_Batch_Size);
    public StandardTaskGenerationBatch(){
        this.dynamicQuery = BSF_TaskPlanningService.buildTaskGenerationBatchQuery(
                                                BSF_Constants.STANDARD_TASK_BATCH_FILTER
                                            );
    }
    public StandardTaskGenerationBatch(String customFilter){
        this.dynamicQuery = BSF_TaskPlanningService.buildTaskGenerationBatchQuery(
                                                        customFilter
                                                    );
    } 
	public Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(this.dynamicQuery);
	}
	public void execute(Database.BatchableContext BC, List<SObject> scope){
		if (scope != null && !scope.isEmpty()) {
            BSF_TaskPlanningService.processAndGenerateTasks(
                (List<Planned_Task__c>)scope,
                false
            );
        }
	}
	public void execute(SchedulableContext scon){
		Database.executeBatch(this,this.batchSize);
	}
	public void finish(Database.BatchableContext BC){}
}