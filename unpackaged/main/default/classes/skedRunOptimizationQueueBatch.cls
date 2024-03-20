global class skedRunOptimizationQueueBatch implements Database.Batchable<sked_Optimization_Run__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected Set<Id> skedRunIds;

    global skedRunOptimizationQueueBatch(Set<Id> inputRunIds) {
        this.skedRunIds = inputRunIds;
    }
    
    global List<sked_Optimization_Run__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Message__c 
                FROM sked_Optimization_Run__c 
                WHERE Id IN :this.skedRunIds];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Optimization_Run__c> optimizationRuns) {
        List<sked_Optimization_Run__c> optimizationRunsToUpdate = new List<sked_Optimization_Run__c>();
        for (sked_Optimization_Run__c optimizationRun : optimizationRuns) {
            optimizationRun.sked_Message__c = optimizationRun.sked_Message__c != NULL ? optimizationRun.sked_Message__c : '';
            try {
                skedSkeduloApiManager api = new skedSkeduloApiManager();
                skedSkeduloApiData.optimizationRunModel model = new skedSkeduloApiData.optimizationRunModel();
                model.uid = optimizationRun.Id;
                skedSkeduloApiData.optimizationRunResult result = api.triggerOptimizationRun(model);
                if (result != NULL && result.success == FALSE) {
                    optimizationRun.sked_Status__c = 'Error';
                	optimizationRun.sked_Message__c += JSON.serialize(result);
                    optimizationRunsToUpdate.add(optimizationRun);
                }
            }
            catch (Exception ex) {
                optimizationRun.sked_Status__c = 'Error';
                optimizationRun.sked_Message__c += ex.getMessage() + '. Stack trace: ' + ex.getStackTraceString();
                optimizationRunsToUpdate.add(optimizationRun);
            }
        }
        if (!optimizationRunsToUpdate.isEmpty()) {
            update optimizationRunsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked_Optimization_Queue_Item__c> queueItems = [SELECT Id, sked_Drive__c
                                                            FROM sked_Optimization_Queue_Item__c
                                                            WHERE sked_Optimization_Queue__r.sked_Optimization_Run__c IN :skedRunIds];
        if (!queueItems.isEmpty()) {
            List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
            for (sked_Optimization_Queue_Item__c queueItem : queueItems) {
                sked_Drive__c drive = new sked_Drive__c(
                    Id = queueItem.sked_Drive__c,
                    sked_Optimization_Status__c = 'In Progress'
                );
                drivesToUpdate.add(drive);
            }
            update drivesToUpdate;
        }
    }
    
}