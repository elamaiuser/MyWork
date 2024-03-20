import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {  opportunityService, opportunityQueryModel, sObjectType } from 'c/dataService';
import TIME_ZONE from '@salesforce/i18n/timeZone';
export default class SlwcDriveExecutionDetails extends LightningElement {
    @api recordId;
    @track drive;
    @track showSpinnerCount = 0;
    @track showAlert = false;
    @track timezoneSidId = TIME_ZONE
    get showSpinner() {
        return this.showSpinnerCount > 0;
    }
    get siteInspectionCompletedByName() {
        if (this.drive.driveSite && this.drive.driveSite.siteInspectionCompletedBy) {
            return this.drive.driveSite.siteInspectionCompletedBy.name;
        }
        return "";
    }
    get driveProductivityPlannedClass() { 
        let driveProductivityPlannedClass = 'drive-health ';
        if (this.drive.driveProductivityPlanned >= 0.8) {
            driveProductivityPlannedClass += "green";
        } 
        else if (this.drive.driveProductivityPlanned >= 0.6) { 
            driveProductivityPlannedClass += "amber";
        }
        else {
            driveProductivityPlannedClass += "red";
        }
        
        return driveProductivityPlannedClass;
    }
    /* PAGE REFERENCE */
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        if (this.recordId) {
            this.initialize(this.recordId);
        }
    }
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        let recordId = this.currentPageReference.state.c__recordId;
        this.initialize(recordId);
    }
    showLoading = () => {
        this.showSpinnerCount++;
    }

    hideLoading = () => {
        this.showSpinnerCount--;
        if(this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        } 
    }
    initialize(recordId) {
        if(!recordId) return;

        this.showLoading();
        Promise.resolve()
        .then(() => {
            if (recordId.startsWith("006")) {
                return this.initializeFromOptyId(recordId);
            }
        })
        
        .catch(error => this.exceptionHandler(error, true))
        .finally(this.hideLoading);
    }
    exceptionHandler = (error, silentError = false) => {
        console.log(error);

        if (!silentError) {}
    }
    initializeFromOptyId(oppId) {
        let queryModel = new opportunityQueryModel();
        queryModel.recordIds = [oppId];
        queryModel.subQueryIndicator = sObjectType.DRIVE | sObjectType.OPPORTUNITY_CONTACT_ROLE;
        let service = new opportunityService();

        this.showLoading()
        return service.query(queryModel)
            .then((result) => {
                let opp = result[0];
                    if (!opp.drives) {
                       this.showAlert = true;
                    }
                    else {
                        this.drive = opp.drives[0];
                    }
            })
            .catch(error => this.exceptionHandler(error, true))
            .finally(this.hideLoading);
    }
}