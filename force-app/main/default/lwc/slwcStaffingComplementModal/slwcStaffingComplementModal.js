import { classNames } from 'c/slwcUtils';
import { LightningElement, api, track } from 'lwc';
import { uniqueId } from 'c/lodash';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SlwcStaffingComplementModal extends LightningElement {
  _isOpen = true;
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

  @track showSpinner = false;
  
  get staffingComplement() {
    return this.drive.driveShifts?.map(driveShift => {
        return {
            key: driveShift.key,
            name: driveShift.name,
            driveShift,
            personJobs: driveShift.jobs?.filter(job => job.resourceRole) || []
        }
    }) || []
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal slds-modal_medium', {
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
    this.init();
  } 

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  exceptionHandler = (error) => {
    if(error && error.message) {
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }
  }

  init = () => {
    
  }
  
  handleClose = () => {
    const closeEvent = new CustomEvent('close', {
      detail: {}
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }
}