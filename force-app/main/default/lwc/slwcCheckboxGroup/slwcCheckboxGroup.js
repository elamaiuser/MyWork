import { LightningElement, track, wire, api } from 'lwc';

export default class SlwcCheckboxGroup extends LightningElement {
    @api options;
    @api name;
    @api label;
    @api required = false;
    @api errorMessage;

    @track selectedValues = [];

    get hasError() {
        return this.errorMessage;
    }

    get cssClass() {
        let css = "slds-form-element";
        if (this.errorMessage) {
            css += " slds-has-error";
        }
        return css;
    }

    handleOnchange(event) {
        let selectedOption = this.options.find((item) => item.value == event.target.value);
        if (event.target.checked) {
            this.selectedValues.push(selectedOption);
        }
        else {
            let index = this.selectedValues.findIndex((item) => item.value == event.target.value);
            this.selectedValues.splice(index, 1);
        }
        this.dispatchEvent(
            new CustomEvent('checkboxeschanged', { detail: { selectedValues: this.selectedValues } })
        );
    }
}