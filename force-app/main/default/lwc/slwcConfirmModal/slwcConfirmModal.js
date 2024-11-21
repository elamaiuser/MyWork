import { LightningElement, api } from 'lwc';
import { classNames } from 'c/slwcUtils';

const MODE = {
  CONFIRM: 'confirm',
  ERROR: 'error',
  SUCCESS: 'success',
}

export default class SlwcConfirmModal extends LightningElement {
  @api isOpen = false;
  @api mode = MODE.CONFIRM;
  @api title = null;
  @api message = null;
  @api handleOnClose = null;
  @api size = null;
  @api width = null;
  @api confirmBtnLabel = null;
  @api cancelBtnLabel = null;
  @api layerIndex = 0;

  get confirmBtnLbl() {
    return this.confirmBtnLabel || 'Confirm'
  }

  get cancelBtnLbl() {
    return this.cancelBtnLabel || 'Cancel'
  }

  get showCancelBtn() {
    return this.cancelBtnLbl !== 'none'
  }
  
  get showConfimnBtn() {
    return this.confirmBtnLbl !== 'none'
  }

  get showFooter() {
    return this.showCancelBtn || this.showConfimnBtn;
  }
  
  get showCloseIcon() {
    return this.mode !== MODE.ERROR && this.mode !== MODE.SUCCESS;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal', `slds-modal_${this.size}`, {
        'slds-fade-in-open': this.isOpen,
        'slds-modal--prompt':  this.mode === MODE.ERROR || this.mode === MODE.SUCCESS
      }),
      headerClass: classNames('slds-modal__header', {
        'slds-theme--error slds-theme--alert-texture': this.mode === MODE.ERROR,
        'slds-theme--success slds-theme--success-texture': this.mode === MODE.SUCCESS
      }),
      footerClass: classNames('slds-modal__footer', {
        'slds-theme--default': this.mode === MODE.ERROR || this.mode === MODE.SUCCESS
      }),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      })
    }
  }
  
  get customStyle() {
    return {
      modalStyle: [
        this.mode === MODE.ERROR ? 'position: absolute; z-index: 11' : '',
        `z-index: ${9001 + Number(this.layerIndex)}`
      ].join(';'),
      modalContainerStyle:  [
        this.width ? `width: ${this.width}` : ''
      ].join(';'),
      backdropStyle: [
        this.mode === MODE.ERROR ? 'position: absolute; z-index: 10' : '',
        `z-index: ${9000 + Number(this.layerIndex)}`
      ].join(';')
    }
  };

  handleConfirm = () => {
    if(this.handleOnClose) {
      this.handleOnClose(true);
    }
    this.isOpen = false;
  }

  handleCancel = () => {
    if(this.handleOnClose) {
      this.handleOnClose(false);
    }
    this.isOpen = false;
  }
}