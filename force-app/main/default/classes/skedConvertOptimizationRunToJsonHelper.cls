public class skedConvertOptimizationRunToJsonHelper {

    public static void convertOptimizationRunToJson(Id optimizationRunId) {
        List<sked_Optimization_Queue__c> optimizationQueues = [SELECT Id, sked_Status__c, sked_Optimization_Run__c,
                                                               (SELECT Id, sked_Drive__c
                                                                FROM sked_Optimization_Queue_Items__r)
                                                               FROM sked_Optimization_Queue__c
                                                               WHERE sked_Optimization_Run__c = :optimizationRunId];
        Set<Id> driveIds = new Set<Id>();
        for (sked_Optimization_Queue__c optimizationQueue : optimizationQueues) {
            for (sked_Optimization_Queue_Item__c queueItem : optimizationQueue.sked_Optimization_Queue_Items__r) {
                driveIds.add(queueItem.sked_Drive__c);
            }
        }
        
        List<sked__Job_Allocation__c> jobAllocations = [SELECT Id, sked__Job__c, sked__Resource__c, sked__Job__r.sked_Drive_Shift__c,
                                                        sked__Job__r.sked_Drive__c, sked_DOT__c, sked_CDL__c
                                                        FROM sked__Job_Allocation__c
                                                        WHERE sked__Job__r.sked_Drive__c IN : driveIds
                                                        AND sked__Job__r.sked_Resource_Role__c != NULL
                                                        AND sked__Status__c != 'Deleted'];
        Map<string, optimizerAllocationModel> mapResult = new Map<string, optimizerAllocationModel>();
        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            string jobId = jobAllocation.sked__Job__c;
            string jobPrefix = '';
            if (jobAllocation.sked_DOT__c == TRUE) {
                jobPrefix = 'driverdot';
            }
            if (jobAllocation.sked_CDL__c == TRUE) {
                jobPrefix = 'drivercdl';
            }
            string key = 'alloc_{driveShiftId}:{jobId}:{index}';
            key = key.replace('{driveShiftId}', jobAllocation.sked__Job__r.sked_Drive_Shift__c);
            key = key.replace('{jobId}', (jobPrefix + jobId));
            integer index = 0;
            string tempKey = key.replace('{index}', string.valueOf(index));
            while (mapResult.containsKey(tempKey)) {
                index++;
                tempKey = key.replace('{index}', string.valueOf(index));
            }
            key = tempKey;
            
            optimizerAllocationModel model = new optimizerAllocationModel();
            model.allocation = jobAllocation.sked__Resource__c;
            mapResult.put(key, model);
        }
            
        system.debug('#JSON#' + JSON.serialize(mapResult));
    }
    
    public class optimizerAllocationModel {
        public string allocation;
    }
    
}