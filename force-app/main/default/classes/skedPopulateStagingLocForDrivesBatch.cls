public class skedPopulateStagingLocForDrivesBatch implements Database.Batchable<SObject> {

    public skedPopulateStagingLocForDrivesBatch() {}

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c
            FROM sked_Drive__c
            WHERE sked_Staging_Location__c = NULL
            AND sked_Collection_Operation__c != NULL
        ]);
     }
  
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        List<sked_Drive__c> drives = (List<sked_Drive__c>) scope;
        
        Set<Id> coIds = new Set<Id>();
        for (sked_Drive__c drive : drives) {
            coIds.add(drive.sked_Collection_Operation__c);
        }

        Map<Id, Biomed_Collection_Op_Center__c> coById = new Map<Id, Biomed_Collection_Op_Center__c>([
            SELECT Id, Name,
            (SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Staging_Location__c FROM sked_Collection_Op_Staging_Locations__r)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id IN :coIds
        ]);

        for (sked_Drive__c drive : drives) { 
            Biomed_Collection_Op_Center__c co = coById.get(drive.sked_Collection_Operation__c);

            if (co != null && co.sked_Collection_Op_Staging_Locations__r != null && !co.sked_Collection_Op_Staging_Locations__r.isEmpty()) {
                for (sked_Collection_Op_Staging_Location__c cosl : co.sked_Collection_Op_Staging_Locations__r) {
                    if (drive.sked_Drive_Date__c >= cosl.sked_Start_Date__c && drive.sked_Drive_Date__c <= cosl.sked_End_Date__c) {
                        drive.sked_Staging_Location__c = cosl.sked_Staging_Location__c;
                    }
                }
            }
        }

        skedHubBase.BypassUpdateTriggers = true;
        update drives;
        skedHubBase.BypassUpdateTriggers = false;
    }
  
    public void finish(Database.BatchableContext BC) {}
}