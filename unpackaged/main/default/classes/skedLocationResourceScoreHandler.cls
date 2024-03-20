public class skedLocationResourceScoreHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
    }
    
    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureExceptionLog(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        populateData(this.context.newRecords, (Map<Id, sked__Location_Resource_Score__c>) this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureExceptionLog(this.context.newRecords, (Map<Id, sked__Location_Resource_Score__c>)this.context.oldMap);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void populateData(List<sked__Location_Resource_Score__c> newRecords) {
        for (sked__Location_Resource_Score__c newRecord : newRecords) {
            if (newRecord.sked_Location_Resource_Relationship__c == skedConstants.LOCATION_RESOURCE_SCORE_PREFERRED) {
                newRecord.sked__Whitelisted__c = TRUE;
                newRecord.sked__Blacklisted__c = FALSE;
            }
            else if (newRecord.sked_Location_Resource_Relationship__c == skedConstants.LOCATION_RESOURCE_SCORE_DECLINED) {
                newRecord.sked__Whitelisted__c = FALSE;
                newRecord.sked__Blacklisted__c = TRUE;
            }

            newRecord.sked_Unique_Key__c = newRecord.sked__Location__c + ':' + newRecord.sked__Resource__c;
        }
    }
    
    private void populateData(List<sked__Location_Resource_Score__c> newRecords, Map<Id, sked__Location_Resource_Score__c> oldMap) {
        List<sked__Location_Resource_Score__c> recordsToPopulate = new List<sked__Location_Resource_Score__c>();
        for (sked__Location_Resource_Score__c newRecord : newRecords) {
            sked__Location_Resource_Score__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Location_Resource_Relationship__c != oldData.sked_Location_Resource_Relationship__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateData(recordsToPopulate);
        }
    }
    
    private void captureExceptionLog(List<sked__Location_Resource_Score__c> newRecords) {        
        Set<Id> locationIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Location_Resource_Score__c newRecord : newRecords) {
            if (newRecord.sked__Blacklisted__c == TRUE) {
                locationIds.add(newRecord.sked__Location__c);
                resourceIds.add(newRecord.sked__Resource__c);
            }
        }
        
        if (!locationIds.isEmpty()) {
            Map<Id, sked__Location__c> mapLocation = new Map<Id, sked__Location__c>([
                SELECT Id, Name
                FROM sked__Location__c
                WHERE Id IN :locationIds
            ]);

            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
                SELECT Id, Name,
                    (SELECT Id, sked__Job__c, sked__Job__r.sked_Drive__c, 
                    sked__Job__r.sked_Drive__r.sked_Drive_Site__c, sked__Resource__c 
                    FROM sked__Job_Allocations__r
                    WHERE sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
                    AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED)
                FROM sked__Resource__c
                WHERE Id IN :resourceIds
            ]);
            
            List<skedHC__Exception__c> newExceptionLog = new List<skedHC__Exception__c>();
            for (sked__Location_Resource_Score__c newRecord : newRecords) {
                if (newRecord.sked__Blacklisted__c == TRUE) {
                    sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
                    if (skedResource.sked__Job_Allocations__r != NULL && !skedResource.sked__Job_Allocations__r.isEmpty()) {
                        sked__Location__c location = mapLocation.get(newRecord.sked__Location__c);
                        for (sked__Job_Allocation__c impactedAllocation : skedResource.sked__Job_Allocations__r) {
                            if (location.Id == impactedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Site__c) {
                                skedHC__Exception__c newException = new skedHC__Exception__c(
                                    sked_Drive__c = impactedAllocation.sked__Job__r.sked_Drive__c,
                                    skedHC__Job__c = impactedAllocation.sked__Job__c,
                                    skedHC__Job_Allocation__c = impactedAllocation.Id,
                                    skedHC__Resource__c = impactedAllocation.sked__Resource__c,
                                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
                                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_SITE_DECLINED,
                                    sked_Location__c = location.Id
                                );
                                newExceptionLog.add(newException);
                            }
                        }
                    }
                }
            }
            if (!newExceptionLog.isEmpty()) {
                insert newExceptionLog;
            }
        }
    }
    
    private void captureExceptionLog(List<sked__Location_Resource_Score__c> newRecords, Map<Id, sked__Location_Resource_Score__c> oldMap) {
        Set<Id> locationIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Location_Resource_Score__c newRecord : newRecords) {
            sked__Location_Resource_Score__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Blacklisted__c != oldData.sked__Blacklisted__c && newRecord.sked__Blacklisted__c == TRUE) {
                locationIds.add(newRecord.sked__Location__c);
                resourceIds.add(newRecord.sked__Resource__c);
            }
        }
        if (!locationIds.isEmpty()) {
            Map<Id, sked__Location__c> mapLocation = new Map<Id, sked__Location__c>([
                SELECT Id, Name
                FROM sked__Location__c
                WHERE Id IN :locationIds
            ]);

            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
                SELECT Id, Name,
                    (SELECT Id, sked__Job__c, sked__Job__r.sked_Drive__c, 
                    sked__Job__r.sked_Drive__r.sked_Drive_Site__c, sked__Resource__c                                                   FROM sked__Job_Allocations__r
                    WHERE sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
                    AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED)
                FROM sked__Resource__c
                WHERE Id IN :resourceIds
            ]);
            
            List<skedHC__Exception__c> newExceptionLog = new List<skedHC__Exception__c>();
            for (sked__Location_Resource_Score__c newRecord : newRecords) {
                sked__Location_Resource_Score__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked__Blacklisted__c != oldData.sked__Blacklisted__c && newRecord.sked__Blacklisted__c == TRUE) {
                    sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
                    if (skedResource.sked__Job_Allocations__r != NULL && !skedResource.sked__Job_Allocations__r.isEmpty()) {
                        sked__Location__c location = mapLocation.get(newRecord.sked__Location__c);
                        for (sked__Job_Allocation__c impactedAllocation : skedResource.sked__Job_Allocations__r) {
                            if (location.Id == impactedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Site__c) {
                                skedHC__Exception__c newException = new skedHC__Exception__c(
                                    sked_Drive__c = impactedAllocation.sked__Job__r.sked_Drive__c,
                                    skedHC__Job__c = impactedAllocation.sked__Job__c,
                                    skedHC__Job_Allocation__c = impactedAllocation.Id,
                                    skedHC__Resource__c = impactedAllocation.sked__Resource__c,
                                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
                                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_SITE_DECLINED,
                                    sked_Location__c = location.Id
                                );
                                newExceptionLog.add(newException);
                            }
                        }
                    }
                }
            }
            if (!newExceptionLog.isEmpty()) {
                insert newExceptionLog;
            }
        }
    }
    
}