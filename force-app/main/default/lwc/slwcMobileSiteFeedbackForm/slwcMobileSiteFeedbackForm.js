import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { debugLogService, jobQueryModel, jobService } from 'c/dataService';

export default class SlwcMobileSiteFeedbackForm extends LightningElement {
    @api jobId;

    @track showSpinner = false;
    @track initialized = false;
    @track siteFeedbackModalData = {}

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    exceptionHandler = (error) => {
        new debugLogService().captureDebugLog(error, this.jobId);
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
        let _jobQueryModel = new jobQueryModel();
        _jobQueryModel.recordIds = [this.jobId];
        let _jobService = new jobService();
        _jobService.query(_jobQueryModel)
        .then(([job]) => {
            this.initialized = true;

            this.siteFeedbackModalData = {
                isOpen: true,
                job
            }
        })
        .catch((error) => this.exceptionHandler(error))
        .finally(() => this.hideLoading())
    }
}