public class skedRoleTimeVarianceHandler extends skedTriggerHub {

    public override void onBeforeInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            validateVarianceType(this.context.newRecords);
        }
    }
    
    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	captureExceptionLog(this.context.newRecords);
            updateRelatedJobs(skedRoleTimeVarianceUtils.getAdjustmentsToAddBufferForRelatedJobs(this.context.newRecords));
        }
    }

    public override void onBeforeUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            validateVarianceType(this.context.newRecords);
        }
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	captureExceptionLog(this.context.newRecords);
            updateRelatedJobs(skedRoleTimeVarianceUtils.getAdjustmentsToModifyBufferForRelatedJobs(this.context.newRecords, (Map<Id, sked_Role_Time_Variance__c>)this.context.oldMap));
        }
    }
    
    public override void onAfterDelete() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	captureExceptionLog(((Map<Id, sked_Role_Time_Variance__c>)this.context.oldMap).values());
            updateRelatedJobs(skedRoleTimeVarianceUtils.getAdjustmentsToRemoveBufferForRelatedJobs(((Map<Id, sked_Role_Time_Variance__c>)this.context.oldMap).values()));
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void captureExceptionLog(List<sked_Role_Time_Variance__c> newRecords) {
        Set<Id> locationIds = new Set<Id>();
        for (sked_Role_Time_Variance__c newRecord : newRecords) {
            locationIds.add(newRecord.sked_Location__c);   
        }
        
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        List<sked_Drive__c> impactedDrives = [SELECT Id
                                              FROM sked_Drive__c
                                              WHERE sked_Drive_Site__c IN :locationIds
                                              AND sked_Drive_Date__c >= TODAY];
        for (sked_Drive__c impactedDrive : impactedDrives) {
            skedHC__Exception__c newException = new skedHC__Exception__c(
                sked_Drive__c = impactedDrive.Id,
                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_ROLE_TIME_VARIANCE_CHANGED
            );
            exceptionLog.add(newException);
        }
        if (!exceptionLog.isEmpty()) {
            insert exceptionLog;
        }
    }

    private void validateVarianceType(List<sked_Role_Time_Variance__c> newRecords) {
        for (sked_Role_Time_Variance__c newRecord : newRecords) {
            if (newRecord.sked_Variation_Type__c == 'Imported from Hemasphere') {
                newRecord.addError('Imported from Hemasphere is only available for migration.');
            }
        }
    }

    private void updateRelatedJobs(List<skedRoleTimeVarianceAdjustment> rtvAdjustments) {
        if (!Test.isRunningTest() && !System.isBatch() && !rtvAdjustments.isEmpty()) {
            Database.executeBatch(new skedUpdateJobTimeVarianceBatch(rtvAdjustments), 100);
        }
    }
}