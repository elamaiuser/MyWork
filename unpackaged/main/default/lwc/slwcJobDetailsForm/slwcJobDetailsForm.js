import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { resourceQueryModel, resourceService, jobAllocationQueryModel, jobAllocationService } from 'c/dataService';
import { JOB_ALLOCATION_STATUS } from 'c/slwcConstants';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcJobDetailsForm extends LightningElement {
    @api jobId;
    @api userId;

    @track showSpinner = false;
    @track initialized = false;
    @track jobAllocation = null;
    @track timezoneSidId = TIME_ZONE;

    get additionalRolesString() {
        if(!this.jobAllocation) return null;
        return this.jobAllocation.additionalRoles ? this.jobAllocation.additionalRoles.split(';').join(', ') : null;
    } 

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
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

    connectedCallback() {
        this.init();
    }
    
    init() {
        this.showLoading();
        let _resourceService = new resourceService();
        let _resourceQuery = new resourceQueryModel();
        _resourceQuery.userIds = [this.userId];

        _resourceService.query(_resourceQuery) 
        .then(([resource]) => {
            let _jobAllocationService = new jobAllocationService();
            let _jobAllocationQueryModel = new jobAllocationQueryModel();
            _jobAllocationQueryModel.jobIds = [this.jobId];
            _jobAllocationQueryModel.resourceIds = [resource.id];
            _jobAllocationQueryModel.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.IN_PROGRESS, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.COMPLETE, JOB_ALLOCATION_STATUS.CHECKED_IN];
            
            return _jobAllocationService.query(_jobAllocationQueryModel);
        })
        .then(([jobAllocation]) => {
            this.initialized = true;
            this.jobAllocation = jobAllocation || {};
        })
        .catch((error) => this.exceptionHandler(error))
        .finally(() => this.hideLoading())
    }
}