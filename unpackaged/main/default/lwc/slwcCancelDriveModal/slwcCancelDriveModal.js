import { LightningElement, api, track } from 'lwc';
import { classNames, getValueFromEvent } from 'c/slwcUtils';
import { driveService, driveQueryModel } from 'c/dataService';
import { compact } from 'c/lodash';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { DRIVE_APPROVAL_STATUS, PENDING_ACTION } from 'c/slwcConstants';

export default class SlwcCancelDriveModal extends LightningElement {
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
  
  @api drives = [];
  @api disableDriveReplacement = false;

  @track showSpinner = false;
  @track cancellationReason = null;
  @track initiatedBy = null;
  @track replacementDrive = null;
  
  get initiatedByControllingFieldValues() {
    return this.drives.map(item => item.typeOfDrive);
  }

  get cancellationReasonControllingFieldValues() {
    return this.initiatedBy ? [this.initiatedBy] : []
  }

  get driveReplacementDefaultFilters() {
    return {
      excludedIds: (this.drives || []).map(drive => drive.id)
    }
  }

  get cancelConfirmText() {
    if(this.drives.length === 1) {
      return 'Are you sure you want to cancel this drive?';
    }

    return `Are you sure you want to cancel ${this.drives.length} selected drive(s)?`;
  } 

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
        `width: 32rem`
      ]).join(';'),
      backdropStyle: [
        `z-index: 9002`
      ].join(';')
    }
  };

  get btnConfirmDisabled() {
    return !this.cancellationReason || this.showSpinner;
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
    this.cancellationReason = null;
    this.initiatedBy = null;
    this.replacementDrive = null;
  }

  handleCancellationReasonChanged = (event) => {
    let value = getValueFromEvent(event);
    this.cancellationReason = value;
  }

  handleInitiatedByChanged = (event) => {
    let value = getValueFromEvent(event);
    this.initiatedBy = value;
  }
  
  handleDriveSelection(event) {
    this.replacementDrive = event.detail.drive;
  }

  handleConfirm = () => {
    let driveHelper = new DriveHelper();
    let drivesToSave = this.drives.map(drive => {
      return driveHelper.cancelDrive(drive, {
        timezoneSidId: TIME_ZONE,
        cancellationReason: this.cancellationReason,
        initiatedBy: this.initiatedBy,
        replacementDriveId: (!this.disableDriveReplacement && this.replacementDrive) ? this.replacementDrive.id : null
      });
    });
    let service = new driveService();
    this.showLoading();
    return service.saveList(drivesToSave)
    .then((result) => {
      if(!result || !result.success) {
        throw result;
      }
      
      this.isOpen = false;
      
      if(drivesToSave.length === 1 && 
        drivesToSave[0].approvalStatus === DRIVE_APPROVAL_STATUS.SUBMITTED && 
        drivesToSave[0].pendingAction === PENDING_ACTION.CANCEL_IN_PROCESS) {
        this.dispatchEvent(new ShowToastEvent({
          message: 'Drive Cancellation has been submitted for approval',
          variant: 'success',
          mode: 'dismissable'
        }));
      } else {
        this.dispatchEvent(new ShowToastEvent({
          message: 'Cancelled Drive(s) successfully.',
          variant: 'success',
          mode: 'dismissable'
        }));
      }
      
      const closeEvent = new CustomEvent('close', {
        detail: {
          result: true,
          cancelledDrives: drivesToSave
        }
      });
      this.dispatchEvent(closeEvent);
    })
    .catch((error) => {
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    })
    .finally(() => this.hideLoading());
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