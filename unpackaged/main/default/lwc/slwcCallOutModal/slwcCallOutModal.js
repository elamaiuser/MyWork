import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getValueFromEvent } from 'c/slwcUtils';

export default class SlwcAdSlwcCallOutModaldRoleModal extends LightningElement {
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

    @track model = {
        callOutType: null,
        callOutReason: null,
        callOutNotes: null
    };

    @wire(CurrentPageReference) pageRef;
    
    get callOutReasonDisabled() {
        return !this.model || !this.model.callOutType
    }

    get callOutReasonControllingFieldValues() {
        return this.model && this.model.callOutType ? [this.model.callOutType] : [];
    }

    connectedCallback() {
    }

    disconnectedCallback() {
    }
    
    /** Custom functions **/
    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {

            }
        }));
    }

    init() {        
        this.model = {};
    }

    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = getValueFromEvent(event);
        this.model[targetName] = targetValue;
    }

    validate() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'), 
            ...this.template.querySelectorAll('lightning-textarea'),
            ...this.template.querySelectorAll('c-slwc-picklist')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

    handleSave() {
        if(!this.validate()) return;

        this.dispatchEvent(new CustomEvent('save', {
            detail: {
                callOutType: this.model.callOutType,
                callOutReason: this.model.callOutReason,
                callOutNotes: this.model.callOutNotes
            }
        }));
        this.closeModal();
    }
}