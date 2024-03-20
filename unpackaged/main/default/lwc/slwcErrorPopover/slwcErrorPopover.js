import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

export default class SlwcErrorPopover extends LightningElement {
    @track showPopover = false;
    @track validities = [];

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('showErrorPopover', this.handleShowErrorPopover, this);
        registerListener('hideErrorPopover', this.closePopover, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    closePopover() {
        this.showPopover = false;
    }

    handleShowErrorPopover(detail) {
        this.showPopover = true;
    }
}