public class GetDrivesForDCRCreateBatch implements Database.Batchable<sked_Drive__c>, Database.Stateful  {
    
    List<sked_Drive__c> drives;

    public GetDrivesForDCRCreateBatch(List<sked_Drive__c> incomingDrives) {
        drives = incomingDrives;
    }
    
    public List<sked_Drive__c> start(Database.BatchableContext BC) {
       return drives;
    }
    
    public void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        Set<Id> validDriveIds = new Set<Id>();
        for (sked_Drive__c drive : drives) {
            validDriveIds.add(drive.Id);
        }
        
        system.debug('### validDriveIds ' + validDriveIds.size());
         
        Map<Id, sked_Drive_Change_Request__c> map_driveId_DCR = skedDriveChangeRequestUtils.GetPendingDCRByDriveId(validDriveIds, new List<String>{'sked_Regenerate_Drive__c'});
        
        system.debug('### map_driveId_DCR ' + map_driveId_DCR.size());
        
        List<sked_Drive_Change_Request__c> driveChangeRequestList = new List<sked_Drive_Change_Request__c>();
        for (Id driveId : validDriveIds) {
            sked_Drive_Change_Request__c dcr = map_driveId_DCR.get(driveId);
            if(dcr == NULL){
                dcr = new sked_Drive_Change_Request__c(sked_Drive__c = driveId);
            }
            dcr.sked_Type__c = skedUtils.addNewItemToMultiPicklist(dcr.sked_Type__c, skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
            driveChangeRequestList.add(dcr);
        }
        
        system.debug('### driveChangeRequestList ' + driveChangeRequestList.size());
        
        List<sked_Drive_Change_Request_Item__c> driveChangeRequestItemList = new List<sked_Drive_Change_Request_Item__c>(); 
        
        if (!driveChangeRequestList.isEmpty())
        { 
            upsert driveChangeRequestList;
                       
            for (sked_Drive_Change_Request__c dcr : driveChangeRequestList) {
                sked_Drive_Change_Request_Item__c dcri;
                if (dcr.sked_Drive_Change_Request_Items__r != null && !dcr.sked_Drive_Change_Request_Items__r.isEmpty()) {
                    dcri = dcr.sked_Drive_Change_Request_Items__r[0];
                } else {
                    dcri = new sked_Drive_Change_Request_Item__c(
                            sked_Drive_Change_Request__c = dcr.Id,
                            sked_Object_API_Name__c = 'sked_Drive__c',
                            sked_Field_API_Name__c = 'sked_Regenerate_Drive__c',
                            sked_Field_Label__c = 'Regenerate Drive',
                            sked_Field_Type__c = 'Boolean',
                            sked_Type__c = 'Change'
                            );
                    driveChangeRequestItemList.add(dcri);
                }
            }
            
            system.debug('### driveChangeRequestItemList ' + driveChangeRequestItemList.size());
            insert driveChangeRequestItemList;
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
    
}