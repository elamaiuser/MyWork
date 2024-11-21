public class skedResourceOverrideHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onAfterInsert() {
        upsertTravelActivities(this.context.newRecords);
        if (!skedSetting.instance.Admin.migrationMode) {
            closeOutOfCoExceptions(this.context.newRecords);
            createOutOfCoExceptionLogs(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Resource_Override__c>)this.context.oldMap);
        }
    }
    
    public override void onAfterUpdate() {
        upsertTravelActivities(this.context.newRecords, (Map<Id, sked__Resource_Override__c>) this.context.oldMap);
        if (!skedSetting.instance.Admin.migrationMode) {
            closeOutOfCoExceptions(this.context.newRecords, (Map<Id, sked__Resource_Override__c>) this.context.oldMap);
            createOutOfCoExceptionLogs(this.context.newRecords, (Map<Id, sked__Resource_Override__c>) this.context.oldMap);
        }
    }
    
    public override void onBeforeDelete() {
        deleteTravelActivities((Map<Id, sked__Resource_Override__c>) this.context.oldMap);
    }

    public override void onAfterDelete() {
        if (!skedSetting.instance.Admin.migrationMode) {
            closeOutOfCoExceptions(this.context.oldRecords);
            createOutOfCoExceptionLogs(this.context.oldRecords);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void deleteTravelActivities(Map<Id, sked__Resource_Override__c> oldMap) {
        delete [SELECT Id FROM sked__Activity__c WHERE sked_Resource_Override__c IN :oldMap.keySet()];
    }
    
    private void populateData(List<sked__Resource_Override__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource_Override__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__c, sked__Primary_Region__r.sked__Timezone__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        
        for (sked__Resource_Override__c newRecord : newRecords) {
            sked__Resource__c resource = mapResource.get(newRecord.sked__Resource__c);
            newRecord.sked_Timezone__c = resource.sked__Primary_Region__r.sked__Timezone__c;
        }
    }

    private void doDateTimeConversion(List<sked__Resource_Override__c> newRecords) {
        for (sked__Resource_Override__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Travel_Back_End__c', 'sked_Travel_Back_End_Date__c', 'sked_Travel_Back_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Travel_Back_Start__c', 'sked_Travel_Back_Start_Date__c', 'sked_Travel_Back_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Travel_To_End__c', 'sked_Travel_To_End_Date__c', 'sked_Travel_To_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Travel_To_Start__c', 'sked_Travel_To_Start_Date__c', 'sked_Travel_To_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked__Resource_Override__c> newRecords, Map<Id, sked__Resource_Override__c> oldMap) {
        for (sked__Resource_Override__c newRecord : newRecords) {
            sked__Resource_Override__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Travel_Back_End__c', 'sked_Travel_Back_End_Date__c', 'sked_Travel_Back_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Travel_Back_Start__c', 'sked_Travel_Back_Start_Date__c', 'sked_Travel_Back_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Travel_To_End__c', 'sked_Travel_To_End_Date__c', 'sked_Travel_To_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Travel_To_Start__c', 'sked_Travel_To_Start_Date__c', 'sked_Travel_To_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void upsertTravelActivities(List<sked__Resource_Override__c> newRecords) {
        Map<Id, sked__Resource_Override__c> resourceOverridesById = new Map<Id, sked__Resource_Override__c>();
        for (sked__Resource_Override__c newRecord : newRecords) {
            resourceOverridesById.put(newRecord.Id, newRecord);
        }
        List<sked__Resource_Override__c> resourceOverrides = [
            SELECT Id, sked__Resource__c, sked_Travel_To_Start__c, sked_Travel_To_End__c, 
            sked_Travel_Back_Start__c, sked_Travel_Back_End__c, sked_Timezone__c,
            sked_Collection_Operation__c, sked_District__c, sked_Is_Travel_Required__c,
            (SELECT Id, sked__Resource__c, sked__Start__c, sked__End__c, sked__Type__c,
             sked_Resource_Override__c
             FROM sked_Activities__r)
            FROM sked__Resource_Override__c
            WHERE Id = :resourceOverridesById.keySet()
        ];

        List<sked__Activity__c> activitiesToInsert = new List<sked__Activity__c>();
        List<sked__Activity__c> activitiesToUpdate = new List<sked__Activity__c>();
        List<sked__Activity__c> activitiesToDelete = new List<sked__Activity__c>();
        for (sked__Resource_Override__c resourceOverride : resourceOverrides) {
            if (resourceOverride.sked_Is_Travel_Required__c == TRUE) {
                Boolean isUpdate = false;
                sked__Activity__c travelToActivity = new sked__Activity__c(
                    sked_Resource_Override__c = resourceOverride.Id,
                    sked_Collection_Operation__c = resourceOverride.sked_Collection_Operation__c,
                    sked_District__c = resourceOverride.sked_District__c,
                    sked_Activity_Title__c = 'Travel To',
                    sked__Type__c = 'Travel To',
                    sked_Show_On_Calendar__c = TRUE,
                    sked_Is_Group_Activity__c = TRUE,
                    sked__Timezone__c = resourceOverride.sked_Timezone__c
                );
                sked__Activity__c travelBackActivity = new sked__Activity__c(
                    sked_Resource_Override__c = resourceOverride.Id,
                    sked_Collection_Operation__c = resourceOverride.sked_Collection_Operation__c,
                    sked_District__c = resourceOverride.sked_District__c,
                    sked_Activity_Title__c = 'Travel Back',
                    sked__Type__c = 'Travel Back',
                    sked_Show_On_Calendar__c = TRUE,
                    sked_Is_Group_Activity__c = TRUE,
                    sked__Timezone__c = resourceOverride.sked_Timezone__c
                );
                
                if (resourceOverride.sked_Activities__r != NULL && !resourceOverride.sked_Activities__r.isEmpty()) {
                    isUpdate = true;
                    for (sked__Activity__c skedActivity : resourceOverride.sked_Activities__r) {
                        if (skedActivity.sked__Type__c == 'Travel To') {
                            travelToActivity = skedActivity;
                        }
                        else if (skedActivity.sked__Type__c == 'Travel Back') {
                            travelBackActivity = skedActivity;
                        }
                    }
                }
                travelToActivity.sked__Start__c = resourceOverride.sked_Travel_To_Start__c;
                travelToActivity.sked__End__c = resourceOverride.sked_Travel_To_End__c;
                travelBackActivity.sked__Start__c = resourceOverride.sked_Travel_Back_Start__c;
                travelBackActivity.sked__End__c = resourceOverride.sked_Travel_Back_End__c;
                
                if (isUpdate) {
                    activitiesToUpdate.addAll(new List<sked__Activity__c>{travelToActivity, travelBackActivity});
                } else {
                    activitiesToInsert.addAll(new List<sked__Activity__c>{travelToActivity, travelBackActivity});
                }
            }
            else {
                if (resourceOverride.sked_Activities__r != NULL && !resourceOverride.sked_Activities__r.isEmpty()) {
                    activitiesToDelete.addAll(resourceOverride.sked_Activities__r);
                }
            }
        }
        
        if (!activitiesToDelete.isEmpty()) {
            delete activitiesToDelete;
        }

        List<sked__Activity__c> activitiesToUpsert = new List<sked__Activity__c>();
        activitiesToUpsert.addAll(activitiesToUpdate);
        activitiesToUpsert.addAll(activitiesToInsert);
        if (!activitiesToUpsert.isEmpty()) {
            upsert activitiesToUpsert;

            List<sked__Activity_Resource__c> activityResourcesToInsert = new List<sked__Activity_Resource__c>(); 
            for (sked__Activity__c activity : activitiesToInsert) {
                sked__Resource_Override__c resourceOverride = resourceOverridesById.get(activity.sked_Resource_Override__c);
                activityResourcesToInsert.add(new sked__Activity_Resource__c(
                    sked__Activity__c = activity.Id,
                    sked__Resource__c = resourceOverride.sked__Resource__c
                ));
            }
    
            if (!activityResourcesToInsert.isEmpty()) {
                insert activityResourcesToInsert;
            }
        }
    }
    
    private void upsertTravelActivities(List<sked__Resource_Override__c> newRecords, Map<Id, sked__Resource_Override__c> oldMap) {
        List<sked__Resource_Override__c> recordsToUpdateActivities = new List<sked__Resource_Override__c>();
        for (sked__Resource_Override__c newRecord : newRecords) {
            sked__Resource_Override__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Is_Travel_Required__c != oldData.sked_Is_Travel_Required__c
               || newRecord.sked_Travel_To_Start__c != oldData.sked_Travel_To_Start__c
               || newRecord.sked_Travel_To_End__c != oldData.sked_Travel_To_End__c
               || newRecord.sked_Travel_Back_Start__c != oldData.sked_Travel_Back_Start__c
               || newRecord.sked_Travel_Back_End__c != oldData.sked_Travel_Back_End__c) {
                recordsToUpdateActivities.add(newRecord);
            }
        }
        if (!recordsToUpdateActivities.isEmpty()) {
            upsertTravelActivities(recordsToUpdateActivities);
        }
    }

    private void createOutOfCoExceptionLogs(List<sked__Resource_Override__c> newRecords, Map<Id, sked__Resource_Override__c> oldMap) {
        Map<Id, skedModels.startEnd> modelsByResource = new Map<Id, skedModels.startEnd>();
        List<sked__Resource_Override__c> recordsToCheckForException = new List<sked__Resource_Override__c>();
        for (sked__Resource_Override__c newRecord : newRecords) {
            sked__Resource_Override__c oldRecord = oldMap.get(newRecord.Id);
            
            if (newRecord.sked__Start__c != oldRecord.sked__Start__c || newRecord.sked__End__c != oldRecord.sked__End__c 
                || newRecord.sked_Collection_Operation__c != oldRecord.sked_Collection_Operation__c) {
                skedModels.startEnd modelForResource = modelsByResource.get(newRecord.sked__Resource__c);
                if (modelForResource == null) {
                    modelForResource = new skedModels.startEnd();
                }
    
                Date newStartDate = Date.newInstance(newRecord.sked__Start__c.year(), newRecord.sked__Start__c.month(), newRecord.sked__Start__c.day());
                Date newEndDate = Date.newInstance(newRecord.sked__End__c.year(), newRecord.sked__End__c.month(), newRecord.sked__End__c.day());
                Date oldStartDate = Date.newInstance(oldRecord.sked__Start__c.year(), oldRecord.sked__Start__c.month(), oldRecord.sked__Start__c.day());
                Date oldEndDate = Date.newInstance(oldRecord.sked__End__c.year(), oldRecord.sked__End__c.month(), oldRecord.sked__End__c.day());
    
                Date earlierStartDate = newStartDate < oldStartDate ? newStartDate : oldStartDate;
                Date laterEndDate = newEndDate > oldEndDate ? newEndDate : oldEndDate;

                if (modelForResource.startDate == null || earlierStartDate < modelForResource.startDate) modelForResource.startDate = earlierStartDate;
                if (modelForResource.endDate == null || laterEndDate > modelForResource.endDate) modelForResource.endDate = laterEndDate;
                
                modelsByResource.put(newRecord.sked__Resource__c, modelForResource);
            }
        }

        if (!modelsByResource.keyset().isEmpty()) {
            createOutOfCoExceptionLogs(modelsByResource);
        }
    }

    private void createOutOfCoExceptionLogs(List<sked__Resource_Override__c> records) {
        Map<Id, skedModels.startEnd> modelsByResource = new Map<Id, skedModels.startEnd>();
        for (sked__Resource_Override__c record : records) {
            skedModels.startEnd modelForResource = modelsByResource.get(record.sked__Resource__c);
            if (modelForResource == null) {
                modelForResource = new skedModels.startEnd();
            }

            Date newStartDate = Date.newInstance(record.sked__Start__c.year(), record.sked__Start__c.month(), record.sked__Start__c.day());
            Date newEndDate = Date.newInstance(record.sked__End__c.year(), record.sked__End__c.month(), record.sked__End__c.day());

            if (modelForResource.startDate == null || newStartDate < modelForResource.startDate) modelForResource.startDate = newStartDate;
            if (modelForResource.endDate == null || newEndDate > modelForResource.endDate) modelForResource.endDate = newEndDate;

            modelsByResource.put(record.sked__Resource__c, modelForResource);
        }

        if (!modelsByResource.keySet().isEmpty()) {
            createOutOfCoExceptionLogs(modelsByResource);
        }
    }

    private void createOutOfCoExceptionLogs(Map<Id, skedModels.startEnd> modelsByResource) {
        List<skedHC__Exception__c> exceptionsToCreate = new List<skedHC__Exception__c>();
        List<sked__Job_Allocation__c> affectedJobAllocations = skedResourceOverrideUtils.getJobAllocationsForOverrides(modelsByResource);

        if (!affectedJobAllocations.isEmpty()) {
            Set<Id> resourceIds = new Set<Id>();
            Set<Id> jobIds = new Set<Id>();
            for (sked__Job_Allocation__c allocation : affectedJobAllocations) {
                resourceIds.add(allocation.sked__Resource__c);
                jobIds.add(allocation.sked__Job__c);
            }

            Map<Id, sked__Job__c> jobById = new Map<Id, sked__Job__c>([
                SELECT Id, Name, sked_Drive__r.sked_Collection_Operation__c, sked_Drive__r.sked_Drive_Date__c
                FROM sked__Job__c
                WHERE Id IN :jobIds
            ]);

            Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
                SELECT Id, Name, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                    (SELECT Id, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
                    FROM sked_Resource_Biomed_Collection_Ops__r
                    ),
                    (SELECT Id, sked_Collection_Operation__c, sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c
                    FROM sked__Resource_Overrides__r
                    ),
                    (SELECT Id, sked_Exception_Code__c, skedHC__Status__c, sked_Drive__r.sked_Drive_Date__c, skedHC__Job_Allocation__c
                    FROM skedHC__Exception_Log__r
                    WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO
                    )
                FROM sked__Resource__c
                WHERE Id IN :resourceIds
            ]);

            for (sked__Job_Allocation__c ja : affectedJobAllocations) {
                sked__Job__c job = jobById.get(ja.sked__Job__c);
                Id driveCo = job.sked_Drive__r.sked_Collection_Operation__c;
                Date driveDate = job.sked_Drive__r.sked_Drive_Date__c;
                sked__Resource__c resource = resourceById.get(ja.sked__Resource__c);
    
                if (!skedResourceUtils.getResourceBelongsToCollectionOp(resource, driveCo, driveDate)) {
                    skedHC__Exception__c exceptionToUpsert;

                    if (resource.skedHC__Exception_Log__r != null && !resource.skedHC__Exception_Log__r.isEmpty()) {
                        for (skedHC__Exception__c exc : resource.skedHC__Exception_Log__r) {
                            if (exc.skedHC__Job_Allocation__c == ja.Id) {
                                exceptionToUpsert = exc;
                                exceptionToUpsert.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN;
                            }
                        }
                    }

                    if (exceptionToUpsert == null) {
                        exceptionToUpsert = new skedHC__Exception__c(
                            sked_Drive__c = job.sked_Drive__c,
                            skedHC__Job__c = job.Id,
                            skedHC__Job_Allocation__c = ja.Id,
                            skedHC__Resource__c = resource.Id,
                            sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO,
                            skedHC__Exception__c = 'Resource is not available to work in Collection Operation',
                            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                        );
                    }

                    exceptionsToCreate.add(exceptionToUpsert);
                }
            }
        }

        if (!exceptionsToCreate.isEmpty() && !System.isBatch()) { 
            upsert exceptionsToCreate;
        }
    }

    private void closeOutOfCoExceptions(List<sked__Resource_Override__c> newRecords) {
        Date earliestStartDate;
        Date latestEndDate;
        
        for (sked__Resource_Override__c newRecord : newRecords) {
            if (earliestStartDate == null || newRecord.sked_Start_Date__c < earliestStartDate) {
                earliestStartDate = newRecord.sked_Start_Date__c;
            }

            if (latestEndDate == null || newRecord.sked_End_Date__c > latestEndDate) {
                latestEndDate = newRecord.sked_End_Date__c;
            }
        }

        closeOutOfCoExceptions(newRecords, earliestStartDate, latestEndDate);
    }

    private void closeOutOfCoExceptions(List<sked__Resource_Override__c> newRecords, Map<Id, sked__Resource_Override__c> oldMap) {
        List<sked__Resource_Override__c> updatedRecords = new List<sked__Resource_Override__c>();
        Date earliestStartDate;
        Date latestEndDate;

        for (sked__Resource_Override__c newRecord : newRecords) {
            sked__Resource_Override__c oldRecord = oldMap.get(newRecord.Id);

            if (newRecord.sked__Start__c != oldRecord.sked__Start__c || newRecord.sked__End__c != oldRecord.sked__End__c || newRecord.sked_Collection_Operation__c != oldRecord.sked_Collection_Operation__c) {
                Date newStartDate = Date.newInstance(newRecord.sked__Start__c.year(), newRecord.sked__Start__c.month(), newRecord.sked__Start__c.day());
                Date newEndDate = Date.newInstance(newRecord.sked__End__c.year(), newRecord.sked__End__c.month(), newRecord.sked__End__c.day());
                Date oldStartDate = Date.newInstance(oldRecord.sked__Start__c.year(), oldRecord.sked__Start__c.month(), oldRecord.sked__Start__c.day());
                Date oldEndDate = Date.newInstance(oldRecord.sked__End__c.year(), oldRecord.sked__End__c.month(), oldRecord.sked__End__c.day());

                Date earlierStartDate = newStartDate < oldStartDate ? newStartDate : oldStartDate;
                Date laterEndDate = newEndDate > oldEndDate ? newEndDate : oldEndDate;
    
                if (earliestStartDate == null || earlierStartDate < earliestStartDate) earliestStartDate = earlierStartDate;
                if (latestEndDate == null || laterEndDate > latestEndDate) latestEndDate = laterEndDate;
                updatedRecords.add(newRecord);
            }
        }

        if (!updatedRecords.isEmpty()) {
            closeOutOfCoExceptions(updatedRecords, earliestStartDate, latestEndDate);
        }
    }

    private void closeOutOfCoExceptions(List<sked__Resource_Override__c> records, Date earliestStartDate, Date latestEndDate) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource_Override__c secondaryCo : records) {
            resourceIds.add(secondaryCo.sked__Resource__c);
        }

        if (!resourceIds.isEmpty()) {
            List<skedHC__Exception__c> outOfCoExceptions = [
                SELECT Id, sked_Drive__r.sked_Collection_Operation__c, skedHC__Resource__c, 
                skedHC__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                sked_Drive__r.sked_Drive_Date__c
                FROM skedHC__Exception__c
                WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO
                AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN
                AND skedHC__Resource__c IN :resourceIds
                AND sked_Drive__r.sked_Drive_Date__c >= :earliestStartDate
                AND sked_Drive__r.sked_Drive_Date__c <= :latestEndDate
            ];
    
            Map<Id, List<skedHC__Exception__c>> exceptionsByResource = new Map<Id, List<skedHC__Exception__c>>();
            for (skedHC__Exception__c skedExc : outOfCoExceptions) {
                List<skedHC__Exception__c> exceptionsForResource = exceptionsByResource.get(skedExc.skedHC__Resource__c);
                if (exceptionsForResource == null) {
                    exceptionsForResource = new List<skedHC__Exception__c>();
                }
    
                exceptionsForResource.add(skedExc);
                exceptionsByResource.put(skedExc.skedHC__Resource__c, exceptionsForResource);
            }
    
            List<skedHC__Exception__c> exceptionsToClose = new List<skedHC__Exception__c>();
            for (sked__Resource_Override__c record : records) {
                List<skedHC__Exception__c> exceptionsForResource = exceptionsByResource.get(record.sked__Resource__c);
                if (exceptionsForResource != null && !exceptionsForResource.isEmpty()) {
                    for (skedHC__Exception__c skedExc : exceptionsForResource) {
                        Id driveCoId = skedExc.sked_Drive__r.sked_Collection_Operation__c;
                        Id resourceCoId = skedExc.skedHC__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
                        Id resourceOverrideCoId = record.sked_Collection_Operation__c;
                        Boolean driveDateInsideOverride = record.sked_Start_Date__c <= skedExc.sked_Drive__r.sked_Drive_Date__c
                            && record.sked_End_Date__c >= skedExc.sked_Drive__r.sked_Drive_Date__c;

                        // If they are in the override CO and the override CO is the Drive CO -> close
                        Boolean canCloseException = false;
                        if (driveDateInsideOverride && resourceOverrideCoId == driveCoId) canCloseException = true;
                        
                        // If they are outside the override CO and the override CO is their primary region -> close
                        if (!driveDateInsideOverride && resourceCoId == driveCoId) canCloseException = true;
                        
                        // If we are deleting an over-ride that takes them away from their primary CO
                        if (Trigger.isDelete && driveDateInsideOverride && resourceCoId == driveCoId) canCloseException = true;

                        if (canCloseException) {
                            skedExc.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                            exceptionsToClose.add(skedExc);
                        }
                    }
                }
            }
    
            if (!exceptionsToClose.isEmpty()) {
                update exceptionsToClose;
            }
        }
    }
}