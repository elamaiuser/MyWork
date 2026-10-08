/**
 * Diffs the regenerated context against its loaded snapshot to compute net DML writes.
 * Deletions bottom-up, then inserts/updates top-down, stamping parent Ids onto new children
 * as they're inserted. A brand-new shift's jobs/slots (ctx.jobsByNewShiftIndex/slotsByNewShiftIndex -
 * kept out of the Id-keyed maps by the engine, since the shift itself has no Id yet) are stamped
 * with the shift's real Id right here, after the shift upsert and before the job/slot upsert.
 */
public class skedDriveGraphSaver {
    // Master fields (never updated once a record has an Id - business rule, not schema
    // read-only; these ARE technically writable, the app just never re-points them).
    @TestVisible private static final Set<String> DRIVE_MASTER_FIELDS = new Set<String>{ 'sked_Opportunity__c' };
    @TestVisible private static final Set<String> JOB_ALLOCATION_MASTER_FIELDS = new Set<String>{ 'sked__Job__c', 'sked__Resource__c' };

    public static void save(skedDriveRegenContext ctx) {
        List<sked__Job__c> allJobs = new List<sked__Job__c>();
        allJobs.addAll(ctx.driveLevelJobs);
        for (List<sked__Job__c> shiftJobs : ctx.jobsByShiftId.values()) {
            allJobs.addAll(shiftJobs);
        }
        List<sked__Job__c> allSnapshotJobs = new List<sked__Job__c>();
        allSnapshotJobs.addAll(ctx.snapshot.driveLevelJobs);
        for (List<sked__Job__c> shiftJobs : ctx.snapshot.jobsByShiftId.values()) {
            allSnapshotJobs.addAll(shiftJobs);
        }

        deleteRemovedRecords(ctx, allJobs, allSnapshotJobs);

        upsertOne(ctx.drive, findSnapshotById(new List<sked_Drive__c>{ ctx.snapshot.drive }, ctx.drive.Id), DRIVE_MASTER_FIELDS);

        upsertLevel(ctx.driveShifts, ctx.snapshot.driveShifts, new Set<String>(), 'sked_Drive__c', ctx.drive.Id);

        // A brand-new shift only gets a real Id from the upsert above - its jobs/slots couldn't be
        // keyed into jobsByShiftId/slotsByShiftId (which need a real Id) until now.
        allJobs.addAll(stampNewShiftJobs(ctx));

        List<sked_Drive_Shift_Tag__c> newShiftTags = stampNewShiftTags(ctx);
        if (!newShiftTags.isEmpty()) {
            insert newShiftTags;
        }
        // Unlike stampNewShiftJobs/stampNewShiftSlots, these are freshly-constructed Id-less
        // sObjects on every call, not the same record reference reused across saves - so they
        // aren't self-healing against a second save() on the same ctx. Clearing after insert
        // prevents a duplicate-insert if save() is ever called twice.
        ctx.tagsByNewShiftIndex.clear();

        upsertLevel(allJobs, allSnapshotJobs, new Set<String>(), null, null);

        List<sked__Job_Allocation__c> allAllocations = new List<sked__Job_Allocation__c>();
        for (List<sked__Job_Allocation__c> jobAllocations : ctx.allocationsByJobId.values()) {
            allAllocations.addAll(jobAllocations);
        }
        List<sked__Job_Allocation__c> allSnapshotAllocations = new List<sked__Job_Allocation__c>();
        for (List<sked__Job_Allocation__c> jobAllocations : ctx.snapshot.allocationsByJobId.values()) {
            allSnapshotAllocations.addAll(jobAllocations);
        }
        upsertLevel(allAllocations, allSnapshotAllocations, JOB_ALLOCATION_MASTER_FIELDS, null, null);

        List<sked__Slot__c> allSlots = new List<sked__Slot__c>();
        for (List<sked__Slot__c> shiftSlots : ctx.slotsByShiftId.values()) {
            allSlots.addAll(shiftSlots);
        }
        allSlots.addAll(stampNewShiftSlots(ctx));
        List<sked__Slot__c> allSnapshotSlots = new List<sked__Slot__c>();
        for (List<sked__Slot__c> shiftSlots : ctx.snapshot.slotsByShiftId.values()) {
            allSnapshotSlots.addAll(shiftSlots);
        }
        upsertLevel(allSlots, allSnapshotSlots, new Set<String>(), null, null);

        upsertLevel(ctx.driveDeliveryJobs, ctx.snapshot.driveDeliveryJobs, new Set<String>(), 'sked_Drive__c', ctx.drive.Id);
    }

    // ctx.jobsByNewShiftIndex is empty for every engine that never proposes a new shift - a no-op.
    private static List<sked__Job__c> stampNewShiftJobs(skedDriveRegenContext ctx) {
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        for (Integer shiftIndex : ctx.jobsByNewShiftIndex.keySet()) {
            Id shiftId = ctx.driveShifts[shiftIndex].Id;
            for (sked__Job__c job : ctx.jobsByNewShiftIndex.get(shiftIndex)) {
                job.sked_Drive_Shift__c = shiftId;
                jobs.add(job);
            }
        }
        return jobs;
    }

    private static List<sked__Slot__c> stampNewShiftSlots(skedDriveRegenContext ctx) {
        List<sked__Slot__c> slots = new List<sked__Slot__c>();
        for (Integer shiftIndex : ctx.slotsByNewShiftIndex.keySet()) {
            Id shiftId = ctx.driveShifts[shiftIndex].Id;
            for (sked__Slot__c slot : ctx.slotsByNewShiftIndex.get(shiftIndex)) {
                slot.sked_Drive_Shift__c = shiftId;
                slots.add(slot);
            }
        }
        return slots;
    }

    // Unlike stampNewShiftJobs/stampNewShiftSlots, these are insert-only, never diffed against a
    // snapshot - sked_Drive_Shift_Tag__c's two master fields (sked_Drive_Shift__c, sked_Tag__c)
    // are both non-reparentable, and an existing shift's tags are never refreshed on regen
    // (confirmed: the legacy interactive path only ever inserts them once too, at creation).
    private static List<sked_Drive_Shift_Tag__c> stampNewShiftTags(skedDriveRegenContext ctx) {
        List<sked_Drive_Shift_Tag__c> tags = new List<sked_Drive_Shift_Tag__c>();
        for (Integer shiftIndex : ctx.tagsByNewShiftIndex.keySet()) {
            Id shiftId = ctx.driveShifts[shiftIndex].Id;
            for (skedDriveShiftTagCalculator.TagResult tagResult : ctx.tagsByNewShiftIndex.get(shiftIndex)) {
                tags.add(new sked_Drive_Shift_Tag__c(
                    sked_Drive_Shift__c = shiftId,
                    sked_Tag__c = tagResult.tagId,
                    sked_Minimum_Quantity__c = tagResult.minimumQuantity
                ));
            }
        }
        return tags;
    }

    /**
     * Anything present in the snapshot but absent from the current context is deleted.
     * Deepest children first: slots -> delivery jobs -> jobs -> shifts. Job Allocation is a
     * MasterDetail child of Job, so deleting a removed job cascades to delete its allocations
     * too - no separate allocation-deletion step needed.
     */
    private static void deleteRemovedRecords(skedDriveRegenContext ctx, List<sked__Job__c> currentJobs, List<sked__Job__c> snapshotJobs) {
        Set<Id> currentJobIds = new Set<Id>();
        for (sked__Job__c job : currentJobs) {
            if (job.Id != null) {
                currentJobIds.add(job.Id);
            }
        }
        List<sked__Job__c> jobsToDelete = new List<sked__Job__c>();
        for (sked__Job__c job : snapshotJobs) {
            if (!currentJobIds.contains(job.Id)) {
                jobsToDelete.add(new sked__Job__c(Id = job.Id));
            }
        }
        if (!jobsToDelete.isEmpty()) {
            delete jobsToDelete;
        }

        Set<Id> currentSlotIds = new Set<Id>();
        for (List<sked__Slot__c> slots : ctx.slotsByShiftId.values()) {
            for (sked__Slot__c slot : slots) {
                if (slot.Id != null) {
                    currentSlotIds.add(slot.Id);
                }
            }
        }
        List<sked__Slot__c> slotsToDelete = new List<sked__Slot__c>();
        for (List<sked__Slot__c> snapshotSlots : ctx.snapshot.slotsByShiftId.values()) {
            for (sked__Slot__c slot : snapshotSlots) {
                if (!currentSlotIds.contains(slot.Id)) {
                    slotsToDelete.add(new sked__Slot__c(Id = slot.Id));
                }
            }
        }
        if (!slotsToDelete.isEmpty()) {
            delete slotsToDelete;
        }

        Set<Id> currentDeliveryJobIds = new Set<Id>();
        for (sked_Drive_Delivery_Job__c deliveryJob : ctx.driveDeliveryJobs) {
            if (deliveryJob.Id != null) {
                currentDeliveryJobIds.add(deliveryJob.Id);
            }
        }
        List<sked_Drive_Delivery_Job__c> deliveryJobsToDelete = new List<sked_Drive_Delivery_Job__c>();
        for (sked_Drive_Delivery_Job__c deliveryJob : ctx.snapshot.driveDeliveryJobs) {
            if (!currentDeliveryJobIds.contains(deliveryJob.Id)) {
                deliveryJobsToDelete.add(new sked_Drive_Delivery_Job__c(Id = deliveryJob.Id));
            }
        }
        if (!deliveryJobsToDelete.isEmpty()) {
            delete deliveryJobsToDelete;
        }

        Set<Id> currentShiftIds = new Set<Id>();
        for (sked_Drive_Shift__c shift : ctx.driveShifts) {
            if (shift.Id != null) {
                currentShiftIds.add(shift.Id);
            }
        }
        List<sked_Drive_Shift__c> shiftsToDelete = new List<sked_Drive_Shift__c>();
        for (sked_Drive_Shift__c shift : ctx.snapshot.driveShifts) {
            if (!currentShiftIds.contains(shift.Id)) {
                shiftsToDelete.add(new sked_Drive_Shift__c(Id = shift.Id));
            }
        }
        if (!shiftsToDelete.isEmpty()) {
            delete shiftsToDelete;
        }
    }

    /**
     * One layer: insert new (Id == null) records after stamping the parent Id (if any),
     * update only records that actually changed vs the snapshot, skip unchanged records
     * entirely (no DML).
     */
    private static void upsertLevel(List<sObject> current, List<sObject> snapshotRecords,
            Set<String> excludedFields, String parentField, Id parentId) {
        Map<Id, sObject> snapshotById = new Map<Id, sObject>();
        for (sObject record : snapshotRecords) {
            if (record.Id != null) {
                snapshotById.put(record.Id, record);
            }
        }

        List<sObject> toInsert = new List<sObject>();
        List<sObject> toUpdate = new List<sObject>();
        for (sObject record : current) {
            if (record.Id == null) {
                if (parentField != null && parentId != null) {
                    record.put(parentField, parentId);
                }
                toInsert.add(record);
            } else if (isChanged(record, snapshotById.get(record.Id), excludedFields)) {
                toUpdate.add(stripFields(record, excludedFields));
            }
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void upsertOne(sObject current, sObject snapshotRecord, Set<String> excludedFields) {
        if (current.Id == null) {
            insert current;
        } else if (isChanged(current, snapshotRecord, excludedFields)) {
            update stripFields(current, excludedFields);
        }
    }

    private static sObject findSnapshotById(List<sObject> snapshotRecords, Id recordId) {
        for (sObject record : snapshotRecords) {
            if (record.Id == recordId) {
                return record;
            }
        }
        return null;
    }

    @TestVisible
    private static Boolean isChanged(sObject current, sObject snapshotRecord, Set<String> excludedFields) {
        if (snapshotRecord == null) {
            return true;
        }
        Map<String, Object> currentFields = current.getPopulatedFieldsAsMap();
        for (String fieldName : currentFields.keySet()) {
            if (fieldName == 'Id' || excludedFields.contains(fieldName)
                    || !isUpdateableField(current.getSObjectType(), fieldName)) {
                continue;
            }
            if (snapshotRecord.get(fieldName) != currentFields.get(fieldName)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Builds a fresh sObject carrying only Id + writable, non-excluded populated fields, so
     * master fields and schema-readonly fields (formula/rollup/system) are never included in
     * the update DML at all (and therefore never touched in the database) - as opposed to
     * setting them to null, which would wipe them.
     */
    private static sObject stripFields(sObject record, Set<String> excludedFields) {
        sObject stripped = record.getSObjectType().newSObject(record.Id);
        Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
        for (String fieldName : populatedFields.keySet()) {
            if (fieldName != 'Id' && !excludedFields.contains(fieldName)
                    && isUpdateableField(record.getSObjectType(), fieldName)) {
                stripped.put(fieldName, populatedFields.get(fieldName));
            }
        }
        return stripped;
    }

    // Object.Field -> isUpdateable, so repeated saves across many records of the same type
    // don't re-describe the same field over and over.
    private static final Map<String, Boolean> updateableFieldCache = new Map<String, Boolean>();

    /**
     * Whether a field can be written via DML at all (false for formula/rollup/system
     * fields). Checked dynamically against the live schema rather than a hand-maintained
     * list, so this can't silently drift out of sync as fields are added to an object.
     */
    @TestVisible
    private static Boolean isUpdateableField(Schema.SObjectType objType, String fieldName) {
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        String cacheKey = objDescribe.getName() + '.' + fieldName;
        if (!updateableFieldCache.containsKey(cacheKey)) {
            Schema.SObjectField field = objDescribe.fields.getMap().get(fieldName);
            updateableFieldCache.put(cacheKey, field != null && field.getDescribe().isUpdateable());
        }
        return updateableFieldCache.get(cacheKey);
    }
}
