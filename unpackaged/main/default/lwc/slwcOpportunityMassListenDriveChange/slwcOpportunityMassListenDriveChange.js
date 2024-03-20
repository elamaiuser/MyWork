import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { opportunityQueryModel, opportunityService } from 'c/dataService';

export default class SlwcOpportunityMassListenDriveChange extends LightningElement {
    @track opportunityIds = [];
    @track showSpinner = false;
    @track initialized = false;

    connectedCallback() {
        this.init();
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

    init = () => {
        this.initialized = false;
        this.showLoading();
        this.fetchAllNotProccessedOpportunities()
        .then(() => {
            this.initialized = true;
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }

    fetchAllNotProccessedOpportunities = () => {
        let service = new opportunityService();
        let queryModel = new opportunityQueryModel();
        queryModel.processingStatuses = ['Mass Update Not Processed'];

        return service.query(queryModel)
        .then((result = []) => {
            this.opportunityIds = result.map(item => item.id);
        });
    }
}