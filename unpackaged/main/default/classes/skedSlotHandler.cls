public class skedSlotHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Slot__c>)this.context.oldMap);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void doDateTimeConversion(List<sked__Slot__c> newRecords) {
        for (sked__Slot__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked__Slot__c> newRecords, Map<Id, sked__Slot__c> oldMap) {
        for (sked__Slot__c newRecord : newRecords) {
            sked__Slot__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void populateData(List<sked__Slot__c> newRecords) {
        Set<Id> driveShiftIds = new Set<Id>();
        for (sked__Slot__c newRecord : newRecords) {
            if (newRecord.sked_Drive_Shift__c != NULL) {
                driveShiftIds.add(newRecord.sked_Drive_Shift__c);
            }
        }
        if (!driveShiftIds.isEmpty()) {
            Map<Id, sked_Drive_Shift__c> mapDriveShift = new Map<Id, sked_Drive_Shift__c>([SELECT Id, sked_Drive__c, sked_Drive__r.sked_Timezone__c
                                                                                           FROM sked_Drive_Shift__c
                                                                                           WHERE Id IN :driveShiftIds]);
            for (sked__Slot__c newRecord : newRecords) {
                if (newRecord.sked_Drive_Shift__c != NULL) {
                    sked_Drive_Shift__c skedDriveShift = mapDriveShift.get(newRecord.sked_Drive_Shift__c);
                    newRecord.sked_Drive__c = skedDriveShift.sked_Drive__c;
                    newRecord.sked_Timezone__c = skedDriveShift.sked_Drive__r.sked_Timezone__c;
                }
            }
        }
    }

}