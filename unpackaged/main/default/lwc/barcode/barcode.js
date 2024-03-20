import { LightningElement, api, track } from 'lwc';
import "./jsBarcode";

export default class Barcode extends LightningElement {
  @track _value = null;
  @api
  get value() {
    return this._value;
  }
  set value(value) {
    this._value = value;
    this.renderBarcode()
  }

  connectedCallback() {
  }

  renderedCallback() {
    this.renderBarcode();
  }

  renderBarcode() {
    if(!this.value) return;
    const canvas = this.template.querySelector('.barcode');
    if(!canvas) return;

    JsBarcode(canvas, this.value);
  }
}