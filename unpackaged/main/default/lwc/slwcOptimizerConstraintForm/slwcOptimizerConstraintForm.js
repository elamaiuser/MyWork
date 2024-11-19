import { LightningElement, api, track } from "lwc";

export default class SlwcOptimizerConstraintForm extends LightningElement {
  @api optimizerConstraintSettings = [];
  @api isReadonly = false;

  @api checkValidity() {
    return [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("c-slwc-picklist"),
    ].reduce((validSoFar, inputCmp) => {
      return validSoFar && inputCmp.checkValidity();
    }, true);
  }

  @api reportValidity() {
    return [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("c-slwc-picklist"),
    ].forEach((inputCmp) => {
      inputCmp.reportValidity();
    });
  }

  @track settingRecords = [];

  handleOnChange(event) {
    const onchangeEvent = new CustomEvent("constraintchange", event);
    this.dispatchEvent(onchangeEvent);
  }

  handleReset() {
    const onchangeEvent = new CustomEvent("constraintreset", {
      detail: {
        driveType: this.optimizerConstraintSettings[0].driveType
      }
    });
    this.dispatchEvent(onchangeEvent);
  }
}