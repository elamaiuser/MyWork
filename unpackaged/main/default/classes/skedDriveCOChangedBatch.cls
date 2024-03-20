global class skedDriveCOChangedBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    protected string lastId = '';
    protected Set<Id> sitecollectionOperationIds;
    
    public skedDriveCOChangedBatch(Set<Id> sitecollectionOperationIds) { 
        this.lastId = '';
        this.sitecollectionOperationIds = sitecollectionOperationIds;
    }
    
    public skedDriveCOChangedBatch(string lastId, Set<Id> sitecollectionOperationIds) { 
        this.lastId = lastId;
        this.sitecollectionOperationIds = sitecollectionOperationIds;
    }
    
    global List<sked_Site_Collection_Operation__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Collection_Operation__c, sked_Collection_Operation__r.Name, sked_End_Date__c, 
                sked_Site__c, sked_Start_Date__c, sked_Region__c
                FROM sked_Site_Collection_Operation__c
                WHERE Id IN :this.sitecollectionOperationIds
                AND Id > :this.lastId
                ORDER BY Id ASC
                LIMIT 50000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Site_Collection_Operation__c> inputRecords) {
        if (!inputRecords.isEmpty()) {
            createDriveChangeRequests(inputRecords);
        }
        
        this.lastId = inputRecords.get(inputRecords.size() - 1).Id;
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked_Site_Collection_Operation__c> remainRecordQuery = [
            SELECT Id
            FROM sked_Site_Collection_Operation__c
            WHERE Id IN :this.sitecollectionOperationIds
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];
        
        if (!remainRecordQuery.isEmpty()) {
            if (!Test.isRunningTest()) {
                Database.executeBatch(new skedDriveCOChangedBatch(this.lastId, this.sitecollectionOperationIds), 200);
            }
        }
    }
    
    /* Private methods */
    private void createDriveChangeRequests(List<sked_Site_Collection_Operation__c> inputRecords) {
        // get site to 'list of collection operation'
        Map<Id, List<sked_Site_Collection_Operation__c>> map_SiteId_CO = new Map<Id, List<sked_Site_Collection_Operation__c>>();
        for (sked_Site_Collection_Operation__c inputRecord : inputRecords) {
            List<sked_Site_Collection_Operation__c> siteCOs = map_SiteId_CO.containsKey(inputRecord.sked_Site__c)
                ? map_SiteId_CO.get(inputRecord.sked_Site__c)
                : new List<sked_Site_Collection_Operation__c>();
            siteCOs.add(inputRecord);
            map_SiteId_CO.put(inputRecord.sked_Site__c, siteCOs);
        }
        
        // query all drives for the sites, along with jobs
        Set<String> nonPendingStatuses = new Set<String>{'Approved', 'Rejected', 'Cancelled', 'Approved by System'};
        List<sked_Drive__c> drives = [
            SELECT Id, sked_Collection_Operation__c, sked_Collection_Operation__r.Name, sked_Drive_Date__c, 
            sked_Drive_Site__c, sked_Site_Collection_Operation__c, sked_Site_Collection_Operation__r.Name
            FROM sked_Drive__c
            WHERE sked_Drive_Site__c IN :map_SiteId_CO.keySet()
            AND sked_Drive_Date__c >= TODAY
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
        ];
        
        Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>();
        Map<Id, Biomed_Collection_Op_Center__c> map_DriveId_CO = new Map<Id, Biomed_Collection_Op_Center__c>();
        Map<Id, sked_Site_Collection_Operation__c> map_DriveId_SiteCO = new Map<Id, sked_Site_Collection_Operation__c>();
        
        List<sked_Drive_Change_Request__c> newDCRs = new List<sked_Drive_Change_Request__c>();
        List<sked_Drive_Change_Request__c> dcrsToUpsert = new List<sked_Drive_Change_Request__c>();
        List<sked_Drive_Change_Request_Item__c> newDCRItems = new List<sked_Drive_Change_Request_Item__c>();
        
        if (drives != null && !drives.isEmpty()) {
            List<sked_Drive_Change_Request__c> existingDCRs = [
                SELECT Id, sked_Status__c, sked_Drive__c, sked_Type__c,
                    (SELECT Id, sked_Field_API_Name__c
                     FROM sked_Drive_Change_Request_Items__r
                     WHERE (sked_Field_API_Name__c = 'sked_Collection_Operation__c' OR sked_Field_API_Name__c = 'sked_Site_Collection_Operation__c'))
                FROM sked_Drive_Change_Request__c WHERE sked_Status__c NOT IN :nonPendingStatuses
                AND sked_Drive__c IN :drives
            ];

            Map<Id, sked_Drive_Change_Request__c> dcrByDriveId = new Map<Id, sked_Drive_Change_Request__c>();
            for (sked_Drive_Change_Request__c dcr : existingDCRs) {
                dcrByDriveId.put(dcr.sked_Drive__c, dcr);
            }
            
            // update collection operation for each drive matching date range
            for (sked_Drive__c drive : drives) {
                mapDrive.put(drive.Id, drive);
                Boolean hasDcr = dcrByDriveId.containsKey(drive.Id);
                List<sked_Site_Collection_Operation__c> siteCOs = map_SiteId_CO.get(drive.sked_Drive_Site__c);
                if (siteCOs != NULL) {
                    for (sked_Site_Collection_Operation__c siteCO : siteCOs) {
                        boolean isCOMatched = drive.sked_Collection_Operation__c != siteCO.sked_Collection_Operation__c;
                        boolean isDateMatched = drive.sked_Drive_Date__c >= siteCO.sked_Start_Date__c && drive.sked_Drive_Date__c <= siteCO.sked_End_Date__c;
                        
                        if (isCOMatched && isDateMatched) {
                            map_DriveId_CO.put(drive.Id, siteCO.sked_Collection_Operation__r);
                            map_DriveId_SiteCO.put(drive.Id, siteCO);
                            
                            sked_Drive_Change_Request__c dcr;
                            if (!hasDcr) {
                                dcr = new sked_Drive_Change_Request__c(
                                    sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_COLLECTION_OP,
                                    sked_Drive__c = drive.Id
                                );
                                newDCRs.add(dcr);
                            }
                            else {
                                dcr = dcrByDriveId.get(drive.Id);
                                List<string> dcrTypes = dcr.sked_Type__c.split(';');
                                if (!dcrTypes.contains(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_COLLECTION_OP)) {
                                    dcrTypes.add(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_COLLECTION_OP);
                                }
                                dcr.sked_Type__c = string.join(dcrTypes, ';');
                            }
                            
                            dcr.sked_New_Collection_Operation__c = siteCO.sked_Collection_Operation__c;
                            dcr.sked_Status__c = 'Pending';
                            dcrsToUpsert.add(dcr);
                        }
                    }
                }
            }
        }

        List<sked_Drive_Change_Request_Item__c> driveChangeRequestItemsToDelete = new List<sked_Drive_Change_Request_Item__c>();
        if (!dcrsToUpsert.isEmpty()) {
            upsert dcrsToUpsert;
            
            for (sked_Drive_Change_Request__c dcr : dcrsToUpsert) {
                Biomed_Collection_Op_Center__c newCollectionOp = map_DriveId_CO.get(dcr.sked_Drive__c);
                sked_Site_Collection_Operation__c newSiteCollectionOp = map_DriveId_SiteCO.get(dcr.sked_Drive__c);
                sked_Drive__c drive = mapDrive.get(dcr.sked_Drive__c);

                Boolean hasExistingDcri = (dcr.sked_Drive_Change_Request_Items__r != null && !dcr.sked_Drive_Change_Request_Items__r.isEmpty());
                if (hasExistingDcri) {
                    driveChangeRequestItemsToDelete.addAll(dcr.sked_Drive_Change_Request_Items__r);
                }
                
                if (newCollectionOp != NULL) {
                    newDCRItems.add(new sked_Drive_Change_Request_Item__c(
                        sked_Drive_Change_Request__c = dcr.Id,
                        sked_Object_API_Name__c = 'sked_Drive__c',
                        sked_Field_API_Name__c = 'sked_Collection_Operation__c',
                        sked_Field_Label__c = 'Collection Operation',
                        sked_Field_Type__c = 'reference',
                        sked_Old_Value__c = drive.sked_Collection_Operation__c,
                        sked_Old_Value_Display__c = drive.sked_Collection_Operation__r.Name,
                        sked_New_Value__c = newCollectionOp.Id,
                        sked_New_Value_Display__c = newCollectionOp.Name,
                        sked_Type__c = 'Change'
                    ));
                }
                
                if (newSiteCollectionOp != null) {
                    newDCRItems.add(new sked_Drive_Change_Request_Item__c(
                        sked_Drive_Change_Request__c = dcr.Id,
                        sked_Object_API_Name__c = 'sked_Drive__c',
                        sked_Field_API_Name__c = 'sked_Site_Collection_Operation__c',
                        sked_Field_Label__c = 'Site Collection Operation',
                        sked_Field_Type__c = 'reference',
                        sked_Old_Value__c = drive.sked_Site_Collection_Operation__c,
                        sked_New_Value__c = newSiteCollectionOp.Id,
                        sked_Type__c = 'Change'
                    ));
                }
            }
        }
        
        if (!driveChangeRequestItemsToDelete.isEmpty()) {
            delete driveChangeRequestItemsToDelete;
        }

        if (!newDCRItems.isEmpty()) { 
            insert newDCRItems;
        }  
    }
    
}