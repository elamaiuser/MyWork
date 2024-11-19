import { LightningElement, api } from "lwc";
import checkbox from './checkbox.html';
import picklist from './picklist.html';
import { OPTIMIZER_SETTING_DISPLAY_TYPE } from "c/slwcConstants";
import * as slwcUtils from "c/slwcUtils";

const DISPLAY_MAPPING = {
    [OPTIMIZER_SETTING_DISPLAY_TYPE.PICKLIST]: picklist,
    [OPTIMIZER_SETTING_DISPLAY_TYPE.CHECKBOX]: checkbox
};

export default class SlwcOptimizerConstraintInput extends LightningElement {
  @api settingRecord;
  @api disabled;

  render() {
    return DISPLAY_MAPPING[this.settingRecord.displayType];
  }

  handleOnChange(event) {
    let newValue = slwcUtils.getValueFromEvent(event);
    const onchangeEvent = new CustomEvent("valuechange", {
      detail: {
        id: this.settingRecord.id,
        value: newValue
      }
    });

    this.dispatchEvent(onchangeEvent);
  }
}