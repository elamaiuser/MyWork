import { LightningElement, api } from 'lwc';

export default class SlwcLightningFormattedUrl extends LightningElement {
  @api record;
  @api idField = 'id';
  @api labelField = 'name';
  @api labelText;
    
  get url() {
    if(!this.record) return null;
    return '/' + this.record[this.idField];
  }

  get label() {
    if(!this.record) return null;
    if(this.labelText) return this.labelText;
    return this.record[this.labelField];
  }
}