import { LightningElement, api } from 'lwc';
import {
    isNullOrEmpty
} from 'c/slwcUtils';

export default class SlwcTextArea extends LightningElement {
    @api disabled;
    @api label;
    @api name;
    @api value;
    @api maxLength;
    @api showLength;

    get currentLength() {
        return isNullOrEmpty(this.value) ? 0 : this.value.length;
    }

    get textClass() {
        return this.currentLength == this.maxLength ? 'slwc-text-area-text-colour-red' : '';
    }

    handleOnChange(event) {
        this.dispatchEvent(new CustomEvent('change', event));
    }
}