global with sharing class BSF_Batch_ActivityTimeBlockAssignment implements Database.Batchable<sObject>, Database.Stateful {

    global Set<Id> collectionOperationIds;
    global Integer totalUpdated = 0;
    global Integer totalErrors = 0;

    global BSF_Batch_ActivityTimeBlockAssignment() {
    }

    global BSF_Batch_ActivityTimeBlockAssignment(Set<Id> collectionOperationIds) {
        this.collectionOperationIds = collectionOperationIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (collectionOperationIds == null || collectionOperationIds.isEmpty()) {
            collectionOperationIds = getActiveCollectionOperationIds();
        }
        Set<Id> coIds = collectionOperationIds;

        String query = 'SELECT Id, sked_Start_Time__c, sked_End_Time__c, sked_Start_Date__c, ' +
            'sked_Day_of_Week__c, sked_Collection_Operation__c, sked_Time_Block__c ' +
            'FROM sked__Activity__c ' +
            'WHERE sked_Time_Block__c = NULL ' +
            'AND sked_Start_Time__c != NULL ' +
            'AND sked_End_Time__c != NULL ' +
            'AND sked_Day_of_Week__c != NULL ' +
            'AND sked_Start_Date__c >= TODAY ' +
            'AND sked_Collection_Operation__c IN :coIds ' +
            'AND Id NOT IN (SELECT sked__Activity__c FROM sked__Activity_Resource__c WHERE sked__Activity__c != NULL)';

        return Database.getQueryLocator(query);
    }

    private Set<Id> getActiveCollectionOperationIds() {
        Set<Id> activeCoIds = new Set<Id>();
        for (Biomed_Collection_Op_Center__c co : [
            SELECT Id, sked_Is_Deactivated__c, External_Id__c, Name
            FROM Biomed_Collection_Op_Center__c
            WHERE sked_Is_Deactivated__c = false
            AND External_Id__c != NULL
            AND Name != :skedConstants.NON_COLLECTION_AREA_CO
        ]) {
            activeCoIds.add(co.Id);
        }
        return activeCoIds;
    }

    global void execute(Database.BatchableContext bc, List<sked__Activity__c> activities) {
        try {
            Set<Id> coIds = collectCollectionOperationIds(activities);
            if (coIds.isEmpty()) {
                return;
            }

            Map<Id, List<Collection_Operation_Time_Block__c>> coToCotbs = new Map<Id, List<Collection_Operation_Time_Block__c>>();
            Map<Id, Time_Block__c> tbById = new Map<Id, Time_Block__c>();
            loadCollectionOperationTimeBlocks(coIds, coToCotbs, tbById);

            List<sked__Activity__c> updates = buildUpdates(activities, coToCotbs, tbById);
            saveUpdates(updates);
        } catch (Exception ex) {
            totalErrors++;
            BSF_Error_Log__c log = BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'BSF_Batch_ActivityTimeBlockAssignment',
                'Execute',
                'Activity Time Block Assignment',
                'Bulk Time Block Assignment',
                'sked__Activity__c',
                null
            );
            Database.insert(new List<BSF_Error_Log__c>{ log }, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('BSF_Batch_ActivityTimeBlockAssignment complete. Updated: ' + totalUpdated + ', Errors: ' + totalErrors);
    }

    private Set<Id> collectCollectionOperationIds(List<sked__Activity__c> activities) {
        Set<Id> coIds = new Set<Id>();
        for (sked__Activity__c a : activities) {
            if (a.sked_Collection_Operation__c != null) {
                coIds.add(a.sked_Collection_Operation__c);
            }
        }
        return coIds;
    }

    private void loadCollectionOperationTimeBlocks(
        Set<Id> coIds,
        Map<Id, List<Collection_Operation_Time_Block__c>> coToCotbs,
        Map<Id, Time_Block__c> tbById
    ) {
        for (Collection_Operation_Time_Block__c cotb : [
            SELECT Id, Collection_Operation__c, Time_Block__c,
                   Effective_Start_Date__c, Effective_End_Date__c,
                   Time_Block__r.Id, Time_Block__r.Name,
                   Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c,
                   Time_Block__r.Days_of_Week__c
            FROM Collection_Operation_Time_Block__c
            WHERE Collection_Operation__c IN :coIds
        ]) {
            if (!coToCotbs.containsKey(cotb.Collection_Operation__c)) {
                coToCotbs.put(cotb.Collection_Operation__c, new List<Collection_Operation_Time_Block__c>());
            }
            coToCotbs.get(cotb.Collection_Operation__c).add(cotb);
            if (cotb.Time_Block__c != null && !tbById.containsKey(cotb.Time_Block__c)) {
                tbById.put(cotb.Time_Block__c, cotb.Time_Block__r);
            }
        }
    }

    private List<sked__Activity__c> buildUpdates(
        List<sked__Activity__c> activities,
        Map<Id, List<Collection_Operation_Time_Block__c>> coToCotbs,
        Map<Id, Time_Block__c> tbById
    ) {
        List<sked__Activity__c> updates = new List<sked__Activity__c>();

        for (sked__Activity__c a : activities) {
            List<Collection_Operation_Time_Block__c> cotbs = coToCotbs.containsKey(a.sked_Collection_Operation__c)
                ? coToCotbs.get(a.sked_Collection_Operation__c)
                : new List<Collection_Operation_Time_Block__c>();

            Id matchedTbId = findMatchingTimeBlock(a, cotbs, tbById);
            if (matchedTbId == null) {
                continue;
            }

            updates.add(new sked__Activity__c(
                Id = a.Id,
                sked_Time_Block__c = matchedTbId
            ));
        }

        return updates;
    }

    private Id findMatchingTimeBlock(
        sked__Activity__c a,
        List<Collection_Operation_Time_Block__c> cotbs,
        Map<Id, Time_Block__c> tbById
    ) {
        List<Id> fitTbIds = new List<Id>();

        for (Collection_Operation_Time_Block__c cotb : cotbs) {
            Time_Block__c tb = tbById.get(cotb.Time_Block__c);
            if (tb == null) {
                continue;
            }

            Boolean dateOk = (cotb.Effective_Start_Date__c == null || a.sked_Start_Date__c >= cotb.Effective_Start_Date__c)
                          && (cotb.Effective_End_Date__c == null || a.sked_Start_Date__c <= cotb.Effective_End_Date__c);
            Boolean dayOk = String.isNotBlank(tb.Days_of_Week__c) && tb.Days_of_Week__c.contains(a.sked_Day_of_Week__c);

            if (!dateOk || !dayOk) {
                continue;
            }

            Boolean fitsWithin = tb.Start_Time__c != null && tb.End_Time__c != null
                && tb.Start_Time__c <= a.sked_Start_Time__c
                && tb.End_Time__c >= a.sked_End_Time__c;

            if (fitsWithin) {
                fitTbIds.add(tb.Id);
            }
        }

        return fitTbIds.size() == 1 ? fitTbIds[0] : null;
    }

    private void saveUpdates(List<sked__Activity__c> updates) {
        if (updates.isEmpty()) {
            return;
        }

        Database.SaveResult[] results = Database.update(updates, false);
        Integer batchErrors = 0;
        for (Database.SaveResult r : results) {
            if (r.isSuccess()) {
                totalUpdated++;
            } else {
                batchErrors++;
            }
        }
        totalErrors += batchErrors;

        if (batchErrors > 0) {
            List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLogWithObjectId(
                results,
                'Activity Time Block Assignment',
                'BSF_Batch_ActivityTimeBlockAssignment',
                'Execute',
                'Error',
                'Bulk Time Block Assignment'
            );
            if (!errorLogs.isEmpty()) {
                Database.insert(errorLogs, false);
            }
        }
    }
}
