import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener } from 'c/pubsub';
import * as slwcUtils from 'c/slwcUtils';

export default class SlwcDriveDeliveryJob extends LightningElement {
    @api drive;
    @api masterData;
    @api displayMode;
    
    @track showModal = false;
    
    get cardTitle() {
        let numberOfRecords = 0;
        if(this.drive) {
            numberOfRecords = (this.drive.driveDeliveryJobs || []).length;
        }
        return `Delivery Jobs (${numberOfRecords})`;
    }
    get isMobile(){
        // return 
        return slwcUtils.isMobile()
        
    }
    get showModalMobile(){
        return this.showModal && this.isMobile
    }

    /* PAGE REFERENCE */
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('showDriveDeliveryJobModal', this.handleShowDeliveryJobModal, this);
        registerListener('closeDriveDeliveryJobModal', this.handleCloseDeliveryJobModal, this);
    }

    handleNewDriveDeliveryJob() {
        let eventValues = {action : "create"};
        fireEvent(this.pageRef, 'showDriveDeliveryJobModal', eventValues);
    }
    handleShowDeliveryJobModal(){
        this.showModal = true;
        console.log("handleShowDeliveryJobModal");
        
    }
    handleCloseDeliveryJobModal(){
        this.showModal = false;
        console.log("handleCloseDeliveryJobModal");

    }
}