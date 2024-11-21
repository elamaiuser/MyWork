import { LightningElement, track, api } from 'lwc';
import { getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { exceptionSettingService, exceptionSettingQueryModel } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SlwcAdminConsoleExceptionSettings extends LightningElement {
    @api isReadonly = false;
    @track exceptionSettings = [];
    @track showSpinner = false;

    get showEmptyMessage() {
        return (this.exceptionSettings || []).length <= 0;
    }

    connectedCallback() {
        this.init();
    }

    disconnectedCallback() {
    }
    
    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    fetchData() {
        this.showLoading();
        let query = new exceptionSettingQueryModel();
        let service = new exceptionSettingService();
        return service.query(query)
            .then((result) => {
                this.exceptionSettings = result;
            })
            .catch((e) => {})
            .finally(() => this.hideLoading());
    }

    handleOnChange(event) {
        let id = event.currentTarget.dataset['item'];
        let item = this.exceptionSettings.find(item => item.id === id);
        if(!item) return;

        let value = getValueFromEvent(event);
        item[event.currentTarget.name] = value;

        this.validate();
    }

    refresh() {
        this.fetchData();
    }

    validate() {
        let allInputsCorrect = [
            ...this.template.querySelectorAll("lightning-input"),
            ...this.template.querySelectorAll("c-slwc-picklist")
        ];
        return allInputsCorrect.reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
    }

    save() {
        let valid = this.validate();
        if(!valid) {
            const event = new ShowToastEvent({
                message: 'Invalid settings.',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);

            return;
        }

        this.showLoading();
        let service = new exceptionSettingService();
        service.saveList(this.exceptionSettings)
            .then(result => {
                if(!result.success) {
                    throw result;
                }
                
                const event = new ShowToastEvent({
                    message: 'Exception Settings has been saved successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            })
            .catch((e) => {})
            .finally(() => this.hideLoading());
    }

    init() {
        this.refresh();
    }
}