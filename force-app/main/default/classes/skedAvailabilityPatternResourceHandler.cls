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
        updateCoApStatusOnResources(this.context.newRecords, (Map<Id, sked__Availability_Pattern_Resource__c>)this.context.oldMap);
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

        Database.saveResult[] updateResults = Database.update(map_resourceId_resourceToUpdate.values(), false);
        insert new List<BSF_Error_Log__c>(BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'Resource CO_AP_Status__c update',
            'skedAvailabilityPatternResourceHandler',
            'updateCoApStatusOnResources on After Insert',
            'Error',
            'Record Update'
        ));
    }

    private void updateCoApStatusOnResources(List<sked__Availability_Pattern_Resource__c> newRecords, Map<Id, sked__Availability_Pattern_Resource__c> oldMap) {
        Map<Id, sked__Resource__c> map_resourceId_resourceToUpdate = new Map<Id, sked__Resource__c>();
        Set<Id> resourceIdsNeedUpdate = new Set<Id>();
        Set<Id> endDatedApIds = new Set<Id>();

        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            sked__Availability_Pattern_Resource__c oldRecord = oldMap.get(newRecord.Id);
            if(newRecord.sked_End_Date__c != oldRecord.sked_End_Date__c && newRecord.sked_End_Date__c <= System.today()) {
                resourceIdsNeedUpdate.add(newRecord.sked__Resource__c);
                endDatedApIds.add(newRecord.sked__Availability_Pattern__c);
            }
        }

        if(!endDatedApIds.isEmpty()) {
            List<sked__Availability_Pattern_Resource__c> existingFutureApResourcesWithProcessedCo = [
                SELECT Id, sked__Resource__c
                FROM sked__Availability_Pattern_Resource__c
                WHERE sked__Availability_Pattern__c IN : endDatedApIds
                AND (sked_End_Date__c = NULL OR sked_End_Date__c >= TODAY)
                AND sked__Resource__r.sked__Resource_Type__c = 'Person'
                AND sked__Resource__r.sked__Is_Active__c = TRUE
                AND sked__Resource__r.CO_AP_Status__c = :skedConstants.CO_AP_STATUS_PROCESSED
                ORDER BY sked__Resource__c
            ];
            
            if(existingFutureApResourcesWithProcessedCo != null && !existingFutureApResourcesWithProcessedCo.isEmpty()) {
                for(sked__Availability_Pattern_Resource__c apResource : existingFutureApResourcesWithProcessedCo) {
                    resourceIdsNeedUpdate.add(apResource.sked__Resource__c);
                }
            }
        }

        for(Id resourceId : resourceIdsNeedUpdate) {
            if(!map_resourceId_resourceToUpdate.containsKey(resourceId)) {
                map_resourceId_resourceToUpdate.put(resourceId, new sked__Resource__c(Id = resourceId, CO_AP_Status__c = skedConstants.CO_AP_STATUS_YET_TO_PROCESS_TOTALS));
            }
        }
        
        Database.saveResult[] updateResults = Database.update(map_resourceId_resourceToUpdate.values(), false);
        insert new List<BSF_Error_Log__c>(BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'Resource CO_AP_Status__c update',
            'skedAvailabilityPatternResourceHandler',
            'updateCoApStatusOnResources  on After Update',
            'Error',
            'Record Update'
        ));
    }

    private void endDateRelatedColOpAvailabilityRecord(List<sked__Availability_Pattern_Resource__c> newRecords, Map<Id, sked__Availability_Pattern_Resource__c> oldMap) {
        Map<String, Date> map_coAndApName_coApEndDate = new Map<String, Date>();
        Map<Id, sObject> sObjectToUpdate = new Map<Id, sObject>();
        Map<String, Decimal> map_apCoId_noOfAssignedResources = new Map<String, Decimal>();
        Set<String> apAndCoIdKey = new Set<String>();

        for(sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            sked__Availability_Pattern_Resource__c oldRecord = oldMap.get(newRecord.Id);
            if(newRecord.sked_End_Date__c != oldRecord.sked_End_Date__c && newRecord.sked_End_Date__c <= System.today()) {
                String mapKey = newRecord.sked_Resource_Primary_CO_Name__c + ' ' + newRecord.sked_Availability_Pattern_Name__c;
                if(!map_coAndApName_coApEndDate.containsKey(mapKey)) {
                    map_coAndApName_coApEndDate.put(mapKey, newRecord.sked_End_Date__c);
                }
                apAndCoIdKey.add(newRecord.sked__Availability_Pattern__c + '_' + newRecord.sked_Resource_Primary_CO__c);
            }
        }

        Set<Id> colIds = new Set<Id>();
        Set<Id> apIds = new Set<Id>();
        
        for(String key : apAndCoIdKey) {
            colIds.add(key.split('_')[1]);
            apIds.add(key.split('_')[0]);
        }

        for (AggregateResult ar : [
            SELECT sked__Availability_Pattern__c apId,
            sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Id resourcePrimaryCo,
            COUNT_DISTINCT(sked__Resource__c) totalActualResources
            FROM sked__Availability_Pattern_Resource__c
            WHERE sked__Resource__r.sked_Collection_Operation_Id__c IN : colIds
            AND sked__Availability_Pattern__c IN : apIds
            AND (sked_End_Date__c = NULL OR sked_End_Date__c > TODAY)
            AND sked__Resource__r.sked__Resource_Type__c = 'Person'
            AND sked__Resource__r.sked__Is_Active__c = TRUE
            GROUP BY sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Id, sked__Availability_Pattern__c
        ]) {
            map_apCoId_noOfAssignedResources.put((String)ar.get('apId') + '_' + (String)ar.get('resourcePrimaryCo') , (Decimal)ar.get('totalActualResources'));
        }

        for(String apAndCoId : apAndCoIdKey) {
            if(map_apCoId_noOfAssignedResources.containsKey(apAndCoId) && map_apCoId_noOfAssignedResources.get(apAndCoId) >= 1) {
                apAndCoIdKey.remove(apAndCoId);
            }
        }

        List<Collection_Operation_Availability__c> existingCoApRecords = [
            SELECT Id, Name, Effective_End_Date__c, Availability_Pattern__c,
            Collection_Operation__c, Collection_Operation__r.Grand_Total_Available_AP__c,
            Total_Actual_Resources__c
            FROM Collection_Operation_Availability__c
            WHERE Name IN :map_coAndApName_coApEndDate.keySet()
        ];

        for(Collection_Operation_Availability__c coAp : existingCoApRecords) {
            if(!apAndCoIdKey.contains(coAp.Availability_Pattern__c + '_' + coAp.Collection_Operation__c)) continue;

            coAp.Effective_End_Date__c = map_coAndApName_coApEndDate.get(coAp.Name);
            sObjectToUpdate.put(coAp.Id, coAp);

            if(!sObjectToUpdate.containsKey(coAp.Collection_Operation__c)) {
                sObjectToUpdate.put(coAp.Collection_Operation__c, new Biomed_Collection_Op_Center__c(Id = coAp.Collection_Operation__c, Grand_Total_Available_AP__c = coAp.Collection_Operation__r.Grand_Total_Available_AP__c));
            }
            ((Biomed_Collection_Op_Center__c)sObjectToUpdate.get(coAp.Collection_Operation__c)).Grand_Total_Available_AP__c -= coAp.Total_Actual_Resources__c;
        }

        sObjectToUpdate.values().sort();
        Database.saveResult[] updateResults = Database.update(sObjectToUpdate.values(), false);
        insert new List<BSF_Error_Log__c>(BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'CO AP / CO update',
            'skedAvailabilityPatternResourceHandler',
            'endDateRelatedColOpAvailabilityRecord',
            'Error',
            'Record Update'
        ));
    }
}