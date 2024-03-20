public class skedOperationRecordHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populateLastModifiedUser(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Operation_Record__c>)this.context.oldMap);
        }
        populateLastModifiedUser(this.context.newRecords);
        lockSubmittedRecord(this.context.newRecords, (Map<Id, sked_Operation_Record__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        onSubmitted(this.context.newRecords, (Map<Id, sked_Operation_Record__c>)this.context.oldMap);
    }

    public override void onBeforeDelete() {
        validateCanDelete(this.context.oldMap.values());
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onSubmitted(List<sked_Operation_Record__c> newRecords, Map<Id, sked_Operation_Record__c> oldMap) {
        Set<Id> driveIdsToComplete = new Set<Id>();
        for (sked_Operation_Record__c newRecord : newRecords) {
            sked_Operation_Record__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.OPERATION_STATUS_SUBMITTED) {
                    driveIdsToComplete.add(newRecord.sked_Drive__c);
                }
            }
        }
        if (!driveIdsToComplete.isEmpty()) {
            List<sked_Drive__c> drivesWithOpRecords = [SELECT Id, sked_Status__c,
                                                       (SELECT Id, sked_Status__c
                                                        FROM sked_Operations__r)
                                                       FROM sked_Drive__c
                                                       WHERE Id IN :driveIdsToComplete];
            List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
            for (sked_Drive__c drive : drivesWithOpRecords) {
                boolean isAllOpRecordsSubmitted = TRUE;
                for (sked_Operation_Record__c opRecord : drive.sked_Operations__r) {
                    if (opRecord.sked_Status__c != skedConstants.OPERATION_STATUS_SUBMITTED) {
                        isAllOpRecordsSubmitted = FALSE;
                        break;
                    }
                }
                if (isAllOpRecordsSubmitted && drive.sked_Status__c != skedConstants.DRIVE_STATUS_COMPLETE) {
                    drive.sked_Status__c = skedConstants.DRIVE_STATUS_COMPLETE;
                    drivesToUpdate.add(drive);
                }
            }
            if (!drivesToUpdate.isEmpty()) {
                update drivesToUpdate;
            }
        }
    }

    private void lockSubmittedRecord(List<sked_Operation_Record__c> newRecords, Map<Id, sked_Operation_Record__c> oldMap) {
        List<sked__Resource__c> resourceUsers = [SELECT Id 
                                                FROM sked__Resource__c 
                                                WHERE sked__User__c = :UserInfo.getUserId()
                                                    AND sked__Is_Active__c = TRUE];
        if (resourceUsers != NULL && !resourceUsers.isEmpty()) {
            sked__Resource__c resourceUser = resourceUsers.get(0);
            for (sked_Operation_Record__c newRecord : newRecords) {
                sked_Operation_Record__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                    if (newRecord.sked_Status__c == skedConstants.OPERATION_STATUS_SUBMITTED) {
                        newRecord.sked_Submitted_By__c = resourceUser.Id;
                        newRecord.sked_Locked__c = TRUE;
                    }
                }
            }
        }
    }
    
    private void doDateTimeConversion(List<sked_Operation_Record__c> newRecords) {
        for (sked_Operation_Record__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Drive_Start__c', 'sked_Actual_Drive_Start_Date__c', 'sked_Actual_Drive_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Drive_End__c', 'sked_Actual_Drive_End_Date__c', 'sked_Actual_Drive_End_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked_Operation_Record__c> newRecords, Map<Id, sked_Operation_Record__c> oldMap) {
        for (sked_Operation_Record__c newRecord : newRecords) {
            sked_Operation_Record__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Drive_Start__c', 'sked_Actual_Drive_Start_Date__c', 'sked_Actual_Drive_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Drive_End__c', 'sked_Actual_Drive_End_Date__c', 'sked_Actual_Drive_End_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void populateLastModifiedUser(List<sked_Operation_Record__c> newRecords) {
        for (sked_Operation_Record__c newRecord : newRecords) {
            newRecord.sked_Last_Modified_User__c = UserInfo.getName();
        }
    }

    private void validateCanDelete(List<sked_Operation_Record__c> deletedRecords) {
        for (sked_Operation_Record__c opRecord : deletedRecords) {
            if (skedTriggerUtils.hasPermissionSetAssignment('sked_ARC_Lead_Resource')) {
                opRecord.addError(skedConstants.OP_RECORD_DELETE_INVALID_PERMISSION);
            }
        }
    }
}