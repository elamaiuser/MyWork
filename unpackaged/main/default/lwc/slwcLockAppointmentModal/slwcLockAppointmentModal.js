import { getValueFromEvent } from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';

export default class SlwcLockAppointmentModal extends LightningElement {
    @api slots;

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
    
    get excludedValues() {
        const allPlasmaSlots = this.slots?.every(slot => slot.slotType === 'Plasma');

        if(!allPlasmaSlots) {
            return ['Inventory Management'];
        }

        return []
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
    }

    disconnectedCallback() {
    }

    init() {
        this.model = {
            fixedSiteLockReason: '',
            fixedSiteLockComment: '',
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
                fixedSiteLockReason: this.model.fixedSiteLockReason
            }
        }));
        this.closeModal();
    }
}