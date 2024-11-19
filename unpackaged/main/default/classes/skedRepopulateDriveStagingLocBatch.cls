public class skedRepopulateDriveStagingLocBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<Id> stagingLocationIds;
    Set<Id> impactedDriveIds = new Set<Id>();

    public skedRepopulateDriveStagingLocBatch(Set<Id> stagingLocationIds) {
        this.stagingLocationIds = stagingLocationIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Drive_Date__c, sked_Collection_Operation__c, sked_Staging_Location__c
            FROM sked_Drive__c
            WHERE sked_Staging_Location__c IN :this.stagingLocationIds
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
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


        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        for (sked_Drive__c drive : drives) { 
            Biomed_Collection_Op_Center__c co = coById.get(drive.sked_Collection_Operation__c);

            if (co != null && co.sked_Collection_Op_Staging_Locations__r != null && !co.sked_Collection_Op_Staging_Locations__r.isEmpty()) {
                for (sked_Collection_Op_Staging_Location__c cosl : co.sked_Collection_Op_Staging_Locations__r) {
                    if (drive.sked_Drive_Date__c >= cosl.sked_Start_Date__c && drive.sked_Drive_Date__c <= cosl.sked_End_Date__c) {
                        if (drive.sked_Staging_Location__c != cosl.sked_Staging_Location__c) {
                            drive.sked_Staging_Location__c = cosl.sked_Staging_Location__c;
                            drivesToUpdate.add(drive);
							this.impactedDriveIds.add(drive.Id);
                        }
                    }
                }
            }
        }

        if (!drivesToUpdate.isEmpty()) {
            update drivesToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        if(!this.impactedDriveIds.isEmpty()) {
        	Database.executeBatch(new skedCreateDCRForTravelTimeChangeBatch(new Set<Id>(),this.impactedDriveIds));
        }
    }
}