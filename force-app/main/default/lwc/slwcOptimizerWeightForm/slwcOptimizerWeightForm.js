import { LightningElement, api } from "lwc";
import { debounce } from "c/lodash";
import * as slwcUtils from "c/slwcUtils";

export default class SlwcOptimizerWeightForm extends LightningElement {
  @api collectionOperation;
  @api isReadonly = false;

  @api checkValidity() {
    return [
      ...this.template.querySelectorAll("lightning-input"),
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
  }

  @api reportValidity() {
    return [
      ...this.template.querySelectorAll("lightning-input"),
    ].forEach((inputCmp) => {
      inputCmp.reportValidity();
    });
  }

  handleOnChange(event) {
    event.stopPropagation();
    let weightLevel = event.target.name;
    let weightValue = slwcUtils.getValueFromEvent(event);

    this.debounceFunc && this.debounceFunc.cancel();
    this.debounceFunc = debounce(() => {
      const onchangeEvent = new CustomEvent("weightchange", {
        detail: {
          [weightLevel]: weightValue
        }
      });
      this.dispatchEvent(onchangeEvent);
    }, 200);
    this.debounceFunc();
  }

  handleReset() {
    const onchangeEvent = new CustomEvent('weightreset');
    this.dispatchEvent(onchangeEvent);
  }
}