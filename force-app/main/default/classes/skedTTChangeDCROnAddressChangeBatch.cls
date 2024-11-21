public class skedTTChangeDCROnAddressChangeBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private Set<ID> siteIDs;
    private Set<Id> impactedDriveIds = new Set<Id>();
    
    public skedTTChangeDCROnAddressChangeBatch(Set<ID> siteIDs) {
        this.siteIDs = siteIDs;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT ID,sked_Drive_Site__c,sked_Drive_Date__c,sked_Status__c
                                         FROM sked_Drive__c 
                                         WHERE sked_Drive_Date__c >= TODAY
                			 AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL 
                                         AND sked_Drive_Site__c IN :this.siteIDs]);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
         List<sked_Drive__c> drives = (List<sked_Drive__c>) scope;
        
        if(!(drives.isEmpty())) {
        	for(sked_Drive__c updateDrive : drives) {
            	this.impactedDriveIds.add(updateDrive.ID);
        	}
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        if(!this.impactedDriveIds.isEmpty()) {
        	Database.executeBatch(new skedCreateDCRForTravelTimeChangeBatch(new Set<Id>(),this.impactedDriveIds));
        }
    }
}