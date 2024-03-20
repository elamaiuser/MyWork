import { LightningElement, track, wire, api } from 'lwc';

export default class SlwcPageErrors extends LightningElement {
    @track _validities = [];
    @track showErrors = false;
    @api title = 'Review the errors on this page.';
    
    @api
    set validities(input) {
        this._validities = input;
        this.showErrors = this._validities && this._validities.length > 0;
    }
    get validities() {
        return this._validities;
    }
}