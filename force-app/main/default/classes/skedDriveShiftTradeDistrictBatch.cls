/* @Description: Batch to update District on Drive Shift Trade post Taxo Processing

* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
11/19/2024                      Souvik Mukherjee                HRP-13713 - Added Code to save modifed Drive Shift Trade Records
* ***********************************************************************************************************************************************/

global class skedDriveShiftTradeDistrictBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, sked_Collection_Operation__c, sked_District__c, sked_Requesting_Staff_Trading_Event_Date__c FROM sked_Drive_Shift_Trade__c WHERE sked_Requesting_Staff_Trading_Event_Date__c >= TODAY');
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive_Shift_Trade__c> driveShiftTrades) {
        List<sked_Drive_Shift_Trade__c> recordsToPopulate = new List<sked_Drive_Shift_Trade__c>();
        Date minDate = System.today();
        Set<Id> collectionOperationIds = new Set<Id>();
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
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.update(recordsToPopulate, false), 'Shift Trade District Correction','skedDriveShiftTradeDistrictBatch','Execute','Error','Error during Drive Shift Trade District Correction');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }

}