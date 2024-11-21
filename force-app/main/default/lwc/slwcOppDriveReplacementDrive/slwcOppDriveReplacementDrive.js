import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {  driveService, driveQueryModel, opportunityService, opportunityQueryModel } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { sObjectType } from 'c/dataService';

export default class SlwcOppDriveExternalSummary extends LightningElement {
    @api recordId;

    @track showSpinner = false;
    @track replacementDrive = {};

    get pageHeader() {
        return `Replacement Drive`;
    }

    /* PAGE REFERENCE */
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        // this.recordId = 'a1Z2i000001ihVoEAI';
        if (this.recordId) {
            this.initialize(this.recordId);
        }
    }

    disconnectedCallback() {
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        let recordId = this.currentPageReference.state.c__recordId;
        this.initialize(recordId);
    }

    exceptionHandler = (error) => {
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }

    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }

    initialize(recordId) {
        if (!recordId) return;

        if (this.isOppId(recordId)) {
            this.refreshDataOpp();
        } else {
            this.refreshDataDrive();
        }
    }

    isOppId(recordId) {
        return recordId.startsWith('006');
    }

    refreshDataDrive() {
        this.showLoading();
        Promise.resolve()
        .then(() => {
            let driveQuery = new driveQueryModel();
            driveQuery.recordIds = [this.recordId];

            let driveSvc = new driveService();
            return driveSvc.query(driveQuery);
        })
        .then(([drive]) => {
            let replacementDriveIds = [];

            if (drive != null && drive.replacementDriveId != null) {
                replacementDriveIds.push(drive.replacementDriveId);
            }

            if (replacementDriveIds.length == 0) throw 'stop';

            let replacementDriveQuery = new driveQueryModel();
            replacementDriveQuery.recordIds = replacementDriveIds;

            let replacementDriveSvc = new driveService();
            return replacementDriveSvc.query(replacementDriveQuery);
        })
        .then(([replacementDrive]) => {
            this.replacementDrive = replacementDrive;
        })
        .catch(error => {
            if (error === 'stop') return;
            this.exceptionHandler(error) 
        })
        .finally(this.hideLoading());
    }

    refreshDataOpp() {
        this.showLoading();
        Promise.resolve()
        .then(() => {
            let opportunityQuery = new opportunityQueryModel();
            opportunityQuery.recordIds = [this.recordId];
            opportunityQuery.subQueryIndicator = sObjectType.DRIVE;

            let oppSvc = new opportunityService();
            return oppSvc.query(opportunityQuery);
        })
        .then(([opp]) => {
            let driveIds = [];

            (opp.drives || []).forEach((drive) => {
                driveIds.push(drive.id);
            });

            let driveQuery = new driveQueryModel();
            driveQuery.recordIds = driveIds;

            let driveScv = new driveService();
            return driveScv.query(driveQuery);
        })
        .then(([drive]) => {
            let replacementDriveIds = [];

            if (drive.replacementDriveId != null) {
                replacementDriveIds.push(drive.replacementDriveId);
            }

            if (replacementDriveIds.length == 0) throw 'stop';

            let replacementDriveQuery = new driveQueryModel();
            replacementDriveQuery.recordIds = replacementDriveIds;

            let replacementDriveSvc = new driveService();
            return replacementDriveSvc.query(replacementDriveQuery);
        })
        .then(([replacementDrive]) => {
            this.replacementDrive = replacementDrive;
        })
        .catch(error => {
            if (error === 'stop') return;
            this.exceptionHandler(error)
        })
        .finally(this.hideLoading);
    }

    get haveReplacementDrive() {
        return (this.replacementDrive != null && this.replacementDrive.id != null);
    }
}