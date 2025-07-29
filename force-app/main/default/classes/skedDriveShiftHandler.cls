public class skedDriveShiftHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onAfterInsert() {
        populateIdentifier(this.context.newRecords);
        if (!skedSetting.instance.Admin.migrationMode) {
            updateDriveShiftOrders(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Drive_Shift__c>)this.context.oldMap);
        }
        autoPopulateDriveProjProductFields(this.context.newRecords, (Map<Id, sked_Drive_Shift__c>)this.context.oldMap); 
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            updateDriveShiftOrders(this.context.newRecords, (Map<Id, sked_Drive_Shift__c>)this.context.oldMap);
        }
    }
    
    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        if (!skedSetting.instance.Admin.migrationMode) {
        	deleteJobs((Map<Id, sked_Drive_Shift__c>)this.context.oldMap);
        }
    }
    
    /************************************************** Privated Methods ***************************************************/
    private void deleteJobs(Map<Id, sked_Drive_Shift__c> oldMap) {
        delete [SELECT Id FROM sked__Job__c WHERE sked_Drive_Shift__c IN :oldMap.keySet()];
    }

    private void doDateTimeConversion(List<sked_Drive_Shift__c> newRecords) {
        for (sked_Drive_Shift__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Finish__c', 'sked_Max_Shift_End_Date__c', 'sked_Max_Shift_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Start__c', 'sked_Min_Shift_Start_Date__c', 'sked_Min_Shift_Start_Time__c', 'sked_Timezone__c');
        }
    }

    private void doDateTimeConversion(List<sked_Drive_Shift__c> newRecords, Map<Id, sked_Drive_Shift__c> oldMap) {
        for (sked_Drive_Shift__c newRecord : newRecords) {
            sked_Drive_Shift__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Finish__c', 'sked_Max_Shift_End_Date__c', 'sked_Max_Shift_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Start__c', 'sked_Min_Shift_Start_Date__c', 'sked_Min_Shift_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void populateIdentifier(List<sked_Drive_Shift__c> newRecords) {
        List<UFIDGenerator.UFIDInfo> ufidInfos = new List<UFIDGenerator.UFIDInfo>();
        for (sked_Drive_Shift__c newRecord : newRecords) {
            UFIDGenerator.UFIDInfo ufidInfo = new UFIDGenerator.UFIDInfo();
            ufidInfo.prefix = 'H';
            ufidInfo.maxLength = 6;
            ufidInfo.value = integer.valueOf(newRecord.sked_UFID_AN__c);
            ufidInfo.recordId = newRecord.id;
            ufidInfo.fieldName = 'sked_UFID__c';
            ufidInfos.add(ufidInfo);
        }
        UFIDGenerator.genUFID(ufidInfos);
    }
    
    private void updateDriveShiftOrders(List<sked_Drive_Shift__c> newRecords) {
        Set<Id> driveIds = new Set<Id>();
        for (sked_Drive_Shift__c newRecord : newRecords) {
            driveIds.add(newRecord.sked_Drive__c);
        }
        if (!driveIds.isEmpty()) {
            updateDriveShiftOrders(driveIds);
        }
    }
    
    private void updateDriveShiftOrders(List<sked_Drive_Shift__c> newRecords, Map<Id, sked_Drive_Shift__c> oldMap) {
        Set<Id> driveIds = new Set<Id>();
        for (sked_Drive_Shift__c newRecord : newRecords) {
            sked_Drive_Shift__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Start__c != oldData.sked_Start__c) {
                driveIds.add(newRecord.sked_Drive__c);
            }
        }
        if (!driveIds.isEmpty()) {
            updateDriveShiftOrders(driveIds);
        }
    }
    
    private void updateDriveShiftOrders(Set<Id> driveIds) {
        List<sked_Drive_Shift__c> skedDriveShifts = [SELECT Id, sked_Drive__c, sked_Start__c, sked_Order__c
                                                     FROM sked_Drive_Shift__c 
                                                     WHERE sked_Drive__c IN :driveIds
                                                     ORDER BY sked_Drive__c, sked_Start__c];
        Map<string, List<sked_Drive_Shift__c>> mapDrive_DriveShifts = new Map<string, List<sked_Drive_Shift__c>>();
        for (sked_Drive_Shift__c driveShift : skedDriveShifts) {
            List<sked_Drive_Shift__c> driveShifts = mapDrive_DriveShifts.get(driveShift.sked_Drive__c);
            if (driveShifts == NULL) {
                driveShifts = new List<sked_Drive_Shift__c>();
            }
            driveShifts.add(driveShift);
            mapDrive_DriveShifts.put(driveShift.sked_Drive__c, driveShifts);
        }
        for (string driveId : mapDrive_DriveShifts.keySet()) {
            List<sked_Drive_Shift__c> driveShifts = mapDrive_DriveShifts.get(driveId);
            Integer driveShiftIndex = 1;
            for (sked_Drive_Shift__c driveShift : driveShifts) {
                driveShift.Name = 'Shift ' + driveShiftIndex;
                driveShift.sked_Order__c = driveShiftIndex;
                driveShiftIndex++;
            }
        }
        update skedDriveShifts;
    }

    private static void autoPopulateDriveProjProductFields(List<sked_Drive_Shift__c> newDriveList,Map<Id, sked_Drive_Shift__c> oldDriveMap) {
        for(sked_Drive_Shift__c skedDriveShift: newDriveList) {
            decimal x2rbcProjectedProcedures = skedDriveShift.sked_2RBC_Projected_Procedures__c != NULL ? skedDriveShift.sked_2RBC_Projected_Procedures__c : 0;
            decimal wbProjectedProcedures = skedDriveShift.sked_WB_Projected_Procedures__c != NULL ? skedDriveShift.sked_WB_Projected_Procedures__c : 0;
            decimal plasmaProjectedProcedures = skedDriveShift.sked_Plasma_Projected_Procedures__c != NULL ? skedDriveShift.sked_Plasma_Projected_Procedures__c : 0;
            decimal plateletProjectedProcedures = skedDriveShift.sked_Platelet_Projected_Procedures__c != NULL ? skedDriveShift.sked_Platelet_Projected_Procedures__c : 0;
            if(oldDriveMap != NULL) {
                if(oldDriveMap.get(skedDriveShift.id).sked_WB_Projected_Procedures__c != skedDriveShift.sked_WB_Projected_Procedures__c  
                   ||(oldDriveMap.get(skedDriveShift.id).sked_2RBC_Projected_Procedures__c != skedDriveShift.sked_2RBC_Projected_Procedures__c )
                   ||(oldDriveMap.get(skedDriveShift.id).sked_Platelet_Projected_Procedures__c != skedDriveShift.sked_Platelet_Projected_Procedures__c )
                   ||(oldDriveMap.get(skedDriveShift.id).sked_Plasma_Projected_Procedures__c != skedDriveShift.sked_Plasma_Projected_Procedures__c )) {
                    if(skedDriveShift.sked_Total_Procedures_Projected__c != NULL) {
                        skedDriveShift.sked_Total_Procedures_Projected__c = x2rbcProjectedProcedures + wbProjectedProcedures + plasmaProjectedProcedures + plateletProjectedProcedures;
                    }
                    if(skedDriveShift.sked_Total_Products_Projected__c != NULL) {
                       skedDriveShift.sked_Total_Products_Projected__c = x2rbcProjectedProcedures * 2 + wbProjectedProcedures + plasmaProjectedProcedures + plateletProjectedProcedures;
                    }  
                }   
            }
        }
    }
    
}