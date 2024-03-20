public class skedOperationRecordStaffHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Operation_Record_Staff__c>)this.context.oldMap);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
	private void doDateTimeConversion(List<sked_Operation_Record_Staff__c> newRecords) {
        for (sked_Operation_Record_Staff__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Shift_Start__c', 'sked_Actual_Shift_Start_Date__c', 'sked_Actual_Shift_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Shift_End__c', 'sked_Actual_Shift_End_Date__c', 'sked_Actual_Shift_End_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked_Operation_Record_Staff__c> newRecords, Map<Id, sked_Operation_Record_Staff__c> oldMap) {
        for (sked_Operation_Record_Staff__c newRecord : newRecords) {
            sked_Operation_Record_Staff__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Shift_Start__c', 'sked_Actual_Shift_Start_Date__c', 'sked_Actual_Shift_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Shift_End__c', 'sked_Actual_Shift_End_Date__c', 'sked_Actual_Shift_End_Time__c', 'sked_Timezone__c');
        }
    }

    private void populateData(List<sked_Operation_Record_Staff__c> newRecords) {
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked_Operation_Record_Staff__c opRecordStaff : newRecords) {
            jobAllocationIds.add(opRecordStaff.sked_Job_Allocation__c);
        }

        Map<Id, sked__Job_Allocation__c> jobAllocationsById = new Map<Id, sked__Job_Allocation__c>([
            SELECT Id, sked_CDL__c, sked_DOT__c
            FROM sked__Job_Allocation__c
            WHERE Id IN :jobAllocationIds
        ]);

        for (sked_Operation_Record_Staff__c newRecord : newRecords) {
            sked__Job_Allocation__c jobAllocation = jobAllocationsById.get(newRecord.sked_Job_Allocation__c);
            if (newRecord.sked_Role__c != NULL && newRecord.sked_Actual_Roles__c == NULL) {
                List<String> roles = newRecord.sked_Role__c.split(',');
                List<String> newRolesStr = new List<String>();
                for (String role : roles) {
                    if (role == skedConstants.JOB_RESOURCE_ROLE_DRIVER) {
                        if (jobAllocation.sked_CDL__c) {
                            newRolesStr.add('Driver CDL B');
                        } else if (jobAllocation.sked_DOT__c) {
                            newRolesStr.add('Driver - DOT');
                        } else {
                            newRolesStr.add('Driver');
                        }
                    } else {
                        newRolesStr.add(role);
                    }
                }
                newRecord.sked_Actual_Roles__c = string.join(newRolesStr, ';');
            }
        }
    }
}