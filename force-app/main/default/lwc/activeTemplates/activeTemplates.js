import { LightningElement, wire, api, track } from 'lwc';
import getActiveTemplates from '@salesforce/apex/activeTemplateController.getActiveTemplates';
import updateFutureOpportunities from '@salesforce/apex/activeTemplateController.updateFutureOpportunities';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ActiveTemplates extends LightningElement {
    //@api recordId; 
    _recordId;
    @track opportunities;
    @track error;
    selectedRecords = [];
    @track sponsorKeyword = '';
    @track showModal = true;
    columns = [
        //{ type: 'checkbox', fieldName: 'Id' },
        //{ label: 'ID', fieldName: 'Id' },
        { label: 'Name', fieldName: 'Name' },
        { label: 'Template Status', fieldName: 'Template_Status__c', type: 'text' },
        { label: 'Drive Keyword', fieldName: 'Drive_Keyword__c', type: 'text' }
    ];
    
    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        console.log('Record ID:', this._recordId);
    }


    @wire(getActiveTemplates, { accountIds: '$_recordId' })
    wiredOpportunities({ error, data }) {
        if (data) {
            this.opportunities = data;
            this.sponsorKeyword = data.length > 0 ? data[0].Account.Sponsor_Keyword__c : '';
            console.log('Opportunities data:', JSON.stringify(data));
            this.error = undefined;
        } else if (error) {
            console.log('Error:', error);
            this.error = error;
            this.opportunities = undefined;
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRecords = selectedRows;
    }

    applyToFutureDrives() {
        const selectedTemplateIds = this.selectedRecords.map(record => record.Id);

        if (selectedTemplateIds.length === 0) {
            this.showToast('Error', 'Please select at least one template', 'error');
            return;
        }

        updateFutureOpportunities({ templateIds: selectedTemplateIds })
            .then(() => {
                console.log('Operation successful');
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Success', 'Request to update drive keyword on template and opportunity has been submitted. Please allow few minutes for the process to complete.', 'success');
                //this.closeModal(); 
                //this.showModal = false;
            })
            .catch(error => {
                console.log('Operation Failed');
                this.showToast('Error', 'Operation failed', 'error');
                //this.showModal = false;
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}