import { CurrentPageReference } from 'lightning/navigation';
import { api, LightningElement, track, wire } from 'lwc';
export default class SlwcAccountMassListenDriveChange extends LightningElement {
    @api recordId;
    // @api recordId = '0013F00000TN2I5QAL';

    @track recordIds = [];

    @wire(CurrentPageReference) pageRef;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        let recordId = this.currentPageReference.state.c__recordId;
        this.init(recordId);
    }

    connectedCallback() {
        if (this.recordId) {
            this.init(this.recordId);
        }
    }

    init = (recordId) => {
        if(!recordId) return;
        this.recordIds = [recordId];
    }
}