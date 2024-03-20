import { LightningElement, api } from 'lwc';
import { isNullOrEmpty } from 'c/slwcUtils';

export default class SlwcLightningFormattedTravelDistance extends LightningElement {
  @api value;
    
  get formattedValue() {
    return !isNullOrEmpty(this.value) ? `${Math.round(this.value)} mi` : 'N/A'
  }
}