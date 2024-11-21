global class skedResourceAverageTravelTimeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    global List<sObject> start(Database.BatchableContext BC) {
        return [SELECT Id
                FROM sked__Resource__c
                WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
                AND sked__Is_Active__c = TRUE];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Resource__c> skedResources) {
        Set<Id> recordIds = new Set<Id>();
        for (sked__Resource__c skedResource : skedResources) {
            recordIds.add(skedResource.Id);
        }
        
        List<AggregateResult> resourceAverageTravelTimeResults = [SELECT sked__Resource__c resourceId, 
                                                                  avg(sked_Travel_Time_To__c) avgTravelTimeTo,
                                                                  avg(sked_Travel_Time_Back__c) avgTravelTimeBack
                                                                  FROM sked__Job_Allocation__c
                                                                  WHERE sked__Resource__c IN :recordIds
                                                                  AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                  AND sked_Travel_Time_To__c != NULL
                                                                  AND sked_Travel_Time_Back__c != NULL
                                                                  GROUP BY sked__Resource__c];
        if (resourceAverageTravelTimeResults != NULL && !resourceAverageTravelTimeResults.isEmpty()) {
            List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();
            for (AggregateResult result : resourceAverageTravelTimeResults) {
                Decimal avgTravelTimeTo = (Decimal)(result.get('avgTravelTimeTo'));
                Decimal avgTravelTimeBack = (Decimal)(result.get('avgTravelTimeBack'));
                sked__Resource__c resourceToUpdate = new sked__Resource__c(
                	Id = (Id)(result.get('resourceId')),
                    sked_Average_Travel_Time_Per_Drive__c = avgTravelTimeTo + avgTravelTimeBack
                );
                resourcesToUpdate.add(resourceToUpdate);
            }
            if (!resourcesToUpdate.isEmpty()) {
                update resourcesToUpdate;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) { }
 
}