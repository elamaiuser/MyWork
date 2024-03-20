import { LightningElement, track, api } from 'lwc';
import { classNames } from 'c/slwcUtils';

export default class SlwcLinkedDriveModal extends LightningElement {
  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;

    if(this._isOpen) {
      this.init();
    }
  }

  @api drive = null;
  @api readOnly = false;
    
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

  connectedCallback() {
    // this.isOpen = true;
    // this.drive =  {
    //   id: 'a1Z2i000001iSNaEAM',
    //   typeOfDrive: 'Mobile',
    //   driveDate: '2021-06-21',
    //   collectionOperationId: 'a0g3F000001iKiaQAE'
    // };
    
    this.init();
  } 

  init = () => {
    if(!this.drive || !this.drive.linkedDriveId) return;
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