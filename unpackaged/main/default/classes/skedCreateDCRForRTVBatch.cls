public class skedCreateDCRForRTVBatch implements Database.Batchable<sked_Role_Time_Variance__c>, Database.Stateful  {
    private List<sked_Role_Time_Variance__c> rtvs; 

    public skedCreateDCRForRTVBatch(List<sked_Role_Time_Variance__c> rtvs) {
        this.rtvs = rtvs;
    }

    public List<sked_Role_Time_Variance__c> start(Database.BatchableContext BC) {
        return this.rtvs;
    }

    public void execute(Database.BatchableContext BC, List<sked_Role_Time_Variance__c> rtvs) {
        List<sked_Drive__c> drivesToGenerateDCR = new List<sked_Drive__c>();
        for (sked_Role_Time_Variance__c rtv : rtvs) {
            List<sked_Drive__c> affectedDrives = [
                SELECT Id
                FROM sked_Drive__c
                WHERE sked_Drive_Site__c = :rtv.sked_Location__c 
                AND sked_Drive_Date__c >= :rtv.sked_Effective_Start_Date__c
                AND sked_Drive_Date__c <= :rtv.sked_Effective_End_Date__c
            ];

            drivesToGenerateDCR.addAll(affectedDrives);
        }

        if (!drivesToGenerateDCR.isEmpty()) { 
            for (sked_Drive__c driveToGenerateDCR : drivesToGenerateDCR) {
                driveToGenerateDCR.sked_RTV_Change_DCR_Required__c = true;
            }

            update drivesToGenerateDCR;
        }
    }

    public void finish(Database.BatchableContext BC) {
        skedCreateNonUserChangeDCRBatch.schedule();
    }

}