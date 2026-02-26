global class skedNightlyUpdateCoApRoleTargetsBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    private List<BSF_Error_Log__c> errorLogListToInsert = new List<BSF_Error_Log__c>();
    private Set<Id> primaryCoIds = new Set<Id>();
    private static final List<String> includedResourceCoApStatus = new List<String>{
        skedConstants.CO_AP_STATUS_YET_TO_PROCESS_CO,
        skedConstants.CO_AP_STATUS_YET_TO_PROCESS_TOTALS,
        skedConstants.CO_AP_STATUS_ERROR
    };

    public skedNightlyUpdateCoApRoleTargetsBatch() {}

    public skedNightlyUpdateCoApRoleTargetsBatch(Set<Id> primaryCoIds) {
        this.primaryCoIds = primaryCoIds;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 
            'SELECT Id, Name, sked__Status__c, sked__Availability_Pattern__c, sked__Resource__c, sked__Resource__r.CO_AP_Status__c, '+
            'sked__Availability_Pattern__r.Name, sked__Resource__r.Name, sked__Resource__r.sked_Collection_Operation_Id__c, '+
            'sked__Resource__r.sked_Biomed_Collection_Op_Center_Name__c, sked__Resource__r.sked__Primary_Region__c '+
            'FROM sked__Availability_Pattern_Resource__c '+
            'WHERE sked__Resource__r.sked__Resource_Type__c = \'' + skedConstants.RESOURCE_TYPE_PERSON + '\' '+
            'AND sked__Resource__r.sked__Is_Active__c = true '+
            'AND (sked__Resource__r.CO_AP_Status__c = null OR sked__Resource__r.CO_AP_Status__c IN :includedResourceCoApStatus) '+
            'AND (sked_End_Date__c = null OR sked_End_Date__c > TODAY) ';

        if(!this.primaryCoIds.isEmpty()) {
            query += 'AND sked__Resource__r.sked_Collection_Operation_Id__c IN :primaryCoIds ';
        }
        query += 'ORDER BY sked__Resource__c';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<sked__Availability_Pattern_Resource__c> availabilityPatternResources) {
        Map<String, Set<String>> map_coIdName_uniqueApIdNames = new Map<String, Set<String>>();
        Map<String, Set<String>> map_coIdName_uniqueApIdNamesCopy = new Map<String, Set<String>>();
        Set<Id> resourceIds = new Set<Id>();

        for(sked__Availability_Pattern_Resource__c apResource : availabilityPatternResources) {
            resourceIds.add(apResource.sked__Resource__c);

            String mapKey = apResource.sked__Resource__r.sked_Collection_Operation_Id__c + '_' + apResource.sked__Resource__r.sked_Biomed_Collection_Op_Center_Name__c;
            if(!map_coIdName_uniqueApIdNames.containsKey(mapKey)) {
                map_coIdName_uniqueApIdNames.put(mapKey, new Set<String>());
            }
            map_coIdName_uniqueApIdNames.get(mapKey).add(apResource.sked__Availability_Pattern__c + '_' + apResource.sked__Availability_Pattern__r.Name);
        }

        for (String key : map_coIdName_uniqueApIdNames.keySet()) {
            map_coIdName_uniqueApIdNamesCopy.put(
                key,
                new Set<String>(map_coIdName_uniqueApIdNames.get(key))
            );
        }

        errorLogListToInsert.addAll(skedUpdateCoApRoleTargetsBatchHelper.autoAssignCollectionOpAvailabilityRecordsAndGetErrorLogs(map_coIdName_uniqueApIdNames));
        errorLogListToInsert.addAll(skedUpdateCoApRoleTargetsBatchHelper.calculateTotalsAndUpdateCoApStatusOnResources(resourceIds, map_coIdName_uniqueApIdNamesCopy));
    }

    global void finish(Database.BatchableContext bc) {
        if(!this.errorLogListToInsert.isEmpty()) {
            insert this.errorLogListToInsert;
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new skedNightlyUpdateCoApRoleTargetsBatch(), 100);
    }

}