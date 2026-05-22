import { LightningElement, api } from 'lwc';

export default class Sfc360GenericDetailModal extends LightningElement {
    @api open = false;
    @api title = "Details";
    @api loading = false;

    get hasData() {
        return this.data && this.data.length > 0;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }
}