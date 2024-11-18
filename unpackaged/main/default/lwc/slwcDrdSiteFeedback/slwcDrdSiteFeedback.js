import { LightningElement, api, track } from 'lwc';

export default class SlwcDrdSiteFeedback extends LightningElement {
    @api recordId;

    @track modalData = {
        isOpen: false
    }

    handleOpenModal() {
        this.modalData.isOpen = true;
    }

    handleCloseModal() {
        this.modalData.isOpen = false;
    }
}