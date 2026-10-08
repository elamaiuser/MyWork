public class skedDCRApplyService {
    @TestVisible private static final String MSG_DCR_NOT_FOUND = 'Cannot find Drive Change Request';
    @TestVisible private static final String MSG_NO_REGENERATION_REQUIRED = 'The Drive Change Request does not require to regenerate the drive.';
    @TestVisible private static final String MSG_ENGINE_UNAVAILABLE = 'Drive regeneration engine is not enabled for this drive type.';

    private Id dcrId;
    @TestVisible private sked_Drive_Change_Request__c dcr;
    @TestVisible private List<sked_Drive_Change_Request_Item__c> changeItems;
    @TestVisible private Id driveId;
    // Computed once in captureDriveChanges and read back in saveDrive, rather than re-querying
    // the same approval-pending state twice.
    @TestVisible private Boolean isDrivePendingApproval;
    // Set only by promoteIfContentionCleared (Draft + pending-approval path); saveDrive reuses it
    // instead of recomputing - safe because nothing between the two calls mutates ctx except
    // ctx.drive.sked_Status__c (Draft -> Tentative), and no contention check differentiates those
    // two statuses (only checkWithin42Days's confirm variant reads status at all, and only cares
    // whether it's == CONFIRMED). A future check that DOES distinguish Draft from Tentative would
    // need to invalidate this cache.
    @TestVisible private skedDriveContentionValidator.ValidationResult cachedContentionResult;

    public class applyResult {
        public Boolean applied = false;
        public String resultMessage;
        public Set<Id> travelTimeJobAllocationIds = new Set<Id>();
    }

    /** Thrown by saveDrive() on persistence failure; the batch cancels the DCR after rollback. */
    public class saveFailureException extends Exception {}

    public applyResult process(Id dcrId) {
        this.dcrId = dcrId;
        applyResult result = new applyResult();

        if (!checkDcr(result)) {
            return result;
        }
        if (!validateOpportunity(result)) {
            return result;
        }
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(this.driveId);
        if (!applyChangesToDrive(result, ctx)) {
            return result;
        }
        // Step: VALIDATE_ASSETS - reassign invalid/insufficient Vehicle/Equipment before the drive
        // is saved (this mutates ctx.allocationsByJobId, unlike skedDriveContentionValidator's
        // validate-only LACKING_VEHICLE/LACKING_EQUIPMENT checks, which run post-save).
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        promoteDraftToTentativeIfContentionCleared(ctx);
        if (!validateDraftDrive(result, ctx)) {
            return result;
        }
        if (!captureDriveChanges(result, ctx)) {
            return result;
        }
        saveDrive(result, ctx);
        return result;
    }

    /**
     * Applies an already-approved DCR. Skips VALIDATE_OPPORTUNITY, VALIDATE_ASSETS, and
     * CAPTURE_DRIVE_CHANGES's contention gate - a human already resolved contentions
     * (sked_Contention_Resolution__c) and approved this DCR via the standard Salesforce approval
     * process, so there's nothing left to route or re-decide. On success the DCR stays Approved
     * (no status write here) - the caller (skedDCRProcessingBatch) restores it after the
     * bookkeeping IN_PROCESS write.
     */
    public applyResult processApproved(Id dcrId) {
        this.dcrId = dcrId;
        applyResult result = new applyResult();

        if (!checkDcr(result)) {
            return result;
        }
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(this.driveId);
        if (!applyChangesToDrive(result, ctx)) {
            return result;
        }
        // Asset allocations are released for a Draft drive right before it's saved, in every
        // mode - see releaseAllAssetAllocations()'s header.
        if (ctx.drive.sked_Status__c == skedConstants.DRIVE_STATUS_DRAFT) {
            releaseAllAssetAllocations(ctx);
        }
        try {
            skedDriveGraphSaver.save(ctx);
        } catch (Exception ex) {
            result.resultMessage = ex.getMessage();
            return result;
        }
        result.applied = true;
        result.resultMessage = 'Drive was updated successfully.';
        return result;
    }

    /**
     * Called immediately before saving a Draft drive. Only the first drive shift's
     * vehicle/equipment job is touched. An already-persisted allocation (Id != null) is marked
     * Deleted rather than carried forward as-is; an allocation never persisted (Id == null) is
     * dropped outright so it's never inserted at all.
     */
    @TestVisible
    private void releaseAllAssetAllocations(skedDriveRegenContext ctx) {
        if (ctx.driveShifts.isEmpty()) {
            return;
        }
        List<sked__Job__c> jobs = ctx.jobsByShiftId.get(ctx.driveShifts[0].Id);
        if (jobs == null) {
            return;
        }
        sked__Job__c vehicleJob;
        sked__Job__c equipmentJob;
        for (sked__Job__c job : jobs) {
            if (vehicleJob == null && job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                vehicleJob = job;
            } else if (equipmentJob == null && job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                equipmentJob = job;
            }
        }
        for (sked__Job__c assetJob : new List<sked__Job__c>{ vehicleJob, equipmentJob }) {
            if (assetJob == null) {
                continue;
            }
            List<sked__Job_Allocation__c> allocations = ctx.allocationsByJobId.get(assetJob.Id);
            if (allocations == null) {
                continue;
            }
            List<sked__Job_Allocation__c> released = new List<sked__Job_Allocation__c>();
            for (sked__Job_Allocation__c allocation : allocations) {
                if (allocation.Id != null) {
                    allocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                    released.add(allocation);
                }
            }
            ctx.allocationsByJobId.put(assetJob.Id, released);
        }
    }

    /**
     * Step: VALIDATE_ASSETS's Draft+pending-approval branch - computes contentions early and
     * promotes Draft -> Tentative right here if they've cleared, matching the source's promotion
     * timing: it runs BEFORE VALIDATE_DRAFT_DRIVE next, so a drive that just cleared must skip the
     * Draft-only military-account check that step gates on Draft status. Reading ctx.drive.sked_
     * Status__c alone in validateDraftDrive wouldn't be enough without this - the promotion has to
     * actually happen before that check runs, not just be visible to it.
     */
    @TestVisible
    private void promoteDraftToTentativeIfContentionCleared(skedDriveRegenContext ctx) {
        if (ctx.drive.sked_Status__c != skedConstants.DRIVE_STATUS_DRAFT) {
            return;
        }
        this.isDrivePendingApproval = (Boolean) slwcApprovalService.isPendingApproval(this.driveId).returnedData;
        if (!this.isDrivePendingApproval) {
            return;
        }
        promoteIfContentionCleared(ctx);
    }

    @TestVisible
    private void promoteIfContentionCleared(skedDriveRegenContext ctx) {
        skedDriveContentionValidator.ValidationResult contentionResult = skedDriveContentionValidator.validateDrive(ctx);
        this.cachedContentionResult = contentionResult;
        if (contentionResult.passed) {
            ctx.drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        }
    }

    /** Step: VALIDATE_DRAFT_DRIVE - Draft drives only; reuses the existing military-account check. */
    @TestVisible
    private Boolean validateDraftDrive(applyResult result, skedDriveRegenContext ctx) {
        if (ctx.drive.sked_Status__c != skedConstants.DRIVE_STATUS_DRAFT) {
            return true;
        }
        try {
            slwcDriveService.validateDraftDriveRequestModel request = new slwcDriveService.validateDraftDriveRequestModel();
            request.driveId = this.driveId;
            slwcDriveService.validateDraftDrive(request);
            return true;
        } catch (Exception ex) {
            result.resultMessage = ex.getMessage();
            return false;
        }
    }

    @TestVisible private static final String ERROR_NO_COLLECTION_OPERATION = 'Cannot find any collection operation associates with this Opportunity.';
    @TestVisible private static final String ERROR_NO_VEHICLE = 'There is no vehicle associate with the collection operation yet.';
    @TestVisible private static final String ERROR_MISSING_SITE = 'Missing Drive Site.';
    @TestVisible private static final String ERROR_MISSING_DATE = 'Missing Drive Date.';
    @TestVisible private static final String ERROR_MISSING_TYPE = 'Missing Drive Type.';
    @TestVisible private static final String ERROR_MISSING_ACCOUNT = 'Missing Account.';

    /** Step: VALIDATE_OPPORTUNITY - is the source data complete enough to re-plan from? */
    @TestVisible
    private Boolean validateOpportunity(applyResult result) {
        List<String> errorMessages = new List<String>();
        Opportunity opp = [
            SELECT Id, AccountId, Drive_Site__c, Drive_Date__c, Type_of_Drive__c
            FROM Opportunity
            WHERE Id = :this.dcr.sked_Drive__r.sked_Opportunity__c
        ];

        if (opp.Drive_Site__c == null) {
            errorMessages.add(ERROR_MISSING_SITE);
        } else if (opp.AccountId == null) {
            errorMessages.add(ERROR_MISSING_ACCOUNT);
        } else if (opp.Drive_Date__c == null) {
            errorMessages.add(ERROR_MISSING_DATE);
        } else if (opp.Type_of_Drive__c == null) {
            errorMessages.add(ERROR_MISSING_TYPE);
        } else {
            // Site-CO junction valid on the drive date
            List<sked_Site_Collection_Operation__c> siteCos = [
                SELECT Id, sked_Collection_Operation__c
                FROM sked_Site_Collection_Operation__c
                WHERE sked_Site__c = :opp.Drive_Site__c
                AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :opp.Drive_Date__c)
                AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :opp.Drive_Date__c)
            ];
            if (siteCos.isEmpty() || siteCos.get(0).sked_Collection_Operation__c == null) {
                errorMessages.add(ERROR_NO_COLLECTION_OPERATION);
            } else if (opp.Type_of_Drive__c == skedConstants.DRIVE_TYPE_MOBILE
                    && !hasVehiclesForCollectionOperation(siteCos.get(0).sked_Collection_Operation__c, opp.Drive_Date__c)) {
                // Mobile-only gate: both Fixed Site engines list ghost vehicle among the Mobile
                // concepts they never port, and their vehicle-requested total is always 0, so a Fixed
                // Site drive was being blocked on a resource it can never use.
                errorMessages.add(ERROR_NO_VEHICLE);
            }
        }

        if (!errorMessages.isEmpty()) {
            result.resultMessage = 'Opportunity is missing below data:\n- ' + String.join(errorMessages, '\n- ');
            return false;
        }
        return true;
    }

    /**
     * Vehicle sources for a CO (org convention): primary region CO + secondary junction
     * (sked_Resource_Biomed_Collection_Op__c) + relocated-in (sked__Resource_Override__c).
     * Active window derived from Effective/Future Inactive dates, not sked__Is_Active__c.
     */
    @TestVisible
    private Boolean hasVehiclesForCollectionOperation(Id collectionOperationId, Date driveDate) {
        Set<Id> additionalResourceIds = new Set<Id>();
        for (sked__Resource_Override__c resourceOverride : [
            SELECT sked__Resource__c FROM sked__Resource_Override__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
            AND sked_Start_Date__c <= :driveDate AND sked_End_Date__c >= :driveDate
        ]) {
            additionalResourceIds.add(resourceOverride.sked__Resource__c);
        }
        for (sked_Resource_Biomed_Collection_Op__c resourceCo : [
            SELECT sked_Resource__c FROM sked_Resource_Biomed_Collection_Op__c
            WHERE sked_Biomed_Collection_Op_Center__c = :collectionOperationId
            AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :driveDate)
            AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :driveDate)
        ]) {
            additionalResourceIds.add(resourceCo.sked_Resource__c);
        }
        Integer vehicleCount = [
            SELECT COUNT() FROM sked__Resource__c
            WHERE sked_Asset_Type__c = :skedConstants.ASSET_TYPE_VEHICLE
            AND sked__Is_Active__c = TRUE
            AND (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c = :collectionOperationId
                 OR Id IN :additionalResourceIds)
            AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :driveDate)
            AND (sked_Future_Inactive_Date__c = NULL OR sked_Future_Inactive_Date__c > :driveDate)
        ];
        return vehicleCount > 0;
    }

    /**
     * Step: CHECKING_DCR - does a calculation engine exist for this drive's type yet? If not,
     * stop here - the DCR stays Pending for a later run.
     */
    @TestVisible
    private Boolean checkDcr(applyResult result) {
        List<sked_Drive_Change_Request__c> dcrs = [
            SELECT Id, sked_Drive__c, sked_Type__c, sked_Status__c, sked_Opportunity_Id__c, CreatedById,
                sked_New_Collection_Operation__c,
                sked_Drive__r.sked_Type_of_Drive__c, sked_Drive__r.sked_Operation_Type__c,
                sked_Drive__r.sked_Status__c, sked_Drive__r.sked_Opportunity__c,
                (SELECT Id, sked_Object_API_Name__c, sked_Field_API_Name__c, sked_Field_Type__c,
                     sked_Old_Value__c, sked_New_Value__c, sked_Type__c
                 FROM sked_Drive_Change_Request_Items__r)
            FROM sked_Drive_Change_Request__c
            WHERE Id = :this.dcrId
        ];
        if (dcrs.isEmpty()) {
            result.resultMessage = MSG_DCR_NOT_FOUND;
            return false;
        }

        this.dcr = dcrs.get(0);
        this.changeItems = new List<sked_Drive_Change_Request_Item__c>();
        for (sked_Drive_Change_Request_Item__c item : this.dcr.sked_Drive_Change_Request_Items__r) {
            if (item.sked_Type__c == 'Change') {
                this.changeItems.add(item);
            }
        }
        if (this.changeItems.isEmpty()) {
            result.resultMessage = MSG_NO_REGENERATION_REQUIRED;
            return false;
        }

        this.driveId = this.dcr.sked_Drive__c;

        if (skedDriveRegenEngineFactory.getEngine(
                this.dcr.sked_Drive__r.sked_Type_of_Drive__c,
                this.dcr.sked_Drive__r.sked_Operation_Type__c) == null) {
            result.resultMessage = MSG_ENGINE_UNAVAILABLE;
            return false;
        }
        return true;
    }

    @TestVisible private static final Map<String, String> TRACKED_FIELDS = new Map<String, String>{
        'totalStaffRequested'       => 'sked_Total_Staff_Requested__c',
        'totalVehicleRequested'     => 'sked_Total_Vehicle_Requested__c',
        'totalEquipmentRequested'   => 'sked_Total_Equipment_Requested__c',
        'projectedRegisteredDonors' => 'sked_Projected_Registered_Donors__c',
        'driveDate'                 => 'sked_Drive_Date__c',
        'startTime'                 => 'sked_Start_Time__c',
        'endTime'                   => 'sked_End_Time__c',
        'driveSiteId'               => 'sked_Drive_Site__c',
        'totalProceduresProjected'  => 'sked_Total_Procedures_Projected__c',
        'totalProductsProjected'    => 'sked_Total_Products_Projected__c',
        'driveProductivityPlanned'  => 'sked_Drive_Productivity_Planned__c',
        'totalSlots'                => 'sked_Total_Slots__c',
        'aptQuantity'               => 'sked_APT_Quantity__c'
    };

    /**
     * Step: CAPTURE_DRIVE_CHANGES (diff only) + approval-state pre-check. The actual save/route
     * decision happens in saveDrive, which computes contention BEFORE deciding whether to save at
     * all - see its header.
     */
    @TestVisible
    private Boolean captureDriveChanges(applyResult result, skedDriveRegenContext ctx) {
        // 1. Diff tracked fields (snapshot vs regenerated) -> impact items
        slwcDriveService.driveChangeRequestModel captureRequest = new slwcDriveService.driveChangeRequestModel();
        captureRequest.id = this.dcr.Id;
        captureRequest.driveId = this.driveId;
        captureRequest.driveChangeRequestItems = new List<slwcDriveService.driveChangeRequestItemModel>();
        for (String fieldApiName : TRACKED_FIELDS.values()) {
            Object oldValue = ctx.snapshot.drive.get(fieldApiName);
            Object newValue = ctx.drive.get(fieldApiName);
            if (oldValue != newValue) {
                slwcDriveService.driveChangeRequestItemModel item = new slwcDriveService.driveChangeRequestItemModel();
                item.objectApiName = 'sked_Drive__c';
                item.fieldApiName = fieldApiName;
                item.oldValue = oldValue == null ? null : String.valueOf(oldValue);
                item.newValue = newValue == null ? null : String.valueOf(newValue);
                captureRequest.driveChangeRequestItems.add(item);
            }
        }
        slwcDriveService.captureDriveImpact(captureRequest);

        // 2. Approval state pre-check
        this.isDrivePendingApproval = (Boolean) slwcApprovalService.isPendingApproval(this.driveId).returnedData;
        if (this.isDrivePendingApproval) {
            String latestStatus = (String) slwcApprovalService.getLatestDCRStatus(this.dcr.Id).returnedData;
            if (latestStatus == skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM) {
                result.resultMessage = 'This DCR was already approved by system. Refreshing page.';
                return false;
            }
            slwcApprovalService.removeWorkItems(new Set<Id>{ this.driveId }); // synchronous - no waitUntil needed
        }
        return true;
    }

    // notUserChanges use item newValue, everything else re-reads the live Opportunity; engines
    // consume these tokens.
    @TestVisible
    private Map<String, Object> buildTokensFromDcr(skedDriveRegenContext ctx) {
        Map<String, Object> tokens = new Map<String, Object>();
        List<String> dcrTypes = this.dcr.sked_Type__c == null ? new List<String>() : this.dcr.sked_Type__c.split(';');
        Map<String, String> typeToToken = new Map<String, String>{
            skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTV_CHANGE          => 'roleTimeVarianceChanged',
            skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE          => 'roleTimeDetailChanged',
            skedConstants.DRIVE_CHANGE_REQUEST_TYPE_SITE_ADDRESS_CHANGE => 'siteAddressChanged',
            skedConstants.DRIVE_CHANGE_REQUEST_TYPE_TRAVEL_TIME_CHANGE  => 'travelTimeChanged',
            skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE    => 'regenerateDrive'
        };
        for (String dcrType : dcrTypes) {
            if (typeToToken.containsKey(dcrType)) {
                tokens.put(typeToToken.get(dcrType), null);
            }
        }
        if (dcrTypes.contains(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_COLLECTION_OP)) {
            applyCollectionOperationChange(ctx);
            tokens.put('collectionOperationId', null);
        }
        return tokens; // User Change DCRs (the only type carrying item-driven field values like
                        // driveDate/startTime/driveSiteId) are excluded from this batch entirely -
                        // see skedDCRProcessingBatch.start()'s query - since they're a record of a
                        // live edit a user already saved directly, not an instruction to replay.
    }

    /**
     * Collection Operation reassignment is system-driven, not a user edit - the DCR's own
     * sked_New_Collection_Operation__c lookup carries the new value directly (unlike most other
     * item-driven fields, which re-read the live Opportunity instead of trusting the DCR item).
     * sked_Site_Collection_Operation__c has no equivalent lookup field on the DCR itself, so its
     * new value comes from the paired Change item skedDriveCOChangedBatch always creates alongside
     * the Collection Operation one.
     *
     * ctx's 5 CO-scoped reference-data lists (collectionOperationTimeBlocks, operationDriveLimits,
     * sameDateDrives, staffingConstraints, sameDateActivities) were loaded against the OLD CO by
     * skedDriveRegenContextLoader.load(), which runs before this method - reload them now that
     * ctx.drive.sked_Collection_Operation__c has its real, new value, or every contention check that
     * reads them (not the one, checkCoChangedCrossRegions, that already queries live - see that
     * class's header) would evaluate the wrong Collection Operation's data.
     */
    @TestVisible
    private void applyCollectionOperationChange(skedDriveRegenContext ctx) {
        if (this.dcr.sked_New_Collection_Operation__c != null) {
            ctx.drive.sked_Collection_Operation__c = this.dcr.sked_New_Collection_Operation__c;
        }
        for (sked_Drive_Change_Request_Item__c item : this.changeItems) {
            if (item.sked_Field_API_Name__c == 'sked_Site_Collection_Operation__c' && String.isNotBlank(item.sked_New_Value__c)) {
                ctx.drive.sked_Site_Collection_Operation__c = Id.valueOf(item.sked_New_Value__c);
            }
        }
        skedDriveRegenContextLoader.loadReferenceData(ctx, ctx.drive.Id);
    }

    /** Step: APPLY_CHANGES_TO_DRIVE - translate the DCR into tokens, let the engine recompute. */
    @TestVisible
    private Boolean applyChangesToDrive(applyResult result, skedDriveRegenContext ctx) {
        // Engine existence was already verified in checkDcr() - by construction it cannot be
        // null here.
        skedDriveRegenEngine engine = skedDriveRegenEngineFactory.getEngine(
            ctx.drive.sked_Type_of_Drive__c, ctx.drive.sked_Operation_Type__c);
        Map<String, Object> tokens = buildTokensFromDcr(ctx);
        ctx.appliedTokens.addAll(tokens.keySet());
        engine.onDriveDataChanged(ctx, tokens);
        return true;
    }

    private static final Set<String> TRAVEL_SENSITIVE_TOKENS = new Set<String>{
        'driveSiteId', 'siteAddressChanged', 'collectionOperationId', 'travelTimeChanged'
    };

    /**
     * Step: SAVE_DRIVE - contention is computed BEFORE deciding whether to save at all: a
     * non-Draft, non-Fixed-Site drive with unresolved contention is never saved, full stop. The
     * Drive itself is left completely unmodified in that case; only the DCR's own status is
     * written. So contention must be computed here first, against the in-memory ctx (before
     * skedDriveGraphSaver.save runs), and the save only happens on paths that actually save. On
     * save failure, cancel via the batch (post-rollback) - see saveFailureException.
     */
    @TestVisible
    private Boolean saveDrive(applyResult result, skedDriveRegenContext ctx) {
        skedDriveContentionValidator.ValidationResult contentionResult = this.cachedContentionResult != null
            ? this.cachedContentionResult
            : skedDriveContentionValidator.validateDrive(ctx);

        Boolean isDraft = ctx.drive.sked_Status__c == skedConstants.DRIVE_STATUS_DRAFT;
        // A Draft drive that isn't pending approval never recomputes contention - leave its
        // loaded pendingActionReasonCode untouched rather than overwriting it.
        if (!(isDraft && !this.isDrivePendingApproval)) {
            ctx.drive.sked_Pending_Action_Reason_Code__c = contentionResult.pendingActionReasonCodes.isEmpty()
                ? null : String.join(contentionResult.pendingActionReasonCodes, ';');
        }

        // A Non Integrated WB Fixed Site drive is never treated as Fixed Site, even though its
        // typeOfDrive otherwise matches.
        Boolean isFixedSiteDrive = ctx.drive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE
            && ctx.drive.sked_Operation_Type__c != skedConstants.OPERATION_TYPE_WB;

        // Draft -> Tentative promotion (when pending-approval contentions clear) already happened
        // in promoteDraftToTentativeIfContentionCleared, before VALIDATE_DRAFT_DRIVE ran - isDraft
        // above already reflects it.
        if (!isDraft && !isFixedSiteDrive && !contentionResult.passed) {
            // Non-Draft, non-Fixed-Site, contended -> route to human approval WITHOUT touching
            // the Drive/Shift/Job/Allocation/Slot data at all.
            ctx.drive.sked_Route_Approval_Request_To__c = computeRouteApprovalRequestTo(contentionResult.pendingActionReasonCodes);
            update new sked_Drive_Change_Request__c(
                Id = this.dcr.Id,
                sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_SUBMITTED,
                sked_Drive_Contention__c = String.join(contentionResult.pendingActionReasonCodes, ';'),
                sked_Route_Approval_Request_To__c = ctx.drive.sked_Route_Approval_Request_To__c
            );
            result.applied = true;
            result.resultMessage = 'Drive has been submitted for approval.';
            return true;
        }

        // Asset allocations are released right before saving whenever the drive is still Draft
        // at this point (post-promotion above) - see releaseAllAssetAllocations()'s header.
        if (isDraft) {
            releaseAllAssetAllocations(ctx);
        }

        try {
            skedDriveGraphSaver.save(ctx);
        } catch (Exception ex) {
            // Save failure cancels the DCR (trigger reverts the Opportunity). The batch's
            // savepoint rollback must happen BEFORE this status write survives, so the
            // cancellation itself happens in skedDCRProcessingBatch.execute()'s catch block
            // (post-rollback), not here - this rethrows a typed exception so the batch knows to
            // do it.
            throw new saveFailureException(ex.getMessage());
        }

        update new sked_Drive_Change_Request__c(
            Id = this.dcr.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM);

        Boolean tokensAreTravelSensitive = false;
        for (String token : TRAVEL_SENSITIVE_TOKENS) {
            if (ctx.appliedTokens.contains(token)) {
                tokensAreTravelSensitive = true;
                break;
            }
        }
        if (tokensAreTravelSensitive) {
            for (List<sked__Job_Allocation__c> jas : ctx.allocationsByJobId.values()) {
                for (sked__Job_Allocation__c ja : jas) {
                    if (ja.Id != null && ja.sked__Status__c != skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                        result.travelTimeJobAllocationIds.add(ja.Id);
                    }
                }
            }
        }
        result.applied = true;
        result.resultMessage = 'Your changes have been approved and updates have been made by system.';
        return true;
    }

    /**
     * Determines who a contended drive routes approval to. Only called once
     * pendingActionReasonCodes is already known non-empty (the route-to-human branch above).
     *
     * The DM-evaluation branch below only fires when pendingActionReasonCodes includes
     * INSUFFICIENT_RESOURCES; that contention isn't implemented yet, so this always resolves to
     * APS exception for now - it becomes correct automatically once that check is added.
     *
     * NOT ported: a companion side effect that also sets pendingAction/approvalStatus for a
     * non-APS user on a Draft drive. That case never overlaps with this method's caller (which
     * requires !isDraft), and there's no interactive Salesforce session (hence no "login user")
     * in a batch-run DCR - inventing a stand-in would be guessing at behavior that isn't defined
     * for this context, so it's left unimplemented pending a product decision.
     */
    @TestVisible
    private String computeRouteApprovalRequestTo(List<String> pendingActionReasonCodes) {
        if (!pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_WITHIN_42_DAYS)
                && pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_INSUFFICIENT_RESOURCES)) {
            return 'Request DM evaluation';
        }
        return 'Request APS exception';
    }
}
