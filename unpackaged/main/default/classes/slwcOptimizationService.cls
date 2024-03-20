global class slwcOptimizationService {
    
    @AuraEnabled
    public static slwcAuraResult initiateOptimizationRun(initiateOptimizationRunRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
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
            sked_Is_Dev__c = skedSetting.instance.Admin.runOptimizationOnDev,
            sked_Account_Preferences_Score__c = request.optimizationSetting.accountPreferencesScore,
            sked_Geographic_Preferences_Score__c = request.optimizationSetting.geographicPreferencesScore,
            sked_Location_Preferences_Score__c = request.optimizationSetting.locationPreferencesScore,
            sked_Seniority_Rank_Score__c = request.optimizationSetting.seniorityRankScore,
            sked_Account_Restrictions__c = request.optimizationSetting.accountRestrictions,
            sked_Location_Restrictions__c = request.optimizationSetting.locationRestrictions,
            sked_Maximum_Weekly_Hours__c = request.optimizationSetting.maximumWeeklyHours,
            sked_PTO_Availability__c = request.optimizationSetting.ptoAvailability,
            sked_Role_Certification_Match__c = request.optimizationSetting.roleCertificationMatch,
            sked_Role_Priorities__c = request.optimizationSetting.rolePriorities
        );
        insert newRun;

        for (sked_Optimization_Queue__c newQueue : newQueues) {
            newQueue.sked_Optimization_Run__c = newRun.Id;
        }
        update newQueues;

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
    
    
    /*********************************************************** Private methods ***********************************************************/
    private static List<sked_Optimization_Queue__c> addDrivesToQueues(initiateOptimizationRunRequestModel request) {
        List<sked_Drive__c> drivesToAddToQueues = [SELECT Id, sked_Collection_Operation__c,
                                                   sked_Drive_Date__c, sked_Type_of_Drive__c
                                                   FROM sked_Drive__c
                                                   WHERE Id IN :request.driveIds];
        Map<string, List<sked_Drive__c>> map_queueKey_Drives = new Map<string, List<sked_Drive__c>>();
        for (sked_Drive__c skedDrive : drivesToAddToQueues) {
            string startDateStr = Json.serialize(request.startDate).replace('"', '');
            string key = startDateStr + ':' + skedDrive.sked_Collection_Operation__c + ':' + skedDrive.sked_Type_of_Drive__c;
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
                    sked_Drive__c = drive.Id
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
                                                            FROM sked_Optimization_Queue_Items__r)
                                                           FROM sked_Optimization_Queue__c];
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
                                            sked_Priority_Role_Scheduled_Percent__c, sked_Average_Hours_per_Staff__c 
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
    
    /*********************************************************** Nested Classes ***********************************************************/
    global class initiateOptimizationRunRequestModel {
        @AuraEnabled public List<string> driveIds {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Date endDate {get;set;}
        @AuraEnabled public optimizationSettingModel optimizationSetting {get;set;}
    }
    
    global class getOptimizationRunsRequestModel {
        @AuraEnabled public List<string> territoryKeys {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Date endDate {get;set;}
    }
    
    global class optimizationSettingModel {
        @AuraEnabled public string accountPreferencesScore {get;set;}
        @AuraEnabled public string geographicPreferencesScore {get;set;}
        @AuraEnabled public string locationPreferencesScore {get;set;}
        @AuraEnabled public string seniorityRankScore {get;set;}
        
        @AuraEnabled public boolean accountRestrictions {get;set;}
        @AuraEnabled public boolean locationRestrictions {get;set;}
        @AuraEnabled public boolean maximumWeeklyHours {get;set;}
        @AuraEnabled public boolean ptoAvailability {get;set;}
        @AuraEnabled public boolean roleCertificationMatch {get;set;}
        @AuraEnabled public boolean rolePriorities {get;set;}
    }
    
    public class linkedDriveModel {
        public string name;
        public string type;
        public sked_Optimization_Queue_Item__c queueItemToOptimize;
    }
    
}