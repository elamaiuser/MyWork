public class skedMergeCollectionOpStagingLocsBatch implements Database.Batchable<sked_Collection_Op_Staging_Location__c>, Database.Stateful{
    Set<Id> affectedStagingLocationIds = new Set<Id>();
    List<Id> coIds;
    Id coId;

    public skedMergeCollectionOpStagingLocsBatch(List<Id> coIds) {
        this.coIds = coIds;
        this.coId = coIds[0];
    }

    public List<sked_Collection_Op_Staging_Location__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Collection_Operation__c, sked_Staging_Location__c
            FROM sked_Collection_Op_Staging_Location__c
            WHERE sked_Collection_Operation__c = :this.coId
            ORDER BY sked_Start_Date__c ASC
        ];
    }

    public void execute(Database.BatchableContext BC, List<sked_Collection_Op_Staging_Location__c> coSls) {
        List<sked_Collection_Op_Staging_Location__c> coSlsToUpdate = new List<sked_Collection_Op_Staging_Location__c>();
        List<sked_Collection_Op_Staging_Location__c> coSlsToDelete = new List<sked_Collection_Op_Staging_Location__c>();

        for (Integer i = 0; i < coSls.size(); i++) {
            Boolean recordUpdated = false;
            Boolean hasNext = (i+1) < coSls.size();
            sked_Collection_Op_Staging_Location__c coSl = coSls[i];
            if (i == 0 && coSl.sked_Start_Date__c != skedConstants.EARLIEST_START_DATE) {
                coSl.sked_Start_Date__c = skedConstants.EARLIEST_START_DATE;
                recordUpdated = true;
            }

            if (hasNext) {
                sked_Collection_Op_Staging_Location__c nextItem = coSls[i+1];
                coSl.sked_End_Date__c = nextItem.sked_Start_Date__c.addDays(-1);
                recordUpdated = true;
                if (coSl.sked_Staging_Location__c == nextItem.sked_Staging_Location__c) {
                    coSl.sked_End_Date__c = nextItem.sked_End_Date__c;
                    coSlsToDelete.add(nextItem);
                    i++;
                }
            } else if (coSl.sked_End_Date__c != skedConstants.LATEST_END_DATE) {
                coSl.sked_End_Date__c = skedConstants.LATEST_END_DATE;
                recordUpdated = true;
            }

            if (recordUpdated) {
                coSlsToUpdate.add(coSl);
            }
            this.affectedStagingLocationIds.add(coSl.sked_Staging_Location__c);
        }

        if (!coSlsToUpdate.isEmpty()) {
            skedHubBase.BypassUpdateTriggers = true;
            update coSlsToUpdate;
            skedHubBase.BypassUpdateTriggers = false;
        }

        if (!coSlsToDelete.isEmpty()) {
            skedHubBase.BypassDeleteTriggers = true;
            delete coSlsToDelete;
            skedHubBase.BypassDeleteTriggers = false;
        }
    }

    public void finish(Database.BatchableContext BC) {
        this.coIds.remove(0);
        if (!this.coIds.isEmpty()) {
            Database.executeBatch(new skedMergeCollectionOpStagingLocsBatch(this.coIds));
        } else if (!this.affectedStagingLocationIds.isEmpty()) {
            Database.executeBatch(new skedRepopulateDriveStagingLocBatch(this.affectedStagingLocationIds));
        }
    }
}