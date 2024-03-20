public class skedRoleTimeDetailHandler extends skedTriggerHub {
    
    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            createDriveChangeRequests(this.context.newRecords);
        }
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            createDriveChangeRequests(this.context.newRecords, (Map<Id, sked_Role_Time_Detail__c>) this.context.oldMap);
        }
    }
    
    public override void onAfterDelete() {
        if (!skedSetting.instance.Admin.migrationMode) {
            createDriveChangeRequests(this.context.oldRecords);
        }
    }

    private void createDriveChangeRequests(List<sked_Role_Time_Detail__c> rtds) {
        if (!Test.isRunningTest() && !System.isBatch() && !rtds.isEmpty()) {
            Database.executeBatch(new skedCreateDCRForRTDBatch(rtds), 200);
        }
    }

    /*********************************************************** Private methods ***********************************************************/
    private void createDriveChangeRequests(List<sked_Role_Time_Detail__c> newRecords, Map<Id, sked_Role_Time_Detail__c> oldMap) {
        List<String> fieldsToCheck = new List<String>{
            'sked_Breakdown_Time__c', 'sked_Collection_Operation__c', 'sked_Days_of_Week__c', 'sked_Drive_Type__c', 'sked_Fixed_Site_Operation_Type__c', 
            'sked_Lead_Time__c', 'sked_Mobile_Type__c', 'sked_Resource_Role_Group__c', 'sked_Setup_Time__c', 'sked_Wrap_up_Time__c'
        };

        List<sked_Role_Time_Detail__c> rtdsRequiringBatch = new List<sked_Role_Time_Detail__c>();
        for (sked_Role_Time_Detail__c rtd : newRecords) {
            sked_Role_Time_Detail__c oldRtd = oldMap.get(rtd.Id);

            Boolean fieldChangedExist = false;
            for (String fieldToCheck : fieldsToCheck) {
                if (rtd.get(fieldToCheck) != oldRtd.get(fieldToCheck)) {
                    fieldChangedExist = true;
                    break;
                }
            }

            Boolean newPeriodIncludedInOldPeriod = rtd.sked_Effective_Start_Date__c >= oldRtd.sked_Effective_Start_Date__c && 
                                                     rtd.sked_Effective_End_Date__c <= oldRtd.sked_Effective_End_Date__c;
            if (fieldChangedExist || !newPeriodIncludedInOldPeriod) {
                rtdsRequiringBatch.add(rtd);
            }
        }

        if (!rtdsRequiringBatch.isEmpty()) {
            Database.executeBatch(new skedCreateDCRForRTDBatch(rtdsRequiringBatch), 200);
        }
    }
    
}