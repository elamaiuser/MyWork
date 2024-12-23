import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { cloneDeep } from 'c/lodash';

export default class SlwcAddRoleModal extends LightningElement {
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
    @api jobAllocation = null;
    @api resource = null;

    @track roleOptions = [];
    @track model = {
        rolesSelected: [] 
    }
    
    @wire(CurrentPageReference) pageRef;

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
        this.roleOptions = this.buildRoleOptions();
        this.model = {
            rolesSelected: [] 
        };
        
        if(this.jobAllocation && this.jobAllocation.additionalRoles) {
            this.model.rolesSelected = (this.jobAllocation.additionalRoles || []).map(this.buildOption);
        }
    }

    buildOption(value) {
        return {
            value: value,
            key: value,
            label: value
        };
    }

    buildRoleOptions() {
        if(!this.resource || !this.resource.roles) return [];

        return (this.resource.roles || [])
            .filter(item => item !== this.jobAllocation.resourceRole)
            .map(this.buildOption)
    }

    handleRoleChanged(event) {
        this.model.rolesSelected = cloneDeep(event.detail.selectedValues);
    }

    handleSave() {
        this.dispatchEvent(new CustomEvent('save', {
            detail: {
                roles: this.model.rolesSelected
                    .map(item => item.value)
            }
        }));
        this.closeModal();
    }
}