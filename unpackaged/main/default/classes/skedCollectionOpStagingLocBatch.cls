public class skedCollectionOpStagingLocBatch implements Database.Batchable<sked_Collection_Op_Staging_Location__c>, Database.Stateful {
    Set<Id> affectedCoIds = new Set<Id>();

    List<skedCoSlWrapper> coSlWrappers;
    skedCoSlWrapper coSlWrapper;

    public skedCollectionOpStagingLocBatch(List<skedCoSlWrapper> coSlWrappers) {
        this.coSlWrappers = coSlWrappers;
        this.coSlWrapper = coSlWrappers[0];
    }

    public List<sked_Collection_Op_Staging_Location__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked_Collection_Operation__c, sked_Start_Date__c, sked_End_Date__c, sked_Staging_Location__c
            FROM sked_Collection_Op_Staging_Location__c
            WHERE sked_Collection_Operation__c =:this.coSlWrapper.coSl.sked_Collection_Operation__c
            AND Id != :this.coSlWrapper.coSl.Id
            ORDER BY sked_Start_Date__c ASC
        ];
    }

    public void execute(Database.BatchableContext BC, List<sked_Collection_Op_Staging_Location__c> existingCoSls) {
        List<sked_Collection_Op_Staging_Location__c> coSlsToUpsert = new List<sked_Collection_Op_Staging_Location__c>();
        List<sked_Collection_Op_Staging_Location__c> coSlsToDelete = new List<sked_Collection_Op_Staging_Location__c>();

        for (Integer i = 0; i < existingCoSls.size(); i++) {
            sked_Collection_Op_Staging_Location__c existingCoSl = existingCoSls.get(i);
            Boolean hasNext = (i+1) < existingCoSls.size();
            Boolean datesOverlap = this.coSlWrapper.cosl.sked_Start_Date__c < existingCoSl.sked_End_Date__c && existingCoSl.sked_Start_Date__c < this.coSlWrapper.cosl.sked_End_Date__c;

            // In the middle of existing
            if (this.coSlWrapper.cosl.sked_Start_Date__c > existingCoSl.sked_Start_Date__c && this.coSlWrapper.cosl.sked_End_Date__c < existingCoSl.sked_End_Date__c) {
                sked_Collection_Op_Staging_Location__c clonedItem = new sked_Collection_Op_Staging_Location__c(
                    sked_Collection_Operation__c = existingCoSl.sked_Collection_Operation__c,
                    sked_Staging_Location__c = existingCoSl.sked_Staging_Location__c,
                    sked_Start_Date__c = this.coSlWrapper.cosl.sked_End_Date__c.addDays(1),
                    sked_End_Date__c = existingCoSl.sked_End_Date__c
                );
                coSlsToUpsert.add(clonedItem);
                existingCoSl.sked_End_Date__c = this.coSlWrapper.cosl.sked_Start_Date__c.addDays(-1);
                coSlsToUpsert.add(existingCoSl);
                continue;

                if (hasNext) {
                    existingCoSls.add(i+1, clonedItem);
                } else {
                    existingCoSls.add(clonedItem);
                }
            }

            // Completely covers existing
            if (this.coSlWrapper.cosl.sked_Start_Date__c <= existingCoSl.sked_Start_Date__c && this.coSlWrapper.cosl.sked_End_Date__c >= existingCoSl.sked_End_Date__c) {
                coSlsToDelete.add(existingCoSl);
                continue;
            }
            
            // Overlap Before
            if (this.coSlWrapper.cosl.sked_Start_Date__c <= existingCoSl.sked_Start_Date__c && datesOverlap) {
                existingCoSl.sked_Start_Date__c = this.coSlWrapper.cosl.sked_End_Date__c.addDays(1);
                coSlsToUpsert.add(existingCoSl);
                continue;
            }

            // Overlap After
            if (this.coSlWrapper.cosl.sked_End_Date__c >= existingCoSl.sked_End_Date__c && datesOverlap) {
                existingCoSl.sked_End_Date__c = this.coSlWrapper.cosl.sked_Start_Date__c.addDays(-1);
                coSlsToUpsert.add(existingCoSl);
                continue;
            }

            // Gaps
            if (this.coSlWrapper.isUpdate) {
                sked_Collection_Op_Staging_Location__c newCosl = this.coSlWrapper.cosl;
                sked_Collection_Op_Staging_Location__c oldCosl = this.coSlWrapper.oldCosl;

                // A1-A2, B1-B2
                // B1 is updated to a later date, need to update A2 to B1.start(-1)
                if (this.coSlWrapper.isStartDateChanged 
                && Math.abs(existingCoSl.sked_End_Date__c.daysBetween(oldCosl.sked_Start_Date__c)) == 1
                && Math.abs(existingCoSl.sked_End_Date__c.daysBetween(newCosl.sked_Start_Date__c)) > 1) {
                    existingCoSl.sked_End_Date__c = newCosl.sked_Start_Date__c.addDays(-1);
                    coSlsToUpsert.add(existingCoSl);
                    continue;

                }

                // A1-A2, B1-B2
                // A2 is updated to an earlier date, need to update B1 to A2.end(+1)
                if (this.coSlWrapper.isEndDateChanged
                && Math.abs(existingCoSl.sked_Start_Date__c.daysBetween(oldCosl.sked_End_Date__c)) == 1
                && Math.abs(existingCoSl.sked_Start_Date__c.daysBetween(newCosl.sked_End_Date__c)) > 1) {
                    existingCoSl.sked_Start_Date__c = newCosl.sked_End_Date__c.addDays(1);
                    coSlsToUpsert.add(existingCoSl);
                    continue;
                }
            }
        }

        if (!coSlsToDelete.isEmpty()) {
            skedHubBase.BypassDeleteTriggers = true;
            delete coSlsToDelete;
            skedHubBase.BypassDeleteTriggers = false;
        }

        if (!coSlsToUpsert.isEmpty()) {
            skedHubBase.BypassUpdateTriggers = true;
            upsert coSlsToUpsert;
            skedHubBase.BypassUpdateTriggers = false;
        }

        this.affectedCoIds.add(this.coSlWrapper.coSl.sked_Collection_Operation__c);
    }

    public void finish(Database.BatchableContext BC) {
        List<skedCoSlWrapper> wrappers = new List<skedCoSlWrapper>();
        wrappers.addAll(this.coslWrappers);
        wrappers.remove(0);
        if (wrappers.size() > 0) {
            Database.executeBatch(new skedCollectionOpStagingLocBatch(wrappers), 1);
        }

        if (wrappers.size() == 0) {
            List<Id> coIds = new List<Id>();
            coIds.addAll(this.affectedCoIds);
            if (!coIds.isEmpty()) {
                Database.executeBatch(new skedMergeCollectionOpStagingLocsBatch(coIds));
            }
        }
    }
}