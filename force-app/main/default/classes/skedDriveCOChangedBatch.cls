/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
* 05/15/2024                     Balaji N                   This batch is created part of HRP-12054
*03/19/2024                      Harika Bolisetti           Logic for HRP-14438//Taxo Run Chaining in finish method
*/


global class skedDriveCOChangedBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    protected string lastId = '';
    protected Set<Id> sitecollectionOperationIds;
    //HRP-14438
    global Decimal taxVer;
    public skedDriveCOChangedBatch(Set<Id> sitecollectionOperationIds) { 
        this.lastId = '';
        this.sitecollectionOperationIds = sitecollectionOperationIds;
    }
    public skedDriveCOChangedBatch(string lastId, Set<Id> sitecollectionOperationIds) { 
        this.lastId = lastId;
        this.sitecollectionOperationIds = sitecollectionOperationIds;
    }
    //HRP-14438
    public skedDriveCOChangedBatch(Set<Id> sitecollectionOperationIds,Decimal taxVer) { 
        this(sitecollectionOperationIds);
        this.taxVer = taxVer;
    }
    global List<sked_Site_Collection_Operation__c> start(Database.BatchableContext BC) {
        //HRP-14438
        try{
            //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedDriveCOChangedBatch',Method__c='start',Type__c='Success',
                                                             Error_Description__c='Batch Process Started',Error_Description_Long__c= null);
            errorLogList.add(errorLog);
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Start','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            
            return [SELECT Id, sked_Collection_Operation__c, sked_Collection_Operation__r.Name, sked_End_Date__c, 
                    sked_Site__c, sked_Start_Date__c, sked_Region__c
                    FROM sked_Site_Collection_Operation__c
                    WHERE Id IN :this.sitecollectionOperationIds
                    AND Id > :this.lastId
                    ORDER BY Id ASC
                    LIMIT 50000];
        } catch (Exception e) { //HRP-14438
            System.debug('Error in start method: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'skedDriveCOChangedBatch', 'Start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return null;
        }
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Site_Collection_Operation__c> inputRecords) {
       try{//HRP-14438
        if (!inputRecords.isEmpty()) {
            createDriveChangeRequests(inputRecords);
        }
        
        this.lastId = inputRecords.get(inputRecords.size() - 1).Id;
       } catch (Exception e) { //HRP-14438
           System.debug('Error in start method: ' + e.getMessage());
           Taxo_Utilities.logErrorForException(e, 'skedDriveCOChangedBatch', 'Execute', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
       }
    }
    
    global void finish(Database.BatchableContext BC) {
        //HRP-14438
        try{
            Boolean runSkedDriveCOChangedBatch = false; 
            //Capture finish method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedDriveCOChangedBatch',Method__c='finish',Type__c='Success',
                                                             Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
            errorLogList.add(errorLog);
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','skedDriveCOChangedBatch','Finish','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
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
                    //HRP-14438
                    Integer batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_COLLECTION_RECORD_TYPE, 'skedDriveCOChangedBatch');   
                    Database.executeBatch(new skedDriveCOChangedBatch(this.lastId, this.sitecollectionOperationIds), batchSize);
                    runSkedDriveCOChangedBatch = true;
                }
            }
              //HRP-14438
            if(this.taxVer!=null && runSkedDriveCOChangedBatch == false){
              
                Integer batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_COLLECTION_RECORD_TYPE, 'skedActivityDistrictBatch');   
                Database.executeBatch(new skedActivityDistrictBatch(taxver),batchSize);
                
            }
        } catch (Exception e) { //HRP-14438
            System.debug('Error in start method: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'skedDriveCOChangedBatch', 'Finish', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
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
            List<Database.UpsertResult> upsertResult = Database.upsert(dcrsToUpsert, false);   //HRP-14438
            BSF_Utilities.createErrorLog(upsertResult,'Taxonomy Run','skedDriveCOChangedBatch','Constructor','Error','Error occured while upserting the record');
                                   
            
            
            //  upsert dcrsToUpsert;
            
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
            //HRP-14438            
            
            Database.DeleteResult[] deleteResults = Database.delete(driveChangeRequestItemsToDelete, false);
            Taxo_Utilities.logErrorsDeletion(deleteResults, 'Taxonomy Run', 'skedDriveCOChangedBatch', 'Constructor', 'Error', 
                                             'Error occurred while deleting the Record');
            
            
            //delete driveChangeRequestItemsToDelete;
        }
        
        if (!newDCRItems.isEmpty()) {
            //HRP-14438
             
            Database.SaveResult[] statusResults = Database.insert(newDCRItems, false);
            Taxo_Utilities.logErrors(statusResults, 'Taxonomy Run', 'skedDriveCOChangedBatch', 'Constructor', 'Error', 'Error occurred while inserting the Record',
                                     BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            
            // insert newDCRItems;
        }  
    }
}