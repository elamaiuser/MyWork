global with sharing class BSF_Batch_TBStaffingConstraintRollout implements Database.Batchable<sObject>, Database.Stateful {

    global Date startDate;
    global Date endDate;
    global Set<Id> collectionOperationIds;
    global Integer totalScannedKeys = 0;
    global Integer totalPrepared = 0;
    global Integer totalInserted = 0;
    global Integer totalSkippedExisting = 0;
    global Integer totalSkippedNoMatch = 0;

    global BSF_Batch_TBStaffingConstraintRollout() {
        this(Date.today(), Date.today().addYears(1));
    }

    global BSF_Batch_TBStaffingConstraintRollout(Date startDate, Date endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }

    global BSF_Batch_TBStaffingConstraintRollout(Set<Id> collectionOperationIds) {
        this(Date.today(), Date.today().addYears(1), collectionOperationIds);
    }

    global BSF_Batch_TBStaffingConstraintRollout(Date startDate, Date endDate, Set<Id> collectionOperationIds) {
        this.startDate = startDate;
        this.endDate = endDate;
        this.collectionOperationIds = collectionOperationIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (collectionOperationIds == null || collectionOperationIds.isEmpty()) {
            collectionOperationIds = getEligibleCollectionOperationIds();
        }
        Set<Id> includedCoIds = collectionOperationIds;
        String mobileType = skedConstants.DRIVE_TYPE_MOBILE;
        Date rangeStart = startDate;
        Date rangeEnd = endDate;

        return Database.getQueryLocator([
            SELECT Id, sked_Collection_Operation__c, sked_Date_of_Constraint__c,
                   sked_Time_Block__c, sked_Drive_Type__c, sked_Total_Staff_Constraints__c
            FROM sked_Staffing_Constraint__c
            WHERE sked_Drive_Type__c = :mobileType
            AND sked_Time_Block__c = NULL
            AND sked_Collection_Operation__c IN :includedCoIds
            AND sked_Date_of_Constraint__c >= :rangeStart
            AND sked_Date_of_Constraint__c <= :rangeEnd
        ]);
    }

    private Set<Id> getEligibleCollectionOperationIds() {
        Set<Id> eligibleCoIds = new Set<Id>();
        for (Biomed_Collection_Op_Center__c co : [
            SELECT Id, sked_Is_Deactivated__c, External_Id__c, Name
            FROM Biomed_Collection_Op_Center__c
            WHERE sked_Is_Deactivated__c = false
            AND External_Id__c != NULL
            AND Name != :skedConstants.NON_COLLECTION_AREA_CO
        ]) {
            eligibleCoIds.add(co.Id);
        }
        return eligibleCoIds;
    }

    global void execute(Database.BatchableContext bc, List<sked_Staffing_Constraint__c> scope) {
        try {
            Map<String, sked_Staffing_Constraint__c> templateByCoDate = dedupeByCollectionOperationAndDate(scope);
            totalScannedKeys += templateByCoDate.size();
            if (templateByCoDate.isEmpty()) {
                return;
            }

            Set<Id> coIds = new Set<Id>();
            Set<Date> dates = new Set<Date>();
            for (sked_Staffing_Constraint__c template : templateByCoDate.values()) {
                coIds.add(template.sked_Collection_Operation__c);
                dates.add(template.sked_Date_of_Constraint__c);
            }

            Map<Id, List<Id>> coToTimeBlockIds = new Map<Id, List<Id>>();
            Map<Id, Set<String>> timeBlockToDays = new Map<Id, Set<String>>();
            loadCollectionOperationTimeBlocks(coIds, coToTimeBlockIds, timeBlockToDays);

            Set<String> alreadyConvertedKeys = loadAlreadyConvertedKeys(coIds, dates);

            List<sked_Staffing_Constraint__c> newConstraints = new List<sked_Staffing_Constraint__c>();

            for (String key : templateByCoDate.keySet()) {
                if (alreadyConvertedKeys.contains(key)) {
                    totalSkippedExisting++;
                    continue;
                }

                sked_Staffing_Constraint__c template = templateByCoDate.get(key);
                Id matchedTimeBlockId = findMatchingTimeBlock(
                    template.sked_Collection_Operation__c,
                    template.sked_Date_of_Constraint__c,
                    coToTimeBlockIds,
                    timeBlockToDays
                );

                if (matchedTimeBlockId == null) {
                    totalSkippedNoMatch++;
                    continue;
                }

                sked_Staffing_Constraint__c newConstraint = template.clone(false, true, false, true);
                newConstraint.sked_Time_Block__c = matchedTimeBlockId;
                newConstraints.add(newConstraint);
            }

            totalPrepared += newConstraints.size();
            saveNewConstraints(newConstraints);
        } catch (Exception ex) {
            BSF_Error_Log__c log = BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'BSF_Batch_TBStaffingConstraintRollout',
                'Execute',
                'TB Staffing Constraint Rollout',
                'Clone Operation Hours Staffing Constraints with Time Block',
                'sked_Staffing_Constraint__c',
                null
            );
            Database.insert(new List<BSF_Error_Log__c>{ log }, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(
            'BSF_Batch_TBStaffingConstraintRollout complete. ScannedKeys: ' + totalScannedKeys +
            ', Prepared: ' + totalPrepared +
            ', Inserted: ' + totalInserted +
            ', SkippedExisting: ' + totalSkippedExisting +
            ', SkippedNoMatch: ' + totalSkippedNoMatch
        );
    }

    private Map<String, sked_Staffing_Constraint__c> dedupeByCollectionOperationAndDate(List<sked_Staffing_Constraint__c> scope) {
        Map<String, sked_Staffing_Constraint__c> templateByCoDate = new Map<String, sked_Staffing_Constraint__c>();
        for (sked_Staffing_Constraint__c sc : scope) {
            if (sc.sked_Collection_Operation__c == null || sc.sked_Date_of_Constraint__c == null) {
                continue;
            }
            String key = buildKey(sc.sked_Collection_Operation__c, sc.sked_Date_of_Constraint__c);
            if (!templateByCoDate.containsKey(key)) {
                templateByCoDate.put(key, sc);
            }
        }
        return templateByCoDate;
    }

    private void loadCollectionOperationTimeBlocks(
        Set<Id> coIds,
        Map<Id, List<Id>> coToTimeBlockIds,
        Map<Id, Set<String>> timeBlockToDays
    ) {
        Set<Id> timeBlockIds = new Set<Id>();

        for (Collection_Operation_Time_Block__c cotb : [
            SELECT Collection_Operation__c, Time_Block__c
            FROM Collection_Operation_Time_Block__c
            WHERE Collection_Operation__c IN :coIds
        ]) {
            if (cotb.Collection_Operation__c == null || cotb.Time_Block__c == null) {
                continue;
            }
            if (!coToTimeBlockIds.containsKey(cotb.Collection_Operation__c)) {
                coToTimeBlockIds.put(cotb.Collection_Operation__c, new List<Id>());
            }
            coToTimeBlockIds.get(cotb.Collection_Operation__c).add(cotb.Time_Block__c);
            timeBlockIds.add(cotb.Time_Block__c);
        }

        if (timeBlockIds.isEmpty()) {
            return;
        }

        for (Time_Block__c tb : [SELECT Id, Days_of_Week__c FROM Time_Block__c WHERE Id IN :timeBlockIds]) {
            Set<String> days = new Set<String>();
            if (String.isNotBlank(tb.Days_of_Week__c)) {
                for (String day : tb.Days_of_Week__c.split(';')) {
                    days.add(day.trim());
                }
            }
            timeBlockToDays.put(tb.Id, days);
        }
    }

    private Set<String> loadAlreadyConvertedKeys(Set<Id> coIds, Set<Date> dates) {
        Set<String> keys = new Set<String>();
        String mobileType = skedConstants.DRIVE_TYPE_MOBILE;

        for (AggregateResult ar : [
            SELECT sked_Collection_Operation__c coId, sked_Date_of_Constraint__c dt
            FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c IN :coIds
            AND sked_Date_of_Constraint__c IN :dates
            AND sked_Drive_Type__c = :mobileType
            AND sked_Time_Block__c != NULL
            GROUP BY sked_Collection_Operation__c, sked_Date_of_Constraint__c
        ]) {
            keys.add(buildKey((Id) ar.get('coId'), (Date) ar.get('dt')));
        }

        return keys;
    }

    private Id findMatchingTimeBlock(
        Id coId,
        Date constraintDate,
        Map<Id, List<Id>> coToTimeBlockIds,
        Map<Id, Set<String>> timeBlockToDays
    ) {
        List<Id> timeBlockIds = coToTimeBlockIds.get(coId);
        if (timeBlockIds == null) {
            return null;
        }

        String dayName = Datetime.newInstance(constraintDate, Time.newInstance(0, 0, 0, 0)).format('EEEE');

        for (Id tbId : timeBlockIds) {
            Set<String> days = timeBlockToDays.get(tbId);
            if (days != null && days.contains(dayName)) {
                return tbId;
            }
        }

        return null;
    }

    private void saveNewConstraints(List<sked_Staffing_Constraint__c> newConstraints) {
        if (newConstraints.isEmpty()) {
            return;
        }

        Database.SaveResult[] results = Database.insert(newConstraints, false);
        Integer batchErrors = 0;
        for (Database.SaveResult r : results) {
            if (r.isSuccess()) {
                totalInserted++;
            } else {
                batchErrors++;
            }
        }

        if (batchErrors > 0) {
            List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLogWithObjectId(
                results,
                'TB Staffing Constraint Rollout',
                'BSF_Batch_TBStaffingConstraintRollout',
                'Execute',
                'Error',
                'Clone Operation Hours Staffing Constraints with Time Block'
            );
            if (!errorLogs.isEmpty()) {
                Database.insert(errorLogs, false);
            }
        }
    }

    private String buildKey(Id coId, Date constraintDate) {
        return coId + '|' + constraintDate;
    }
}
