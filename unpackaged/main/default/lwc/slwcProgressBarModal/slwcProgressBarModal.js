import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';

export default class SlwcProgressBarModal extends LightningElement {
    @track showModal = false;
    @track progress = 0;
    @api action;

    get progressBarStyle() {
        return `width:${this.progress}%`;
    }

    get inProgress() {
        return this.progress < 100;
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('showProgressBarModal', this.handleShowProgressBarModal, this);
        registerListener('updateProgressBar', this.handleUpdateProgressBar, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleShowProgressBarModal(detail) {
        this.progress = detail.progress;
        this.showModal = true;
    }

    handleUpdateProgressBar(detail) {
        this.progress = detail.progress;
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleViewResults() {
        this.showModal = false;
        fireEvent(this.pageRef, 'progressBarModal_viewResults');
    }
}