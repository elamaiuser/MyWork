import { LightningElement, api, track } from 'lwc';
import { classNames, getValueFromEvent } from 'c/slwcUtils';
import { compact } from 'c/lodash';

export default class SlwcAcknowledgeConfirmModal extends LightningElement {
  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  }
  set isOpen(value) {
    this._isOpen = value;
    
    if(this._isOpen) {
      this.init();
    }
  }
  
  @api driveShiftTrade;
  @api userResource;
  
  @track model = {};

  size = 'medium';
  get customClass() {
    return {
      modalClass: classNames('slds-modal', `slds-modal_${this.size}`, {
        'slds-fade-in-open': this.isOpen
      }),
      headerClass: classNames('slds-modal__header', {
      }),
      footerClass: classNames('slds-modal__footer', {
      }),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      })
    }
  }
  
  get customStyle() {
    return {
      modalStyle: [
        `z-index: 9003`
      ].join(';'),
      modalContainer: compact([
        `transform: none`,
      ]).join(';'),
      backdropStyle: [
        `z-index: 9002`
      ].join(';')
    }
  };

  get btnConfirmDisabled() {
    if(this.isTATAcknowledgeRequired && !this.model.staffTATAcknowledge) return true;
    if(this.isGMHAcknowledgeRequired && !this.model.staffGMHAcknowledge) return true;
    if(this.isRelocatedAcknowledgeRequired && !this.model.staffRelocatedAcknowledge) return true;
    if(this.UnavailableForCOAcknowledgeRequired && !this.model.staffUnavailableForCOAcknowledge) return true;
    return false;
  }

  get isRequestingStaff() {
    return this.driveShiftTrade?.requestingStaffId === this.userResource.id;
  }

  get isTATAcknowledgeRequired() {
    if(this.isRequestingStaff) {
        return this.driveShiftTrade?.requestingStaffTurnaroundViolation;
    }
    return this.driveShiftTrade?.tradingStaffTurnaroundViolation;
  }

  get isGMHAcknowledgeRequired() {
    if(this.isRequestingStaff) {
        return this.driveShiftTrade?.requestingStaffGuaranteedMinHrsForfeited;
    }
    return this.driveShiftTrade?.tradingStaffGuaranteedMinHrsForfeited;
  }

  get isRelocatedAcknowledgeRequired() {
    if(this.isRequestingStaff) {
      return this.driveShiftTrade?.requestingStaffRelocated;
    }
    return this.driveShiftTrade?.tradingStaffRelocated;
  }

  get UnavailableForCOAcknowledgeRequired() {
    if(this.isRequestingStaff) {
      return this.driveShiftTrade?.requestingStaffUnavailableForCO;
    }
    return this.driveShiftTrade?.tradingStaffUnavailableForCO;
  }

  connectedCallback() {
    this.init();
  }

  showLoading() {
    this.showSpinner = true;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  init() {
    this.model = {
        staffTATAcknowledge: false,
        staffGMHAcknowledge: false,
        staffRelocatedAcknowledge: false,
        staffUnavailableForCOAcknowledge: false
    }
  }

  handleOnChangeModel(event) {
    const eventName = event.target.name;
    this.model[eventName] = getValueFromEvent(event);
  }

  handleConfirm = () => {
    this.isOpen = false;

    let returnModel = {
        id: this.driveShiftTrade.id
    }
    
    if(this.isTATAcknowledgeRequired) {
        if(this.isRequestingStaff) {
            returnModel.requestingStaffTATAcknowledge = this.model.staffTATAcknowledge;
        } else {
            returnModel.tradingStaffTATAcknowledge = this.model.staffTATAcknowledge;
        }
    }
    if(this.isGMHAcknowledgeRequired) {
        if(this.isRequestingStaff) {
            returnModel.requestingStaffGMHAcknowledge = this.model.staffGMHAcknowledge;
        } else {
            returnModel.tradingStaffGMHAcknowledge = this.model.staffGMHAcknowledge;
        }
    }
    if (this.isRelocatedAcknowledgeRequired) {
      if(this.isRequestingStaff) {
        returnModel.requesterRelocatedAcknowledge = this.model.staffRelocatedAcknowledge;
      } else {
        returnModel.traderRelocatedAcknowledge = this.model.staffRelocatedAcknowledge;
      }
    }
    if (this.UnavailableForCOAcknowledgeRequired) {
      if (this.isRequestingStaff) {
        returnModel.requesterUnavailableForCOAcknowledge = this.model.staffUnavailableForCOAcknowledge;
      } else {
        returnModel.traderUnavailableForCOAcknowledge = this.model.staffUnavailableForCOAcknowledge;
      }
    }
    
    const saveEvent = new CustomEvent('save', {
      detail: returnModel
    });
    this.dispatchEvent(saveEvent);
    this.handleCancel();
  }

  handleCancel = () => {
    this.isOpen = false;

    const closeEvent = new CustomEvent('close', {
      detail: {
        result: false
      }
    });
    this.dispatchEvent(closeEvent);
  }
}