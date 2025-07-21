import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import RELATED_SCHEDULED_DRIVE from '@salesforce/schema/Opportunity.Related_Scheduled_Drive__c';

export default class RedirectToVF extends LightningElement {
    @api recordId;
    
    @wire(getRecord, {
        recordId: '$recordId',
        fields:[RELATED_SCHEDULED_DRIVE]
    })
    wiredDrive({error, data}) {
        if (data) {
            const driveWorkSheetVfPageUrl = `/apex/generateDriveWorksheetPdf?id=${data.fields.Related_Scheduled_Drive__c.value}`;
            window.open(driveWorkSheetVfPageUrl, '_blank');
            this.closeQuickAction();            
        } else if (error) {
            console.error(error);
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}