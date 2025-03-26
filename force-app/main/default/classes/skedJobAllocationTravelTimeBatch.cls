global class skedJobAllocationTravelTimeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    protected Set<Id> jobAllocationIds;
    
    global skedJobAllocationTravelTimeBatch(Set<Id> jobAllocationIds) {
        this.jobAllocationIds = jobAllocationIds;
    }
    
    global List<sObject> start(Database.BatchableContext BC) {
        return [SELECT Id
                FROM sked__Job_Allocation__c
                WHERE Id IN :this.jobAllocationIds
                AND (sked_Travel_Time_To__c = NULL OR sked_Travel_Time_Back__c = NULL)
                AND sked__Job__r.sked_Drive__r.sked_Collection_Operation__c != NULL
                AND sked__Job__r.sked_Drive__r.sked_Drive_Site__c != NULL
                AND (sked__Resource__r.sked__GeoLocation__Latitude__s != NULL AND sked__Resource__r.sked__GeoLocation__Longitude__s != NULL)
        ];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> skedAllocations) {
        skedJobAllocationTravelTimeService.jobAllocationTravelDataRequest travelDataRequest = new skedJobAllocationTravelTimeService.jobAllocationTravelDataRequest();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            travelDataRequest.jobAllocationRequestModels.add(new skedJobAllocationTravelTimeService.jobAllocationRequestModel(skedAllocation.Id));
        }

        skedJobAllocationTravelTimeService.jobAllocationTravelDataResult travelDataResult = skedJobAllocationTravelTimeService.calculateTravelTime(travelDataRequest);

        List<sked__Job_Allocation__c> skedAllocationsToUpdate = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
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
                skedAllocationsToUpdate.add(skedAllocation);
            }
        }
        
        if (skedAllocationsToUpdate.size() > 0) {
            update skedAllocations;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        //verify if job allocations are created by optimization run
        List<sked__Job_Allocation__c> jaQuery = [SELECT Id, sked_Optimization_Run__c
                                                 FROM sked__Job_Allocation__c
                                                 WHERE Id IN : this.jobAllocationIds
                                                 AND sked_Optimization_Run__c != NULL
                                                 LIMIT 1];
        if (!jaQuery.isEmpty()) {
            slwcOptimizationService.evaluateOptimizationRunResult(jaQuery.get(0).sked_Optimization_Run__c);
        }
        
        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, this.jobAllocationIds), 100);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
}