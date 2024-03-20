import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { cloneDeep } from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';
import { sObjectType, clientAvailabilityService } from 'c/dataService';
import { clientAvailabilityValidator } from 'c/slwcValidator';
import * as autoMapper from 'c/autoMapper';

export default class SlwcClientAvailabilityModal extends LightningElement {
    @api accountId;
    @track action = "create";
    @track timezoneSidId = TIME_ZONE;
    @track showModal = false;
    @track showSpinner = false;
    @track model;

    recurringFuncs;

    @wire(CurrentPageReference) pageRef;

    get modalHeader() {
        switch (this.action) {
            case "create":
                return "New Client Availability";
            case "edit":
                return "Update Client Availability";
            case "delete":
                return "Delete Client Availability";
        }
    }
    get isDeleteForm() {
        return this.action == 'delete';
    }

    connectedCallback() {
        registerListener('showClientAvailabilityModal', this.handleShowClientAvailabilityModal, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    get isValid() {
        let validator = new clientAvailabilityValidator();
        validator.validate(this.model);

        let allInputs = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')];
        allInputs.forEach((inputCmp) => {
            inputCmp.reportValidity();
        });
        
        return this.model.validities.length == 0;
    }

    handleSave() {
        if (this.isValid) {
            let service = new clientAvailabilityService();
            this.showSpinner = true;
            service.save(this.model)
                .then((result) => {
                    if (result.success) {
                        this.showModal = false;

                        this.dispatchEvent(new ShowToastEvent({
                            message: 'Client Availability was {0}.',
                            variant: 'success',
                            mode: 'dismissable',
                            messageData: [this.model.id ? 'saved' : 'created']
                        }));

                        let eventValues = { action: this.action, record: result.returnedData };
                        fireEvent(this.pageRef, 'onClientAvailabilityDMLCompleted', eventValues);
                    }
                    else {
                        this.dispatchEvent(new ShowToastEvent({
                            message: 'Error saving Client Availability',
                            variant: 'error',
                            mode: 'dismissable'
                        }));
                    }
                })
                .catch((error) => {
                    console.log('Error', JSON.stringify(error));
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }

    handleDelete() {
        let service = new clientAvailabilityService();
        this.showSpinner = true;
            service.delete(this.model)
                .then((result) => {
                    if (result.success) {
                        this.showModal = false;

                        this.dispatchEvent(new ShowToastEvent({
                            message: 'Client Availability was deleted.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));

                        let eventValues = { action: this.action, record: result.returnedData };
                        fireEvent(this.pageRef, 'onClientAvailabilityDMLCompleted', eventValues);
                    }
                    else {
                        this.dispatchEvent(new ShowToastEvent({
                            message: 'Error deleting Client Availability',
                            variant: 'error',
                            mode: 'dismissable'
                        }));
                    }
                })
                .catch((error) => {
                    console.log('Error', JSON.stringify(error));
                })
                .finally(() => {
                    this.showSpinner = false;
                });
    }

    handleOnChange(event) {
        let value = slwcUtils.getValueFromEvent(event);
        this.model[event.target.name] = value;

        if (event.target.name == "start" && !this.model.finish) {
            this.model.finish = value;
        }
    }

    handleShowClientAvailabilityModal(detail) {
        this.action = detail.action;
        switch(this.action) {
            case "create":
                this.model = autoMapper.autoMapperInstance.initiateModel('sked__Client_Availability__c');
                this.model.accountId = this.accountId;
                this.model.isAvailable = false;
                this.model.validaties = [];
                if(detail.model && detail.model.start) {
                    this.model.start = detail.model.start;
                }

                if(detail.model && detail.model.finish) {
                    this.model.finish = detail.model.finish;
                }
                break;
            case "edit":
                this.model = cloneDeep(detail.model);
                break;
            case "delete":
                this.model = cloneDeep(detail.model);
                break;
        }
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }
}