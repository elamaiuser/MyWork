import { debugLogService } from 'c/dataService';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { DRIVE_TYPE } from 'c/slwcConstants';
import { DriveHelper } from 'c/slwcDriveGenerator';
import * as slwcUtils from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, track, wire } from 'lwc';
import { cloneDeep } from 'c/lodash';

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
    @track filters = {};
    @track model = {};
    @track errorMessages = [];
    @track recurrenceDatesPickerModalData = {};

    @wire(CurrentPageReference) pageRef;
    masterData = {};

    get modalHeader() {
        return 'Bulk Edit Volunteer Jobs'
    }

    get isFixedSiteDrive() {
        return this.drive && this.drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE;
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

    handleShowModal(detail) {
        this.showLoading();
        Promise.resolve()
        .then(() => {
            this.showModal = true;
            this.action = detail.action;
            this.resourceType = detail.resourceType;
            this.type = detail.type;
            this.driveShift = detail.driveShift;
            this.drive = detail.drive;  
            this.job = detail.job;
            this.errorMessages = [];

            this.filters.volunteerRole = this.job.volunteerRole;
            this.filters.quantity = this.job.quantity;

            this.model.isLocked = !!this.job.isLocked;
            this.model.recurrenceDates = cloneDeep(this.job.recurrenceDates) ?? [];
            this.model.recurrenceDriveIds = cloneDeep(this.job.recurrenceDriveIds) ?? [];
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }

    validate() {
        this.errorMessages = [];

        const allValid = [
            ...this.template.querySelectorAll('lightning-input'), 
            ...this.template.querySelectorAll('c-slwc-picklist')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        
        if (this.filters.quantity <= 0) {
            this.errorMessages.push({
                message: 'Quantity must be greater than 0.'
            })
        }
        return allValid && !this.errorMessages.length;
    }

    handleSave() {
        if(!this.validate()) return;

        if(this.isVolunteerResource) {
            // const existed = this.driveShift.jobs?.find(job => job.volunteerRole === this.job.volunteerRole);
            // if(existed) {
            //     this.job = {
            //         ...this.job,
            //         redcrossVolunteerQuantity: this.job.redcrossVolunteerQuantity || 0,
            //         sponsorVolunteerQuantity: this.job.sponsorVolunteerQuantity || 0,
            //         key: existed.key,
            //         id: existed.id
            //     }

            //     this.dispatchEvent(
            //         new ShowToastEvent({
            //             title: 'Success',
            //             message: `Volunteer complement ${this.isVolunteerQuantityChanged ? 'quantity ': ''} has been updated!`,
            //             variant: 'success'
            //         })
            //     );

            //     const isRedCrossQtyUpdateBannerNeeded = 
            //         this.isVolunteerResource && 
            //         this.job.volunteerRole === VOLUNTEER_TYPE.DONOR_AMBASSADOR &&
            //         this.job.redcrossVolunteerQuantity !== existed?.redcrossVolunteerQuantity && 
            //         this.drive?.driveShifts?.length > 1;
            //     if(isRedCrossQtyUpdateBannerNeeded) {
            //         this.dispatchEvent(
            //             new ShowToastEvent({
            //                 title: 'Alert!',
            //                 message: `Red Cross Volunteer Quantity has been updated on ${this.driveShift.name}. Red Cross Volunteer Quantity will be updated on all shifts.`,
            //                 variant: 'warning'
            //             })
            //         );
            //     }
            // }
        }
        
        // const originalJob = this.driveShift.jobs?.find(_job => _job.resourceRole === this.job.resourceRole);
        // const isDualRoleModified = this.isDualRoleEditMode && originalJob?.dualRole !== this.job.dualRole;
        // const reducedDualRoleQuantity = this.isDualRoleEditMode ? Math.max(originalJob?.quantity - this.job.quantity, 0) : 0;
        // this.job = {
        //     ...this.job,
        //     isDualRoleModified: isDualRoleModified,
        //     reducedDualRoleQuantity: reducedDualRoleQuantity
        // };

        // let eventValues = {action: this.action, shiftKey: this.driveShift.key, job: this.job};
        // if(this.type != "allocationModal"){
        //     fireEvent(this.pageRef, 'saveJob', eventValues);
        // } else {
        //     eventValues = {...eventValues, shiftId: this.driveShift.id }
        //     fireEvent(this.pageRef, 'saveJobModal', eventValues);
        // }
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