import { LightningElement, api } from 'lwc';
import { classNames, isNullOrEmpty } from 'c/slwcUtils';

export default class SlwcCustomDatatablePlannedProductivityCell extends LightningElement {
  @api value = null;
  @api showBanding = false;
  @api band = null; //HRP-10892

  get formattedValue() {
    if(isNullOrEmpty(this.value)) return null;
    return +Number(this.value).toFixed(3);
  }

  get banding() {
    /* HRP - 10892 - Replacing the below logic to include new one to check for banding based on the formula field value instead of default hard values
    if(this.value >= 0.8) return 'Green';
    if(this.value >= 0.6 && this.value < 0.8) return 'Amber';
    if(this.value < 0.6) return 'Red'; */
    if (this.band.toString().includes("Green")) return "Green";
    if (this.band.toString().includes("Amber")) return "Amber";
    if (this.band.toString().includes("Red")) return "Red";
  }

  get classes() {
    // HRP-10892 - Added a if else logic to check for the value of the band field to set the class name accordingly
    if(this.band){
      return classNames('drive-health', {
        /* HRP - 10892 - Replacing the below logic to include new one to check for banding based on the formula field value instead of default hard values
        'green': this.value >= 0.8,
        'amber': this.value >= 0.6 && this.value < 0.8,
        'red': this.value < 0.6 */
        'green': this.band.toString().includes("Green"),
        'amber': this.band.toString().includes("Amber"),
        'red': this.band.toString().includes("Red")
      });
    }
    else {
      return classNames('drive-health',{
        'green': this.value >= 0.8,
        'amber': this.value >= 0.6 && this.value < 0.8,
        'red': this.value < 0.6
      });
    }    
  }
}