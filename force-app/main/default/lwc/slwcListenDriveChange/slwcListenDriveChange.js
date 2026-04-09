import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { subscribe} from 'lightning/empApi';

export default class SlwcListenDriveChange extends NavigationMixin(LightningElement) {
    @api recordId;
    
    @track showSpinner = false;
    @track showModal = false;
    @track driveChangeEvent = null;
    
    @wire(CurrentPageReference) pageRef;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.recordId = this.currentPageReference.attributes.recordId;
    }

    connectedCallback() {
        console.log("connectedCallback recordId::"+this.recordId);
        subscribe("/event/sked_Drive_Change_Request_Event__e", -1, this.messageCallback).then(
            (response) => {
                console.log(
                    "Subscription request sent to: ",
                    JSON.stringify(response.channel)
                );
            }
        );
    }

    messageCallback = (response) => {
        if (response.data.payload.sked_Opportunity_Id__c === this.recordId) {
            console.log("Listen Change Model");
           this.showModal = true;
           this.driveChangeEvent = response.data.payload;
        }
    }; 

    handleCloseModal() {
        console.log("handleCloseModal Change Model");
        this.showModal = false;
        this.handleNavigateToRecord(this.recordId);
    }

    handleNavigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }
}