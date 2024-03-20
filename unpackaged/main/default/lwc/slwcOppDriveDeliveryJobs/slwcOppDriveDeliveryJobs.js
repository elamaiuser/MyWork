import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {  opportunityService, opportunityQueryModel, driveService, driveDeliveryJobService, sObjectType, driveDeliveryJobQueryModel } from 'c/dataService';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { slwcDriveGeneratorHelper } from 'c/slwcDriveGenerator';
import { DRIVE_DELIVERY_JOB_DISPLAY_MODE } from 'c/slwcConstants';

let driveGeneratorInstance = {
    drive: null,
    masterData: {
        driveTags: {
        accountTags: [],
        locationTags: []
        },
        isReadonly: false,
        lunchBreakSettings: [],
        resourceRoleGroups: null,
        roleTimeData: null,
        roleTimeDetailMap: null,
        roleTimeVarianceMap: {},
        sameDateActivities: [],
        sameDateDrives: [],
        staffingDecisionMatrix: null,
        timezoneSidId: null,
        vehicles: [],
        backupDriveShiftMap: {},
        fieldReadonlyMap: {}
    },
    errorMessages: []
};

export default class SlwcOppDriveDeliveryJobs extends LightningElement {
    @api recordId;

    @track drive = null;
    @track showSpinnerCount = 0;
    @track displayMode = DRIVE_DELIVERY_JOB_DISPLAY_MODE.TAB;

    get showSpinner() {
        return this.showSpinnerCount > 0;
    }
    
    get masterData() {
        return driveGeneratorInstance.masterData;
    }
    
    /* PAGE REFERENCE */
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        // this.recordId = 'a1Z2i000001eqdPEAQ';
        
        if (this.recordId) {
            this.initialize(this.recordId);
        }
        registerListener('saveDriveDeliveryJob', this.handleSaveDeliveryJob, this);
        registerListener('deleteDriveDeliveryJob', this.handleDeleteDriveDeliveryJob, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
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
        
        this.displayMode = recordId.startsWith('006') ? DRIVE_DELIVERY_JOB_DISPLAY_MODE.TAB : DRIVE_DELIVERY_JOB_DISPLAY_MODE.WIDGET;
        
        this.showLoading();
        Promise.resolve()
        .then(() => {
            return slwcDriveGeneratorHelper.initialize(recordId)
            .then((result) => {
                driveGeneratorInstance = result.driveGeneratorInstance;
                return result.drive;
            })
        })
        .then((drive) => {
            this.drive = drive;
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }

    refreshData() {
        this.showLoading();
        Promise.resolve()
        .then(() => {
            let serivce = new driveDeliveryJobService();
            let queryModel = new driveDeliveryJobQueryModel();
            queryModel.driveIds = [this.drive.id];
            queryModel.subQueryIndicator = sObjectType.DRIVE_BAG;

            return serivce.query(queryModel)
        })
        .then((result) => {
            this.drive.driveDeliveryJobs = result || [];
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }

    handleSaveDeliveryJob(detail){
        let newDriveDeliveryJob = detail.driveDeliveryJobs;
        newDriveDeliveryJob.driveId = this.drive.id;

        let service = new driveDeliveryJobService();
        this.showLoading();
        service.save(newDriveDeliveryJob)
        .then(result => {      
            this.dispatchEvent(new ShowToastEvent({
                message: 'Save Drive Delivery Job successfully.',
                variant: 'success',
                mode: 'dismissable'
            }));

            return this.refreshData();
        })
        .catch(error => console.log(error))
        .finally(this.hideLoading);

    }
    handleDeleteDriveDeliveryJob(detail){
        let driveDeliveryJob = detail.driveDeliveryJobs;
        let service = new driveDeliveryJobService();
        this.showLoading();
        service.delete(driveDeliveryJob)
        .then(result => {      
            this.dispatchEvent(new ShowToastEvent({
                message: 'Delete Drive Delivery Job successfully.',
                variant: 'success',
                mode: 'dismissable'
            }));

            return this.refreshData();
        })
        .catch(error => console.log(error))
        .finally(this.hideLoading);
    }
}