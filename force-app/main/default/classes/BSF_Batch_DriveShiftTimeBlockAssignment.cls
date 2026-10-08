
global with sharing class BSF_Batch_DriveShiftTimeBlockAssignment implements Database.Batchable<sObject>, Database.Stateful {

    global Set<Id> collectionOperationIds;
    global Integer totalUpdated = 0;
    global Integer totalErrors = 0;

    global BSF_Batch_DriveShiftTimeBlockAssignment() {
    }

    global BSF_Batch_DriveShiftTimeBlockAssignment(Set<Id> collectionOperationIds) {
        this.collectionOperationIds = collectionOperationIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String cancelStatus = skedConstants.DRIVE_STATUS_CANCEL;
        String mobileType = skedConstants.DRIVE_TYPE_MOBILE;
        String nonIntegratedWB = skedConstants.OPERATION_TYPE_WB;

        if (collectionOperationIds == null || collectionOperationIds.isEmpty()) {
            collectionOperationIds = getActiveCollectionOperationIds();
        }
        Set<Id> coIds = collectionOperationIds;

        String query = 'SELECT Id, sked_Start_Time__c, sked_End_Time__c, ' +
            'sked_Time_Block__c, sked_Contention__c, sked_Contention_Resolution__c, ' +
            'sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Collection_Operation__c, ' +
            'sked_Drive__r.sked_Day_of_Week__c, sked_Drive__r.sked_Status__c, ' +
            'sked_Drive__r.sked_Drive_Site__r.Operation_Type__c, sked_Drive__r.sked_Type_of_Drive__c ' +
            'FROM sked_Drive_Shift__c ' +
            'WHERE sked_Time_Block__c = NULL ' +
            'AND sked_Contention_Resolution__c = NULL ' +
            'AND sked_Drive__r.sked_Status__c != :cancelStatus ' +
            'AND (sked_Drive__r.sked_Drive_Site__r.Operation_Type__c = :nonIntegratedWB ' +
            'OR sked_Drive__r.sked_Type_of_Drive__c = :mobileType) ' +
            'AND sked_Drive__r.sked_Drive_Date__c >= TODAY ' +
            'AND sked_Drive__r.sked_Collection_Operation__c IN :coIds';

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

    global void execute(Database.BatchableContext bc, List<sked_Drive_Shift__c> shifts) {
        try {
            Set<Id> coIds = collectExistingCollectionOperationIds(shifts);
            if (coIds.isEmpty()) {
                return;
            }

            Map<Id, List<Collection_Operation_Time_Block__c>> coToCotbs = new Map<Id, List<Collection_Operation_Time_Block__c>>();
            Map<Id, Time_Block__c> tbById = new Map<Id, Time_Block__c>();
            loadCollectionOperationTimeBlocks(coIds, coToCotbs, tbById);

            List<sked_Drive_Shift__c> updates = buildUpdates(shifts, coToCotbs, tbById);
            saveUpdates(updates);
        } catch (Exception ex) {
            totalErrors++;
            BSF_Error_Log__c log = BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'BSF_Batch_DriveShiftTimeBlockAssignment',
                'Execute',
                'Drive Shift Time Block Assignment',
                'Bulk Time Block/Contention Assignment',
                'sked_Drive_Shift__c',
                null
            );
            Database.insert(new List<BSF_Error_Log__c>{ log }, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('BSF_Batch_DriveShiftTimeBlockAssignment complete. Updated: ' + totalUpdated + ', Errors: ' + totalErrors);
    }

    private Set<Id> collectExistingCollectionOperationIds(List<sked_Drive_Shift__c> shifts) {
        Set<Id> coIds = new Set<Id>();
        for (sked_Drive_Shift__c s : shifts) {
            if (s.sked_Drive__r != null && s.sked_Drive__r.sked_Collection_Operation__c != null) {
                coIds.add(s.sked_Drive__r.sked_Collection_Operation__c);
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

    private List<sked_Drive_Shift__c> buildUpdates(
        List<sked_Drive_Shift__c> shifts,
        Map<Id, List<Collection_Operation_Time_Block__c>> coToCotbs,
        Map<Id, Time_Block__c> tbById
    ) {
        List<sked_Drive_Shift__c> updates = new List<sked_Drive_Shift__c>();

        for (sked_Drive_Shift__c s : shifts) {
            if (s.sked_Contention_Resolution__c != null && s.sked_Time_Block__c != null) {
                continue;
            }

            Date driveDate = (s.sked_Drive__r != null) ? s.sked_Drive__r.sked_Drive_Date__c : null;
            Id coId = (s.sked_Drive__r != null) ? s.sked_Drive__r.sked_Collection_Operation__c : null;
            String dow = (s.sked_Drive__r != null) ? s.sked_Drive__r.sked_Day_of_Week__c : null;
            if (driveDate == null || coId == null || String.isBlank(dow)) {
                continue;
            }

            List<Collection_Operation_Time_Block__c> cotbs = coToCotbs.containsKey(coId)
                ? coToCotbs.get(coId)
                : new List<Collection_Operation_Time_Block__c>();

            TimeBlockMatch match = evaluateTimeBlockMatch(s, driveDate, dow, cotbs, tbById);
            if (match == null) {
                continue;
            }

            if (match.timeBlockId == s.sked_Time_Block__c && match.contentionCode == s.sked_Contention__c) {
                continue;
            }
            if (s.sked_Time_Block__c == null && s.sked_Contention__c != null) {
                continue;
            }

            updates.add(new sked_Drive_Shift__c(
                Id = s.Id,
                sked_Time_Block__c = match.timeBlockId,
                sked_Contention__c = match.contentionCode
            ));
        }

        return updates;
    }

    private TimeBlockMatch evaluateTimeBlockMatch(
        sked_Drive_Shift__c s,
        Date driveDate,
        String dow,
        List<Collection_Operation_Time_Block__c> cotbs,
        Map<Id, Time_Block__c> tbById
    ) {
        List<Id> fitTBs = new List<Id>();
        Integer applicableCount = 0;
        Id singleApplicableTbId = null;

        for (Collection_Operation_Time_Block__c cotb : cotbs) {
            Time_Block__c tb = tbById.get(cotb.Time_Block__c);
            if (tb == null) {
                continue;
            }

            Boolean dateOk = (cotb.Effective_Start_Date__c == null || driveDate >= cotb.Effective_Start_Date__c)
                          && (cotb.Effective_End_Date__c == null || driveDate <= cotb.Effective_End_Date__c);
            Boolean dayOk = String.isNotBlank(tb.Days_of_Week__c) && tb.Days_of_Week__c.contains(dow);

            if (!dateOk || !dayOk) {
                continue;
            }

            applicableCount++;
            if (singleApplicableTbId == null) {
                singleApplicableTbId = tb.Id;
            }

            if (shiftFitsWithinTimeBlock(s, tb)) {
                fitTBs.add(tb.Id);
            }
        }

        if (fitTBs.size() > 1) {
            return new TimeBlockMatch(null, skedConstants.CONTENTION_CODE_FITS_MULTIPLE_TIME_BLOCKS);
        }
        if (fitTBs.size() == 1) {
            return new TimeBlockMatch(fitTBs[0], null);
        }
        if (applicableCount == 0) {
            return null;
        }
        if (applicableCount == 1) {
            return new TimeBlockMatch(singleApplicableTbId, skedConstants.CONTENTION_CODE_OUT_OF_TIME_BLOCK);
        }
        return new TimeBlockMatch(null, skedConstants.CONTENTION_CODE_MISSING_TIME_BLOCK);
    }

    private Boolean shiftFitsWithinTimeBlock(sked_Drive_Shift__c s, Time_Block__c tb) {
        return tb.Start_Time__c != null && tb.End_Time__c != null
            && s.sked_Start_Time__c != null && s.sked_End_Time__c != null
            && tb.Start_Time__c <= s.sked_Start_Time__c
            && tb.End_Time__c >= s.sked_End_Time__c;
    }

    private void saveUpdates(List<sked_Drive_Shift__c> updates) {
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
                'Drive Shift Time Block Assignment',
                'BSF_Batch_DriveShiftTimeBlockAssignment',
                'Execute',
                'Error',
                'Bulk Time Block/Contention Assignment'
            );
            if (!errorLogs.isEmpty()) {
                Database.insert(errorLogs, false);
            }
        }
    }

    private class TimeBlockMatch {
        private Id timeBlockId;
        private String contentionCode;

        private TimeBlockMatch(Id timeBlockId, String contentionCode) {
            this.timeBlockId = timeBlockId;
            this.contentionCode = contentionCode;
        }
    }
}
