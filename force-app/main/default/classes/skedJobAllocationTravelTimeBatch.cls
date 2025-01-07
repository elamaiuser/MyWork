global class skedJobAllocationTravelTimeBatch implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private Set<Id> processedJobAllocationIds = new Set<Id>();
    global static void schedule() {
        skedUtils.scheduleUniqueJobInSeconds('skedJobAllocationTravelTimeBatch', new skedJobAllocationTravelTimeBatch(), 15, true);
    }

    global void execute(SchedulableContext SC) {
        Integer existingBatchCount = [
            SELECT COUNT() 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'skedJobAllocationTravelTimeBatch' 
            AND JobType = 'BatchApex' 
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
        if (existingBatchCount == 0) {
            Database.executeBatch(new skedJobAllocationTravelTimeBatch(), 40);
        }
    }
    
    global List<sObject> start(Database.BatchableContext BC) {
        return this.queryJobAllocations();
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> skedAllocations) {
        skedJobAllocationTravelTimeService.jobAllocationTravelDataRequest travelDataRequest = new skedJobAllocationTravelTimeService.jobAllocationTravelDataRequest();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            travelDataRequest.jobAllocationRequestModels.add(new skedJobAllocationTravelTimeService.jobAllocationRequestModel(skedAllocation.Id));
        }

        skedJobAllocationTravelTimeService.jobAllocationTravelDataResult travelDataResult = skedJobAllocationTravelTimeService.calculateTravelTime(travelDataRequest);

        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            this.processedJobAllocationIds.add(skedAllocation.Id);
            skedJobAllocationTravelTimeService.jobAllocationModel jobAllocationWithTravelData = travelDataResult.getJobAllocationById(skedAllocation.Id);
            if (jobAllocationWithTravelData != null) {
                skedAllocation.sked_Travel_Time_To__c = jobAllocationWithTravelData.travelTimeTo;
                skedAllocation.sked_Travel_Time_Back__c = jobAllocationWithTravelData.travelTimeBack;
                skedAllocation.sked_Geoservice_Travel_Distance_Back__c = jobAllocationWithTravelData.geoServiceTravelDistanceBack;
                skedAllocation.sked_Geoservice_Travel_Distance_To__c = jobAllocationWithTravelData.geoServiceTravelDistanceTo;
                skedAllocation.sked_Geoservice_Travel_Time_Back__c = jobAllocationWithTravelData.geoServiceTravelTimeBack;
                skedAllocation.sked_Geoservice_Travel_Time_To__c = jobAllocationWithTravelData.geoServiceTravelTimeTo;
                skedAllocation.sked_Is_Relocated_Resource__c = jobAllocationWithTravelData.isRelocatedResource;
                skedAllocation.sked__Start__c = jobAllocationWithTravelData.start;
                skedAllocation.sked__Set_End__c = jobAllocationWithTravelData.setEnd;
                skedAllocation.sked__Duration__c = jobAllocationWithTravelData.duration;
            }
            skedAllocation.sked_Completed_Post_Processes__c = skedUtils.addNewItemToMultiPicklist(skedAllocation.sked_Completed_Post_Processes__c, skedConstants.JOB_ALLOCATION_POST_PROCESS_TRAVEL_TIME);
        }
        
        update skedAllocations;
    }
    
    global void finish(Database.BatchableContext BC) {
        //verify if job allocations are created by optimization run
        List<sked__Job_Allocation__c> jaQuery = [SELECT Id, sked_Optimization_Run__c
                                                 FROM sked__Job_Allocation__c
                                                 WHERE Id IN : this.processedJobAllocationIds
                                                 AND sked_Optimization_Run__c != NULL
                                                 LIMIT 1];
        if (!jaQuery.isEmpty()) {
            slwcOptimizationService.evaluateOptimizationRunResult(jaQuery.get(0).sked_Optimization_Run__c);
        }

        List<sked__Job_Allocation__c> remainingJobAllocations = this.queryJobAllocations();
        if (!remainingJobAllocations.isEmpty()) {
            Database.executeBatch(new skedJobAllocationTravelTimeBatch(), 40);
        }

        skedJobAllocationPostProcessBatch.schedule();
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private List<sked__Job_Allocation__c> queryJobAllocations() {
        return [SELECT Id, sked_Completed_Post_Processes__c
                FROM sked__Job_Allocation__c
                WHERE (sked_Travel_Time_To__c = NULL OR sked_Travel_Time_Back__c = NULL)
                AND sked__Job__r.sked_Drive__r.sked_Collection_Operation__c != NULL
                AND sked__Job__r.sked_Drive__r.sked_Drive_Site__c != NULL
                AND (sked__Resource__r.sked__GeoLocation__Latitude__s != NULL AND sked__Resource__r.sked__GeoLocation__Longitude__s != NULL)
                AND sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
                AND sked__Status__c NOT IN ('Deleted', 'Declined', 'Complete')
                AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c  >= TODAY
                AND sked__Job__r.sked_Drive__r.sked_Status__c NOT IN ('Cancel', 'Complete')
                AND sked_Completed_Post_Processes__c EXCLUDES ('Travel Time')
                LIMIT 50000
        ];
    }
}