public class skedDriveRegenContext {
    public sked_Drive__c drive;
    public List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
    public Map<Id, List<sked__Job__c>> jobsByShiftId = new Map<Id, List<sked__Job__c>>();
    public List<sked__Job__c> driveLevelJobs = new List<sked__Job__c>();
    public Map<Id, List<sked__Job_Allocation__c>> allocationsByJobId = new Map<Id, List<sked__Job_Allocation__c>>();
    public Map<Id, List<sked__Slot__c>> slotsByShiftId = new Map<Id, List<sked__Slot__c>>();
    // A brand-new shift (proposed by an engine, not yet inserted) has no real Id to key by -
    // keyed instead by the shift's index position in driveShifts, resolved to a real Id and
    // folded into jobsByShiftId/slotsByShiftId by skedDriveGraphSaver once the shift is inserted.
    public Map<Integer, List<sked__Job__c>> jobsByNewShiftIndex = new Map<Integer, List<sked__Job__c>>();
    public Map<Integer, List<sked__Slot__c>> slotsByNewShiftIndex = new Map<Integer, List<sked__Slot__c>>();
    public Map<Integer, List<skedDriveShiftTagCalculator.TagResult>> tagsByNewShiftIndex = new Map<Integer, List<skedDriveShiftTagCalculator.TagResult>>();
    public List<sked_Drive_Delivery_Job__c> driveDeliveryJobs = new List<sked_Drive_Delivery_Job__c>();
    public Set<String> appliedTokens = new Set<String>();
    public skedDriveRegenContext snapshot; // deep clone taken at load; diff basis for capture + save

    // Read-only reference/comparison data for the time-block + drive-limit family of contention
    // checks - never mutated by a regen engine, so loaded AFTER snapshot is taken (see
    // skedDriveRegenContextLoader) to avoid needlessly doubling it into the snapshot clone.
    public List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks = new List<Collection_Operation_Time_Block__c>();
    public List<sked_Operation_Drive_Limit__c> operationDriveLimits = new List<sked_Operation_Drive_Limit__c>();
    public List<sked_Drive__c> sameDateDrives = new List<sked_Drive__c>();
    public List<sked_Staffing_Constraint__c> staffingConstraints = new List<sked_Staffing_Constraint__c>();
    public List<sked__Activity__c> sameDateActivities = new List<sked__Activity__c>();

    public skedDriveRegenContext deepClone() {
        return (skedDriveRegenContext) JSON.deserialize(JSON.serialize(this), skedDriveRegenContext.class);
    }

    // sked_Total_Staff/Vehicle/Equipment_Requested__c on sked_Drive__c are Roll-Up Summary fields -
    // not writable, and never recalculated in-memory during a regen (see
    // skedMobileDriveRegenEngine.applyToContext's comment) - so a check needing the CURRENT
    // (post-regen) total must compute it fresh instead of reading the rollup. Ported from
    // baseGenerator.js's updateDriveRequestedResources (:577-605), which sums every non-staffing-
    // modal-manual job's quantity across ALL shifts - staff by resourceRole, vehicle/equipment by
    // assetType. This is a straight SUM on every branch (not the per-shift rollup fields' own MAX/
    // MAX for vehicle/equipment, which only describe the LAST-PERSISTED state, not this regen's
    // in-memory one), and staff carries no role-name exclusion (unlike applyShiftSetupRollups's
    // staffSetupExcludedRoleNames, a DIFFERENT filter that doesn't apply here).
    // Shared by skedMobileDriveRegenEngine.resetElectContentions and
    // skedDriveContentionValidator.checkPartOfLinkedDrive, which both need the identical values.
    public static Decimal sumStaffRequested(Map<Id, List<sked__Job__c>> jobsByShiftId) {
        Decimal total = 0;
        for (List<sked__Job__c> jobs : jobsByShiftId.values()) {
            for (sked__Job__c job : jobs) {
                if (isManuallyCreatedFromStaffingModal(job) || String.isBlank(job.sked_Resource_Role__c)) {
                    continue;
                }
                total += job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
            }
        }
        return total;
    }

    public static Decimal sumVehicleRequested(Map<Id, List<sked__Job__c>> jobsByShiftId) {
        return sumByAssetType(jobsByShiftId, skedConstants.ASSET_TYPE_VEHICLE);
    }

    public static Decimal sumEquipmentRequested(Map<Id, List<sked__Job__c>> jobsByShiftId) {
        return sumByAssetType(jobsByShiftId, skedConstants.ASSET_TYPE_EQUIPMENT);
    }

    private static Decimal sumByAssetType(Map<Id, List<sked__Job__c>> jobsByShiftId, String assetType) {
        Decimal total = 0;
        for (List<sked__Job__c> jobs : jobsByShiftId.values()) {
            for (sked__Job__c job : jobs) {
                if (isManuallyCreatedFromStaffingModal(job) || job.sked_Asset_Type__c != assetType) {
                    continue;
                }
                total += job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
            }
        }
        return total;
    }

    // Duplicated (not shared) from skedDriveContentionValidator/skedMobileDriveJobBuilder's own
    // copies of this exact check - single string, established precedent in this ticket.
    private static Boolean isManuallyCreatedFromStaffingModal(sked__Job__c job) {
        return job.sked_Is_Manually_Created__c == true && job.sked_Manually_Created_From__c == 'Staffing Modal';
    }
}
