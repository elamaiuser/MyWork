global class slwcOptimizationService implements Callable {
    
    @AuraEnabled
    public static slwcAuraResult initiateOptimizationRun(initiateOptimizationRunRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        List<String> optimizationDriveTypes = new List<String>();
        List<sked_Optimization_Queue__c> newQueues = addDrivesToQueues(request);
        indicateInheritances(newQueues);
        
        string startDateStr = Json.serialize(newQueues.get(0).sked_Start_Date__c).replace('"', '');
        string runKey = startDateStr + ':' + newQueues.get(0).sked_Collection_Operation__c;

        sked_Optimization_Run__c newRun = new sked_Optimization_Run__c (
            sked_Collection_Operation__c = newQueues.get(0).sked_Collection_Operation__c,
            sked_Start_Date__c = request.startDate,
            sked_End_Date__c = request.endDate,
            sked_Status__c = skedConstants.OPTIMIZATION_RUN_STATUS_PENDING,
            sked_UniqueKey__c = runKey,
            sked_Is_Dev__c = skedSetting.instance.Admin.runOptimizationOnDev
        );
        insert newRun;

        sked__Region__c skedRegion = [SELECT sked__Timezone__c
                                      FROM sked__Region__c
                                      WHERE sked_Biomed_Collection_Op_Center__c = :newRun.sked_Collection_Operation__c
                                      LIMIT 1];

        for (sked_Optimization_Queue__c newQueue : newQueues) {
            newQueue.sked_Optimization_Run__c = newRun.Id;
            if(!optimizationDriveTypes.contains(newQueue.sked_Drive_Type__c)){
                optimizationDriveTypes.add(newQueue.sked_Drive_Type__c);
            }            
        }
        update newQueues;
        newRun.sked_Drive_Types__c = String.join(optimizationDriveTypes, ';');
        newRun.sked_Timezone__c = skedRegion.sked__Timezone__c;
        update newRun;

        insertOptimizationRunSettings(request, newQueues.get(0).sked_Collection_Operation__c, newRun.Id);

        List<sked_Drive__c> reshuffledDrives = getReshuffledDrives(request.driveIds, request.startDate, request.endDate, newRun.Id, newRun.sked_Drive_Types__c);
       
        if (reshuffledDrives != null && !reshuffledDrives.isEmpty()) {            
            List<sked_Optimization_Queue_Item__c> reshuffledQueueItems = new List<sked_Optimization_Queue_Item__c>();
            for (sked_Drive__c reshuffledDrive : reshuffledDrives) { 
                for (sked_Optimization_Queue__c newQueue : newQueues) { 
                    if (newQueue.sked_Drive_Type__c == reshuffledDrive.sked_Type_of_Drive__c && newQueue.sked_Collection_Operation__c == reshuffledDrive.sked_Collection_Operation__c
                        && newQueue.sked_Optimization_Run__c == newRun.Id) { 
                            sked_Optimization_Queue_Item__c reshuffledQueueItem = new sked_Optimization_Queue_Item__c(
                                sked_Optimization_Queue__c = newQueue.Id,
                                sked_Drive__c = reshuffledDrive.Id,
                                sked_Type__c = 'Reshuffled'
                            );                            
                            reshuffledQueueItems.add(reshuffledQueueItem);
                    }
                }            
            }
            insert reshuffledQueueItems;
        }
        

        Set<Id> runIds = new Set<Id>();
        runIds.add(newRun.Id);
        skedRunOptimizationQueueBatch batch = new skedRunOptimizationQueueBatch(runIds);
        Database.executeBatch(batch, 1);
        return result;
    }

    @AuraEnabled
    public static slwcAuraResult getOptimizationRuns(getOptimizationRunsRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        
        List<sked_Optimization_Queue_Item__c> queueItems = [SELECT Id, sked_Optimization_Queue__r.sked_Optimization_Run__c
                                                            FROM sked_Optimization_Queue_Item__c
                                                            WHERE sked_Drive__r.sked_Territory_Key__c IN :request.territoryKeys
                                                            AND sked_Optimization_Queue__r.sked_Start_Date__c < :request.endDate
                                                            AND sked_Optimization_Queue__r.sked_End_Date__c > :request.startDate];
        
        Set<Id> optimizationRunIds = new Set<Id>();
        for (sked_Optimization_Queue_Item__c queueItem : queueItems) {
            optimizationRunIds.add(queueItem.sked_Optimization_Queue__r.sked_Optimization_Run__c);
        }
        List<sked_Optimization_Run__c> optimizationRuns = [SELECT Id, Name, CreatedBy.Id, CreatedBy.Name, CreatedBy.SmallPhotoUrl, CreatedDate,
                                                           sked_Collection_Operation__c, sked_Collection_Operation__r.Name, sked_End_Date__c,
                                                           sked_Start_Date__c, sked_Status__c
                                                           FROM sked_Optimization_Run__c
                                                           WHERE Id IN :optimizationRunIds];
        
        result.returnedData = optimizationRuns;
        return result;
    }

    //HRP-12511
    @AuraEnabled
    public static slwcAuraResult getOptimizationRunStatistics(String optimizationId) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        List<sked_Optimization_Run__c> optimizationRuns =  new List<sked_Optimization_Run__c>();
        
            optimizationRuns = [SELECT sked_Opt_Stat_Total_Planned_Allocations__c, sked_Opt_Stat_Total_Sched_Allocations__c, sked_Opt_Stat_Total_Unsched_Allocations__c, sked_Opt_Stat_Total_Resource_Sched__c,
                                sked_Opt_Stat_Total_Resource_Unsched__c, sked_Opt_Stat_Total_Sched_Time__c, sked_Opt_Stat_Total_Travel_Time__c, sked_Opt_Stat_Total_Travel_Distances__c,
                                sked_Opt_Stat_Max_Travel_Time_Alloc__c, sked_Opt_Stat_Avg_Num_Alloc_Resource__c, sked_Opt_Stat_Hard_Constraints_Score__c, sked_Opt_Stat_Soft_Constraints_Score__c,
                                sked_Opt_Parm_Accnt_Prefer__c, sked_Opt_Parm_Site_Prefer__c, sked_Opt_Parm_Geo_Prefer__c, sked_Opt_Parm_Hire_Date_Skills__c,sked_Opt_Parm_Role_Priority_Skills__c,
                                sked_Start_Date__c, sked_End_Date__c, sked_Timezone__c
                                FROM sked_Optimization_Run__c WHERE Id = :optimizationId];
        result.returnedData = optimizationRuns;
        return result;
    }

    @AuraEnabled
    public static slwcAuraResult getOptimizedJobAllocation(String optimizationId) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        List<sked__Job_Allocation__c> jobAllocationRecords = new List<sked__Job_Allocation__c>();
        sked_Optimization_Run__c optimizationRun = [SELECT sked_Opt_Run_Meta__c, sked_Opt_Run_Diff__c
                                                    FROM sked_Optimization_Run__c WHERE Id = :optimizationId];
        List<JobAllocationWrapper> jobAllocations = getJobAllocationsFromRunMetaAndDifference(optimizationRun.sked_Opt_Run_Meta__c, optimizationRun.sked_Opt_Run_Diff__c );
        jobAllocationRecords = getJobAllocations(jobAllocations);
        result.returnedData = jobAllocationRecords;
        return result;
    }

    // HRP-12511: Added this Callable method to populate the sked_Optimization_Run_Stat_Parm__c fields
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'populateOptimizationRunStatParmFields' {
                    populateOptimizationRunStatParmFields((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + slwcOptimizationService.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }
        return result;
    }

    public static Set<Id> compareOptimizerSettings(String currentOptimizerRunId, Set<Id> previousOptimizerRunIds) { 
        Set<Id> matchingOptimizationRunIds = new Set<Id>();

        List<sked_CollectionOperationOptimizerSetting__c> currentOptimizerSettings = [
            SELECT sked_Constraint__c, sked_Default_Weight__c, sked_Optimizer_Mapped_Weight__c
            FROM sked_CollectionOperationOptimizerSetting__c
            WHERE sked_Optimization_Run__c = :currentOptimizerRunId
            ORDER BY sked_Constraint__c ASC
        ];

        string currentRunSetting = '';
        for (sked_CollectionOperationOptimizerSetting__c setting : currentOptimizerSettings) {
            currentRunSetting += setting.sked_Constraint__c + ',' + setting.sked_Default_Weight__c + ',' + setting.sked_Optimizer_Mapped_Weight__c + ';';
        }

        List<sked_Optimization_Run__c> previousRuns = [
            SELECT Id,
            (SELECT sked_Constraint__c, sked_Default_Weight__c, sked_Optimizer_Mapped_Weight__c
             FROM sked_CollectionOpOptimizerSettings__r
             ORDER BY sked_Constraint__c ASC)
            FROM sked_Optimization_Run__c
            WHERE Id IN :previousOptimizerRunIds
        ];

        for (sked_Optimization_Run__c previousRun : previousRuns) {
            string previousRunSetting = '';
            for (sked_CollectionOperationOptimizerSetting__c setting : previousRun.sked_CollectionOpOptimizerSettings__r) {
                previousRunSetting += setting.sked_Constraint__c + ',' + setting.sked_Default_Weight__c + ',' + setting.sked_Optimizer_Mapped_Weight__c + ';';
            }
            if (currentRunSetting == previousRunSetting) {
                matchingOptimizationRunIds.add(previousRun.Id);
            }
        }

        return matchingOptimizationRunIds;
    }

    public static List<sked_Drive__c> getReshuffledDrives(List<String> driveIds, date startDate, date endDate, String currentOptimizationRunId, String optDriveTypes) {
        Set<Id> driveCollectionOperationIds = new Set<Id>();
        Set<Id> coMatchedResourceIds = new Set<Id>();
        Set<Id> reshufflingCandidateDriveIds = new Set<Id>();
        Set<Id> optimizationRunIdsForReshufflingCandidateDrives = new Set<Id>();
        Set<Id> reshuffledDriveOptimizationIds = new Set<Id>();
        List<sked_Drive__c> reshuffledDrives = new List<sked_Drive__c>();

        List<sked_Drive__c> selectedDrives = [SELECT Id, sked_Collection_Operation__c 
                                              FROM sked_Drive__c WHERE Id IN :driveIds];

        for (sked_Drive__c selectedDrive : selectedDrives) {
            driveCollectionOperationIds.add(selectedDrive.sked_Collection_Operation__c);
        }

        List<sked__Resource__c> primaryCoResources = [
            SELECT Id
            FROM sked__Resource__c
            WHERE sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :driveCollectionOperationIds
            AND sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            AND ((sked_Employment_Status__c = :skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE) 
                OR (sked_Employment_Status__c = :skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE AND sked_Anticipated_Leave_Return_Date__c <= :endDate))
            AND (sked_Termination_Date__c = NULL OR sked_Termination_Date__c > :startDate)
            AND (sked_Planned_Termination_Date__c = NULL OR sked_Planned_Termination_Date__c > :startDate)
        ];
        for (sked__Resource__c primaryCoResource : primaryCoResources) {
            coMatchedResourceIds.add(primaryCoResource.Id);
        }

        List<sked_Resource_Biomed_Collection_Op__c> secondaryCoResources = [
            SELECT sked_Resource__c 
            FROM sked_Resource_Biomed_Collection_Op__c
            WHERE sked_Biomed_Collection_Op_Center__c IN :driveCollectionOperationIds
            AND ((sked_Start_Date__c = NULL OR sked_Start_Date__c <= :endDate) AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :startDate))
            AND sked_Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            AND sked_Resource__r.sked_Drive_Type__c = :optDriveTypes
        ];
        for (sked_Resource_Biomed_Collection_Op__c secondaryCoResource : secondaryCoResources) {
            coMatchedResourceIds.add(secondaryCoResource.sked_Resource__c);
        }

        List<sked__Resource_Override__c> resourceOverrides = [
            SELECT Id, sked__Resource__c 
            FROM sked__Resource_Override__c 
            WHERE sked_Collection_Operation__c IN :driveCollectionOperationIds
            AND (sked_Start_Date__c <= :endDate AND sked_End_Date__c >= :startDate)
            AND sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            AND sked__Resource__r.sked_Drive_Type__c = :optDriveTypes
        ];
        for (sked__Resource_Override__c resourceOverride : resourceOverrides) {
            coMatchedResourceIds.add(resourceOverride.sked__Resource__c);
        }

        List<sked__Job_Allocation__c> coMatchedResourceAllocations = [
            SELECT sked__Job__r.sked_Drive__c
            FROM sked__Job_Allocation__c 
            WHERE sked__Resource__c IN :coMatchedResourceIds
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c >= :startDate
            AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c <= :endDate
        ];
        
        for (sked__Job_Allocation__c coMatchedResourceAllocation : coMatchedResourceAllocations) {
            if (!driveIds.contains(coMatchedResourceAllocation.sked__Job__r.sked_Drive__c)) {
                reshufflingCandidateDriveIds.add(coMatchedResourceAllocation.sked__Job__r.sked_Drive__c);
            }
        }

        List<sked_Drive__c> reshufflingCandidateDrives = [
            SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_Optimization_Run__c
            FROM sked_Drive__c 
            WHERE Id IN :reshufflingCandidateDriveIds
            AND sked_Exclude_from_Optimizer__c = false
        ];
                                                          
        for (sked_Drive__c reshufflingCandidateDrive : reshufflingCandidateDrives) {
            optimizationRunIdsForReshufflingCandidateDrives.add(reshufflingCandidateDrive.sked_Optimization_Run__c);
        }

        if (!optimizationRunIdsForReshufflingCandidateDrives.isEmpty()) {
            reshuffledDriveOptimizationIds = compareOptimizerSettings(currentOptimizationRunId, optimizationRunIdsForReshufflingCandidateDrives);
        }

        if (!reshuffledDriveOptimizationIds.isEmpty()) {
            for (sked_Drive__c reshufflingCandidateDrive : reshufflingCandidateDrives) {
                if (reshuffledDriveOptimizationIds.contains(reshufflingCandidateDrive.sked_Optimization_Run__c)) {
                    reshuffledDrives.add(reshufflingCandidateDrive);
                }
            }  
        }
        
        return reshuffledDrives;                                                               
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private static List<sked_Optimization_Queue__c> addDrivesToQueues(initiateOptimizationRunRequestModel request) {
        List<sked_Drive__c> drivesToAddToQueues = [SELECT Id, sked_Collection_Operation__c,
                                                   sked_Drive_Date__c, sked_Type_of_Drive__c,
                                                   sked_Operation_Type__c
                                                   FROM sked_Drive__c
                                                   WHERE Id IN :request.driveIds];
        Map<string, List<sked_Drive__c>> map_queueKey_Drives = new Map<string, List<sked_Drive__c>>();
        for (sked_Drive__c skedDrive : drivesToAddToQueues) {
            string driveType = skedDrive.sked_Type_of_Drive__c;
            if(skedDrive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_WB){
                driveType = skedConstants.DRIVE_TYPE_MOBILE;
            }
            string startDateStr = Json.serialize(request.startDate).replace('"', '');
            string key = startDateStr + ':' + skedDrive.sked_Collection_Operation__c + ':' + driveType;
            List<sked_Drive__c> drives;
            if (map_queueKey_Drives.containsKey(key)) {
                drives = map_queueKey_Drives.get(key);
            }
            else {
                drives = new List<sked_Drive__c>();
                map_queueKey_Drives.put(key, drives);
            }
            drives.add(skedDrive);
        }
        
        Map<string, sked_Optimization_Queue__c> map_queueKey_Queue = new Map<string, sked_Optimization_Queue__c>();
        List<sked_Optimization_Queue__c> newQueues = new List<sked_Optimization_Queue__c>();
        for (string queueKey : map_queueKey_Drives.keySet()) {
            List<string> keyParts = queueKey.split(':');
            sked_Optimization_Queue__c newQueue = new sked_Optimization_Queue__c(
                sked_Start_Date__c = request.startDate,
                sked_End_Date__c = request.endDate,
                sked_Collection_Operation__c = keyParts[1],
                sked_Drive_Type__c = keyParts[2],
                sked_Status__c = skedConstants.OPTIMIZATION_QUEUE_STATUS_PENDING
            );
            newQueues.add(newQueue);
            map_queueKey_Queue.put(queueKey, newQueue);
        }
        if (!newQueues.isEmpty()) {
            insert newQueues;
        }
        
        //create optimization queue items
        List<sked_Optimization_Queue_Item__c> queueItems = new List<sked_Optimization_Queue_Item__c>();
        for (string queueKey : map_queueKey_Drives.keySet()) {
            sked_Optimization_Queue__c queue = map_queueKey_Queue.get(queueKey);
            List<sked_Drive__c> drives = map_queueKey_Drives.get(queueKey);
            for (sked_Drive__c drive : drives) {
                sked_Optimization_Queue_Item__c queueItem = new sked_Optimization_Queue_Item__c(
                    sked_Optimization_Queue__c = queue.Id,
                    sked_Drive__c = drive.Id,
                    sked_Type__c = 'Selected'
                );
                queueItems.add(queueItem);
            }
        }
        if (!queueItems.isEmpty()) {
            insert queueItems;
        }
        return newQueues;
    }
    
    public static void indicateInheritances(List<sked_Optimization_Queue__c> inputQueues) {
    	Set<Id> queueIds = new Set<Id>();
        for (sked_Optimization_Queue__c queue : inputQueues) {
            queueIds.add(queue.Id);
        }
        if (!queueIds.isEmpty()) {
            List<sked_Optimization_Queue__c> skedQueues = [SELECT Id,
                                                           (SELECT Id, sked_Drive__c, 
                                                            sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Total_Staff_Requested__c,
                                                            sked_Drive__r.sked_Linked_Drives__r.Name, sked_Drive__r.sked_Linked_Drives__r.sked_Linked_Drive_Type__c
                                                            FROM sked_Optimization_Queue_Items__r WHERE sked_Drive__r.sked_Linked_Drives__c != NULL)
                                                           FROM sked_Optimization_Queue__c WHERE Id IN :queueIds];
            List<sked_Optimization_Queue_Item__c> queueItemsToUpdate = new List<sked_Optimization_Queue_Item__c>();
            for (sked_Optimization_Queue__c skedQueue : skedQueues) {
                Map<string, linkedDriveModel> mapLinkedDrive = new Map<string, linkedDriveModel>();
                
                for (sked_Optimization_Queue_Item__c skedQueueItem : skedQueue.sked_Optimization_Queue_Items__r) {
                    if (skedQueueItem.sked_Drive__r.sked_Linked_Drives__r != NULL) {
                        linkedDriveModel linkedDrive = mapLinkedDrive.get(skedQueueItem.sked_Drive__r.sked_Linked_Drives__r.Name);
                        if (linkedDrive == NULL) {
                            linkedDrive = new linkedDriveModel();
                            linkedDrive.name = skedQueueItem.sked_Drive__r.sked_Linked_Drives__r.Name;
                            linkedDrive.type = skedQueueItem.sked_Drive__r.sked_Linked_Drives__r.sked_Linked_Drive_Type__c;
                            mapLinkedDrive.put(skedQueueItem.sked_Drive__r.sked_Linked_Drives__r.Name, linkedDrive);
                        }
                        if (linkedDrive.queueItemToOptimize == NULL) {
                            linkedDrive.queueItemToOptimize = skedQueueItem;
                        }
                        else {
                            if (linkedDrive.type == skedConstants.LINKED_DRIVE_TYPE_SINGLE) {
                                if (skedQueueItem.sked_Drive__r.sked_Total_Staff_Requested__c > linkedDrive.queueItemToOptimize.sked_Drive__r.sked_Total_Staff_Requested__c) {
                                    linkedDrive.queueItemToOptimize = skedQueueItem;
                                }
                            }
                            else if (linkedDrive.type == skedConstants.LINKED_DRIVE_TYPE_MULTI) {
                                if (skedQueueItem.sked_Drive__r.sked_Drive_Date__c < linkedDrive.queueItemToOptimize.sked_Drive__r.sked_Drive_Date__c) {
                                    linkedDrive.queueItemToOptimize = skedQueueItem;
                                }
                            }
                        }
                    }
                }
                for (sked_Optimization_Queue_Item__c skedQueueItem : skedQueue.sked_Optimization_Queue_Items__r) {
                    if (skedQueueItem.sked_Drive__r.sked_Linked_Drives__r != NULL) {
                        linkedDriveModel linkedDrive = mapLinkedDrive.get(skedQueueItem.sked_Drive__r.sked_Linked_Drives__r.Name);
                        if (skedQueueItem.Id != linkedDrive.queueItemToOptimize.Id) {
                            skedQueueItem.sked_Inherit_Result_From__c = linkedDrive.queueItemToOptimize.Id;
                            queueItemsToUpdate.add(skedQueueItem);
                        }
                    }
                }
            }
            if (!queueItemsToUpdate.isEmpty()) {
                update queueItemsToUpdate;
            }
        }
    }
    
    public static void evaluateOptimizationRunResult(Id optimizationRunId) {
        sked_Optimization_Run__c skedRun = [SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                                            sked_Total_Travel_Time__c, sked_No_of_Percent_Jobs_Filled__c, 
                                            sked_Priority_Role_Scheduled_Percent__c, sked_Average_Hours_per_Staff__c, sked_Collection_Operation__c
                                            FROM sked_Optimization_Run__c
                                            WHERE Id = :optimizationRunId]; 

        //Total Travel Time
        List<AggregateResult> aggregateTravelTimeResult = [SELECT sum(sked_GeoService_Travel_Time_To__c) totalTravelTimeTo,
                                                           sum(sked_GeoService_Travel_Time_Back__c) totalTravelTimeBack
                                                           FROM sked__Job_Allocation__c
                                                           WHERE sked_Optimization_Run__c = :optimizationRunId];
        if (aggregateTravelTimeResult != NULL) {
            decimal totalTravelTimeTo = (Decimal)(aggregateTravelTimeResult.get(0)).get('totalTravelTimeTo');
            decimal totalTravelTimeBack = (Decimal)(aggregateTravelTimeResult.get(0)).get('totalTravelTimeBack');
            totalTravelTimeTo = totalTravelTimeTo != NULL ? totalTravelTimeTo : 0;
            totalTravelTimeBack = totalTravelTimeBack != NULL ? totalTravelTimeBack : 0;
            skedRun.sked_Total_Travel_Time__c = totalTravelTimeTo + totalTravelTimeBack;
        }
        
        //% jobs filled
        List<sked_Optimization_Queue_Item__c> queueItems = [SELECT Id, sked_Drive__c
                                                            FROM sked_Optimization_Queue_Item__c
                                                            WHERE sked_Optimization_Queue__r.sked_Optimization_Run__c = :optimizationRunId];
        Set<Id> driveIds = new Set<Id>();
        for (sked_Optimization_Queue_Item__c queueItem : queueItems) {
            driveIds.add(queueItem.sked_Drive__c);
        }
        
        List<sked__Job__c> optimizedJobs = [SELECT Id, sked__Quantity__c, sked__Job_Allocation_Count__c
                                            FROM sked__Job__c
                                            WHERE sked_Drive__c IN :driveIds
                                            AND sked_Resource_Role__c != NULL
                                            AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED];
        if (!optimizedJobs.isEmpty()) {
            Decimal noOfJobs = optimizedJobs.size();
            Decimal noOfJobFilled = 0;
            for (sked__Job__c optimizedJob : optimizedJobs) {
                if (optimizedJob.sked__Quantity__c == optimizedJob.sked__Job_Allocation_Count__c) {
                    noOfJobFilled += 1;
                }
            }
            skedRun.sked_No_of_Percent_Jobs_Filled__c = (noOfJobFilled / noOfJobs) * 100;
            skedRun.sked_No_of_Percent_Jobs_Filled__c = skedRun.sked_No_of_Percent_Jobs_Filled__c.setScale(2);
        }
        
        //% priority role scheduled
        List<sked__Job_Allocation__c> skedAllocations = [SELECT Id, sked__Resource__c, sked__Job__r.sked_Resource_Role__c,
                                                         sked__Job__r.sked__Duration__c
                                                         FROM sked__Job_Allocation__c
                                                         WHERE sked_Optimization_Run__c = :optimizationRunId];
        if (!skedAllocations.isEmpty()) {
            Set<Id> resourceIds = new Set<Id>();
            for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
                resourceIds.add(skedAllocation.sked__Resource__c);
            }
            
            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id,
                                                                                     (SELECT Id, sked__Tag__r.Name
                                                                                      FROM sked__ResourceTags__r
                                                                                      WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                                                                                      AND sked__Tag__r.sked_Priority__c != NULL
                                                                                      AND sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE
                                                                                      ORDER BY sked__Tag__r.sked_Priority__c ASC 
                                                                                      LIMIT 1)
                                                                                     FROM sked__Resource__c
                                                                                     WHERE Id IN :resourceIds]);
            Decimal noOfJobAllocations = skedAllocations.size();
            Decimal noOfPriorityRoleScheduled = 0;
            Decimal totalDurationAllocated = 0;
            Decimal noOfResourcesAllocated = mapResource.size();
            
            for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
                totalDurationAllocated += skedAllocation.sked__Job__r.sked__Duration__c;
                
                sked__Resource__c skedResource = mapResource.get(skedAllocation.sked__Resource__c);
                if (!skedResource.sked__ResourceTags__r.isEmpty()) {
                    sked__Resource_Tag__c resourcePriorityRole = skedResource.sked__ResourceTags__r.get(0);
                    if (skedAllocation.sked__Job__r.sked_Resource_Role__c == resourcePriorityRole.sked__Tag__r.Name) {
                        noOfPriorityRoleScheduled += 1;
                    }
                }
            }
            skedRun.sked_Priority_Role_Scheduled_Percent__c = (noOfPriorityRoleScheduled / noOfJobAllocations) * 100;
            skedRun.sked_Priority_Role_Scheduled_Percent__c = skedRun.sked_Priority_Role_Scheduled_Percent__c.setScale(2);
            
            //average hours per staff after optimized
            skedRun.sked_Average_Hours_per_Staff__c = (totalDurationAllocated / 60) / noOfResourcesAllocated;
            skedRun.sked_Average_Hours_per_Staff__c = skedRun.sked_Average_Hours_per_Staff__c.setScale(2);
        }
        
        update skedRun;
    }

    //HRP-12511
    @future (callout=true)
    public static void populateOptimizationRunStatParmFields(Set<Id> optimizationIds) {
        skedSkeduloApiManager api = new skedSkeduloApiManager();
        List<sked__Debug_Log__c> debugLogs = new List<sked__Debug_Log__c>();
        List<sked_Optimization_Run__c> optimizationRuns = [SELECT Id, sked_Run_ID__c, sked_Opt_Stat_Total_Planned_Allocations__c, sked_Opt_Stat_Total_Sched_Allocations__c, sked_Opt_Stat_Total_Resource_Sched__c,
                                                    sked_Opt_Stat_Total_Resource_Unsched__c, sked_Opt_Stat_Total_Sched_Time__c, sked_Opt_Stat_Total_Travel_Time__c, sked_Opt_Stat_Total_Travel_Distances__c,
                                                    sked_Opt_Stat_Max_Travel_Time_Alloc__c, sked_Opt_Stat_Avg_Num_Alloc_Resource__c, sked_Opt_Stat_Hard_Constraints_Score__c, sked_Opt_Stat_Soft_Constraints_Score__c,
                                                    sked_Opt_Parm_Accnt_Prefer__c, sked_Opt_Parm_Site_Prefer__c, sked_Opt_Parm_Geo_Prefer__c, sked_Opt_Parm_Hire_Date_Skills__c,sked_Opt_Parm_Role_Priority_Skills__c,
                                                    sked_Opt_Run_Meta__c, sked_Opt_Run_Diff__c   
                                                    FROM sked_Optimization_Run__c WHERE Id IN :optimizationIds];

        List<sked_CollectionOperationOptimizerSetting__c> skedCollectionOptimizerSettings = [SELECT sked_Constraint__c, sked_Optimizer_Mapped_Weight__c
                                                                                             FROM sked_CollectionOperationOptimizerSetting__c
                                                                                             WHERE sked_Optimization_Run__c IN :optimizationIds];              

        if (!optimizationRuns.isEmpty() && !test.isRunningTest()) {
            for (sked_Optimization_Run__c optimizationRun : optimizationRuns) {                                
                try {
                    skedSkeduloApiData.OptimizationRunStatisticsResult optRunStatResponse = api.getOptimizerRunStatistics(optimizationRun.sked_Run_ID__c);
                    skedSkeduloApiData.OptimizationRunParametersResult optRunParmResponse = api.getOptimizerRunParameters(optimizationRun.sked_Run_ID__c);
                    skedSkeduloApiData.optimizationRunMetaResult optRunMetaResponse = api.getOptimizerRunMetaResult(optimizationRun.sked_Run_ID__c);
                    skedSkeduloApiData.optimizationRunDiffResult optRunDiffResponse = api.getOptimizerRunDiffResult(optimizationRun.sked_Run_ID__c);
                    if (optRunStatResponse.success) {
                        skedSkeduloApiData.OptimizationRunStatistics optRunStatResult = optRunStatResponse.result;
                        optimizationRun.sked_Opt_Stat_Total_Planned_Allocations__c = optRunStatResult.totalPlannedAllocations;
                        optimizationRun.sked_Opt_Stat_Total_Sched_Allocations__c = optRunStatResult.totalScheduledAllocations;
                        optimizationRun.sked_Opt_Stat_Total_Resource_Sched__c = optRunStatResult.utilizedResources;
                        optimizationRun.sked_Opt_Stat_Total_Resource_Unsched__c = optRunStatResult.unutilizedResources;
                        optimizationRun.sked_Opt_Stat_Total_Sched_Time__c = optRunStatResult.averageTotalScheduledTimePerUtilizedResourceInMinutes * optRunStatResult.utilizedResources;
                        optimizationRun.sked_Opt_Stat_Total_Travel_Time__c = optRunStatResult.totalTravelTimeInMinutes;
                        optimizationRun.sked_Opt_Stat_Total_Travel_Distances__c = optRunStatResult.totalTravelDistanceInMeters;
                        optimizationRun.sked_Opt_Stat_Max_Travel_Time_Alloc__c = optRunStatResult.maxTravelTimeToAllocationInMinutes;
                        optimizationRun.sked_Opt_Stat_Avg_Num_Alloc_Resource__c = optRunStatResult.averageNumberOfAllocationsPerResource;                
                    }                               
                    if (optRunParmResponse.success) {
                        skedSkeduloApiData.OptimizationRunParameters optRunParmResult = optRunParmResponse.result;            
                        optimizationRun.sked_Opt_Stat_Hard_Constraints_Score__c = optRunParmResult.score.hardScore;
                        optimizationRun.sked_Opt_Stat_Soft_Constraints_Score__c = optRunParmResult.score.softScore;
                        optimizationRun.sked_Opt_Parm_Accnt_Prefer__c = optRunParmResult.weights.pref;
                        optimizationRun.sked_Opt_Parm_Site_Prefer__c = optRunParmResult.weights.pref;
                        optimizationRun.sked_Opt_Parm_Geo_Prefer__c = optRunParmResult.weights.distanceAL;                                        
                    }                    
                    if (optRunMetaResponse.success) {
                        optimizationRun.sked_Opt_Run_Meta__c = JSON.serialize(optRunMetaResponse.allocationMeta);
                    }                    
                    if (optRunDiffResponse.success) {
                        optimizationRun.sked_Opt_Run_Diff__c = JSON.serialize(optRunDiffResponse.allocations);
                    }
                    if (!skedCollectionOptimizerSettings.isEmpty()) {
                        for (sked_CollectionOperationOptimizerSetting__c skedCollectionOptimizerSetting : skedCollectionOptimizerSettings){
                            if (skedCollectionOptimizerSetting.sked_Constraint__c == 'Hire Date') {
                                optimizationRun.sked_Opt_Parm_Hire_Date_Skills__c = skedCollectionOptimizerSetting.sked_Optimizer_Mapped_Weight__c;
                            } else if (skedCollectionOptimizerSetting.sked_Constraint__c == 'Role Priorities') {
                                optimizationRun.sked_Opt_Parm_Role_Priority_Skills__c = skedCollectionOptimizerSetting.sked_Optimizer_Mapped_Weight__c;
                            }
                        }
                    }                                     
                }
                catch(Exception ex) {
                    debugLogs.add(new sked__Debug_Log__c (
                        sked__Type__c = 'Optimizer',
                        sked__Message__c = ex.getMessage(),
                        sked__Summary__c = ex.getStackTraceString()
                    ));
                }                
            }
            update  optimizationRuns;            
        }               
    }

    public static List<JobAllocationWrapper> getJobAllocationsFromRunMetaAndDifference(String runMeta, String runDifference) {
        List<JobAllocationWrapper> jobAllocations = new List<JobAllocationWrapper>(); 
        List<Object> runMetaList = (List<Object>)JSON.deserializeUntyped(runMeta);
        Map<String, Object> runDifferenceMap = (Map<String, Object>)JSON.deserializeUntyped(runDifference);  
        String jobPrefix1 = 'drivercdl'; 
        String jobPrefix2 = 'driverdot';     
        
        for (Object runMetaObj : runMetaList) {
            Map<String, Object> runMetaMap = (Map<String, Object>)runMetaObj;
            String featureAllocId = (String)runMetaMap.get('featureAllocId');
            String jobId = (String)runMetaMap.get('jobId');
            if (jobId.startsWith(jobPrefix1)) {
                jobId = jobId.substring(jobPrefix1.length());
            } else if (jobId.startsWith(jobPrefix2)) {
                jobId = jobId.substring(jobPrefix2.length());
            }            
            if (runDifferenceMap.containsKey(featureAllocId)) {
                Map<String, Object> allocationData = (Map<String, Object>)runDifferenceMap.get(featureAllocId);
                String allocation = (String)allocationData.get('allocation');    
                if (allocation != null) {
                    jobAllocations.add(new JobAllocationWrapper(jobId, allocation));
                }
            }
        }    
        return jobAllocations;
    }

    public static List<sked__Job_Allocation__c> getJobAllocations(List<JobAllocationWrapper> jobAllocations) {
        Set<Id> jobIds = new Set<Id>(); 
        Set<Id> resourceIds = new Set<Id>();      
        for (JobAllocationWrapper jobAlloc : jobAllocations) {            
            jobIds.add(jobAlloc.jobId);
            resourceIds.add(jobAlloc.allocation);            
        }
        List<sked__Job_Allocation__c> jobAllocationRecords = [
            SELECT Id, sked__Job__c, sked__Resource__c, sked_Optimization_Run__c, sked__Resource__r.Name,
            sked__Job__r.sked_Resource_Role__c, sked__Job__r.sked_Drive__c
            FROM sked__Job_Allocation__c
            WHERE sked__Job__c IN :jobIds
            AND sked__Resource__c IN :resourceIds            
        ];            
        return jobAllocationRecords;
    }   

    private static void insertOptimizationRunSettings(initiateOptimizationRunRequestModel request, String collectionOperationId, String optimizationRunId) {
        Biomed_Collection_Op_Center__c collectionOperation = [
                SELECT Id, sked_Low_Weight__c, sked_Medium_Weight__c, sked_High_Weight__c, sked_Role_Priorities_Weight__c
                FROM Biomed_Collection_Op_Center__c
                WHERE Id = :collectionOperationId
                LIMIT 1
            ];
        
        List<sked_CollectionOperationOptimizerSetting__c> optimizeRunSettings = new List<sked_CollectionOperationOptimizerSetting__c>();
        for (optimizationSettingModel setting : request.optimizationSettings) {
            sked_CollectionOperationOptimizerSetting__c optimizeRunSetting = new sked_CollectionOperationOptimizerSetting__c(
                sked_Optimization_Run__c = optimizationRunId,
                sked_Drive_Type__c = setting.driveType,
                sked_Constraint__c = setting.constraint,
                sked_Constraint_Type__c = setting.constraintType,
                sked_Display_Type__c = setting.displayType,
                sked_Default_Weight__c = setting.defaultWeight,
                sked_Enabled__c = setting.enabled
            );
            skedCollectionOpOptimizerSettingUtils.populateOptimizerMappedWeight(optimizeRunSetting, collectionOperation);
            optimizeRunSettings.add(optimizeRunSetting);
        }

        if (!optimizeRunSettings.isEmpty()) {
            insert optimizeRunSettings;
        }
    }

    /*********************************************************** Nested Classes ***********************************************************/
    global class JobAllocationWrapper {
        public String jobId { get; set; }
        public String allocation { get; set; }
        public String uniqueKey { get; set;}
        public JobAllocationWrapper(String jobId, String allocation) {
            this.jobId = jobId;
            this.allocation = allocation;
            this.uniqueKey = jobId + ':' + allocation;
        }
    }
    global class initiateOptimizationRunRequestModel {
        @AuraEnabled public List<string> driveIds {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Date endDate {get;set;}
        @AuraEnabled public List<optimizationSettingModel> optimizationSettings {get;set;}
    }
    
    global class getOptimizationRunsRequestModel {
        @AuraEnabled public List<string> territoryKeys {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Date endDate {get;set;}
    }
    
    global class optimizationSettingModel {
        @AuraEnabled public string constraint {get;set;}
        @AuraEnabled public string constraintType {get;set;}
        @AuraEnabled public string displayType {get;set;}
        @AuraEnabled public string driveType {get;set;}
        @AuraEnabled public string defaultWeight {get;set;}
        @AuraEnabled public boolean enabled {get;set;}
    }
    
    public class linkedDriveModel {
        public string name;
        public string type;
        public sked_Optimization_Queue_Item__c queueItemToOptimize;
    }    
}