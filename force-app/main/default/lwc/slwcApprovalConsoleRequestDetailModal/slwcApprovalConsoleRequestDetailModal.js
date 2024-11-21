import { LightningElement, track, api } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';

export default class SlwcApprovalConsoleRequestDetailModal extends LightningElement {
  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;
    this.init();
  }

  @api recordId = null;
  @api showSpinner = false;
  @api objectLabel = null;

  get title() {
    return `${this.objectLabel} Details`;
  }

  get confirmBtnLabel() {
    return this.action;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal slds-modal_large', {
        'slds-fade-in-open': this.isOpen
      }),
      headerClass: classNames('slds-modal__header'),
      footerClass: classNames('slds-modal__footer'),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      })
    }
  }
  
  init = () => {
  }

  handleCancel = () => {
    const closeEvent = new CustomEvent('close', {
      detail: {
        result: true
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }
}