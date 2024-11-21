import { LightningElement, api, track } from 'lwc';
import { debounce } from "c/lodash";
import { getValueFromEvent } from "c/slwcUtils";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import skedDriveTemplate from './skedDrive.html';
import skedDriveController from './skedDrive.js';

const MODE = {
    DRIVE: {
      id: 'sked_Drive__c',
      template: skedDriveTemplate,
      controller: skedDriveController
    }
}
export default class SlwcAdvancedLookup extends LightningElement {
    controllerInstance = null;

    @api objectApiName = 'sked_Drive__c';
    @api lookupLabel = '';
    @api defaultFilters = null;
    @api selectedValue;
    
    @track showSpinner = false;
    @track showModal = false;

    @track filters = {};
    @track results = [];

    get modeSettings() {
        if(!this.objectApiName) return null;
        return Object.values(MODE).find(mode => mode.id === this.objectApiName);
    }

    get tableColumns() {
        if (this.controllerInstance) {
            return this.controllerInstance.getTableColumns();
        }
    }

    connectedCallback() {
        if (this.modeSettings) {
            this.controllerInstance = new this.modeSettings.controller();
            this.controllerInstance.init();
            this.filters = this.controllerInstance.getDefaultFilters();
            this.fetchResults();
        }
    }

    render() {
        return this.modeSettings && this.modeSettings.template;
    }

    exceptionHandler = (error) => {
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }

    showLoading() {
        this.showSpinner = true;
    }
    hideLoading() {
        this.showSpinner = false;
    }

    fetchResults() {
        this.showLoading();
        this.controllerInstance.fetchResults(this.filters, this.defaultFilters)
        .then((results) => {
            this.results = results;
        })
        .finally(() => this.hideLoading());
    }
    
    openModal() {
        this.showModal = true;
    }
    closeModal() {
        this.showModal = false;
    }

    handleRowSelection(event) {
        this.selectedValue = (event.detail.selectedRows && event.detail.selectedRows.length) ? event.detail.selectedRows[0] : null;
    }

    handleDriveSelected(event) {
        this.selectedValue = event.detail.selection;
    }

    handleFilterChanged(event) {
        let eventType = event.target.type || '';
        let eventName = event.currentTarget.name;
        if(eventType === 'text') {
            this.debounceFunc && this.debounceFunc.cancel();
            this.debounceFunc = debounce(() => {
                let value = getValueFromEvent(event);
                this.filters[eventName] = value;
                this.fetchResults();
            }, 700);
            this.debounceFunc();
            return;
        }

        if (this.controllerInstance) {
            this.filters = this.controllerInstance.handleFilterChanged(event, this.filters);
        }

        this.fetchResults();
    }

    saveClose() {
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                value: this.selectedValue
            }
        }));

        this.closeModal();
    }
}