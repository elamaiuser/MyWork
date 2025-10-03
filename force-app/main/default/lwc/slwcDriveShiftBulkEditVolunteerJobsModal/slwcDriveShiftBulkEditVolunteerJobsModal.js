import { debugLogService, jobQueryModel, jobService } from 'c/dataService';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { DRIVE_TYPE, DRIVE_STATUS, OPERATION_TYPE, VOLUNTEER_COUNTS_ADJUSTMENT_REASON } from 'c/slwcConstants';
import { DriveHelper } from 'c/slwcDriveGenerator';
import * as slwcUtils from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, track, wire } from 'lwc';
import { cloneDeep, groupBy } from 'c/lodash';

const STEP = {
    STEP_1: 'step1',
    STEP_2: 'step2'
}

export default class SlwcDriveShiftBulkEditVolunteerJobsModal extends LightningElement {
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
    @track filters = {};
    @track model = {};
    @track errorMessages = [];
    @track recurrenceDatesPickerModalData = {};
    @track daysWithJobs = [];

    @wire(CurrentPageReference) pageRef;
    masterData = {};

    get modalHeader() {
        return 'Bulk Edit Volunteer Jobs'
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
        return "Volunteer updates will only be applied to drives with no issues.";
    }

    get appointmentAlertInstructionMessage() {
        return "To update a volunteer on a drive with a pending issue, resolve the issue and come back to this screen to confirm the update on the drive.";
    }

    get isOtherVolunteerAdjustmentReasonSelected() {
        return this.model?.volunteerAdjustmentReason === VOLUNTEER_COUNTS_ADJUSTMENT_REASON.OTHER;
    }
    
    get isOtherVolunteerAdjustmentReasonNeeded() {
        return this.isOtherVolunteerAdjustmentReasonSelected;
    }

    get isVolunteerAdjustmentReasonRequired () {
        return this.model?.volunteerRole || this.model?.redcrossVolunteerQuantity;
    }
    
    get showStep1() {
        return this.step === STEP.STEP_1;
    }

    get showStep2() {
        return this.step === STEP.STEP_2;
    }

    get isFixedSiteDrive() {
        return this.drive && this.drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE;
    }

    get modalOverflowInitial() {
        return false;
    }
    
    connectedCallback() {
        registerListener('showBulkEditVolunteerJobsModal', this.handleShowModal, this);
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

    /** Custom functions **/
    closeModal() {
        fireEvent(this.pageRef, 'closeBulkEditVolunteerJobsModal');
        this.showModal = false;
    }

    handleOnFiltersChange(event) {
        const name = event.target.name
        this.filters[name] = slwcUtils.getValueFromEvent(event);
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
            this.errorMessages = [];

            this.filters.volunteerRole = this.job.volunteerRole;
            this.filters.redcrossVolunteerQuantity = this.job.redcrossVolunteerQuantity;

            this.model.isLocked = !!this.job.isLocked;
            this.model.redcrossVolunteerQuantity = null;
            this.model.volunteerRole = '';
            this.model.volunteerAdjustmentReason = '';
            this.model.otherVolunteerAdjustmentReason = '';
            this.model.recurrenceDates = cloneDeep(this.job.bulkEditVolunteerJobsSelectedDays) ?? [];
            this.model.recurrenceDriveIds = cloneDeep(this.job.bulkEditVolunteerJobsSelectedJobIds) ?? [];
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
        
        if (this.filters.redcrossVolunteerQuantity <= 0) {
            this.errorMessages.push({
                message: 'Red Cross Volunteer Quantity must be greater than 0.'
            })
        }

        if (!this.model.recurrenceDates?.length) {
            this.errorMessages.push({
                message: 'Please select at least 1 recurrence day.'
            })
        }

        if (!slwcUtils.isNullOrEmpty(this.model.redcrossVolunteerQuantity) && this.model.redcrossVolunteerQuantity <= 0) {
            this.errorMessages.push({
                message: 'Edit Field Red Cross Volunteer Quantity must be greater than 0.'
            })
        }

        return allValid && !this.errorMessages.length;
    }

    handleSaveStep1() {
        if(!this.validateStep1()) return;
        this.step = STEP.STEP_2;
        this.initStep2();
    }

    populateDaysWithJobs(jobs = []) {
        const mapJobsByDate = groupBy(jobs, 'driveDate');
        const mapVolunteerRolesByDriveId = this.mapVolunteerRolesByDriveId;

        const result = [];
        this.model.recurrenceDates.forEach(dateIso => {
            result.push({
                dateIso: dateIso,
                jobs: (mapJobsByDate[dateIso] || []).map(job => {
                    const errorMessages = [];
                    const notMatchVolunteerRole = job.volunteerRole !== this.filters.volunteerRole;
                    const notMatchVolunteerRoleQuantity = job.redcrossVolunteerQuantity !== this.filters.redcrossVolunteerQuantity;
                    const volunteerRolesSameDrive = (mapVolunteerRolesByDriveId[job.driveId] ?? []).filter(item => item.id !== job.id);
                    const newVolunteerRoleAlreadyExists = volunteerRolesSameDrive.find(item => item.volunteerRole === this.model.volunteerRole);

                    if(notMatchVolunteerRole) {
                        errorMessages.push("Role does not match")
                    }

                    if(notMatchVolunteerRoleQuantity) {
                        errorMessages.push("Red Cross Volunteer Quantity does not match")
                    }

                    if(newVolunteerRoleAlreadyExists) {
                        errorMessages.push("Role already exists")
                    }

                    return {
                        ...job,
                        errorMessages
                    }
                })
            })
        })

        this.model.daysWithJobs = result;
    }

    fetchVolunteerRolesSameDrives(jobs = []){
        this.mapVolunteerRolesByDriveId = {};
        if(!jobs.length) return Promise.resolve();

        const driveIds = jobs.map(job => job.driveId);
        let jobQuery = new jobQueryModel();
        jobQuery.driveIds = driveIds;
        jobQuery.isVounteerRole = true;
        
        const jobSvc = new jobService();
    
        return jobSvc.query(jobQuery)
            .then(result => {
                this.mapVolunteerRolesByDriveId = groupBy(result, job => job.driveId);
            })
    }
    
    initStep2() {
        this.showLoading();
        Promise.resolve()
        .then(() => {
            let jobQuery = new jobQueryModel();
            jobQuery.selectedDates = this.model.recurrenceDates;
            jobQuery.driveTypes = [DRIVE_TYPE.FIXED_SITE];
            jobQuery.driveOperationTypes = [OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH, OPERATION_TYPE.NON_INTEGRATED_WB];
            jobQuery.collectionOperationIds = [this.drive.collectionOperationId];
            jobQuery.driveLocationIds = [this.drive.driveSiteId];
            jobQuery.driveStatuses = [
                DRIVE_STATUS.SYSTEM_GENERATED,
                DRIVE_STATUS.TENTATIVE,
                DRIVE_STATUS.CONFIRMED,
                DRIVE_STATUS.HOLD
            ];
            jobQuery.driveExcludedIds = [this.drive.id];
            jobQuery.isVounteerRole = true;

            const jobSvc = new jobService();
    
            return jobSvc.query(jobQuery);
        })
        .then((futureJobs) => {
            return this.fetchVolunteerRolesSameDrives(futureJobs)
                .then(() =>{
                    return futureJobs;
                })
        })
        .then((futureJobs) => {     
            futureJobs.forEach((job) => {
                job.driveRecordUrl = '/' + job.driveId;
                job.recordUrl = '/' + job.id;
            });
            
            return this.populateDaysWithJobs(futureJobs);
        })
        .then(() => {
            this.step = STEP.STEP_2  
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
                
        let eventValues = {
            action: this.action, 
            shiftKey: this.driveShift.key, 
            job: {
                ...this.job,
                isLocked: !!this.model.isLocked,
                volunteerRole: this.model.volunteerRole,
                redcrossVolunteerQuantity: this.model.redcrossVolunteerQuantity,
                volunteerAdjustmentReason: this.model.volunteerAdjustmentReason,
                otherVolunteerAdjustmentReason: this.model.otherVolunteerAdjustmentReason,
                bulkEditVolunteerJobsSelectedDays: this.model.daysWithJobs.filter(day => {
                    return day.jobs.length && !!day.jobs.find(job => !job.errorMessages.length)
                }).map(day => day.dateIso),
                bulkEditVolunteerJobsSelectedJobIds: this.model.daysWithJobs.reduce((jobIds, day) => {
                    jobIds.push(...day.jobs.filter(job => !job.errorMessages.length).map(job => job.id))
                    return jobIds;
                }, [])
            }
        };
        fireEvent(this.pageRef, 'saveBulkEditVolunteerJobModal', eventValues);
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