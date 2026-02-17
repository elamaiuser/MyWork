public without sharing class CollectionOpAvailabilityTriggerService {

    public static void updateCoApStatusOnResources(List<Collection_Operation_Availability__c> newList, Map<Id, Collection_Operation_Availability__c> oldMap) {
        Set<Id> colOpIds = new Set<Id>();
        Set<Id> apIds = new Set<Id>();
        List<sked__Resource__c> resourceListToUpdate = new List<sked__Resource__c>();
        
        for(Collection_Operation_Availability__c newCoAp : newList) {
            Collection_Operation_Availability__c oldCoAp = oldMap?.get(newCoAp.Id) ?? null;

            if(oldCoAp != null)  {
                if(oldCoAp.Min_Nbr_of_Staff__c != newCoAp.Min_Nbr_of_Staff__c 
                    && newCoAp.Min_Nbr_of_Staff__c > 0 
                    && newCoAp.Effective_End_Date__c > System.today()
                ) {
                    colOpIds.add(newCoAp.Collection_Operation__c);
                    apIds.add(newCoAp.Availability_Pattern__c);
                }
            }
        }

        List<sked__Availability_Pattern_Resource__c> availabilityPatternResources = [
            SELECT Id, sked__Resource__c,
            sked__Resource__r.CO_AP_Status__c
            FROM sked__Availability_Pattern_Resource__c
            WHERE sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            AND sked__Resource__r.sked__Is_Active__c = true
            AND (sked_End_Date__c = null OR sked_End_Date__c > TODAY)
            AND sked__Resource__r.sked_Collection_Operation_Id__c IN :colOpIds
            AND sked__Availability_Pattern__c IN :apIds
            ORDER BY sked__Resource__c
        ];
        
        for(sked__Availability_Pattern_Resource__c apResource : availabilityPatternResources) {
            resourceListToUpdate.add(new sked__Resource__c(
                Id = apResource.sked__Resource__c,
                CO_AP_Status__c = skedConstants.CO_AP_STATUS_YET_TO_PROCESS_TOTALS
            ));
        }

        skedHubBase.BypassUpdateTriggers = true;
        Database.SaveResult[] updateResults = Database.update(resourceListToUpdate, false);
        insert new List<BSF_Error_Log__c>(BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'Resource Records update',
            'CollectionOpAvailabilityTriggerService',
            'updateCoApStatusOnResources',
            'Error',
            'Record Update'
        ));
        skedHubBase.BypassUpdateTriggers = false;
    }
}