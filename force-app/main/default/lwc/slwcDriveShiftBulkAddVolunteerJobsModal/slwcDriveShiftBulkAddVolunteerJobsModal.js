import { debugLogService, driveQueryModel, driveService, jobQueryModel, jobService, sObjectType } from 'c/dataService';
import { cloneDeep, groupBy } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { DRIVE_TYPE, DRIVE_STATUS, OPERATION_TYPE, VOLUNTEER_COUNTS_ADJUSTMENT_REASON } from 'c/slwcConstants';
import { DriveHelper } from 'c/slwcDriveGenerator';
import * as slwcUtils from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, track, wire } from 'lwc';

const STEP = {
    STEP_1: 'step1',
    STEP_2: 'step2'
}

export default class SlwcDriveShiftBulkAddVolunteerJobsModal extends LightningElement {
    helper = new DriveHelper();

    /* api */
    @api job;
    @api action;
    @api drive;
    @api driveShift;
    @api resourceType;
    @api type;

    @track showModal = false;
    @track showSpinner = false;
    @track step = STEP.STEP_1;
    @track model = {};
    @track errorMessages = [];
    @track recurrenceDatesPickerModalData = {};

    @wire(CurrentPageReference) pageRef;
    masterData = {};

    get modalHeader() {
        return 'Bulk Add Volunteer Jobs';
    }

    get modalSize() {
        if(this.step === STEP.STEP_2) return 'medium';
        return 'base'
    }

    get modalSaveBtnLabel() {
        if(this.step === STEP.STEP_1) return 'Next';
        return 'Save'
    }

    get modalCancelBtnLabel() {
        if(this.step === STEP.STEP_2) return 'Back';
        return 'Cancel'
    }

    get appointmentAlertMessage() {
        return "Volunteer additions will only be applied to drives with no issues.";
    }

    get appointmentAlertInstructionMessage() {
        return "To add a volunteer on a drive with a pending issue, resolve the issue and come back to this screen to confirm the addition on the drive.";
    }

    get isOtherVolunteerAdjustmentReasonSelected() {
        return this.model?.volunteerAdjustmentReason === VOLUNTEER_COUNTS_ADJUSTMENT_REASON.OTHER;
    }

    get showStep1() {
        return this.step === STEP.STEP_1;
    }

    get showStep2() {
        return this.step === STEP.STEP_2;
    }

    get modalOverflowInitial() {
        return this.showStep1;
    }

    connectedCallback() {
        registerListener('showBulkAddVolunteerJobsModal', this.handleShowModal, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    exceptionHandler = (error) => {
        new debugLogService().captureDebugLog(error, this.drive?.id);
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }

    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }

    closeModal() {
        fireEvent(this.pageRef, 'closeBulkAddVolunteerJobsModal');
        this.showModal = false;
    }

    handleOnChange(event) {
        const name = event.target.name
        this.model[name] = slwcUtils.getValueFromEvent(event);
    }

    handleCloseModal() {
        if(this.step === STEP.STEP_2) {
            return this.handleBack();
        }

        this.closeModal();
    }

    handleShowModal(detail) {
        this.showLoading();
        Promise.resolve()
            .then(() => {
                this.showModal = true;
                this.step = STEP.STEP_1;
                this.action = detail.action;
                this.resourceType = detail.resourceType;
                this.type = detail.type;
                this.driveShift = detail.driveShift;
                this.drive = detail.drive;
                this.job = detail.job;
                this.masterData = detail.masterData;
                this.errorMessages = [];

                this.model.isLocked = !!this.job.isLocked;
                this.model.redcrossVolunteerQuantity = null;
                this.model.volunteerRole = '';
                this.model.volunteerAdjustmentReason = '';
                this.model.otherVolunteerAdjustmentReason = '';
                this.model.recurrenceDates = cloneDeep((this.job.bulkAddVolunteerJobsSelectedDrives || []).map(d => d.driveDate)) ?? [];
                this.model.recurrenceDriveIds = cloneDeep((this.job.bulkAddVolunteerJobsSelectedDrives || []).map(d => d.driveId)) ?? [];
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading);
    }

    validateStep1() {
        this.errorMessages = [];

        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('c-slwc-picklist')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (slwcUtils.isNullOrEmpty(this.model.volunteerRole)) {
            this.errorMessages.push({
                message: 'Volunteer Role is required.'
            })
        }

        if (slwcUtils.isNullOrEmpty(this.model.redcrossVolunteerQuantity) || this.model.redcrossVolunteerQuantity < 0) {
            this.errorMessages.push({
                message: 'Red Cross Volunteer Quantity must be greater than or equal to 0.'
            })
        }

        if (!this.model.recurrenceDates?.length) {
            this.errorMessages.push({
                message: 'Please select at least 1 recurrence day.'
            })
        }

        // Check if the volunteer role already exists on the current drive shift
        if (this.driveShift?.jobs?.find(job => job.volunteerRole === this.model.volunteerRole)) {
            this.errorMessages.push({
                message: `${this.model.volunteerRole} role already exists.`
            });
        }

        if (this.errorMessages.length) return false;

        return allValid;
    }

    handleSaveStep1() {
        if(!this.validateStep1()) return;
        this.initStep2();
    }

    populateDaysWithDrives(drives = [], existingJobs = []) {
        const mapJobsByDriveId = groupBy(existingJobs, 'driveId');
        const mapDrivesByDate = groupBy(drives, 'driveDate');
        const today = DateTime.fromObject({ zone: this.masterData?.timezoneSidId }).toISODate();

        this.model.daysWithDrives = [...this.model.recurrenceDates]
            .filter(d => d >= today)
            .sort()
            .map(dateIso => {
                const drivesForDate = (mapDrivesByDate[dateIso] || []).map(drive => {
                    const driveJobs = mapJobsByDriveId[drive.id] || [];
                    const hasRoleExist = driveJobs.some(job => job.volunteerRole === this.model.volunteerRole);

                    return {
                        ...drive,
                        driveRecordUrl: '/' + drive.id,
                        errorMessages: hasRoleExist ? ['Role already exists'] : []
                    };
                });

                // The current drive is excluded from the query to prevent duplicate insertion,
                // but it will receive a new job via saveBulkAddVolunteerJob. Show it in the
                // review table so the user can see all affected drives.
                if (dateIso === this.drive?.driveDate) {
                    drivesForDate.unshift({
                        id:             this.drive.id,
                        name:           this.drive.name,
                        status:         this.drive.status,
                        driveRecordUrl: '/' + this.drive.id,
                        isCurrentDrive: true,
                        errorMessages:  []
                    });
                }

                return { dateIso, drives: drivesForDate };
            });
    }

    initStep2() {
        this.showLoading();
        let fetchedDrives = [];
        Promise.resolve()
            .then(() => {
                const driveSvc = new driveService();
                const driveQuery = new driveQueryModel();
                const today = DateTime.fromObject({ zone: this.masterData?.timezoneSidId }).toISODate();

                driveQuery.selectedDates = this.model.recurrenceDates.filter(d => d >= today);
                driveQuery.eventTypes = [DRIVE_TYPE.FIXED_SITE];
                driveQuery.operationTypes = [OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH, OPERATION_TYPE.NON_INTEGRATED_WB];
                driveQuery.collectionOpIds = [this.drive.collectionOperationId];
                driveQuery.locationIds = [this.drive.driveSiteId];
                driveQuery.excludedIds = [this.drive.id];
                driveQuery.subQueryIndicator = sObjectType.DRIVE_SHIFT;
                driveQuery.statuses = [
                    DRIVE_STATUS.SYSTEM_GENERATED,
                    DRIVE_STATUS.TENTATIVE,
                    DRIVE_STATUS.CONFIRMED,
                    DRIVE_STATUS.HOLD
                ];

                return driveSvc.query(driveQuery);
            })
            .then((drives) => {
                fetchedDrives = drives;
                const driveIds = drives.map(d => d.id);
                if (!driveIds.length) return [];

                const jobSvc = new jobService();
                const jobQuery = new jobQueryModel();

                jobQuery.driveIds = driveIds;
                jobQuery.isVounteerRole = true;

                return jobSvc.query(jobQuery);
            })
            .then((existingJobs) => {
                this.populateDaysWithDrives(fetchedDrives, existingJobs);
            })
            .then(() => {
                this.step = STEP.STEP_2;
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading);
    }

    handleBack() {
        this.step = STEP.STEP_1;
    }

    handleSaveModal() {
        if(this.step === STEP.STEP_1) {
            return this.handleSaveStep1();
        }

        const redcrossVolunteerQuantity = Number(this.model.redcrossVolunteerQuantity);
        const sponsorVolunteerQuantity = Number(this.job.sponsorVolunteerQuantity || 0);
        const quantity = redcrossVolunteerQuantity + sponsorVolunteerQuantity;
        const bulkAddVolunteerJobsSelectedDrives = (this.model.daysWithDrives || []).reduce((acc, day) => {
            acc.push(...day.drives
                .filter(drive => !drive.errorMessages.length && !drive.isCurrentDrive)
                .map(drive => ({
                    driveId:          drive.id,
                    driveShiftId:     drive.driveShifts?.[0]?.id,
                    driveShiftStart:  drive.driveShifts?.[0]?.start,
                    driveShiftFinish: drive.driveShifts?.[0]?.finish,
                    driveSiteId:      drive.driveSiteId,
                    driveDate:        drive.driveDate
                }))
            );
            return acc;
        }, []);

        const eventValues = {
            action: this.action,
            shiftKey: this.driveShift.key,
            job: {
                ...this.job,
                isLocked: !!this.model.isLocked,
                volunteerRole: this.model.volunteerRole,
                redcrossVolunteerQuantity: redcrossVolunteerQuantity,
                quantity: quantity,
                volunteerAdjustmentReason: this.model.volunteerAdjustmentReason,
                otherVolunteerAdjustmentReason: this.model.otherVolunteerAdjustmentReason,
                bulkAddVolunteerJobsSelectedDrives: bulkAddVolunteerJobsSelectedDrives
            }
        };

        fireEvent(this.pageRef, 'saveBulkAddVolunteerJobModal', eventValues);
        this.closeModal();
    }

    /* Recurrence Dates Picker modal */
    openRecurrenceDatesPickerModalData() {
        this.recurrenceDatesPickerModalData = {
            isOpen: true,
            selectedDays: this.model.recurrenceDates,
            selectedDriveIds: this.model.recurrenceDriveIds
        }
    }

    saveRecurrenceDatesPickerModalData(event) {
        const { selectedDays, selectedDriveIds } = event.detail;

        this.model.recurrenceDates = selectedDays;
        this.model.recurrenceDriveIds = selectedDriveIds
    }

    closeRecurrenceDatesPickerModalData() {
        this.recurrenceDatesPickerModalData = {};
    }
}
