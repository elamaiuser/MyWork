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