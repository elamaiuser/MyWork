import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { cloneDeep } from 'c/lodash';

export default class SlwcRecurrenceDatesPickerModal extends LightningElement {
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

    @api driveShiftSlot = null;
    @api selectedDays = [];

    @track model = {
        selectedDays: [] 
    }
    
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
    }

    disconnectedCallback() {
    }
    
    init() {
        this.model = {
            selectedDays: this.selectedDays
        };
        
        if(this.jobAllocation && this.jobAllocation.additionalRoles) {
            this.model.rolesSelected = (this.jobAllocation.additionalRoles.split(";") || []).map(this.buildOption);
        }
    }

    handleOnChange(event) {
        this.model.selectedDays = cloneDeep(event.detail.selectedDays);
    }

    handleSave() {
        this.dispatchEvent(new CustomEvent('save', {
            detail: {
                selectedDays: this.model.selectedDays
            }
        }));
        this.closeModal();
    }
    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
            }
        }));
    }
}