/**
 * Guards the SDM mapping timeline on a Collection Operation and raises Drive Change Requests when a
 * new mapping is added.
 *
 * Mappings are maintained through the OOTB Collection Operation SDM related list, which has no way
 * to close the current row and open its successor as one operation. This handler supplies the
 * missing invariant: for a given Collection Operation and drive type, the effective windows must be
 * contiguous and must not overlap.
 */
public class skedCollectionOperationSDMHandler extends skedTriggerHub {

    private static final String ERROR_OVERLAP = 'This SDM mapping overlaps an existing mapping for the same Collection Operation and drive type. Close the current mapping first, then start the new one the day after it ends.';
    private static final String ERROR_GAP = 'This SDM mapping leaves a gap after the previous mapping for the same Collection Operation and drive type. It must start the day after the previous mapping ends.';

    public override void onBeforeInsert() {
        validateEffectiveWindows((List<sked_Collection_Operation_SDM__c>) this.context.newRecords);
    }

    public override void onBeforeUpdate() {
        validateEffectiveWindows((List<sked_Collection_Operation_SDM__c>) this.context.newRecords);
    }

    /**
     * Deliberately no onAfterUpdate counterpart: closing the current mapping's end date is the first
     * half of the two-step remap, and the drives it affects are picked up by the insert that follows.
     */
    public override void onAfterInsert() {
        if (skedSetting.instance.Admin.migrationMode) {
            return;
        }
        // Database.executeBatch is illegal from batch/future context, so a migration or integration
        // job writing junction rows simply does not fan out.
        if (System.isBatch() || System.isFuture()) {
            return;
        }
        enqueueDcrFanOut((List<sked_Collection_Operation_SDM__c>) this.context.newRecords);
    }

    private void enqueueDcrFanOut(List<sked_Collection_Operation_SDM__c> records) {
        Set<Id> junctionIds = new Set<Id>();
        for (sked_Collection_Operation_SDM__c record : records) {
            junctionIds.add(record.Id);
        }

        // Re-queried because the batch matches drives on the SDM's record type, which a trigger
        // record cannot carry.
        List<sked_Collection_Operation_SDM__c> junctions = [
            SELECT Id, sked_Collection_Operation__c, sked_Effective_Start_Date__c,
                   sked_Effective_End_Date__c, sked_Staffing_Decision_Matrix__r.RecordType.Name
            FROM sked_Collection_Operation_SDM__c
            WHERE Id IN :junctionIds
        ];

        if (!junctions.isEmpty()) {
            Database.executeBatch(new skedCreateDCRForSDMChangeBatch(junctions), 200);
        }
    }

    private void validateEffectiveWindows(List<sked_Collection_Operation_SDM__c> records) {
        Map<Id, String> driveTypeBySdmId = getDriveTypeBySdmId(records);

        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Id> recordIdsBeingSaved = new Set<Id>();
        for (sked_Collection_Operation_SDM__c record : records) {
            collectionOperationIds.add(record.sked_Collection_Operation__c);
            if (record.Id != null) {
                recordIdsBeingSaved.add(record.Id);
            }
        }

        Map<String, List<TimelineWindow>> windowsByTimeline = new Map<String, List<TimelineWindow>>();

        for (sked_Collection_Operation_SDM__c sibling : [
            SELECT Id, sked_Collection_Operation__c, sked_Effective_Start_Date__c,
                   sked_Effective_End_Date__c, sked_Staffing_Decision_Matrix__r.RecordType.Name
            FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c IN :collectionOperationIds
        ]) {
            // The in-transaction version of an updated row supersedes what is still in the database.
            if (recordIdsBeingSaved.contains(sibling.Id)) {
                continue;
            }
            addWindow(windowsByTimeline, sibling.sked_Collection_Operation__c,
                sibling.sked_Staffing_Decision_Matrix__r.RecordType.Name,
                sibling.sked_Effective_Start_Date__c, sibling.sked_Effective_End_Date__c, null);
        }

        for (sked_Collection_Operation_SDM__c record : records) {
            addWindow(windowsByTimeline, record.sked_Collection_Operation__c,
                driveTypeBySdmId.get(record.sked_Staffing_Decision_Matrix__c),
                record.sked_Effective_Start_Date__c, record.sked_Effective_End_Date__c, record);
        }

        for (List<TimelineWindow> windows : windowsByTimeline.values()) {
            validateTimeline(windows);
        }
    }

    private Map<Id, String> getDriveTypeBySdmId(List<sked_Collection_Operation_SDM__c> records) {
        Set<Id> staffingDecisionMatrixIds = new Set<Id>();
        for (sked_Collection_Operation_SDM__c record : records) {
            staffingDecisionMatrixIds.add(record.sked_Staffing_Decision_Matrix__c);
        }

        Map<Id, String> driveTypeBySdmId = new Map<Id, String>();
        for (sked_Staffing_Decision_Matrix__c matrix : [
            SELECT Id, RecordType.Name
            FROM sked_Staffing_Decision_Matrix__c
            WHERE Id IN :staffingDecisionMatrixIds
        ]) {
            driveTypeBySdmId.put(matrix.Id, matrix.RecordType.Name);
        }
        return driveTypeBySdmId;
    }

    /**
     * A row with no start date cannot be positioned on the timeline, so it is left out of the
     * comparison entirely rather than guessed at.
     */
    private void addWindow(Map<String, List<TimelineWindow>> windowsByTimeline, Id collectionOperationId,
            String driveType, Date startDate, Date endDate, sked_Collection_Operation_SDM__c record) {
        if (startDate == null || String.isBlank(driveType)) {
            return;
        }

        String timelineKey = collectionOperationId + '|' + driveType;
        if (!windowsByTimeline.containsKey(timelineKey)) {
            windowsByTimeline.put(timelineKey, new List<TimelineWindow>());
        }
        windowsByTimeline.get(timelineKey).add(new TimelineWindow(startDate, endDate, record));
    }

    /**
     * Sorting by start date means any overlap or gap shows up between two neighbours, so only
     * adjacent pairs need checking rather than every combination.
     */
    private void validateTimeline(List<TimelineWindow> windows) {
        if (windows.size() < 2) {
            return;
        }

        windows.sort();
        for (Integer i = 0; i < windows.size() - 1; i++) {
            TimelineWindow earlier = windows.get(i);
            TimelineWindow later = windows.get(i + 1);

            if (earlier.endDate == null || later.startDate <= earlier.endDate) {
                addPairError(earlier, later, ERROR_OVERLAP);
            } else if (later.startDate != earlier.endDate.addDays(1)) {
                addPairError(earlier, later, ERROR_GAP);
            }
        }
    }

    /**
     * Only a record taking part in this save is blocked. Two pre-existing rows that already conflict
     * are somebody else's data problem and must not fail an unrelated edit.
     */
    private void addPairError(TimelineWindow earlier, TimelineWindow later, String message) {
        if (later.record != null) {
            later.record.addError(message);
        } else if (earlier.record != null) {
            earlier.record.addError(message);
        }
    }

    private class TimelineWindow implements Comparable {
        private Date startDate;
        private Date endDate;
        private sked_Collection_Operation_SDM__c record;

        private TimelineWindow(Date startDate, Date endDate, sked_Collection_Operation_SDM__c record) {
            this.startDate = startDate;
            this.endDate = endDate;
            this.record = record;
        }

        public Integer compareTo(Object other) {
            TimelineWindow otherWindow = (TimelineWindow) other;
            if (this.startDate == otherWindow.startDate) {
                return 0;
            }
            return this.startDate < otherWindow.startDate ? -1 : 1;
        }
    }
}