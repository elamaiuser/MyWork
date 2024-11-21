import { LightningElement, api } from 'lwc';

export default class SlwcResourceName extends LightningElement {
  @api resource = null;

  get recordUrl() {
    if(!this.resource) return null;
    return '/' + this.resource.id
  }
}