public class skedOptimizationQueueHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
	private void populateData(List<sked_Optimization_Queue__c> newRecords) {
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Optimization_Queue__c newRecord : newRecords) {
            if (string.isBlank(newRecord.Name)) {
            	collectionOperationIds.add(newRecord.sked_Collection_Operation__c);
            }
            List<string> keyParts = new List<string>();
            keyParts.add(Json.serialize(newRecord.sked_Start_Date__c).replace('"', ''));
            keyParts.add(newRecord.sked_Collection_Operation__c);
            keyParts.add(newRecord.sked_Drive_Type__c);
            newRecord.sked_UniqueKey__c = string.join(keyParts, ':');
            
            if (newRecord.sked_Start_Date__c != NULL) {
                DateTime startDateDt = DateTime.newInstance(newRecord.sked_Start_Date__c, Time.newInstance(0, 0, 0, 0));
                newRecord.sked_Start_Date_Str__c = startDateDt.format(skedDateTimeUtils.DATE_FORMAT);
            }
            if (newRecord.sked_End_Date__c != NULL) {
                DateTime endDateDt = DateTime.newInstance(newRecord.sked_End_Date__c, Time.newInstance(0, 0, 0, 0));
                newRecord.sked_End_Date_Str__c = endDateDt.format(skedDateTimeUtils.DATE_FORMAT);
            }
        }
        if (!collectionOperationIds.isEmpty()) {
            Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, Name 
                                                                                                         FROM Biomed_Collection_Op_Center__c
                                                                                                         WHERE Id IN :collectionOperationIds]);
            for (sked_Optimization_Queue__c newRecord : newRecords) {
                if (string.isBlank(newRecord.Name)) {
                    if (mapCO.containsKey(newRecord.sked_Collection_Operation__c)) {
                        Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(newRecord.sked_Collection_Operation__c);
                        List<string> nameParts = new List<string>();
                        nameParts.add(collectionOperation.Name);
                        nameParts.add(string.valueOf(newRecord.sked_Start_Date__c));
                        nameParts.add(newRecord.sked_Drive_Type__c);
                        newRecord.Name = string.join(nameParts, ' - ');
                    }
                }
            }
        }
    }
    
}