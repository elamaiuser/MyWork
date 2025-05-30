import { getValueFromEvent } from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcLockAppointmentModal extends LightningElement {
    driveHelper = new DriveHelper();

    @api slots;
    @api drive;

    @track _isOpen = false;
    @api
    get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;
        if(this._isOpen) {
            this.init();
        }
    }

    @track model = {}
    @track recurrenceDatesPickerModalData = {};

    get excludedValues() {
        const allPlasmaSlots = this.slots?.every(slot => slot.slotType === 'Plasma');

        if(!allPlasmaSlots) {
            return ['Inventory Management'];
        }

        return []
    }

    get showApplyFutureDatesBtn() {
        const isLinkedDrive = this.drive.linkedDriveId;
        return (
            this.driveHelper.isFixedSiteDrive(this.drive) ||
            this.driveHelper.isWbFixedSiteDrive(this.drive)
        ) && !isLinkedDrive;
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
    }

    disconnectedCallback() {
    }

    init() {
        const recurrenceDates = this.slots.length === 1 ? this.slots[0].recurrenceDates ?? [] : []
        const selectedDriveIds = this.slots.length === 1 ? this.slots[0].selectedDriveIds ?? [] : []
        this.model = {
            fixedSiteLockReason: '',
            fixedSiteLockComment: '',
            recurrenceDates,
            selectedDriveIds
        }
    }

    validate() {    
        const allValid = [
            ...this.template.querySelectorAll('lightning-textarea'),
            ...this.template.querySelectorAll('c-slwc-picklist')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
    
        return allValid;
      }

    handleOnChange(event) {
        event.stopPropagation();
    
        if(event.detail && event.detail.selection) {
          this.model[event.currentTarget.name] = event.detail.selection.id;
        } else {
          let value = getValueFromEvent(event);
          this.model[event.currentTarget.name] = value;
        }
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
            }
        }));
    }

    handleSave() {
        if(!this.validate()) return;

        this.dispatchEvent(new CustomEvent('save', {
            detail: {
                fixedSiteLockComment: this.model.fixedSiteLockComment,
                fixedSiteLockReason: this.model.fixedSiteLockReason,
                recurrenceDates: this.model.recurrenceDates,
                selectedDriveIds: this.model.selectedDriveIds
            }
        }));
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