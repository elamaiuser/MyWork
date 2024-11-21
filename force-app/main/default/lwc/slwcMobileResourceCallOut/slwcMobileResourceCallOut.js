import { LightningElement, track, api } from 'lwc';
import { jobQueryModel, jobService, resourceQueryModel, resourceService, sObjectType } from 'c/dataService';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { DateTime } from "c/luxon";
import { JOB_ALLOCATION_STATUS } from 'c/slwcConstants';

export default class SlwcMobileResourceCallOut extends LightningElement {
    @api userId;
    @api jobId;
    @track initialized = false;
    @track showSpinner = false;
    @track job;
    @track resource;
    @track confirmModalData = {};

    get resourceId() {
        return this.resource?.id;
    }

    get driveDate() {
        return this.job?.driveDate;
    }

    get jobAllocation() {
        if (!this.job) return null;

        return this.job.jobAllocations?.find(item => {
            return item.resourceId === this.resourceId && item.status !== JOB_ALLOCATION_STATUS.DELETED;
        })
    }

    get duration() {
        return this.resource?.dailyTimeOffHours;
    }

    connectedCallback() {
        this.init();
    }

    exceptionHandler = (error) => {
        this.showConfirmModal({
            mode: 'error',
            title: 'Error',
            message: error.message,
            confirmBtnLabel: 'none',
            cancelBtnLabel: 'Close',
            onClose: () => {
                this.confirmModalData = {};
            }
        });
    }

    showLoading = () => {
        this.showSpinner = true;
    };

    hideLoading = () => {
        this.showSpinner = false;
    };

    init() {
        this.showLoading();
        Promise.all([
            this.retrieveJob(),
            this.retrieveResource()
        ])
            .then(() => {
                if (!this.jobAllocation) {
                    this.showConfirmModal({
                        mode: 'error',
                        title: 'Error',
                        message: 'This screen cannot be loaded as you do not have an Active Job Allocation record associated. Please contact your administrator for assistance.',
                        confirmBtnLabel: 'none',
                        cancelBtnLabel: 'none'
                    });
                    return;
                }

                if(![JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, 
                    JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, 
                    JOB_ALLOCATION_STATUS.IN_PROGRESS].includes(this.jobAllocation.status)) {
                    this.showConfirmModal({
                        mode: 'error',
                        title: 'Error',
                        message: `Job Allocation with status ${this.jobAllocation.status} cannot be called out.`,
                        confirmBtnLabel: 'none',
                        cancelBtnLabel: 'none'
                    });
                    return;
                }

                this.initialized = true;
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading);

    }

    retrieveResource() {
        let service = new resourceService();
        let query = new resourceQueryModel();
        query.userIds = [this.userId];
        return service.query(query)
            .then(([resource]) => {
                this.resource = resource;
                return resource;
            })
    }

    retrieveJob() {
        let service = new jobService();
        let query = new jobQueryModel();
        query.recordIds = [this.jobId];
        query.subQueryIndicator = sObjectType.JOB_ALLOCATION;
        return service.query(query)
            .then(([job]) => {
                this.job = job;
                return job;
            })
    }

    handleSaveCallOutModal = (event) => {
        const { callOutType, callOutReason, callOutNotes, callOutReceivedDateTime, timeOffPlan, timeOffReasonCode, usePtoForCallOut, hasTimeOffPlans } = event.detail;

        let params = {
            resourceId: this.resourceId,
            jobId: this.jobId,
            callOutReported: true,
            callOutType: callOutType,
            callOutReason: callOutReason,
            callOutNotes: callOutNotes,
            callOutReceivedDateTime: callOutReceivedDateTime,
            timeOffPlan: timeOffPlan,
            timeOffReasonCode: timeOffReasonCode,
            usePtoForCallOut: usePtoForCallOut,
            hasTimeOffPlans: hasTimeOffPlans
        };

        this.showLoading();
        let service = new resourceService();
        service.saveCallOut({
            request: params
        }).then(res => {
            this.showConfirmModal({
                title: 'Success',
                message: 'Call out successfully. Please close the form and pull to refresh Job Details.',
                confirmBtnLabel: 'none',
                cancelBtnLabel: 'none'
            });      
        })
            .catch(error => this.exceptionHandler(error))
            .finally(() => this.hideLoading());
    }

    /** Confirm Modal **/
    showConfirmModal(confirmModalData) {
        this.confirmModalData = {
            ...confirmModalData,
            isOpen: true
        }
    }

    hideConfirmModal() {
        this.confirmModalData = {};
    }
}