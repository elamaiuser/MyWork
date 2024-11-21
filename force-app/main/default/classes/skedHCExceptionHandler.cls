public class skedHCExceptionHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
    }
    
    public override void onAfterInsert() {
        updateDriveExceptionIndicator(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        populateData(this.context.newRecords, (Map<Id, skedHC__Exception__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        onClosedException(this.context.newRecords, (Map<Id, skedHC__Exception__c>)this.context.oldMap);
    }
    
    public override void onAfterDelete() {
        onDeletedException((Map<Id, skedHC__Exception__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onClosedException(List<skedHC__Exception__c> newRecords, Map<Id, skedHC__Exception__c> oldMap) {
        Set<Id> driveIds = new Set<Id>();
        for (skedHC__Exception__c newRecord : newRecords) {
            skedHC__Exception__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.skedHC__Status__c != oldData.skedHC__Status__c) {
                if (newRecord.skedHC__Status__c == skedConstants.EXCEPTION_LOG_STATUS_CLOSED) {
                    if (newRecord.sked_Drive__c != NULL) {
                        driveIds.add(newRecord.sked_Drive__c);
                    }
                }
            }
        }
        if (!driveIds.isEmpty()) {
            onRemovedExceptionFromDrives(driveIds);
        }
    }
    
    private void onDeletedException(Map<Id, skedHC__Exception__c> oldMap) {
        Set<Id> driveIds = new Set<Id>();
        for (skedHC__Exception__c oldData : oldMap.values()) {
            if (oldData.skedHC__Status__c == skedConstants.EXCEPTION_LOG_STATUS_OPEN) {
                if (oldData.sked_Drive__c != NULL) {
                    driveIds.add(oldData.sked_Drive__c);
                }
            }
        }
        if (!driveIds.isEmpty()) {
            onRemovedExceptionFromDrives(driveIds);
        }
    }
    
    private void onRemovedExceptionFromDrives(Set<Id> driveIds) {
        List<sked_Drive__c> skedDrives = [SELECT Id, sked_Has_Exception__c,
                                          (SELECT Id
                                           FROM sked_Exception_Log__r
                                           WHERE skedHC__Status__c != :skedConstants.EXCEPTION_LOG_STATUS_CLOSED)
                                          FROM sked_Drive__c
                                          WHERE Id IN :driveIds];
        if (!skedDrives.isEmpty()) {
            List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
            for (sked_Drive__c skedDrive : skedDrives) {
                boolean hasException = skedDrive.sked_Exception_Log__r != NULL && !skedDrive.sked_Exception_Log__r.isEmpty();
                if (skedDrive.sked_Has_Exception__c != hasException) {
                    skedDrive.sked_Has_Exception__c = hasException;
                    drivesToUpdate.add(skedDrive);
                }
            }
            if (!drivesToUpdate.isEmpty()) {
                update drivesToUpdate;
            }
        }
    }
    
    private void populateData(List<skedHC__Exception__c> newRecords) {
        Set<Id> jobIds = new Set<Id>();
        for (skedHC__Exception__c newRecord : newRecords) {
            jobIds.add(newRecord.skedHC__Job__c);
        }
        Map<Id, sked__Job__c> mapJob = new Map<Id, sked__Job__c>([
            SELECT Id, sked_Drive__c 
            FROM sked__Job__c 
            WHERE Id IN :jobIds
        ]);
        
        List<sked_Exception_Setting__c> exceptionSettings = [
            SELECT Id, sked_Exception_Code__c, sked_Exception__c, sked_Priority__c
            FROM sked_Exception_Setting__c
        ];

        Map<string, sked_Exception_Setting__c> mapExceptionSetting = new Map<string, sked_Exception_Setting__c>();
        for (sked_Exception_Setting__c exceptionSetting : exceptionSettings) {
            mapExceptionSetting.put(exceptionSetting.sked_Exception_Code__c, exceptionSetting);
        }
        
        for (skedHC__Exception__c newRecord : newRecords) {
            generateUniqueKey(newRecord);
            
            if (string.isNotBlank(newRecord.skedHC__Job__c) && string.isBlank(newRecord.sked_Drive__c)) {
                if (mapJob != null && mapJob.containsKey(newRecord.skedHC__Job__c)) {
                    sked__Job__c job = mapJob.get(newRecord.skedHC__Job__c);
                    newRecord.sked_Drive__c = job.sked_Drive__c;
                }
            }
            if (string.isNotBlank(newRecord.sked_Exception_Code__c)) {
                if (mapExceptionSetting.containsKey(newRecord.sked_Exception_Code__c)) {
                    sked_Exception_Setting__c exceptionSetting = mapExceptionSetting.get(newRecord.sked_Exception_Code__c);
                    newRecord.sked_Priority__c = exceptionSetting.sked_Priority__c;
                    if (string.isBlank(newRecord.skedHC__Exception__c)) {
                        newRecord.skedHC__Exception__c = exceptionSetting.sked_Exception__c;
                    }
                }
            }
        }
    }
    
    private void populateData(List<skedHC__Exception__c> newRecords, Map<Id, skedHC__Exception__c> oldMap) {
        Set<Id> jobIds = new Set<Id>();
        for (skedHC__Exception__c newRecord : newRecords) {
            jobIds.add(newRecord.skedHC__Job__c);
        }
        Map<Id, sked__Job__c> mapJob = new Map<Id, sked__Job__c>([SELECT Id, sked_Drive__c FROM sked__Job__c WHERE Id IN :jobIds]);
        
        Id currentUserId = UserInfo.getUserId();
        DateTime currentTime = system.now();
        for (skedHC__Exception__c newRecord : newRecords) {
            generateUniqueKey(newRecord);
            
            skedHC__Exception__c oldData = oldMap.get(newRecord.Id);
            if (string.isNotBlank(newRecord.skedHC__Job__c) && string.isBlank(newRecord.sked_Drive__c)) {
                if (mapJob != null && mapJob.containsKey(newRecord.skedHC__Job__c)) {
                    sked__Job__c job = mapJob.get(newRecord.skedHC__Job__c);
                    newRecord.sked_Drive__c = job.sked_Drive__c;
                }
            }
            if (newRecord.skedHC__Status__c != oldData.skedHC__Status__c) {
                if (newRecord.skedHC__Status__c == skedConstants.EXCEPTION_LOG_STATUS_CLOSED) {
                    newRecord.sked_Resolved_By__c = currentUserId;
                    newRecord.sked_Resolved_Time__c = currentTime;
                }
            }
        }
    }
    
    private void generateUniqueKey(skedHC__Exception__c record) {
        if (record.skedHC__Job__c != NULL && !string.isBlank(record.skedHC__Exception__c)) {
            record.sked_UniqueKey__c = record.skedHC__Job__c + ':' + record.skedHC__Exception__c;
        }
        if (record.sked_Resource_Hours_Record__c != NULL && !string.isBlank(record.sked_Exception_Code__c)) {
            record.sked_UniqueKey__c = record.sked_Resource_Hours_Record__c + ':' + record.sked_Exception_Code__c;
        }
    }
    
    private void updateDriveExceptionIndicator(List<skedHC__Exception__c> newRecords) {
        Set<Id> driveIds = new Set<Id>();
        for (skedHC__Exception__c newRecord : newRecords) {
            if (newRecord.sked_Drive__c != NULL) {
                driveIds.add(newRecord.sked_Drive__c);
            }
        }
        if (!driveIds.isEmpty()) {
            List<sked_Drive__c> skedDrives = [SELECT Id, sked_Has_Exception__c
                                              FROM sked_Drive__c
                                              WHERE Id IN :driveIds
                                              AND sked_Has_Exception__c = FALSE];
            if (!skedDrives.isEmpty()) {
                for (sked_Drive__c skedDrive : skedDrives) {
                    skedDrive.sked_Has_Exception__c = TRUE;
                }
                update skedDrives;
            }
        }
    }

}