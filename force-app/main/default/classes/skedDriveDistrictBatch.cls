global class skedDriveDistrictBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, sked_Collection_Operation__c, sked_District__c, sked_Drive_Date__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= TODAY AND sked_Status__c != \'Cancel\'');
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        List<sked_Drive__c> recordsToPopulate = new List<sked_Drive__c>();
        Set<Id> collectionOperationIds = new Set<Id>();
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
            update recordsToPopulate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }

}