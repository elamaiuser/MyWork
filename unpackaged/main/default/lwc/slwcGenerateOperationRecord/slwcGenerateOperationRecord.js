import { LightningElement, api, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { operationRecordService } from 'c/dataService';

export default class SlwcGenerateOperationRecord extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showSpinner = false;

    constructor() {
        super();
    }

    btnNoClicked() {
        const closeModalEvent = new CustomEvent('closemodal', {});
        this.dispatchEvent(closeModalEvent);
    }

    btnYesClicked() {
        this.showSpinner = true;
        let request = {driveId: this.recordId};
        let service = new operationRecordService();
        service.generateOperationRecords({request: request})
            .then(opportunity => {
                const closeModalEvent = new CustomEvent('closemodal', {});
                this.dispatchEvent(closeModalEvent);

                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Generate Operations Record Successfully!',
                        variant: 'success'
                    }),
                );

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        "recordId": this.recordId,
                        "objectApiName": "Opportunity",
                        "actionName": "view"
                    },
                });
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Generate Operations Record.',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    errorCallback(error, stack) {
        var err = error;
    }
}