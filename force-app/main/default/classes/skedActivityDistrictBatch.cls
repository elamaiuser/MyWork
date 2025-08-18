/* @Description: Batch to update District on Sked Activity post Taxo Processing

* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
11/19/2024                      Souvik Mukherjee                HRP-13713 - Added Code to save modifed Activity Records
*03/19/2024                     Harika Bolisetti                Logic for HRP-14437 //Taxo Run Chaining in finish method

* ***********************************************************************************************************************************************/

global class skedActivityDistrictBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    //HRP-14437
    global Decimal taxVer;
    public skedActivityDistrictBatch(Decimal taxVer){
        this.taxVer = taxVer;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //HRP-14437
        try{
            //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedActivityDistrictBatch',Method__c='start',Type__c='Success',
                                                             Error_Description__c='Batch Process Started',Error_Description_Long__c= null);
            errorLogList.add(errorLog);
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','skedActivityDistrictBatch','Start','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return Database.getQueryLocator('SELECT Id, sked_Collection_Operation__c, sked_District__c, sked_Start_Date__c FROM sked__Activity__c WHERE sked_Start_Date__c >= TODAY');
        } catch (Exception e) { //HRP-14437
            Taxo_Utilities.logErrorForException(e, 'skedActivityDistrictBatch', 'Start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return null;
        }
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Activity__c> activities) {
        List<sked__Activity__c> recordsToPopulate = new List<sked__Activity__c>();
        Date minDate = System.today();
        Set<Id> collectionOperationIds = new Set<Id>();
        try{//HRP-14437
        for (sked__Activity__c activity : activities) {
            recordsToPopulate.add(activity);
            
            if (activity.sked_Collection_Operation__c != NULL) {
                collectionOperationIds.add(activity.sked_Collection_Operation__c);
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
            
            for (sked__Activity__c recordToPopulate : recordsToPopulate) {
                if (mapCO.containsKey(recordToPopulate.sked_Collection_Operation__c)) {
                    Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(recordToPopulate.sked_Collection_Operation__c);
                    
                    for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                        boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= recordToPopulate.sked_Start_Date__c;
                        boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= recordToPopulate.sked_Start_Date__c;
                        if (isStartDateMatched && isEndDateMatched) {
                            recordToPopulate.sked_District__c = territoryCO.sked_Territory__c;
                            break;
                        }
                    }
                }
            }
            //11/19/2024 - Added Save Logic with Error handling for HRP-13713
           // List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.update(recordsToPopulate, false), 'Activity District Correction','skedActivityDistrictBatch','Execute','Error','Error during Sked Activity District Correction');
           // InsertBsfErrorLog.insertBsfErrors(logList);
           
            //HRP-14437
            Database.SaveResult[] statusResults = Database.update(recordsToPopulate, false);
            Taxo_Utilities.logErrors(statusResults, 'Taxonomy Run', 'skedActivityDistrictBatch', 'Execute', 'Error', 'Error occurred while updating the Record',
                                     BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
             
        }
        } catch (Exception e) { //HRP-14437
            Taxo_Utilities.logErrorForException(e, 'skedActivityDistrictBatch', 'execute', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
    }    
    global void finish(Database.BatchableContext BC) {
        try{//HRP-14437
            //Capture finish method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedActivityDistrictBatch',Method__c='finish',
                                                             Type__c='Success',Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
            errorLogList.add(errorLog);           
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Finish','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
         
            if (this.taxver != null) {
                List<Taxonomy_Run_Config__mdt> configRecords = Taxonomy_Run_Config__mdt.getAll().values();
                Boolean runCorrectionBatch = false;
                for (Taxonomy_Run_Config__mdt record : configRecords) {
                    if (record.Is_Active__c && record.Category__c == 'Batch Size Config' && record.Allow_Batch_Run__c == TRUE) {
                        runCorrectionBatch = true;
                        break; 
                    }
                }
                
                Integer batchSize;
                if (runCorrectionBatch) {
                    batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_COLLECTION_RECORD_TYPE, 'JobSkedRegionCorrectionBatch');
                    Database.executeBatch(new JobSkedRegionCorrectionBatch(taxver), batchSize);
                } else {
                    batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_COLLECTION_RECORD_TYPE, 'skedDriveDistrictBatch');
                    Database.executeBatch(new skedDriveDistrictBatch(taxver), batchSize);
                }
            }

        } catch (Exception e) { //HRP-14437
            
            Taxo_Utilities.logErrorForException(e, 'skedActivityDistrictBatch', 'finish', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
    }
}