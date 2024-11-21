import { LightningElement, api } from 'lwc';
import { isNullOrEmpty } from 'c/slwcUtils';

export default class SlwcLightningFormattedTravelTime extends LightningElement {
  @api value;

  get formattedValue() {
    return !isNullOrEmpty(this.value) ? `${this.convertHours(this.value)}` : 'N/A'
  }

  convertHours(minutes) {
    minutes = Math.ceil(minutes);
    const min = Math.round(minutes % 60)
    const hours = Math.round(Math.floor(minutes / 60))
    return `${hours}h ${min}m`
  }
}