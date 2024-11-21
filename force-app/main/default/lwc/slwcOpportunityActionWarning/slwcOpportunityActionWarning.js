import { driveQueryModel, driveService } from 'c/dataService';
import { DRIVE_STATUS, OPPORTUNITY_STAGE, DRIVE_APPROVAL_STATUS } from 'c/slwcConstants';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

export default class SlwcOpportunityActionWarning extends LightningElement {
    @api recordId;

    @track drive;

    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_FIELD] })
    wiredRecord({ error, data }) {
        this.init();
    }

    @wire(CurrentPageReference) pageRef;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.recordId = this.currentPageReference.attributes.recordId;
        this.init();
    }

    get warningText() {
        if (!this.drive) return null;
        
        const driveSubmittedForApproval = [DRIVE_APPROVAL_STATUS.SUBMITTED, DRIVE_APPROVAL_STATUS.WAITING_FOR_APS_APPROVAL, 
            DRIVE_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL, DRIVE_APPROVAL_STATUS.DM_WAITING_FOR_DRD_FEEDBACK, 
            DRIVE_APPROVAL_STATUS.APS_WAITING_FOR_DRD_FEEDBACK].includes(this.drive.approvalStatus); 
        if (this.drive.status === DRIVE_STATUS.DRAFT && 
            this.drive.opportunity.stage !== OPPORTUNITY_STAGE.DISCOVERY &&
            !driveSubmittedForApproval) {
            return 'Prior to moving this Opportunity to Committed Stage, you must submit the Drive on the Drive Scheduling tab.';
        }

        return null;
    }

    connectedCallback() {
        // this.recordId = '0062i0000083IVFAA2';
        // this.init();
    }

    exceptionHandler = (error) => {
        if (error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }

    init() {
        if (!this.recordId) return;

        let service = new driveService();
        let queryModel = new driveQueryModel();
        queryModel.opportunityIds = [this.recordId];

        Promise.all([
            service.query(queryModel)
        ])
            .then(([[drive]]) => {
                this.drive = drive;
            })
            .catch(error => this.exceptionHandler(error))
    }
}