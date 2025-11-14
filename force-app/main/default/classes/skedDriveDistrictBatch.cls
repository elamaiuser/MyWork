/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
*03/21/2025                      Harika Bolisetti            Logic for HRP-14440//Taxo Run Chaining in finish method
*/

global class skedDriveDistrictBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    //  HRP-14440
    global Decimal taxVer;
    
    public skedDriveDistrictBatch(Decimal taxVer){
        this.taxVer = taxVer;
    }

    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //HRP-14440
        try{
            //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedDriveDistrictBatch',Method__c='start',
                                                             Type__c='Success',Error_Description__c='Batch Process Started',Error_Description_Long__c= null);
            errorLogList.add(errorLog);
            // insert errorLog;
           
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','skedDriveDistrictBatch','Start','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            
          return Database.getQueryLocator('SELECT Id, sked_Collection_Operation__c, sked_District__c, sked_Drive_Date__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= TODAY AND sked_Status__c != \'Cancel\'');
          
        }catch (Exception e) {//HRP-14440
            Taxo_Utilities.logErrorForException(e, 'skedDriveDistrictBatch', 'start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return null;     
        }
    } 
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        List<sked_Drive__c> recordsToPopulate = new List<sked_Drive__c>();
        Set<Id> collectionOperationIds = new Set<Id>();
          try{//HRP-14440
        for (sked_Drive__c drive : drives) {
            recordsToPopulate.add(drive);
            
            if (drive.sked_Collection_Operation__c != NULL) {
                collectionOperationIds.add(drive.sked_Collection_Operation__c);
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
            
            for (sked_Drive__c recordToPopulate : recordsToPopulate) {
                if (mapCO.containsKey(recordToPopulate.sked_Collection_Operation__c)) {
                    Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(recordToPopulate.sked_Collection_Operation__c);
                    
                    for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                        boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= recordToPopulate.sked_Drive_Date__c;
                        boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= recordToPopulate.sked_Drive_Date__c;
                        if (isStartDateMatched && isEndDateMatched) {
                            recordToPopulate.sked_District__c = territoryCO.sked_Territory__c;
                            break;
                        }
                    }
                }
            }
            //HRP-14440
            
             //11/19/2024 - Added Save Logic with Error handling for HRP-13713
        ////    List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.update(recordsToPopulate, false), 'Activity District Correction','skedActivityDistrictBatch','Execute','Error','Error during Sked Activity District Correction');
           // InsertBsfErrorLog.insertBsfErrors(logList); 
           // 
            Database.SaveResult[] statusResults = Database.update(recordsToPopulate, false);
            Taxo_Utilities.logErrors(statusResults, 'Taxonomy Run', 'skedDriveDistrictBatch', 'Execute', 'Error', 'Error occurred while updating the Record',
                                     BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            
        }
              
          }  catch (Exception e) {
              Taxo_Utilities.logErrorForException(e, 'skedDriveDistrictBatch', 'execute', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
          }
        
    }
    
    global void finish(Database.BatchableContext BC) {
        //HRP-14440
        try{
             //Capture finish method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='skedDriveDistrictBatch',Method__c='finish',
                                                             Type__c='Success',Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
            errorLogList.add(errorLog);
            
            
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','skedDriveDistrictBatch','Finish','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            if(this.taxVer!=null){
                Integer batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_COLLECTION_RECORD_TYPE, 'skedResourceOverrideDistrictBatch');   
                Database.executeBatch(new skedResourceOverrideDistrictBatch(taxver),batchSize);     
            }
            
        }  catch (Exception e) {
            Taxo_Utilities.logErrorForException(e, 'skedDriveDistrictBatch', 'finish', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            
        }
        
    }
    
}