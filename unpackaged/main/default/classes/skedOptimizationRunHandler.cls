public class skedOptimizationRunHandler extends skedTriggerHub {

    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
    }
    
    public override void onAfterUpdate() {
        //Batch >> Run >> Queue >> Queue Item >> Drive
        updateOptimizationStatus(this.context.newRecords, (Map<Id, sked_Optimization_Run__c>)this.context.oldMap);        
    }
    
    /*********************************************************** Privated Methods ***********************************************************/  

    private void updateOptimizationStatus(List<sked_Optimization_Run__c> newRecords, Map<Id, sked_Optimization_Run__c> oldMap) {
        List<sked_Optimization_Run__c> optimizationRuns = new List<sked_Optimization_Run__c>();
        for (sked_Optimization_Run__c newRecord : newRecords) {
            sked_Optimization_Run__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                optimizationRuns.add(newRecord);
            }
        }
        //HRP-12511
        publishOptimizationRunStatPlatformEvents(optimizationRuns);

        List<sked_Optimization_Queue__c> optimizationQueues = [SELECT Id, sked_Status__c, sked_Optimization_Run__c,
                                                               (SELECT Id, sked_Drive__c
                                                                FROM sked_Optimization_Queue_Items__r)
                                                               FROM sked_Optimization_Queue__c
                                                               WHERE sked_Optimization_Run__c IN :optimizationRuns];
        Map<Id, List<sked_Optimization_Queue__c>> mapOptimizationRun_Queues = new Map<Id, List<sked_Optimization_Queue__c>>();
        for (sked_Optimization_Queue__c optimizationQueue : optimizationQueues) {
            List<sked_Optimization_Queue__c> queues = mapOptimizationRun_Queues.get(optimizationQueue.sked_Optimization_Run__c);
            if (queues == NULL) {
                queues = new List<sked_Optimization_Queue__c>();
            }
            queues.add(optimizationQueue);
            mapOptimizationRun_Queues.put(optimizationQueue.sked_Optimization_Run__c, queues);
        }
        
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        for (sked_Optimization_Run__c optimizationRun : optimizationRuns) {
            List<sked_Optimization_Queue__c> queues = mapOptimizationRun_Queues.get(optimizationRun.Id);
            for (sked_Optimization_Queue__c optimizationQueue : queues) {
                optimizationQueue.sked_Status__c = optimizationRun.sked_Status__c;
                
                for (sked_Optimization_Queue_Item__c queueItem : optimizationQueue.sked_Optimization_Queue_Items__r) {
                    string status = optimizationRun.sked_Status__c;
                    if (optimizationRun.sked_Status__c == skedConstants.OPTIMIZATION_RUN_STATUS_COMPLETE) {
                        status = 'Completed';
                    }
                    if (optimizationRun.sked_Status__c == skedConstants.OPTIMIZATION_RUN_STATUS_IN_PROGRESS || optimizationRun.sked_Status__c == skedConstants.OPTIMIZATION_RUN_STATUS_POST_PROCESS) {
                        status = 'In Progress';
                    }
                    if (optimizationRun.sked_Status__c == skedConstants.OPTIMIZATION_RUN_STATUS_CLOSED) {
                        status = 'Pending';
                    }
                    sked_Drive__c drive = new sked_Drive__c(
                        Id = queueItem.sked_Drive__c,
                        sked_Optimization_Status__c = status
                    );
                    drivesToUpdate.add(drive);
                }
            }
        }
        
        update optimizationQueues;
        if (!drivesToUpdate.isEmpty()) {
            update drivesToUpdate;
        }
    }

    //HRP-12511
    private void publishOptimizationRunStatPlatformEvents(List<sked_Optimization_Run__c> updOptRunRecords){
        Set<Id> optimizationIds = new Set<Id>();        
        for (sked_Optimization_Run__c optimizationRunStat : updOptRunRecords){
            if(optimizationRunStat.sked_Status__c == skedConstants.OPTIMIZATION_RUN_STATUS_COMPLETE){                
                optimizationIds.add(optimizationRunStat.Id);                 
            }            
        }

        if(!optimizationIds.isEmpty()){
            skedFutureCallEventHandler.publishFutureCallEvent(
                'slwcOptimizationService', 
                'populateOptimizationRunStatParmFields', 
                optimizationIds
            );
        }           
    }

    private void populateData(List<sked_Optimization_Run__c> newRecords) {
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Optimization_Run__c newRecord : newRecords) {
            if (newRecord.sked_Start_Date__c != NULL) {
                DateTime startDateDt = DateTime.newInstance(newRecord.sked_Start_Date__c, Time.newInstance(0, 0, 0, 0));
                newRecord.sked_Start_Date_Str__c = startDateDt.format(skedDateTimeUtils.DATE_FORMAT);
            }
            if (newRecord.sked_End_Date__c != NULL) {
                DateTime endDateDt = DateTime.newInstance(newRecord.sked_End_Date__c, Time.newInstance(0, 0, 0, 0));
                newRecord.sked_End_Date_Str__c = endDateDt.format(skedDateTimeUtils.DATE_FORMAT);
            }
        }
    }

}