public class skedCreateRegenerateDriveDCRBatch implements Database.Batchable<sked_Drive__c>, Database.Stateful  {

    public skedCreateRegenerateDriveDCRBatch() {}
    
    public List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id
                FROM sked_Drive__c
                WHERE sked_Is_2RBC_Procedures_Not_Matched__c = TRUE
                AND sked_Drive_Date__c >= TODAY
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE];
    }
    
    public void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        Set<Id> driveIds = new Set<Id>();
        for (sked_Drive__c drive : drives) {
            driveIds.add(drive.Id);
        }
        
        Map<Id, sked_Drive_Change_Request__c> map_driveId_DCR = skedDriveChangeRequestUtils.GetPendingDCRByDriveId(driveIds, new List<String>{'sked_Regenerate_Drive__c'});

        List<sked_Drive_Change_Request__c> dcrs = new List<sked_Drive_Change_Request__c>();
        for (sked_Drive__c drive : drives) {
            sked_Drive_Change_Request__c dcr = map_driveId_DCR.get(drive.Id);
            if (dcr == NULL) {
                dcr = new sked_Drive_Change_Request__c(
                    sked_Drive__c = drive.Id
                );
            }
            dcr.sked_Type__c = skedUtils.addNewItemToMultiPicklist(dcr.sked_Type__c, skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
            dcrs.add(dcr);
        }
        
        if (!dcrs.isEmpty()) { 
            upsert dcrs;
            
            List<sked_Drive_Change_Request_Item__c> dcris = new List<sked_Drive_Change_Request_Item__c>();
            for (sked_Drive_Change_Request__c dcr : dcrs) {
                sked_Drive_Change_Request_Item__c dcri;
                if (dcr.sked_Drive_Change_Request_Items__r != null && !dcr.sked_Drive_Change_Request_Items__r.isEmpty()) {
                    dcri = dcr.sked_Drive_Change_Request_Items__r[0];
                } 
                else {
                    dcri = new sked_Drive_Change_Request_Item__c(
                        sked_Drive_Change_Request__c = dcr.Id,
                        sked_Object_API_Name__c = 'sked_Drive__c',
                        sked_Field_API_Name__c = 'sked_Regenerate_Drive__c',
                        sked_Field_Label__c = 'Regenerate Drive',
                        sked_Field_Type__c = 'Boolean',
                        sked_Type__c = 'Change'
                    );
                    dcris.add(dcri);
                }
            }
            
            insert dcris;
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
    
}