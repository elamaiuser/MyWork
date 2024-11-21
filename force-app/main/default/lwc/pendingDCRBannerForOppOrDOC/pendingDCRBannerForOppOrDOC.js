import { LightningElement , api, wire, track} from 'lwc';
import { driveChangeRequestService, driveChangeRequestQueryModel } from 'c/dataService';
import { DRIVE_REQUEST_CHANGE_STATUS } from 'c/slwcConstants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import warningMsg from '@salesforce/label/c.Pending_DCR_Banner_Msg';

export default class PendingDCRBannerForOppOrDOC extends LightningElement {
    @api recordId;

    @track driveChangeRequest;

    // To check whether the banner is on Opportunity or on DOC
    get isBannerOnOpportunity(){
        return this.recordId && this.recordId.startsWith('006');
    }

    // To get the banner message to show in the UI
    get bannerMsg() {
        if (!this.driveChangeRequest) return; 
                
        return warningMsg;
        
    }

    // To get the error msg on the UI to debug easily
    errorHandler = (error) => {
        console.log(error);
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }


    connectedCallback()
    {
        if (!this.recordId) return;
    
        let dcrService = new driveChangeRequestService();
        let dcrQueryModel = new driveChangeRequestQueryModel();

        if (this.isBannerOnOpportunity)
        {
            dcrQueryModel.opportunityIds = [this.recordId];
           
          } else {
            
            dcrQueryModel.driveIds = [this.recordId];
        }

        dcrQueryModel.statuses = [DRIVE_REQUEST_CHANGE_STATUS.PENDING];

        return dcrService.query(dcrQueryModel)
            .then(([driveChangeRequest]) => {
                this.driveChangeRequest = driveChangeRequest;
        })
        .catch(error => this.errorHandler(error));
    }

}