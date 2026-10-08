/**
 * Carries an existing job's non-deleted allocations forward onto its regenerated counterpart
 * (matched via skedMobileDriveJobBuilder.applyExistingRecordIds - only jobs that already have a real
 * Id have anything to carry forward), realigning each allocation's start/end/duration to the
 * regenerated job's (possibly shifted) start/finish times.
 *
 * The travel-time check here is pure and callout-free - it only decides whether travel time applies,
 * using the allocation's own already-resolved travel-time fields (falling back to the job's own when
 * unset). It does not compute a fresh travel-time estimate - that requires a distance-matrix callout
 * that is not implemented in this pipeline.
 *
 * This class covers only the allocation piece: job tag merge-forward is handled separately by
 * skedMobileDriveJobBuilder (via skedMobileJobTagLoader), and preserving manually-created jobs across
 * regeneration (dual-role restore) is not implemented.
 */
public with sharing class skedMobileJobAllocationCarryForward {

    /**
     * Mutates each shift's jobAllocationsByJobId in place. Call after
     * skedMobileDriveJobBuilder.applyExistingRecordIds has already assigned real Ids to matched jobs.
     */
    public static void carryForwardJobAllocations(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed,
            sked_Drive__c drive, Biomed_Collection_Op_Center__c collectionOperation, String timezoneSidId) {
        List<Id> carriedForwardJobIds = new List<Id>();
        for (skedMobileDriveJobBuilder.ProposedDriveShift shift : proposed) {
            for (sked__Job__c job : shift.jobs) {
                if (job.Id != null) {
                    carriedForwardJobIds.add(job.Id);
                }
            }
        }
        if (carriedForwardJobIds.isEmpty()) {
            return;
        }

        Map<Id, List<sked__Job_Allocation__c>> existingAllocationsByJobId = skedMobileJobAllocationLoader.loadForJobs(carriedForwardJobIds);
        Map<String, String> groupByRole = skedMobileDriveJobBuilder.buildGroupByRoleLookup();

        for (skedMobileDriveJobBuilder.ProposedDriveShift shift : proposed) {
            for (sked__Job__c job : shift.jobs) {
                List<sked__Job_Allocation__c> existingAllocations = job.Id == null ? null : existingAllocationsByJobId.get(job.Id);
                if (existingAllocations == null || existingAllocations.isEmpty()) {
                    continue;
                }
                shift.jobAllocationsByJobId.put(job.Id, buildCarriedForwardAllocations(job, existingAllocations, drive, collectionOperation, groupByRole, timezoneSidId));
            }
        }
    }

    private static List<sked__Job_Allocation__c> buildCarriedForwardAllocations(sked__Job__c job, List<sked__Job_Allocation__c> existingAllocations,
            sked_Drive__c drive, Biomed_Collection_Op_Center__c collectionOperation, Map<String, String> groupByRole, String timezoneSidId) {
        List<sked__Job_Allocation__c> result = new List<sked__Job_Allocation__c>();
        Boolean isDrivingRoleJob = isDrivingRoleJob(job, groupByRole);

        for (sked__Job_Allocation__c existing : existingAllocations) {
            sked__Job_Allocation__c carried = new sked__Job_Allocation__c(
                Id = existing.Id,
                sked__Job__c = job.Id,
                sked__Resource__c = existing.sked__Resource__c
            );

            if (String.isBlank(job.sked_Resource_Role__c)) {
                // An asset job (no resourceRole) keeps the job's own start/finish outright, no travel-time adjustment.
                carried.sked__Start__c = job.sked__Start__c;
                carried.sked__Set_End__c = job.sked__Finish__c;
            } else {
                Boolean requiresTravelTime = isDrivingRoleJob
                    || (collectionOperation.sked_No_Travel_Time__c != true
                        && (drive.sked_Travel_Time_Included__c == 'All Roles' || existing.sked_Is_Relocated_Resource__c == true));

                Decimal travelTimeTo = existing.sked_Travel_Time_To__c != null ? existing.sked_Travel_Time_To__c : job.sked_Travel_Time__c;
                Decimal travelTimeBack = existing.sked_Travel_Time_Back__c != null ? existing.sked_Travel_Time_Back__c : job.sked_Travel_Time2__c;

                Decimal subtractMinutes = requiresTravelTime
                    ? (nullToZero(travelTimeTo) - nullToZero(job.sked_Travel_Time__c))
                    : nullToZero(travelTimeTo);
                Decimal addMinutes = requiresTravelTime
                    ? (nullToZero(travelTimeBack) - nullToZero(job.sked_Travel_Time2__c))
                    : nullToZero(travelTimeBack);

                carried.sked__Start__c = skedDateTimeUtils.addMinutes(job.sked__Start__c, -1 * subtractMinutes, timezoneSidId);
                carried.sked__Set_End__c = skedDateTimeUtils.addMinutes(job.sked__Finish__c, addMinutes, timezoneSidId);
            }

            carried.sked__Duration__c = (carried.sked__Set_End__c.getTime() - carried.sked__Start__c.getTime()) / (1000 * 60);

            result.add(carried);
        }
        return result;
    }

    private static Decimal nullToZero(Decimal value) {
        return value == null ? 0 : value;
    }

    // A role job's own role or its dual role belonging to the Driving Roles group is enough - the two
    // are never in conflicting groups in practice, since Driver/Driver Support are the only members.
    private static Boolean isDrivingRoleJob(sked__Job__c job, Map<String, String> groupByRole) {
        if (groupByRole.get(job.sked_Resource_Role__c) == skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES) {
            return true;
        }
        return String.isNotBlank(job.sked_Dual_Role__c) && groupByRole.get(job.sked_Dual_Role__c) == skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES;
    }
}
