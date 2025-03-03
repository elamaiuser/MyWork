import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';
import { registerListener,fireEvent, unregisterAllListeners } from 'c/pubsub';
import { DRIVE_TYPE, OPERATION_TYPE } from 'c/slwcConstants';
import { DriveHelper } from 'c/slwcDriveGenerator'

const DRIVE_DATA_CHANGED_EVENT = 'drivedatachanged';
const CMP_NAME = 'slwcDriveDetails';

export default class SlwcDriveShifts extends LightningElement {
    driveHelper = new DriveHelper();

    @api drive;
    @api masterData;
    @api showErrors;
    @track showModal = false;
    @track confirmModalData = {};
    @track activeDriveShiftKey = null;

    @wire(CurrentPageReference) pageRef;

    get isMobile() {
        return slwcUtils.isMobile()
    }
    get isFixedSiteDrive() {
        return this.driveHelper.isFixedSiteDrive(this.drive);
    }
    get isMobileDrive() {
        return this.driveHelper.isMobileDrive(this.drive);
    }
    get show2RBCAssetsField() {
        return this.driveHelper.show2RBCField(this.drive);
    }

    get showPlateletAssetsField() {
        return this.driveHelper.showPlateletField(this.drive);
    }
    
    get showPlasmaAssetsField() {
        return this.driveHelper.showPlasmaField(this.drive);
    }

    get showModalMobile(){
        return this.showModal && this.isMobile || this.confirmModalData.isOpen && this.isMobile
    }
    get driveShifts() {
        if(!this.drive) return [];
        return this.drive.driveShifts || [];
    }
    get driveShiftWrappers() {
        let wrappers = [];
        if (this.driveShifts && this.driveShifts.length) {
            this.driveShifts.forEach((driveShift, index) => {
                let wrapper = {
                    name: "Drive Shift " + (index + 1),
                    driveShift: driveShift,
                    shown: this.activeDriveShiftKey === driveShift.key
                }
                wrappers.push(wrapper);
            });
        }
        return wrappers;
    }

    connectedCallback() {
        this.setupDefaultTab();

        registerListener('showJobModal', this.handleShowModal, this);
        registerListener('closeJobModal', this.handleCloseModal, this);

        registerListener('showDualRoleAssignmentModal', this.handleShowModal, this);
        registerListener('closeDualRoleAssignmentModal', this.handleCloseModal, this);

        registerListener('showDriveShiftTagModal', this.handleShowModal, this);
        registerListener('closeDriveShiftTagModal', this.handleCloseModal, this);

        registerListener('openShiftSlotsModal', this.handleShowModal, this);
        registerListener('closeShiftSlotsModal', this.handleCloseModal, this);
        
        registerListener('openDriveShiftConfirmModal', this.handleOpenConfirmModal, this);
        registerListener('closeDriveShiftConfirmModal', this.hideConfirmModal, this);
    }

    setupDefaultTab() {
        if(!this.drive || !this.drive.driveShifts || !this.drive.driveShifts.length) return;

        this.activeDriveShiftKey = this.drive.driveShifts[0].key;
    }
    
    handleShowModal(){
        this.showModal = true;
    }
    handleCloseModal(){
        this.showModal = false;
    }
    handleOpenConfirmModal(detail){
        if(detail.action === 'deleteJob'){
            this.showConfirmModal({
                title: "Delete Job",
                message: "Are you sure you want to delete this Job?",
                onClose: this.handleDelete,
                detail: detail
            })
        } else if(detail.action === 'deleteDriveShiftTag'){
            this.showConfirmModal({
                title: "Delete Drive Shift Tag",
                message: "Are you sure you want to delete this tag?",
                onClose: this.handleDeleteDriveShiftTag,
                detail: detail
            })
        } else if(detail.action === 'deleteShiftSlotConfirm'){
            this.showConfirmModal({
                title: "Delete Appointment Confirmation",
                message: "Are you sure you want to delete this appointment?",
                onClose: this.handleDeleteAppointment,
                detail: detail
            })
        } else if(detail.action === 'resetShiftSlots'){
            this.showConfirmModal({
                title: "Reset Appointments Confirmation",
                message: "Are you sure you want to reset appointments?",
                onClose: this.handleResetAppointment,
                detail: detail
            })
        } else if(detail.action === 'regenerateShiftSlots'){
            this.showConfirmModal({
                title: "Re-generate Appointments Confirmation",
                message: "Are you sure you want to re-generate appointments?",
                onClose: this.handleRegenerateAppointment,
                detail: detail
            })
        }
    }
    handleDelete = (confirm) => {
        if(confirm) {
            fireEvent(this.pageRef, 'deleteJob', this.confirmModalData.detail);
        }
        this.hideConfirmModal();
    }
    handleDeleteAppointment = (confirm) => {
        if(confirm) {
            const _event = new CustomEvent('deleteappointment', this.confirmModalData.detail);
            this.dispatchEvent(_event);
        }
        this.hideConfirmModal();
    }
    handleDeleteDriveShiftTag = (confirm) => {
        if(confirm) {
            fireEvent(this.pageRef, 'deleteDriveShiftTag', this.confirmModalData.detail);
        }
        this.hideConfirmModal();
    }
    handleResetAppointment = (confirm) => {
        if(confirm) {
            const _event = new CustomEvent('resetappointments', this.confirmModalData.detail);
            this.dispatchEvent(_event);
        }
        this.hideConfirmModal();
    }
    handleRegenerateAppointment = (confirm) => {
        if(confirm) {
            const _event = new CustomEvent('regenerateappointments', this.confirmModalData.detail);
            this.dispatchEvent(_event);
        }
        this.hideConfirmModal();
    }
    handleChangeTab = (event) => {
        this.activeDriveShiftKey = event.target.value;
    }

    /* ON CHANGE HANDLERS */
    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = slwcUtils.getValueFromEvent(event);

        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(() => {
            const numberOf2rbcAssetsChanged = targetName === 'numberOf2rbcAssets';
            if(!this.isFixedSiteDrive && numberOf2rbcAssetsChanged) {
                if(Number(targetValue) < this.drive.preferredNumberOf2rbcAssets) {
                    this.showConfirmModal({
                        title: 'Confirmation',
                        message: `The current projection is above the capacity of the machines. Do you want to continue?`,
                        onClose: (result) => {
                            this.hideConfirmModal();
                            if(result) {
                                this.handleDispatchEvent(DRIVE_DATA_CHANGED_EVENT, [
                                    {
                                        targetName: targetName, 
                                        targetValue: targetValue
                                    }
                                ]);
                            } else {
                                this.template.querySelector('lightning-input[data-name="numberOf2rbcAssets"]').value = this.drive.numberOf2rbcAssets;
                            }
                        }
                    });
        
                    return;
                }
            }

            this.handleDispatchEvent(DRIVE_DATA_CHANGED_EVENT, [
                {
                    targetName: targetName, 
                    targetValue: targetValue
                }
            ]);
        }, 800);
    }

    showDriveShiftsMetadataModal(event) {
        this.dispatchEvent(
            new CustomEvent('showdriveshiftsmetadatamodal', {
                bubbles: true,
                composed: true,
                detail: {}
            })
        );
    }

    handleDispatchEvent(eventName, properties) {
        this.dispatchEvent(
            new CustomEvent(eventName, {
                bubbles: true,
                composed: true,
                detail: {
                    cmpName: CMP_NAME,
                    properties: properties
                }
            })
        );
    }

    /** Confirm Modal **/
    showConfirmModal(confirmModalData) {
        this.confirmModalData = {...confirmModalData,
            isOpen: true,
            confirmBtnLabel: confirmModalData.confirmBtnLabel || 'Yes',
            cancelBtnLabel: confirmModalData.cancelBtnLabel || 'No',
        }
    }
    
    hideConfirmModal() {
        this.confirmModalData = {};
    }
}