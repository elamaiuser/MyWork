public class skedCreateDCRForVehicleReqChangeBatch implements Database.Batchable<sked_Drive__c>, Database.Stateful {

    private Map<Id, Boolean> newValueBySiteId;

    public skedCreateDCRForVehicleReqChangeBatch(Map<Id, Boolean> newValueBySiteId) {
        this.newValueBySiteId = newValueBySiteId;
    }

    public List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Drive_Site__c, sked_Do_Not_Use_Vehicle__c
                FROM sked_Drive__c
                WHERE sked_Drive_Site__c IN :this.newValueBySiteId.keySet()
                AND sked_Drive_Date__c >= TODAY
                AND sked_Type_of_Drive__c = :skedConstants.DRIVE_TYPE_MOBILE
                AND sked_Surrogate_Drive_for__c = NULL
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE];
    }

    public void execute(Database.BatchableContext BC, List<sked_Drive__c> impactedDrives) {
        List<sked_Drive__c> drivesToFlag = new List<sked_Drive__c>();
        for (sked_Drive__c impactedDrive : impactedDrives) {
            Boolean newValue = this.newValueBySiteId.get(impactedDrive.sked_Drive_Site__c);
            if (impactedDrive.sked_Do_Not_Use_Vehicle__c != newValue) {
                impactedDrive.sked_Vehicle_Req_Change_DCR_Required__c = true;
                drivesToFlag.add(impactedDrive);
            }
        }

        if (!drivesToFlag.isEmpty()) {
            update drivesToFlag;
        }
    }

    public void finish(Database.BatchableContext BC) {
        skedCreateNonUserChangeDCRBatch.schedule();
    }
}