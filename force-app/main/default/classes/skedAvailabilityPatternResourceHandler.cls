public class skedAvailabilityPatternResourceHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onAfterInsert() {
        captureAPExceptionLogs(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        populateData(this.context.newRecords, (Map<Id, sked__Availability_Pattern_Resource__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Availability_Pattern_Resource__c>)this.context.oldMap);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void captureAPExceptionLogs(List<sked__Availability_Pattern_Resource__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        DateTime minDt, maxDt;
        DateTime currentTime = system.now();
        
        Map<Id, List<sked__Availability_Pattern_Resource__c>> map_resourceId_patternResources = new Map<Id, List<sked__Availability_Pattern_Resource__c>>();
        for (sked__Availability_Pattern_Resource__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
            DateTime prStart = newRecord.sked__Start__c == NULL ? currentTime : newRecord.sked__Start__c;
            DateTime prEnd = newRecord.sked__End__c == NULL ? skedDateTimeUtils.MAX_DATETIME : newRecord.sked__End__c;
            
            minDt = minDt == NULL || minDt > prStart ? prStart : minDt;
            maxDt = maxDt == NULL || maxDt < prEnd ? prEnd : maxDt;
            
            List<sked__Availability_Pattern_Resource__c> patternResources = map_resourceId_patternResources.get(newRecord.sked__Resource__c);
            if (patternResources == NULL) {
                patternResources = new List<sked__Availability_Pattern_Resource__c>();
                map_resourceId_patternResources.put(newRecord.sked__Resource__c, patternResources);
            }
            patternResources.add(newRecord);
        }
        
        List<sked__Activity_Resource__c> skedActivityResources = [
            SELECT Id, sked_Start1__c, sked_End__c
            FROM sked__Activity_Resource__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked_Start1__c < :maxDt
            AND sked_End__c > :minDt
        ];
        
        Set<Id> impactedActivityResourceIds = new Set<Id>();
        for (sked__Activity_Resource__c skedActivityResource : skedActivityResources) {
            List<sked__Availability_Pattern_Resource__c> patternResources = map_resourceId_patternResources.get(skedActivityResource.sked__Resource__c);
            for (sked__Availability_Pattern_Resource__c patternResource : patternResources) {
                DateTime prStart = patternResource.sked__Start__c == NULL ? currentTime : patternResource.sked__Start__c;
                DateTime prEnd = patternResource.sked__End__c == NULL ? skedDateTimeUtils.MAX_DATETIME : patternResource.sked__End__c;
                
                if (skedActivityResource.sked_Start1__c < prEnd && skedActivityResource.sked_End__c > prStart) {
                    impactedActivityResourceIds.add(skedActivityResource.Id);
                }
            }
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
                newRecord.sked_End_Date__c = skedDateTimeUtils.MAX_DATE;
                newRecord.sked_End_Time__c = Time.newInstance(0, 0, 0, 0);
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
                newRecord.sked_End_Date__c = skedDateTimeUtils.MAX_DATE;
                newRecord.sked_End_Time__c = Time.newInstance(0, 0, 0, 0);
            }
        }
    }
        
}