public class skedDriveRegenContextLoader {
    // Direct (non-relationship) fields this loader selects - mirrors what the LWC drive
    // generator loads, so field coverage doesn't silently drift from the legacy implementation.
    @TestVisible
    private static final String DRIVE_FIELDS =
        'Id, sked_UFID__c, Name, sked_2RBC_Projected_Procedures__c, sked_Account__c, sked_Account_Type__c, ' +
        'sked_Approval_Status__c, sked_APT_Quantity__c, sked_APT_Required__c, sked_Cancellation_Detail__c, ' +
        'sked_Cancellation_Reason__c, sked_Collection_Operation__c, sked_Contention_Resolution__c, ' +
        'sked_Dispatched_At__c, sked_Designated_Approver__c, sked_District__c, sked_Drive_Date__c, ' +
        'sked_Drive_Dispatched__c, sked_Drive_Operation_Type__c, sked_Drive_Owner__c, ' +
        'sked_Drive_Productivity_Actual__c, sked_Drive_Productivity_Planned__c, sked_Drive_Productivity_Scheduled__c, ' +
        'sked_Drive_Site__c, sked_Drive_Shift_Count__c, sked_Dual_Roles_Auto_Generated__c, sked_Do_Not_Use_Vehicle__c, ' +
        'sked_End_Time__c, sked_Equipment_Allocated__c, sked_Exclude_from_Optimizer__c, sked_Has_Exception__c, ' +
        'sked_Hold_Status_expires_on__c, sked_Historical_Registered_Donors__c, sked_Industry_Code__c, ' +
        'sked_Is_Surrogate__c, sked_Is_New_Drive_Confirmation__c, sked_Initiated_By__c, sked_Last_Contact_Type__c, ' +
        'sked_Linked_Drives__c, sked_Market__c, sked_Max_Shift_End__c, sked_Maximum_Lunch_Break_Duration__c, ' +
        'sked_MigrationID__c, sked_Min_Shift_Start__c, sked_Need_By_Date__c, sked_Next_Drive__c, ' +
        'sked_Next_Drive_Date__c, sked_Number_of_2RBC_Assets__c, sked_Number_of_Plasma_Assets__c, ' +
        'sked_Number_of_Platelet_Assets__c, sked_Number_of_Vehicles__c, sked_No_of_Allocated_Buses__c, ' +
        'sked_No_of_days_to_Next_Drive__c, sked_No_of_Scheduled_Appointments__c, sked_No_of_Allocated_DOT__c, ' +
        'sked_No_of_Allocated_CDL__c, sked_Operation_Notes__c, sked_Operation_Type__c, sked_Opportunity__c, ' +
        'sked_Optimization_Status__c, sked_Platelet_Rounds__c, sked_Pending_Action__c, ' +
        'sked_Pending_Action_Reason_Code__c, sked_Plasma_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, ' +
        'sked_Prefer_System_Generated_Vehicles__c, sked_Primary_Contact__c, sked_Procedure_Capacity__c, ' +
        'sked_Procedures_Projected__c, sked_Projected_Registered_Donors__c, sked_Promotions__c, sked_Rank__c, ' +
        'sked_Recruited_By__c, sked_Redcross_Volunteer_Required__c, sked_Redcross_Volunteer_Quantity__c, ' +
        'sked_Rejection_Reason_Code__c, sked_Replacement_Drive__c, sked_Route_Approval_Request_To__c, ' +
        'sked_Staff_Allocated__c, sked_Staff_Capacity__c, sked_Staff_Locked__c, sked_Staging_Location__c, ' +
        'sked_Stage__c, sked_Status__c, sked_Start_Time__c, sked_Surrogate_Drive_for__c, sked_Submission_Notes__c, ' +
        'sked_Site_Collection_Operation__c, sked_Timezone__c, sked_Territory_Key__c, sked_Target_Productivity_Metric__c, ' +
        'sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c, sked_Total_Slots__c, ' +
        'sked_Total_Equipment_Requested__c, sked_Total_Staff_Requested__c, sked_Total_Vehicle_Requested__c, ' +
        'sked_Travel_Time_Included__c, sked_Travel_Time_CO_To_Site__c, sked_Travel_Time_Site_To_CO__c, ' +
        'sked_Type_of_Drive__c, sked_Use_Chaser_Vehicle__c, sked_IMPACT__c, sked_WB_Projected_Procedures__c, ' +
        'sked_Vehicles_Allocated__c, sked_Vehicle_Capacity__c, sked_Vehicle_Types__c, sked_Lock_Lunch_Break__c, ' +
        'sked_ARC_Region_ID__c, sked_Drive_Productivity_Banding__c, Average_Staff_Capacity__c, Max_Role_Capacity__c, ' +
        'Max_Role_Capacity_With_Draw_Hours__c, Excess_Staff_Capacity__c, ' +
        'sked_actual_visit_donor_cnt__c, sked_actual_total_qns__c, sked_actual_total_deferrals__c, ' +
        'sked_actual_wb_units_collected__c, sked_actual_drbc_units_collected__c, sked_actual_hispanic_cnt__c, ' +
        'sked_actual_african_amrcn_cnt__c, sked_actual_total_units_collected__c';

    public static skedDriveRegenContext load(Id driveId) {
        skedDriveRegenContext ctx = new skedDriveRegenContext();

        ctx.drive = (sked_Drive__c) Database.query('SELECT ' + DRIVE_FIELDS + ' FROM sked_Drive__c WHERE Id = :driveId');

        // sked_Start__c/Finish__c/Donors_Scheduled__c aren't needed for this loader's own diffing
        // (keyed by Id), but skedDriveContentionValidator reads ctx directly, pre-save - it needs
        // these populated even when the drive's engine doesn't itself replace driveShifts/
        // jobsByShiftId wholesale. sked_Time_Block__c/sked_Contention__c/sked_Contention_Resolution__c/
        // sked_Start_Time__c/sked_End_Time__c are for the time-block contention family
        // (skedDriveContentionValidator.validateDriveTimeBlocks). sked_Staff_Setup__c/
        // sked_Vehicles_Needed__c/sked_Equipment__c are for checkPartOfLinkedDrive's fresh (non-rollup)
        // total computation (skedDriveRegenContext.sumStaffSetup/maxVehiclesNeeded/maxEquipmentNeeded) -
        // same reason: an engine that doesn't replace driveShifts wholesale must still leave them queryable.
        ctx.driveShifts = [
            SELECT Id, sked_Drive__c, sked_Start__c, sked_Finish__c, sked_Donors_Scheduled__c,
                sked_Time_Block__c, sked_Contention__c, sked_Contention_Resolution__c, sked_Start_Time__c, sked_End_Time__c,
                sked_Staff_Setup__c, sked_Vehicles_Needed__c, sked_Equipment__c
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c = :driveId
        ];
        Set<Id> shiftIds = new Map<Id, sked_Drive_Shift__c>(ctx.driveShifts).keySet();

        // Extra fields here are for skedDriveContentionValidator's STAFFING_COMPLEMENT_CHANGED
        // check (diffs job fields against ctx.snapshot) - unused by this loader's own diffing.
        // sked__Start__c/Finish__c/Duration__c and the JobTags subquery are for LOCKED_RESOURCE_
        // UNAVAILABLE (turnaround time, CDL/DOT hours, required-tag checks against a locked staff
        // allocation's own job).
        for (sked__Job__c job : [
            SELECT Id, sked_Drive__c, sked_Drive_Shift__c, sked_Asset_Type__c, sked__Quantity__c,
                sked_Resource_Role__c, sked_Dual_Role__c, sked_System_Quantity__c, sked_VPHH_Quantity__c,
                sked_APT_Quantity__c, sked_Is_Manually_Created__c, sked_Manually_Created_From__c,
                sked__Start__c, sked__Finish__c, sked__Duration__c,
                (SELECT Id, sked__Tag__c FROM sked__JobTags__r)
            FROM sked__Job__c
            WHERE sked_Drive__c = :driveId
            AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
        ]) {
            if (job.sked_Drive_Shift__c == null) {
                ctx.driveLevelJobs.add(job);
            } else {
                if (!ctx.jobsByShiftId.containsKey(job.sked_Drive_Shift__c)) {
                    ctx.jobsByShiftId.put(job.sked_Drive_Shift__c, new List<sked__Job__c>());
                }
                ctx.jobsByShiftId.get(job.sked_Drive_Shift__c).add(job);
            }
        }

        Set<Id> jobIds = new Set<Id>();
        for (List<sked__Job__c> shiftJobs : ctx.jobsByShiftId.values()) {
            for (sked__Job__c job : shiftJobs) {
                jobIds.add(job.Id);
            }
        }
        for (sked__Job__c job : ctx.driveLevelJobs) {
            jobIds.add(job.Id);
        }
        // sked_Is_Locked__c/Start__c/Set_End__c/Geoservice_Travel_Time_* are for LOCKED_RESOURCE_
        // UNAVAILABLE (identifying locked staff allocations, turnaround-time neighbor windows, and
        // the already-persisted travel-time exception fields).
        for (sked__Job_Allocation__c allocation : [
            SELECT Id, sked__Job__c, sked__Status__c, sked__Resource__c, sked_Is_Locked__c,
                sked__Start__c, sked__Set_End__c, sked_Geoservice_Travel_Time_To__c, sked_Geoservice_Travel_Time_Back__c
            FROM sked__Job_Allocation__c
            WHERE sked__Job__c IN :jobIds
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
        ]) {
            if (!ctx.allocationsByJobId.containsKey(allocation.sked__Job__c)) {
                ctx.allocationsByJobId.put(allocation.sked__Job__c, new List<sked__Job_Allocation__c>());
            }
            ctx.allocationsByJobId.get(allocation.sked__Job__c).add(allocation);
        }

        for (sked__Slot__c slot : [
            SELECT Id, sked_Drive_Shift__c
            FROM sked__Slot__c
            WHERE sked_Drive_Shift__c IN :shiftIds
        ]) {
            if (!ctx.slotsByShiftId.containsKey(slot.sked_Drive_Shift__c)) {
                ctx.slotsByShiftId.put(slot.sked_Drive_Shift__c, new List<sked__Slot__c>());
            }
            ctx.slotsByShiftId.get(slot.sked_Drive_Shift__c).add(slot);
        }

        ctx.driveDeliveryJobs = [
            SELECT Id, sked_Drive__c
            FROM sked_Drive_Delivery_Job__c
            WHERE sked_Drive__c = :driveId
        ];

        ctx.snapshot = ctx.deepClone();

        // Read-only reference data for the time-block + DRIVE_LIMIT contention family - loaded after
        // the snapshot so it isn't needlessly doubled into the clone (see skedDriveRegenContext).
        loadReferenceData(ctx, driveId);

        return ctx;
    }

    /**
     * All 5 of ctx's CO/date-scoped reference-data lists, all keyed off ctx.drive's OWN
     * Collection Operation/Drive Date - re-callable, not just called once from load(). A CO-change
     * DCR mutates ctx.drive.sked_Collection_Operation__c in memory AFTER load() already ran
     * (skedDCRApplyService.applyCollectionOperationChange) - every one of these 5 lists goes stale
     * against the OLD CO unless this is called again right after that mutation. See
     * skedDriveContentionValidator's header (checkCoChangedCrossRegions) for the sibling problem
     * this same root cause creates for a single live-queried value - this method is the general fix
     * for every OTHER consumer that reads these lists straight off ctx instead of querying live.
     */
    public static void loadReferenceData(skedDriveRegenContext ctx, Id driveId) {
        ctx.collectionOperationTimeBlocks = [
            SELECT Id, Collection_Operation__c, Time_Block__c, Effective_Start_Date__c, Effective_End_Date__c,
                Time_Block__r.Days_of_Week__c, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c
            FROM Collection_Operation_Time_Block__c
            WHERE Collection_Operation__c = :ctx.drive.sked_Collection_Operation__c
        ];

        // Every limit type is loaded (not just DRIVE_LIMIT) - skedDriveContentionValidator's
        // findDriveLimitByDay filters by type itself, matching the source exactly (including a
        // blank/null sked_Type__c defaulting to DRIVE_LIMIT). x2RBC/DOT/CDL_LIMIT aren't
        // implemented yet, but this same reference data is what they'll need too.
        ctx.operationDriveLimits = [
            SELECT Id, sked_Collection_Operation__c, sked_Type__c, Time_Block__c, sked_Days_of_Week__c,
                sked_Effective_Start_Date__c, sked_Effective_End_Date__c, sked_Quantity__c,
                (SELECT Id, sked_Date__c, sked_Quantity__c FROM sked_Operation_Drive_Limit_Overrides__r)
            FROM sked_Operation_Drive_Limit__c
            WHERE sked_Collection_Operation__c = :ctx.drive.sked_Collection_Operation__c
        ];

        // Surrogate drives are always excluded from drive queries (see skedDriveContentionValidator's
        // other checks) - the source's own driveService.query has no such exclusion, but every other
        // drive query in this port applies it for the same data-integrity reason. Linked-drive/staff/
        // equipment/DOT/CDL fields are for skedSameDayLinkedDriveCollapser + the x2RBC/DOT/CDL_LIMIT
        // checks; sked_Staff_Setup__c/Time_Block__r.Start_Time__c are per-shift, for the same collapser.
        ctx.sameDateDrives = ctx.drive.sked_Drive_Date__c == null ? new List<sked_Drive__c>() : [
            SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Operation_Type__c,
                sked_Linked_Drives__c, sked_Linked_Drives__r.sked_Linked_Drive_Type__c,
                sked_Total_Staff_Requested__c, sked_Total_Equipment_Requested__c,
                sked_No_of_Allocated_DOT__c, sked_No_of_Allocated_CDL__c,
                (SELECT Id, sked_Time_Block__c, sked_Staff_Setup__c, sked_Time_Block__r.Start_Time__c FROM sked_Drive_Shifts__r)
            FROM sked_Drive__c
            WHERE sked_Collection_Operation__c = :ctx.drive.sked_Collection_Operation__c
            AND sked_Drive_Date__c = :ctx.drive.sked_Drive_Date__c
            AND Id != :driveId
            AND sked_Surrogate_Drive_for__c = null
        ];

        // For INSUFFICIENT_RESOURCES - matches the source's own query (fixedSiteGenerator.js:600,
        // staffingConstraintQuery.driveTypes = [this.drive.typeOfDrive]): CO, the CURRENT drive's own
        // type (not hardcoded to Mobile - that was a real bug, silently starving this check of data
        // for every Fixed Site drive), single day (startDate == endDate == the drive's date).
        String constraintDriveType = staffingConstraintDriveType(ctx.drive);
        ctx.staffingConstraints = ctx.drive.sked_Drive_Date__c == null ? new List<sked_Staffing_Constraint__c>() : [
            SELECT Id, sked_Time_Block__c, sked_Total_Staff_Constraints__c
            FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :ctx.drive.sked_Collection_Operation__c
            AND sked_Drive_Type__c = :constraintDriveType
            AND sked_Date_of_Constraint__c = :ctx.drive.sked_Drive_Date__c
        ];

        // For INSUFFICIENT_RESOURCES - matches the source's own query (isGroupActivity=true,
        // reduceFromStaffingConstraint=true, single-day range collapsed to an exact date match).
        ctx.sameDateActivities = ctx.drive.sked_Drive_Date__c == null ? new List<sked__Activity__c>() : [
            SELECT Id, sked_Time_Block__c, sked_Fixed_Site_Staff_Quantity__c, sked_Mobile_Staff_Quantity__c,
                sked_Linked_Drives__c, sked_Linked_Drives__r.sked_Linked_Drive_Type__c
            FROM sked__Activity__c
            WHERE sked_Collection_Operation__c = :ctx.drive.sked_Collection_Operation__c
            AND sked_Is_Group_Activity__c = true
            AND sked_Reduce_From_Staffing_Constraint__c = true
            AND sked_Start_Date__c = :ctx.drive.sked_Drive_Date__c
        ];
    }

    /**
     * A WB Fixed Site drive draws on Mobile-typed staffing reference data throughout, not its own
     * drive type: wbFixedSiteGenerator.js:614 hardcodes driveTypes = [DRIVE_TYPE.MOBILE], and its
     * constructor (wbFixedSiteGenerator.js:286-288) builds Fetch with driveType: MOBILE so the
     * Staffing Decision Matrix fetch (fetch.js:83) reads Mobile's pools too. Both siblings pass
     * this.drive.typeOfDrive instead (mobileGenerator.js:759, fixedSiteGenerator.js:600).
     */
    private static String staffingConstraintDriveType(sked_Drive__c drive) {
        Boolean isWbFixedSiteDrive = drive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE
            && drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_WB;
        return isWbFixedSiteDrive ? skedConstants.DRIVE_TYPE_MOBILE : drive.sked_Type_of_Drive__c;
    }
}
