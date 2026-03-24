import skedGoogleMapApis from '@salesforce/resourceUrl/skedGoogleMapApis';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import * as slwcUtils from 'c/slwcUtils';
import { driveValidator } from 'c/slwcValidator';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import {
    loadScript
} from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, track, wire } from 'lwc';

import driveManagementTabTemplate from './driveManagementTab.html';
import surrogateDriveTemplate from './surrogateDrive.html';
// import opportunityDriveShiftsTemplate from './opportunityDriveShifts.html';

import TIME_ZONE from '@salesforce/i18n/timeZone';
import { approvalService, dataService, debugLogService, driveQueryModel, driveService, jobService, slotService } from 'c/dataService';
import { chunk } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { ASSET_TYPE, DRIVE_APPROVAL_STATUS, DRIVE_CHANGE_REQUEST_TYPE, DRIVE_REQUEST_CHANGE_STATUS, DRIVE_SHIFT_TIME_BLOCK_CONTENTION, DRIVE_STATUS, OPPORTUNITY_STAGE, PENDING_ACTION } from 'c/slwcConstants';
import { DriveHelper, slwcDriveGeneratorHelper } from 'c/slwcDriveGenerator';

// import { auraProxyConfig } from 'c/auraProxy';
// auraProxyConfig.enableMock();

let driveGeneratorInstance = {
    drive: null,
    masterData: {
        driveTags: {
        accountTags: [],
        locationTags: []
        },
        isReadonly: false,
        lunchBreakSettings: [],
        resourceRoleGroups: null,
        roleTimeData: null,
        roleTimeDetailMap: null,
        roleTimeVarianceMap: {},
        sameDateActivities: [],
        sameDateDrives: [],
        staffingDecisionMatrix: null,
        timezoneSidId: null,
        vehicles: [],
        backupDrive: null,
        backupDriveShiftMap: {},
        fieldReadonlyMap: {}
    },
    errorMessages: []
};

const DISPLAY_MODE = {
    DRIVE_MANAGEMENT_TAB: 'driveManagementTab',
    OPPORTUNITY_DRIVE_SHIFTS_TAB: 'opportunityDriveShifts',
}

const TABS = {
    DRIVE_DETAILS: 'driveTails',
    DRIVE_SHIFTS: 'driveShifts',
    MULTI_DAY_LINKED_DRIVES: 'multiDayLinkedDrives',
    SCHEDULING_PROGRESS: 'schedulingProgress',
    FIXED_SITE: 'fixedSite',
    WB_FIXED_SITE: 'wbFixedSite',
    MOBILE: 'mobile',
    PRODUCTIVITY: 'productivity',
    ACCOUNT_INFORMATION: 'accountInformation',
    SYSTEM_INFORMATION: 'systemInformation'
}

const eventListeners = {
    'driveGenerator:driveChanged': [],
};

export default class SlwcDriveManagement extends NavigationMixin(LightningElement) {
    @api displayMode = DISPLAY_MODE.DRIVE_MANAGEMENT_TAB;
    // @api recordId = 'a1Z2i000001ikePEAQ';
    @api recordId;
    @api showCloseButton = false;

    @track initialized = false;
    @track showSpinnerCount = 0;
    @track confirmModalData = {};
    @track pendingActionDriveConfirmModalData = {};

    @track TABS = TABS;
    @track currentTab = TABS.DRIVE_DETAILS;
    @track drive = null;
    @track originalDrive = null;
    @track showErrors = false;
    @track tabDetailsError = false;
    @track tabShiftsError = false;
    @track isDriveNotScheduled = false;
    @track driveSideMenuData = {};
    @track driveShiftsMetadataModalData = {};
    @track adminSettings = {};

    tabDetailsValidationFields = [];
    driveHelper = new DriveHelper();
    isDirty = false;
    isSetUnsavedChangesDone = false;
    bindHandleDriveChanged;
    
    get driveHasGenerated() {
        if (!this.recordId) return false;
        return this.drive && this.drive.id;
    }
    
    get isFixedSiteDrive() {
        return this.driveHelper.isFixedSiteDrive(this.drive);
    }

    get isMobileDrive() {
        return this.driveHelper.isMobileDrive(this.drive);
    }

    get isWbFixedSiteDrive() {
        return this.driveHelper.isWbFixedSiteDrive(this.drive);
    }

    get isMobile() {
        return slwcUtils.isMobile()
    }

    get driveGeneratorInstance() {
        return driveGeneratorInstance;
    }

    get masterData() {
        return driveGeneratorInstance.masterData;
    }

    get drivesWithVehicles() {
        return driveGeneratorInstance.drivesWithVehicles
    }

    get isEditMode() {
        return this.drive && this.drive.id;
    }
    
    get isSurrogateDrive() {
        return this.drive && this.drive.isSurrogate;
    }
    
    get surrogateDrive() {
        if (!this.isSurrogateDrive) return null;
        return {
            id: this.drive.surrogateDriveForId,
            name: this.drive.surrogateDriveForName
        }
    }

    get showCreateSurrogateDriveButton() {
        if (!this.isEditMode) return false;
        const statusValid = [DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.COMPLETE].includes(this.drive.status);
        const today = DateTime.local().setZone(TIME_ZONE).toISODate();
        const isAPSUser = this.driveHelper.isAPSUser(this.masterData.loginUser);
        const dateValid = this.drive.driveDate <= today;
        return isAPSUser && statusValid && dateValid;
    }

    get showAllocateButton() {
        return !this.isMobile
            && this.drive
            && [DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE].includes(this.drive.status);
    }

    get isAllocateAssetsOnly() {
        return [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE].includes(this.drive.status);
    }

    get showSaveButtons() {
        if (!this.masterData.isReadonly) return true;
        const anyFieldEditable = Object.keys(this.masterData.fieldReadonlyMap).find(field => {
            return !this.masterData.fieldReadonlyMap[field]
        });

        return anyFieldEditable;
    }

    get title() {
        return this.isEditMode ? this.drive.name : 'New Drive';
    }

    get accountUrl() {
        let result = '';
        if (this.drive && this.drive.account) {
            result = '/' + this.drive.account.id;
        }
        return result;
    }
    
    get showSpinner() {
        return this.showSpinnerCount > 0;
    }

    get showDriveDetailsTab() {
        return this.currentTab === TABS.DRIVE_DETAILS;
    }

    get showDriveShiftsTab() {
        return this.currentTab === TABS.DRIVE_SHIFTS;
    }

    get showMultiDayLinkedDrivesTab() {
        return this.currentTab === TABS.MULTI_DAY_LINKED_DRIVES;
    }

    get showSchedulingProgressTab() {
        return this.currentTab === TABS.SCHEDULING_PROGRESS;
    }

    get showProductivityTab() {
        return this.currentTab === TABS.PRODUCTIVITY;
    }

    get showAccountInformationTab() {
        return this.currentTab === TABS.ACCOUNT_INFORMATION;
    }

    get showSystemInformationTab() {
        return this.currentTab === TABS.SYSTEM_INFORMATION;
    }

    get showFixedSiteTab() {
        return this.currentTab === TABS.FIXED_SITE;
    }
    
    get showWbFixedSiteTab() {
        return this.currentTab === TABS.WB_FIXED_SITE;
    }

    get showMobileTab() {
        return this.currentTab === TABS.MOBILE;
    }

    get showSaveDraftButton() {
        return !this.isFixedSiteDrive && this.drive && this.drive.status === DRIVE_STATUS.DRAFT;
    }  

    get showHoldButton() {
        return !this.isFixedSiteDrive && this.drive && this.drive.status === DRIVE_STATUS.DRAFT;
    }

    get showRemoveHoldButton() {
        return !this.isFixedSiteDrive && this.drive && this.drive.status === DRIVE_STATUS.HOLD;
    }

    get showSubmitButton() {
        return !this.isFixedSiteDrive && this.drive && this.drive.status === DRIVE_STATUS.DRAFT;
    }

    get showSaveButton() {
        return !this.isFixedSiteDrive && this.drive && this.drive.status !== DRIVE_STATUS.DRAFT;
    }

    get showDCRWarning() {
        return this.drive && this.drive.pendingAction && this.drive.pendingAction === PENDING_ACTION.DRIVE_CHANGE_REQUEST && driveGeneratorInstance.masterData.waitingDriveChangeRequest;
    }

    get showNoTravelDataWarning() {
        if (!this.initialized) {
            return false;
        }

        const { travelTimeBreakdownsCoToSite, travelTimeBreakdownsSiteToCo } = this.driveHelper.getTravelTimeBreakdownData(this.drive, this.masterData);
        return this.drive && (
            !travelTimeBreakdownsCoToSite?.length || 
            !travelTimeBreakdownsSiteToCo?.length
        );
    }

    get showPendingUserChangeWarning() {
        if (!this.drive || !driveGeneratorInstance.masterData.pendingDriveChangeRequest) return false;
        return driveGeneratorInstance.masterData.pendingDriveChangeRequest.status === DRIVE_REQUEST_CHANGE_STATUS.PENDING && driveGeneratorInstance.masterData.pendingDriveChangeRequest.type.includes(DRIVE_CHANGE_REQUEST_TYPE.USER_CHANGE);
    }

    get showApproveDriveSubmissionBtn() {
        return this.driveHelper.isAPSUser(this.masterData.loginUser) && this.driveHelper.isDriveSubmittedForSubmissionApproval(this.drive);
    }

    get driveDateOfWeek() {
        if (!this.drive || !this.drive.driveDate) return null;
        return DateTime.fromFormat(this.drive.driveDate, 'yyyy-MM-dd').toFormat('EEEE');
    }

    get disabledHoldButton() {
        return ![OPPORTUNITY_STAGE.DISCOVERY, OPPORTUNITY_STAGE.SOLICITATION].includes(this.drive.opportunity.stage);
    }

    get isAdmin() {
        return this.driveHelper.isAdminUser(this.masterData.loginUser);
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        if (this.recordId) {
            this.initialize(this.recordId);
        }

        this.tabDetailsValidationFields = ['driveDate', 'projectedRegisteredDonors', 'name', 'startTime'];
        //this.tabDetailsValidationFields = ['driveDate', 'projectedRegisteredDonors', 'name', 'startTime','accountType','militaryAuthorityName','militaryAuthorityPhone','industryCode','acceptsAutomation','internalName','physicalLocationType','roomName','siteBuildingName','directionsFromCollectionOperation','floorDescription','automationSuitability','siteContactId','operationType'];
        
        this.bindHandleDriveChanged = this.handleDriveChanged.bind(this);
        
        this.removeAllEventListeners('driveGenerator:driveChanged');

        this.addEventListenerWithStore('driveGenerator:driveChanged', this.bindHandleDriveChanged);
        document.addEventListener('driveGenerator:showToastr', (event) => {
            this.dispatchEvent(new ShowToastEvent({
                message: event.detail.message,
                variant: event.detail.variant,
                mode: 'dismissable'
            }));
        });

        registerListener('saveJob', this.handleSaveJob, this);
        registerListener('deleteJob', this.handleDeleteJob, this);

        registerListener('saveBulkEditVolunteerJobModal', this.handleSaveBulkEditVolunteerJobModal, this);
        registerListener('saveBulkAddVolunteerJobModal', this.handleSaveBulkAddVolunteerJobModal, this);
        registerListener('saveDualRoleAssignmentModal', this.handleSaveDualRoleAssignmentModal, this);

        registerListener('saveDriveShiftTag', this.handleSaveDriveShiftTag, this);
        registerListener('deleteDriveShiftTag', this.handleDeleteDriveShiftTag, this);

        registerListener('openDriveStaffingDetails', this.handleOpenDriveStaffingDetails, this);
    }

    disconnectedCallback() {
        document.removeEventListener('driveGenerator:driveChanged', this.bindHandleDriveChanged);

        unregisterAllListeners(this);
    }

    addEventListenerWithStore(eventType, listener) {
        document.addEventListener(eventType, listener);
        if (!eventListeners[eventType]) {
            eventListeners[eventType] = [];
        }
        eventListeners[eventType].push(listener);
    }

    removeAllEventListeners(eventType) {
        if (eventListeners[eventType]) {
            eventListeners[eventType].forEach((listener) => {
                document.removeEventListener(eventType, listener);
            });
            eventListeners[eventType] = [];
        }
    }

    render() {
        if (this.isSurrogateDrive) {
            return surrogateDriveTemplate;
        }
        return driveManagementTabTemplate;
    }
    
    exceptionHandler = (error) => {
        console.log('error :: ', error);
        new debugLogService().captureDebugLog(error, this.drive?.id);
        if (error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }
    
    showLoading = () => {
        this.showSpinnerCount++;
    }

    hideLoading = () => {
        this.showSpinnerCount--;
        if (this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        } 
    }

    /** Initialize **/
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        let recordId = this.currentPageReference.state.c__recordId;
        this.initialize(recordId);
    }

    initialize(recordId) {
        if (!recordId) return;
        
        this.showLoading();
        Promise.resolve()
        .then(() => {
            if (!window.google) {
                return loadScript(this, skedGoogleMapApis)
                    .catch((e) => { })
            }
        })
        .then(() => {
            if (!recordId.startsWith('006')) {
                let _driveService = new driveService();
                let query = new driveQueryModel();
                query.recordIds = [recordId];
                return _driveService.query(query)
                .then(([drive]) => {
                    this.drive = drive;
                    this.originalDrive = drive;

                    if (!drive) {
                        throw 'Drive has not been generated';
                    }

                    if (drive.isSurrogate) {
                        throw 'Surrogate drive';
                    }
                    console.log('this.drive ', this.drive);
                })

            } else {
                let _driveService = new driveService();
                let query = new driveQueryModel();
                query.opportunityIds = [recordId];
                return _driveService.query(query)
                .then(([drive]) => {
                    this.drive = drive;

                    if (!drive) {
                        throw 'Drive has not been generated';
                    }
                    
                    if (drive.isSurrogate) {
                        throw 'Surrogate drive';
                    }
                })
            }
        }).then(() => {
            return slwcDriveGeneratorHelper.initialize(recordId)
            .then((result) => {
                driveGeneratorInstance = result.driveGeneratorInstance;
                return result.drive;
            })
        })
        .then((drive) => {
            this.drive = drive;
            return driveGeneratorInstance.checkAndApplyDriveChangeRequest();
        })
        .then(() => {
            return Promise.all([
                this.retrieveCustomSettings()
            ]);
        })
        .then(() => {
            this.initialized = true;
        })
        .catch(error => {
            if (typeof error !== 'string') {
                this.exceptionHandler(error);
            }
        })
        .finally(this.hideLoading);
    }
    
    handleChangeTab(event) {
        this.currentTab = event.target.value;
    }

    handleDriveChanged(event) {
        if (!event.detail.drive || !this.drive) return;

        if (event.detail.drive.id === this.drive.id) {
            this.drive = {
                ...this.drive,
                ...event.detail.drive
            }
        }

        if (this.isDirty === false && location.href.includes('sked_Drive__c') && !event.detail.changedFromApplyingDCRs && this.isSetUnsavedChangesDone === false) {
            this.isDirty = true;
            this.isSetUnsavedChangesDone = true;
            this.handleDirtyStateChanged(true);
        }
    }

    handleDirtyStateChanged(isDirty) {
        const dirtyStateEvent = new CustomEvent('dirtystatechanged', { detail: { isDirty } });
        this.dispatchEvent(dirtyStateEvent);
    }

    /** Handle button actions **/
    isValid() {
        fireEvent(this.pageRef, 'hideErrorPopover');

        let validator = new driveValidator(this.masterData);
        validator.validate(this.drive);

        this.drive.tabDetailsValidities = [];
        if (this.drive.validities.length) {
            this.drive.validities.forEach((item) => {
                if (this.tabDetailsValidationFields.indexOf(item.field) > -1) {
                    this.drive.tabDetailsValidities.push(item);
                }
            });
        }
        this.tabDetailsError = this.drive.tabDetailsValidities.length;
        this.tabShiftsError = false;
        this.drive.driveShifts.forEach((shift) => {
            if (!this.tabShiftsError && shift.validities.length) {
                this.tabShiftsError = true;
            }
        });
        let hasError = this.tabDetailsError || this.tabShiftsError;
        if (hasError) {
            fireEvent(this.pageRef, 'showErrorPopover');
        }

        return !hasError;
    }

    btnCloseClicked() {
        this.dispatchEvent(
            new CustomEvent(
                'close', 
                { 
                    composed: true, 
                    detail: {
                        message: 'close'
                    }
                })
        );
    }

    btnAllocateClicked() {
        let eventValues = { drive: this.drive };
        fireEvent(this.pageRef, 'openDriveStaffingDetails', eventValues);
    }

    btnCreateSurrogateDriveClicked() {
        const driveDate = DateTime.fromString(this.drive.driveDate, 'yyyy-MM-dd').toFormat('MM/dd/yyyy');
        const driveStartTime = this.formatTime(this.drive.startTime);
        const driveEndTime = this.formatTime(this.drive.endTime);

        this.showConfirmModal({
            title: 'Create Surrogate Drive Confirmation',
            message: `This will create a new Surrogate Drive with the following references:
                 - Account: ${this.drive.account.name}
                 - Site: ${this.drive.driveSite.name}
                 - Drive: ${this.drive.name}
                 - Drive Date: ${driveDate}
                 - Start Time: ${driveStartTime}
                 - End Time: ${driveEndTime}
                 - Opportunity: ${this.drive.opportunity.name}
                 - Type Of Drive: ${this.drive.typeOfDrive}

                Do you want to continue?`,

            onClose: (result) => {
                this.hideConfirmModal();
                if (result) {
                    this.handleCreateSurrogateDrive();
                }
            }
        });
    }

    handleCreateSurrogateDrive() {
        this.showLoading();

        let surrogateDrive = {
            name: this.driveHelper.truncateDriveName('Surrogate Drive for ' + this.drive.name),
            accountId: this.drive.accountId,
            driveDate: this.drive.driveDate,
            minShiftStart: this.drive.minShiftStart,
            maxShiftEnd: this.drive.maxShiftEnd,
            startTime: this.drive.startTime,
            endTime: this.drive.endTime,
            driveSiteId: this.drive.driveSiteId,
            opportunityId: this.drive.opportunityId,
            surrogateDriveForId: this.drive.id,
            status: DRIVE_STATUS.CONFIRMED,
            typeOfDrive: this.drive.typeOfDrive //HRP-16053
        }
        let service = new driveService();
        service.save(surrogateDrive)
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    message: 'Surrogate Drive was created successfully.',
                    variant: 'success',
                    mode: 'dismissable',
                }));
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading);
    }

    btnSaveDraftClicked(event, saveAndApproveApprovalIfAny = false) {
        this.showErrors = true;
        if (this.isValid() === true) {
            this.handleSave(saveAndApproveApprovalIfAny);
        }
    }
    
    btnSubmitClicked() {
        this.showErrors = true;
        if (this.isValid() === true) {
            this.handleSubmit();
        }
    }

    btnRemoveHoldClicked() {
        this.showConfirmModal({
            title: 'Remove Hold Confirmation',
            message: `Are you sure you want to remove hold this Drive?\nNotes: System will release all allocations and put this Drive back to Draft.`,

            onClose: (result) => {
                this.hideConfirmModal();
                if (result) {
                   this.handleRemoveHold();
                }
            }
        });
    }

    btnHoldClicked() {
        this.showErrors = true;
        if (this.isValid() === true) {
            this.showConfirmModal({
                title: 'Hold Drive Confirmation',
                message: `Are you sure you want to hold this Drive?`,
    
                onClose: (result) => {
                    this.hideConfirmModal();
                    if (result) {
                       this.handleHoldDrive();
                    }
                }
            });        
        }
    }
    
    btnApproveDCRClicked() {
        this.btnSaveClicked();
    }

    btnApproveDriveSubmissionClicked() {
        if (!this.showApproveDriveSubmissionBtn) return;

        if ([DRIVE_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL,
            DRIVE_APPROVAL_STATUS.DM_WAITING_FOR_DRD_FEEDBACK].includes(this.drive.approvalStatus)) {
            //save draft & approve
            this.btnSaveDraftClicked(null, true);
        } else {
            this.btnSaveClicked();
        }
    }

    requiresAssetValidation() {        
        let requiresAssetValidation = false;
        requiresAssetValidation = this.driveHelper.checkForChangesToDrive(this.drive, this.masterData.backupDrive);
        
        if (!requiresAssetValidation) { 
            requiresAssetValidation = this.driveHelper.checkForChangesToDriveJobs(this.drive, this.masterData.backupDrive);
        }

        if (!requiresAssetValidation) { 
            requiresAssetValidation = this.driveHelper.checkForChangesToDriveShifts(this.drive, this.masterData.backupDrive);
        }

        if (this.showApproveDriveSubmissionBtn) {
            requiresAssetValidation = true;
        }

        return requiresAssetValidation;
    }

    requireTimeBlockValidation() {
        let requireTimeBlockValidation = false;

        // Check if drive uses time blocks and if any shift has empty TimeBlock
        if (this.driveHelper.isDriveUseTimeBlock(this.drive, this.masterData)) {
            requireTimeBlockValidation = this.drive.driveShifts.some(shift => !shift.timeBlockId);
        }

        // Check if any shift has "Out Of Time Block" contention without proper resolution
        if (!requireTimeBlockValidation) {
            requireTimeBlockValidation = this.drive.driveShifts.some(shift => {
                const hasOutOfTimeBlockContention = shift.contention && 
                    shift.contention.includes(DRIVE_SHIFT_TIME_BLOCK_CONTENTION.OUT_OF_TIME_BLOCK);
                const hasAcknowledgementResolution = shift.contentionResolution && 
                    shift.contentionResolution.includes('Elect to acknowledge the drive shift is out of Time Block');
                
                return hasOutOfTimeBlockContention && !hasAcknowledgementResolution;
            });
        }

        return requireTimeBlockValidation;
    }

    btnSaveClicked() {
        this.showErrors = true;
        if (this.isValid() === true) {
            if (!this.requiresAssetValidation() && !this.requireTimeBlockValidation()) {
                return this.handleSave();
            }

            this.showLoading();
            return Promise.resolve()
                .then(() => {
                    return driveGeneratorInstance.validateCurrentAssignedAssets([], this.showApproveDriveSubmissionBtn)
                        .then(({ allAssignedEquipmentsValid, newEquipmentJobsMap, lockedEquipments = [], allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
                        //equipments
                        return Promise.resolve()
                        .then(() => {
                            if (!allAssignedEquipmentsValid) {
                                return driveGeneratorInstance.onDriveDataChanged([{
                                    targetName: 'totalEquipmentRequestedChanged',
                                    targetValue: {
                                        equipmentJobsMap: newEquipmentJobsMap,
                                        lockedEquipments: lockedEquipments
                                    }
                                }])
                            }
                        })
                        .then(() => {
                            return {
                                allAssignedVehiclesValid, 
                                newVehicles,
                                lockedVehicles, 
                                canHandleDriveProjectedRegisteredDonors
                            }
                        })
                    })
                    .then(({ allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
                        //vehicles
                        if (!canHandleDriveProjectedRegisteredDonors) {
                            Promise.resolve()
                            .then(() => {
                                return driveGeneratorInstance.onDriveDataChanged([{
                                    targetName: 'totalVehicleRequestedChanged',
                                    targetValue: {
                                        totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                        vehicles: newVehicles,
                                        lockedVehicles: lockedVehicles
                                    }
                                }])
                            })
                            .then(() => {
                                return this.handleValidate();
                            })
                            
                            throw "break";
                        }

                        if (!allAssignedVehiclesValid && canHandleDriveProjectedRegisteredDonors) {
                            let currentNoOfVehicles = this.drive.totalVehicleRequested;
                            if (!this.drive.preferSystemGeneratedVehicles) {
                                driveGeneratorInstance.onDriveDataChanged([{
                                    targetName: 'totalVehicleRequestedChanged',
                                    targetValue: {
                                        totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                        vehicles: newVehicles,
                                        lockedVehicles: lockedVehicles
                                    }
                                }])
                                .then(() => {
                                    return this.handleValidate();
                                })


                                throw 'break';
                            }
                            
                            if (currentNoOfVehicles !== (newVehicles.length + lockedVehicles.length)) {
                                this.showConfirmModal({
                                    title: 'Drive Confirmation',
                                    message: 'Number of Vehicles changes. Please review again.',
                                    confirmBtnLabel: 'OK',
                                    cancelBtnLabel: 'none',
                                    onClose: () => {
                                        this.hideConfirmModal();
                                        driveGeneratorInstance.onDriveDataChanged([{
                                            targetName: 'numberOfVehicles',
                                            targetValue: newVehicles.length + lockedVehicles.length
                                        }, {
                                            targetName: 'totalVehicleRequestedChanged',
                                            targetValue: {
                                                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                                vehicles: newVehicles,
                                                lockedVehicles: lockedVehicles
                                            }
                                        }])
                                    }
                                });
                            } else {
                                Promise.resolve()
                                .then(() => {
                                    return driveGeneratorInstance.onDriveDataChanged([{
                                        targetName: 'totalVehicleRequestedChanged',
                                        targetValue: {
                                            totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                            vehicles: newVehicles,
                                            lockedVehicles: lockedVehicles
                                        }
                                    }])
                                })
                                .then(() => {
                                    return this.handleValidate();
                                })
                            }
                            
                            throw "break";
                        }
                    })
                })
                .then(() => {
                    return this.handleValidate();
                })
                .catch(error => {
                    if (error !== 'break') {
                        this.exceptionHandler(error);
                    }
                })
                .finally(this.hideLoading);
        }
    }

    handleSubmit() {
        this.showLoading();
        const service = new driveService();
        service.validateDraftDrive({
            request: {
                driveId: this.drive.id
            }
        })
        .then(() => {
            return driveGeneratorInstance.submitDrive();
        })
        .then(({ showReviewDriveMessage, drive: newDrive }) => {
            this.drive = newDrive;

           if (showReviewDriveMessage) {
                this.showConfirmModal({
                    title: 'Drive Changed',
                    message: `The drive has changed. Please review and submit again.`,
                    cancelBtnLabel: 'none',
                    confirmBtnLabel: 'OK',
                    onClose: (result) => {
                        this.hideConfirmModal();
                    }
                });
            } else {
                this.handleValidate()
            }
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading)
    }

    handleValidate() {
        this.showLoading();
        return driveGeneratorInstance.validateDrive()
        .then((newDrive) => {
            this.drive = newDrive;
            let pendingActionReasonCodes = this.drive.pendingActionReasonCode ? this.drive.pendingActionReasonCode.split(';') : [];
            if (pendingActionReasonCodes.length > 0) {
                this.showPendingActionDriveConfirmModal();
            } else {
                this.drive.status = [DRIVE_STATUS.DRAFT].includes(this.drive.status) ? DRIVE_STATUS.TENTATIVE : this.drive.status;
                this.handleSave();
            }
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading)
    }

    handleSave(saveAndApproveApprovalIfAny = true) {
        this.showLoading();
        
        const isAPSUser = this.driveHelper.isAPSUser(this.masterData.loginUser);
        const needToApproveApprovalIfAny = saveAndApproveApprovalIfAny && isAPSUser;

        if (this.drive.status === DRIVE_STATUS.DRAFT) {
            this.drive = driveGeneratorInstance.releaseAllAssetAllocations();
        }
        
        let drivesToSave = [];
        let model = { ...this.drive };
        drivesToSave.push(model);

        let newDriveId = null;
        let service = new driveService();
        return service.saveList(drivesToSave)
            .then(result => {
                let drive = result.returnedData[0];
                newDriveId = drive.Id;
            })
            .then(() => {
                //approve drive submission if needed
                if (!needToApproveApprovalIfAny) return;
                if (!this.driveHelper.isDriveSubmittedForSubmissionApproval(this.drive)) return;

                const request = {
                    recordId: this.drive.id,
                    action: 'Approve'
                };
                
                const _approvalService = new approvalService();
                return _approvalService.approveReject({ request: request })
                .then(() => {
                    if (isAPSUser && (this.drive.approvalStatus === DRIVE_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL ||
                        this.drive.approvalStatus === DRIVE_APPROVAL_STATUS.DM_WAITING_FOR_DRD_FEEDBACK)) {
                        return _approvalService.approveReject({ request: request })
                    }
                });
            })
            .then(() => {
                //approve DCR if needed
                if (!needToApproveApprovalIfAny) return;
                if (!this.showDCRWarning || !(driveGeneratorInstance.masterData.waitingDriveChangeRequest)) {
                    return;
                }
                
                const request = {
                    recordId: driveGeneratorInstance.masterData.waitingDriveChangeRequest.id,
                    action: 'Approve'
                };
                
                const _approvalService = new approvalService();
                return _approvalService.approveReject({ request: request })
                .then(() => {
                    if (isAPSUser && (driveGeneratorInstance.masterData.waitingDriveChangeRequest.status === DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL || 
                        driveGeneratorInstance.masterData.waitingDriveChangeRequest.status === DRIVE_REQUEST_CHANGE_STATUS.DM_WAITING_FOR_DRD_FEEDBACK)) {
                        return _approvalService.approveReject({ request: request })
                        }
                });
            })
            .then(() => {
                if (!this.isFixedSiteDrive && !this.isWbFixedSiteDrive) return;
                return driveGeneratorInstance.calculateRecurrenceSlots(model)
                .then((drivesToSave = []) => {
                    if (!drivesToSave.length) return;

                    const driveSvc = new driveService();
                    const slotSvc = new slotService();
                    const promises = chunk(drivesToSave, 50).map(chunkDrives => {
                        return () => {
                            let slotsToSave = [];
                            let slotsToDelete = [];
                            let drives = [];
                            chunkDrives.forEach(drive => {
                                slotsToSave = slotsToSave.concat(drive.slotsToSave || []);
                                slotsToDelete = slotsToDelete.concat(drive.slotsToDelete || []);
                                drives.push({
                                    id: drive.id,
                                    totalSlots: drive.totalSlots
                                })
                            });

                            return Promise.resolve()
                            .then(() => {
                                if (slotsToDelete.length > 0) {
                                    return slotSvc.deleteList(slotsToDelete);
                                }
                            })
                            .then(() => {
                                if (slotsToSave.length > 0) {
                                    return slotSvc.saveList(slotsToSave);
                                }
                            })
                            .then(() => {
                                if (drives.length > 0) {
                                    return driveSvc.saveList(drives);
                                }
                            });
                        }
                    });
                
                    return slwcUtils.serial(promises);
                })
            })
            .then(() => {
                if (!this.isFixedSiteDrive && !this.isWbFixedSiteDrive) return;
                return driveGeneratorInstance.calculateRecurrenceVolunteerJobs(model)
                    .then((jobsToSave = []) => {
                        if (!jobsToSave.length) return;

                        const jobSvc = new jobService();
                        const promises = chunk(jobsToSave, 50).map(chunkJobs => {
                            return () => {
                                return jobSvc.saveList(chunkJobs);
                            }
                        });
                        return slwcUtils.serial(promises);
                    })
            })
            .then(() => {
                if (!this.isFixedSiteDrive && !this.isWbFixedSiteDrive) return;
                return driveGeneratorInstance.calculateRecurrenceNewVolunteerJobs(model)
                    .then((jobsToSave = []) => {
                        if (!jobsToSave.length) return;

                        const jobSvc = new jobService();
                        const promises = chunk(jobsToSave, 50).map(chunkJobs => {
                            return () => {
                                return jobSvc.saveList(chunkJobs);
                            }
                        });
                        return slwcUtils.serial(promises);
                    })
            })
            .then(() => {
                let message = `Drive ${this.drive.name} was ${this.drive.id ? 'saved' : 'created'}.`;
          
                this.dispatchEvent(new ShowToastEvent({
                    message: message,
                    variant: 'success',
                    mode: 'dismissable',
                }));

                this.handleDirtyStateChanged(false);

                this.handleNavigateToRecord();
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading);
    }

    handleHoldDrive() {
        this.showLoading();
        driveGeneratorInstance.submitDrive()
            .then(({ showReviewDriveMessage, drive: newDrive }) => {
            this.drive = newDrive;

            return driveGeneratorInstance.validateDrive()
            .then((newDrive) => {
                this.drive = newDrive;
                let pendingActionReasonCodes = this.drive.pendingActionReasonCode ? this.drive.pendingActionReasonCode.split(';') : [];
                const contentionsPreventHold = [
                    'Insufficient Resources',
                    'Lacking of vehicles',
                    'Lacking of equipment',
                    'Exceeds Operational Drive Limit',
                    'Exceeds 2RBC Operational Limit',
                    'Excess Staff Capacity',
                    DRIVE_SHIFT_TIME_BLOCK_CONTENTION.OUT_OF_TIME_BLOCK,
                    DRIVE_SHIFT_TIME_BLOCK_CONTENTION.FIT_MULTIPLE_TIME_BLOCKS,
                    DRIVE_SHIFT_TIME_BLOCK_CONTENTION.MISSING_TIME_BLOCK
                ];
                const anyContentionsPreventHold = pendingActionReasonCodes.filter(pendingActionReasonCode => {
                    return contentionsPreventHold.includes(pendingActionReasonCode);
                })

                if (anyContentionsPreventHold.length > 0) {
                    this.showConfirmModal({
                        title: 'Cannot Hold Drive',
                        message: `Cannot hold this Drive due to below contentions:
                            ${anyContentionsPreventHold.map(contention => {
                                return ` - ${contention}`;
                            }).join('\n')}
                        `,
                        confirmBtnLabel: 'OK',
                        cancelBtnLabel: 'none',
                        onClose: () => {
                            this.hideConfirmModal();
                        }
                    });
                } else {
                    this.drive = driveGeneratorInstance.holdDrive();
                    this.handleSave();
                }
            })
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading)
    }

    handleRemoveHold() {
        this.showLoading();

        let service = new driveService();
        return service.save({
            id: this.drive.id,
            status: DRIVE_STATUS.DRAFT
        })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    message: `Drive ${this.drive.name} was saved.`,
                    variant: 'success',
                    mode: 'dismissable',
                }));

                this.handleNavigateToRecord();
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading);
    }

    handleNavigateToRecord() {
        this.handleDirtyStateChanged(false);
        this.isSetUnsavedChangesDone = false;
        this.isDirty = false;
        if (this.showCloseButton) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    onDriveDataChanged(event) {
        if (event.stopPropagation) {
            event.stopPropagation();
        }
        const detail = event.detail;

        console.log('on drive data changed' + detail.cmpName);
        if (this.isDirty === false && location.href.includes('sked_Drive__c') && this.isSetUnsavedChangesDone === false) {
            this.isDirty = true;
            this.isSetUnsavedChangesDone = true;
            this.handleDirtyStateChanged(true);
        }
        if (detail.cmpName == 'slwcDriveDetails' || detail.cmpName == 'slwcDriveCompactView' || detail.cmpName == 'slwcDriveMarketing') {
            let driveChanges = [];
            detail.properties.forEach((property) => {
                let targetValue = property.targetValue;
                if (property.targetName == 'projectedRegisteredDonors'
                    || property.targetName == 'x2rbcProjectedProcedures'
                    || property.targetName == 'wbProjectedProcedures'
                    || property.targetName == 'plateletProjectedProcedures'
                    || property.targetName == 'plasmaProjectedProcedures'
                    || property.targetName == 'numberOf2rbcAssets'
                    || property.targetName == 'numberOfPlateletAssets'
                    || property.targetName == 'numberOfPlasmaAssets'
                    || property.targetName == 'numberOfVehicles') {
                    targetValue = Number(targetValue);
                }
                driveChanges.push(
                    {
                        targetName: property.targetName,
                        targetValue: targetValue
                    }
                )
            });
            
            this.showLoading();
            return Promise.resolve()
                .then(() => {
                    return driveGeneratorInstance.validateCurrentAssignedAssets(driveChanges)
                    .then(({ allAssignedEquipmentsValid, newEquipmentJobsMap, lockedEquipments = [], allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
                        //equipments
                        return Promise.resolve()
                        .then(() => {
                            if (!allAssignedEquipmentsValid) {
                                return driveGeneratorInstance.onDriveDataChanged([...event.detail.properties, {
                                    targetName: 'totalEquipmentRequestedChanged',
                                    targetValue: {
                                        equipmentJobsMap: newEquipmentJobsMap,
                                        lockedEquipments: lockedEquipments
                                    }
                                }])
                            }
                        })
                        .then(() => {
                            return {
                                allAssignedVehiclesValid, 
                                newVehicles,
                                lockedVehicles,
                                canHandleDriveProjectedRegisteredDonors
                            }
                        })
                    })
                    .then(({ allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
                        //vehicles
                        if (!canHandleDriveProjectedRegisteredDonors) {
                            driveGeneratorInstance.onDriveDataChanged([...event.detail.properties, {
                                targetName: 'totalVehicleRequestedChanged',
                                targetValue: {
                                    totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                    vehicles: newVehicles,
                                    lockedVehicles: lockedVehicles
                                }
                            }])
                            
                            throw "break";
                        }

                        if (!allAssignedVehiclesValid && canHandleDriveProjectedRegisteredDonors) {
                            let currentNoOfVehicles = this.drive.totalVehicleRequested;
                            if (!this.drive.preferSystemGeneratedVehicles) {
                                driveGeneratorInstance.onDriveDataChanged([...event.detail.properties, {
                                    targetName: 'totalVehicleRequestedChanged',
                                    targetValue: {
                                        totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                        vehicles: newVehicles,
                                        lockedVehicles: lockedVehicles
                                    }
                                }])

                                throw 'break';
                            }

                            if (currentNoOfVehicles !== (newVehicles.length + lockedVehicles.length)) {
                                this.showConfirmModal({
                                    title: 'Drive Confirmation',
                                    message: 'Number of Vehicles changes. Please review again.',
                                    confirmBtnLabel: 'OK',
                                    cancelBtnLabel: 'none',
                                    onClose: () => {
                                        this.hideConfirmModal();
                                        driveGeneratorInstance.onDriveDataChanged([...event.detail.properties, {
                                            targetName: 'numberOfVehicles',
                                            targetValue: newVehicles.length + lockedVehicles.length
                                        }, {
                                            targetName: 'totalVehicleRequestedChanged',
                                            targetValue: {
                                                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                                vehicles: newVehicles,
                                                lockedVehicles: lockedVehicles
                                            }
                                        }])
                                    }
                                });
                            } else {
                                driveGeneratorInstance.onDriveDataChanged([...event.detail.properties, {
                                    targetName: 'totalVehicleRequestedChanged',
                                    targetValue: {
                                        totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                                        vehicles: newVehicles,
                                        lockedVehicles: lockedVehicles
                                    }
                                }])
                            }
                            
                            throw "break";
                        }
                    })
                })
                .then(() => {
                    return driveGeneratorInstance.onDriveDataChanged(driveChanges);
                })
                .catch(error => {
                    if (error !== 'break') {
                        this.exceptionHandler(error);
                    }
                })
                .finally(this.hideLoading);
        }
        else if (detail.cmpName == 'slwcDriveShifts') {
            console.log('here in change slwcDriveShifts');
            let driveShiftChanges = [];
            console.log('detail.properties ',detail.properties);
            detail.properties.forEach((property) => {
                let targetValue = property.targetValue;
                driveShiftChanges.push(
                    {
                        targetName: property.targetName,
                        targetValue: targetValue
                    }
                )
            });

            this.showLoading();
            return driveGeneratorInstance.onDriveShiftDataChanged(detail.key, driveShiftChanges)
                .catch(error => this.exceptionHandler(error))
                .finally(this.hideLoading);
        }
    }

    /* Drive Staffings **/
    handleOpenDriveStaffingDetails(detail) {
        const { drive } = detail;
        this.driveSideMenuData = {
            shown: true,
            recordId: drive.id
        }
    }

    handleCloseDriveStaffingDetails() {
        this.driveSideMenuData = {
            shown: false,
            recordId: ''
        }
    }

    handleSaveDriveStaffingDetails() {
        // this.handleCloseDriveStaffingDetails();
        this.initialize(this.recordId);
    }

    handleDispatchedDriveStaffingDetails() {
        this.initialize(this.recordId);
    }

    /** Drive Delivery Jobs **/
    handleSaveDeliveryJob(detail) {
        driveGeneratorInstance.saveDriveDeliveryJob(detail.driveDeliveryJobs);
    }

    handleDeleteDriveDeliveryJob(detail) {
        driveGeneratorInstance.deleteDriveDeliveryJob(detail.driveDeliveryJobs);
    }

    /** Drive Shift Slots **/
    handleResetAppointments(event) {
        if (!event.detail.driveShift) return;
        
        driveGeneratorInstance.resetSlots(event.detail.driveShift.key);
    }

    handleRegenerateAppointments(event) {
        if (!event.detail.driveShift) return;
        
        driveGeneratorInstance.regenerateSlots(event.detail.driveShift.key);
    }

    handleSaveAppointment(event) {
        if (!event.detail.driveShift || !event.detail.slotKey) return;
        
        if (event.detail.action === 'delete') {
            driveGeneratorInstance.deleteSlot(event.detail.driveShift.key, {
                ...event.detail.newSlot,
                key: event.detail.slotKey
            })
        } else if (event.detail.action === 'unlock') {
            driveGeneratorInstance.saveSlot(event.detail.driveShift.key, {
                ...event.detail.newSlot,
                locked: false,
                fixedSiteLockReason: '',
                fixedSiteLockComment: '',
                key: event.detail.slotKey
            }, event.detail.action)
        } else {
            driveGeneratorInstance.saveSlot(event.detail.driveShift.key, {
                ...event.detail.newSlot,
                key: event.detail.slotKey
            })
        }
    }

    handleDeleteAppointment(event) {
        if (!event.detail.driveShift || !event.detail.slotKey) return;
        
        driveGeneratorInstance.deleteSlot(event.detail.driveShift.key, {
            key: event.detail.slotKey
        })
    }

    /** Drive Shift Tags **/
    handleSaveDriveShiftTag(detail) {
        if (!detail.driveShift || !detail.driveShiftTag) return;
        
        driveGeneratorInstance.saveDriveShiftTag(detail.driveShift.key, detail.driveShiftTag)
    }

    handleDeleteDriveShiftTag(detail) {
        if (!detail.driveShift || !detail.driveShiftTag) return;
        
        driveGeneratorInstance.deleteDriveShiftTag(detail.driveShift.key, detail.driveShiftTag)
    }

    /** Drive Shift Resource Requirement **/
    handleDeleteJob(detail) {
        driveGeneratorInstance.deleteJob(detail.driveShift ? detail.driveShift.key : detail.shiftKey, detail.job);
    }

    handleSaveJob(detail) {
        driveGeneratorInstance.saveJob(detail.shiftKey, detail.job);
    }

    handleSaveBulkEditVolunteerJobModal(detail) {
        driveGeneratorInstance.saveBulkEditVolunteerJob(detail.shiftKey, detail.job);
    }

    handleSaveBulkAddVolunteerJobModal(detail) {
        driveGeneratorInstance.saveBulkAddVolunteerJob(detail.shiftKey, detail.job);
    }

    /** Confirm Modal **/
    showConfirmModal(confirmModalData) {
        this.confirmModalData = {
            ...confirmModalData,
            isOpen: true,
            confirmBtnLabel: confirmModalData.confirmBtnLabel || 'Yes',
            cancelBtnLabel: confirmModalData.cancelBtnLabel || 'No',
        }
    }
    
    hideConfirmModal() {
        this.confirmModalData = {};
    }

    /** Pending Action Drive Confirm Modal **/
    showPendingActionDriveConfirmModal(pendingActionDriveConfirmModalData) {
        this.pendingActionDriveConfirmModalData = {
            ...pendingActionDriveConfirmModalData,
            isOpen: true
        }
    }
    
    hidePendingActionDriveConfirmModal() {
        this.pendingActionDriveConfirmModalData = {};
    }

    savePendingActionDriveConfirmModal(event) {
        this.hidePendingActionDriveConfirmModal();

        const { submissionNotes, contentionResolution, driveShiftContention, driveShiftTimeBlockId, driveShiftContentionResolution, status, equipmentAllocations, vehicleAllocations } = event.detail;
        this.drive.submissionNotes = submissionNotes || this.drive.submissionNotes;
        if (status) {
            this.drive.status = status;
        }
        this.drive.contentionResolution = contentionResolution;

        if(driveShiftContentionResolution?.length) {
            this.drive.driveShifts.forEach((driveShift, driveShiftIndex) => {
                driveShift.contentionResolution = driveShiftContentionResolution[driveShiftIndex] ?? '';
            })
        }

        if(driveShiftContention?.length) {
            this.drive.driveShifts.forEach((driveShift, driveShiftIndex) => {
                driveShift.contention = driveShiftContention[driveShiftIndex] ?? '';
            })
        }

        if(driveShiftTimeBlockId?.length) {
            this.drive.driveShifts.forEach((driveShift, driveShiftIndex) => {
                driveShift.timeBlockId = driveShiftTimeBlockId[driveShiftIndex] ?? '';
            })
        }
        
        if (this.drive.status === DRIVE_STATUS.DRAFT) {
            this.drive = driveGeneratorInstance.releaseAllAssetAllocations();
        }

        if (this.drive.status !== DRIVE_STATUS.DRAFT) {
            if (equipmentAllocations) {
                let equipmentJob = this.drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
                equipmentJob.jobAllocations = [...equipmentAllocations];
            }

            if (vehicleAllocations) {
                let vehicleJob = this.drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.VEHICLE);
                vehicleJob.jobAllocations = [...vehicleAllocations];
            }
        }
        
        this.handleSave();
    }

    /* Drive Shifts Metadata Modal */
    showDriveShiftsMetadataModal() {
        this.driveShiftsMetadataModalData = {
            isOpen: true
        }
    }

    hideDriveShiftsMetadataModal() {
        this.driveShiftsMetadataModalData = {};
    }
    
    saveDriveShiftsMetadataModal(event) {
        const { detail } = event;
        let { driveShiftsMetadata } = detail;

        driveGeneratorInstance.onDriveDataChanged([{
            targetName: 'driveShiftsMetadata',
            targetValue: driveShiftsMetadata
        }])
    }

    /** Dual Role Assignment Modal */
    handleSaveDualRoleAssignmentModal(detail) {
        const { driveShift, jobsToCreate, jobsToUpdate, jobsToDelete } = detail;
        driveGeneratorInstance.saveJobDualRole(driveShift.key, jobsToCreate, jobsToUpdate, jobsToDelete);
    }

    formatTime(time) {
        if (!time) {
            return '';
        }
        return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
    }

    retrieveCustomSettings() {
        let settingKeys = ["adminSetting"];
        return Promise.resolve()
            .then(() => {
                let service = new dataService();
                return service.getCustomSettings({ settingKeys: settingKeys })
                    .then((result) => {
                        this.adminSettings = result.returnedData.adminSetting;
                    })
            });
    }
}