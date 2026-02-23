public class skedAvailabilityPatternResourceHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onAfterInsert() {
        captureAPExceptionLogs(this.context.newRecords);
        updateCoApStatusOnResources(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        populateData(this.context.newRecords, (Map<Id, sked__Availability_Pattern_Resource__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Availability_Pattern_Resource__c>)this.context.oldMap);
        }
    }

    public override void onAfterUpdate() {
        endDateRelatedColOpAvailabilityRecord(this.context.newRecords, (Map<Id, sked__Availability_Pattern_Resource__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void captureAPExceptionLogs(List<sked__Availability_Pattern_Resource__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        DateTime currentTime = system.now();
        
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }
        
        List<sked__Activity_Resource__c> skedActivityResources = [
            SELECT Id, sked_Start1__c, sked_End__c
            FROM sked__Activity_Resource__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked_End__c > :currentTime
        ];
        
        Set<Id> impactedActivityResourceIds = new Set<Id>();
        for (sked__Activity_Resource__c skedActivityResource : skedActivityResources) {
            impactedActivityResourceIds.add(skedActivityResource.Id);
        }
        
        if (!impactedActivityResourceIds.isEmpty()) {
            if (!System.isBatch() && !Test.isRunningTest()) {
                Database.executeBatch(new skedCaptureAPExceptionLogBatch(impactedActivityResourceIds), 50);
            }
        }
    }
    
    private void doDateTimeConversion(List<sked__Availability_Pattern_Resource__c> newRecords) {
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked__Availability_Pattern_Resource__c> newRecords, Map<Id, sked__Availability_Pattern_Resource__c> oldMap) {
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            sked__Availability_Pattern_Resource__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }

    private void populateData(List<sked__Availability_Pattern_Resource__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
            
            if (newRecord.sked__End__c == NULL && newRecord.sked_End_Date__c == NULL) {
                newRecord.sked__End__c = skedDateTimeUtils.MAX_DATETIME;
            }
        }
        
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__c, sked__Primary_Region__r.sked__Timezone__c,
                                                                                 sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked__Resource__c) && mapResource.containsKey(newRecord.sked__Resource__c)) {
                sked__Resource__c resource = mapResource.get(newRecord.sked__Resource__c);
                if (resource.sked__Primary_Region__c != NULL) {
                    newRecord.sked_Timezone__c = resource.sked__Primary_Region__r.sked__Timezone__c;
                }
            }
        }
    }
    
    private void populateData(List<sked__Availability_Pattern_Resource__c> newRecords, Map<Id, sked__Availability_Pattern_Resource__c> oldMap) {
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            if (newRecord.sked__End__c == NULL && newRecord.sked_End_Date__c == NULL) {
                newRecord.sked__End__c = skedDateTimeUtils.MAX_DATETIME;
            }
        }
    }

    private void updateCoApStatusOnResources(List<sked__Availability_Pattern_Resource__c> newRecords) {
        Map<Id, sked__Resource__c> map_resourceId_resourceToUpdate = new Map<Id, sked__Resource__c>();
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            if(!map_resourceId_resourceToUpdate.containsKey(newRecord.sked__Resource__c)) {
                map_resourceId_resourceToUpdate.put(newRecord.sked__Resource__c, new sked__Resource__c(Id = newRecord.sked__Resource__c, CO_AP_Status__c = skedConstants.CO_AP_STATUS_YET_TO_PROCESS_CO));
            }
        }

        skedHubBase.BypassUpdateTriggers = true;
        Database.saveResult[] updateResults = Database.update(map_resourceId_resourceToUpdate.values(), false);
        insert new List<BSF_Error_Log__c>(BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'Resource CO_AP_Status__c update',
            'skedAvailabilityPatternResourceHandler',
            'updateCoApStatusOnResources',
            'Error',
            'Record Update'
        ));
        skedHubBase.BypassUpdateTriggers = false;
    }

    private void endDateRelatedColOpAvailabilityRecord(List<sked__Availability_Pattern_Resource__c> newRecords, Map<Id, sked__Availability_Pattern_Resource__c> oldMap) {
        Map<String, Date> map_coAndApName_coApEndDate = new Map<String, Date>();
        Map<Id, sObject> sObjectToUpdate = new Map<Id, sObject>();

        for(sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            sked__Availability_Pattern_Resource__c oldRecord = oldMap.get(newRecord.Id);
            if(newRecord.sked_End_Date__c != oldRecord.sked_End_Date__c && newRecord.sked_End_Date__c <= System.today()) {
                String mapKey = newRecord.sked_Resource_Primary_CO_Name__c + ' ' + newRecord.sked_Availability_Pattern_Name__c;
                if(!map_coAndApName_coApEndDate.containsKey(mapKey)) {
                    map_coAndApName_coApEndDate.put(mapKey, newRecord.sked_End_Date__c);
                }
            }
        }

        List<Collection_Operation_Availability__c> existingCoApRecords = [
            SELECT Id, Effective_End_Date__c,
            Collection_Operation__c, Collection_Operation__r.Grand_Total_Available_AP__c,
            Total_Actual_Resources__c
            FROM Collection_Operation_Availability__c
            WHERE Name IN :map_coAndApName_coApEndDate.keySet()
        ];

        for(Collection_Operation_Availability__c coAp : existingCoApRecords) {
            coAp.Effective_End_Date__c = map_coAndApName_coApEndDate.get(coAp.Name);
            if(!sObjectToUpdate.containsKey(coAp.Collection_Operation__c)) {
                sObjectToUpdate.put(coAp.Collection_Operation__c, new Biomed_Collection_Op_Center__c(Id = coAp.Collection_Operation__c, Grand_Total_Available_AP__c = coAp.Collection_Operation__r.Grand_Total_Available_AP__c));
            }
            ((Biomed_Collection_Op_Center__c)sObjectToUpdate.get(coAp.Collection_Operation__c)).Grand_Total_Available_AP__c -= coAp.Total_Actual_Resources__c;
        }

        sObjectToUpdate.putAll(existingCoApRecords);
        skedHubBase.BypassUpdateTriggers = true;
        Database.saveResult[] updateResults = Database.update(sObjectToUpdate.values(), false);
        insert new List<BSF_Error_Log__c>(BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'CO AP / CO update',
            'skedAvailabilityPatternResourceHandler',
            'endDateRelatedColOpAvailabilityRecord',
            'Error',
            'Record Update'
        ));
        skedHubBase.BypassUpdateTriggers = false;
    }
}