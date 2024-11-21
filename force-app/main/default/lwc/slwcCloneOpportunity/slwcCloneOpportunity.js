import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { opportunityService } from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';

import NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import ACCOUNT_FIELD from '@salesforce/schema/Opportunity.AccountId';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Opportunity.Account.Name';

export default class SlwcCloneOpportunity extends NavigationMixin(LightningElement) {
    @api recordId;
    @track stage;
    @track driveDate;
    @track cloneDrives;
    @track showSpinner = false;
    @track today;

    constructor() {
        super();
        this.cloneDrives = true;
        this.stage = 'Planning';

        let todayVal = new Date();
        this.today = todayVal.toISOString().substring(0, 10);
        this.driveDate = this.today;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, ACCOUNT_FIELD, ACCOUNT_NAME_FIELD] })
    record;

    get name() {
        return getFieldValue(this.record.data, NAME_FIELD);
    }

    get accountId() {
        return getFieldValue(this.record.data, ACCOUNT_FIELD);
    }

    get accountName() {
        return getFieldValue(this.record.data, ACCOUNT_NAME_FIELD);
    }

    handleOptionClicked(event) {
        if( event.target.name === 'cloneDrives' ){
            this.cloneDrives = event.target.checked;
        }
    }

    btnCancelClicked() {
        const closeModalEvent = new CustomEvent('closemodal', {});
        this.dispatchEvent(closeModalEvent);
    }

    btnCloneClicked() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);

        if (allValid) {
            this.showSpinner = true;
            let service = new opportunityService();
            service.cloneOpportunity({sourceOpportunityId: this.recordId, newDriveDateIso: this.driveDate, cloneDrives: this.cloneDrives})
                .then(opportunity => {
                    const closeModalEvent = new CustomEvent('closemodal', {});
                    this.dispatchEvent(closeModalEvent);

                    this.dispatchEvent(
                        new ShowToastEvent({
                            message: 'Draft Drive ' + this.name + ' was cloned.',
                            variant: 'success'
                        }),
                    );

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            "recordId": opportunity.Id,
                            "objectApiName": "Opportunity",
                            "actionName": "view"
                        },
                    });
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error cloning Draft Drive.',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }

    errorCallback(error, stack) {
        var err = error;
    }

    handleDriveDateChanged(event) {
        this.driveDate = slwcUtils.getValueFromEvent(event);
    }
}