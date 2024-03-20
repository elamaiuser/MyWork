import { LightningElement, api } from 'lwc';
import { classNames, isNullOrEmpty } from 'c/slwcUtils';

export default class SlwcCustomDatatablePlannedProductivityCell extends LightningElement {
  @api value = null;
  @api showBanding = false;

  get formattedValue() {
    if(isNullOrEmpty(this.value)) return null;
    return +Number(this.value).toFixed(3);
  }

  get banding() {
    if(this.value >= 0.8) return 'Green';
    if(this.value >= 0.6 && this.value < 0.8) return 'Amber';
    if(this.value < 0.6) return 'Red';
  }

  get classes() {
    return classNames('drive-health', {
      'green': this.value >= 0.8,
      'amber': this.value >= 0.6 && this.value < 0.8,
      'red': this.value < 0.6
    })
  }
}