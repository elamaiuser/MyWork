/* @Description: Batch to update District on Drive Shift Trade post Taxo Processing

* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
11/19/2024                      Souvik Mukherjee                HRP-13713 - Added Code to save modifed Drive Shift Trade Records
*03/25/2025                     Harika Bolisetti               Logic for HRP-14442//Taxo Run Chaining in finish method
* ***********************************************************************************************************************************************/

global class skedDriveShiftTradeDistrictBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    //HRP-14442
    global Decimal taxVer;
    public skedDriveShiftTradeDistrictBatch(Decimal taxVer){
        this.taxVer = taxVer;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //HRP-14442
        try{
            //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedDriveShiftTradeDistrictBatch',Method__c='start',Type__c='Success',
                                                             Error_Description__c='Batch Process Started',Error_Description_Long__c= null);
            errorLogList.add(errorLog);
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','skedDriveShiftTradeDistrictBatch','Start','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return Database.getQueryLocator('SELECT Id, sked_Collection_Operation__c, sked_District__c, sked_Requesting_Staff_Trading_Event_Date__c FROM sked_Drive_Shift_Trade__c WHERE sked_Requesting_Staff_Trading_Event_Date__c >= TODAY');
        }catch (Exception e) {//HRP-14442
            Taxo_Utilities.logErrorForException(e, 'skedDriveShiftTradeDistrictBatch', 'start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return null;
        }
    } 
    
    global void execute(Database.BatchableContext BC, List<sked_Drive_Shift_Trade__c> driveShiftTrades) {
        List<sked_Drive_Shift_Trade__c> recordsToPopulate = new List<sked_Drive_Shift_Trade__c>();
        Date minDate = System.today();
        Set<Id> collectionOperationIds = new Set<Id>();
        try{//HRP-14442
            for (sked_Drive_Shift_Trade__c driveShiftTrade : driveShiftTrades) {
                recordsToPopulate.add(driveShiftTrade);
                
                if (driveShiftTrade.sked_Collection_Operation__c != NULL) {
                    collectionOperationIds.add(driveShiftTrade.sked_Collection_Operation__c);
                }
            }
            if (!recordsToPopulate.isEmpty()) {
                Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>();
                if (!collectionOperationIds.isEmpty()) {
                    mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, 
                                                                         (SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Territory__c
                                                                          FROM sked_Territory_Collection_Operations__r)
                                                                         FROM Biomed_Collection_Op_Center__c
                                                                         WHERE Id IN :collectionOperationIds]);
                }
            
                for (sked_Drive_Shift_Trade__c recordToPopulate : recordsToPopulate) {
                    if (mapCO.containsKey(recordToPopulate.sked_Collection_Operation__c)) {
                        Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(recordToPopulate.sked_Collection_Operation__c);
                        
                        for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                            boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= recordToPopulate.sked_Requesting_Staff_Trading_Event_Date__c ;
                            boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= recordToPopulate.sked_Requesting_Staff_Trading_Event_Date__c ;
                            if (isStartDateMatched && isEndDateMatched) {
                                recordToPopulate.sked_District__c = territoryCO.sked_Territory__c;
                                break;
                            }
                        }
                    }
                }
                //11/19/2024 - Added Save Logic with Error handling for HRP-13713
               // List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.update(recordsToPopulate, false), 'Shift Trade District Correction','skedDriveShiftTradeDistrictBatch','Execute','Error','Error during Drive Shift Trade District Correction');
               // InsertBsfErrorLog.insertBsfErrors(logList);
                //HRP -14442
                  Database.SaveResult[] statusResults = Database.update(recordsToPopulate, false);
                Taxo_Utilities.logErrors(statusResults, 'Taxonomy Run', 'skedDriveShiftTradeDistrictBatch', 'Execute', 'Error', 'Error occurred while updating the Record',
                                         BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            }
        }catch (Exception e) {//HRP-14442
            Taxo_Utilities.logErrorForException(e, 'skedDriveShiftTradeDistrictBatch', 'execute', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        //HRP-14442
        //Capture finish method entry in Error Log
        List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
        BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedDriveShiftTradeDistrictBatch',Method__c='finish',Type__c='Success',
                                                         Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
        errorLogList.add(errorLog);
        Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
        Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','skedDriveShiftTradeDistrictBatch','Finish','Error',
                                 'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        //Fetch Bio Collection Records with Future Version
        try{
            List<Taxonomy_Run__c> updateTaxoRun = new List<Taxonomy_Run__c>();
            List<Taxonomy_Run__c> recordsToUpdate = new List<Taxonomy_Run__c>();
            for(Taxonomy_Run__c txr : [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c
                                       FROM Taxonomy_Run__c 
                                       WHERE Future_Version_Number__c =:taxver and Taxo_Record_Type__c =: BSF_Constants.BIO_COLLECTION_RECORD_TYPE] ){
                                           txr.Status__c = 'Completed';
                                           txr.Processing_End__c = System.now();
                                           updateTaxoRun.add(txr);
                                       }
            if(updateTaxoRun.size() > 0){
                Database.SaveResult[] updateResults = Database.update(updateTaxoRun, false);
                Taxo_Utilities.logErrors(updateResults,'Taxonomy Run','BSF_Batch_TaxoRunControlBatch','Execute','Error',
                                         'Error occured in while updating the Taxonomy Run Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            }
        }catch (Exception e) {//HRP-14442
            Taxo_Utilities.logErrorForException(e, 'skedDriveShiftTradeDistrictBatch', 'Finish', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        } 
        
    }
}