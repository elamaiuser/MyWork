public class skedCreateDCRForTravelTimeChangeBatch implements Database.Batchable<sked_Drive__c>, Database.Stateful {
    
    private Set<Id> impactedIndexIds;
    private Set<Id> impactedDriveIds;
    
    public skedCreateDCRForTravelTimeChangeBatch(Set<Id> impactedIndexIds, Set<Id> impactedDriveIds) {
        this.impactedIndexIds = impactedIndexIds;
        this.impactedDriveIds = impactedDriveIds;
    }
    
    public List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id
                FROM sked_Drive__c
                WHERE (ID IN :this.impactedDriveIds
                OR (sked_Travel_Time_CO_To_Site__c IN :this.impactedIndexIds OR sked_Travel_Time_Site_To_CO__c IN :this.impactedIndexIds))
                AND sked_Drive_Date__c >= TODAY
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL];
    }
    
    public void execute(Database.BatchableContext BC, List<sked_Drive__c> impactedDrives) {
        for (sked_Drive__c impactedDrive : impactedDrives) {
            impactedDrive.sked_Travel_Time_Change_DCR_Required__c = true;
        }

        update impactedDrives;
    }
    
    public void finish(Database.BatchableContext BC) {
        skedCreateNonUserChangeDCRBatch.schedule();
    }

}