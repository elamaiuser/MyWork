import { LightningElement, api, track } from 'lwc';
import { classNames, getValueFromEvent } from 'c/slwcUtils';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { DRIVE_STATUS } from 'c/slwcConstants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SlwcPendingActionDriveConfirmModal extends LightningElement {
  driveHelper = new DriveHelper();
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
  
  @api driveGeneratorInstance;
  @api model = {
    submissionNotes: null
  }
  @api masterData = {};

  @track resolveContentionsModalData = {
  };

  get drive() {
    return this.driveGeneratorInstance ? this.driveGeneratorInstance.drive : null;
  }
  
  get isAPSUser() {
    return this.driveHelper.isAPSUser(this.masterData.loginUser);
  }

  get pendingActionReasonCodes() {
    return this.drive?.pendingActionReasonCode?.split(';') || []
  }

  get submissionNotesRequired() {
    return this.drive && this.drive.routeApprovalRequestTo === 'Request DM evaluation';
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal', `slds-modal_x-small`, {
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
      backdropStyle: [
        `z-index: 9002`
      ].join(';')
    }
  };

  get resolveContentionsModalCustomClass() {
    return {
      modalClass: classNames('slds-modal', `slds-modal_medium`, {
        'slds-fade-in-open': this.resolveContentionsModalData.isOpen
      }),
      headerClass: classNames('slds-modal__header', {
      }),
      footerClass: classNames('slds-modal__footer', {
      }),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.resolveContentionsModalData.isOpen
      })
    }
  }
  
  get resolveContentionsModalCustomStyle() {
    return {
      modalStyle: [
        `z-index: 9005`
      ].join(';'),
      backdropStyle: [
        `z-index: 9004`
      ].join(';')
    }
  };

  connectedCallback() {
    this.init();
  }

  init() {
    console.log('this.drive?.pendingActionReasonCode ',this.drive?.pendingActionReasonCode);
    this.model = {
      submissionNotes: null
    };
  }

  handleOnChange(event) {
    event.stopPropagation();

    if(event.detail && event.detail.selection) {
      this.model[event.currentTarget.name] = event.detail.selection.id;
    } else {
      let value = getValueFromEvent(event);
      this.model[event.currentTarget.name] = value;
    }
  }

  validate() {
    let allInputsCorrect = [
        ...this.template.querySelectorAll("lightning-textarea")
    ];
    return allInputsCorrect.reduce((validSoFar, inputField) => {
        inputField.reportValidity();
        return validSoFar && inputField.checkValidity();
    }, true);
  }

  handleSave = (event) => {
    if(!this.validate()) return;
    const action = event.currentTarget.dataset['action'];
    
    if(action === 'putToApprovalQueue') {
      this.isOpen = false;
      const closeEvent = new CustomEvent('save', {
        detail: {
          submissionNotes: this.model.submissionNotes,
          contentionResolution: []
        }
      });
      this.dispatchEvent(closeEvent);
      return;
    }

    if(action === 'resolveContentions') {
      this.showResolveContentionsModal();
      this.handleCancel();
    }
  }

  handleCancel = () => {
    this.isOpen = false;

    const closeEvent = new CustomEvent('close', {
      detail: {
      }
    });
    this.dispatchEvent(closeEvent);
  }

  showResolveContentionsModal = () => {
    this.resolveContentionsModalData = {
      isOpen: true
    };
  }

  closeResolveContentionsModal = () => {
    this.resolveContentionsModalData = {};
  }

  handleSaveContentionsModal = () => {
    Promise.resolve()
    .then(() => {
      const resolveContentionComponent = this.template.querySelector('c-slwc-resolve-drive-contentions');
      return resolveContentionComponent.getData();
    })
    .then(({ drive, contentionResolution, driveTimeBlockContentions = [], driveContentions, equipmentJob, vehicleJob }) => {
      if(driveTimeBlockContentions.length > 0) {
         this.dispatchEvent(new ShowToastEvent({
          message: 'Please resolve all time block contentions before saving.',
          variant: 'error',
          mode: 'dismissable',
        }));
        return;
      }

      const anyNotPassedContention = driveContentions.find(item => {
        return !item.passed;
      })
  
      if(anyNotPassedContention) {
        this.dispatchEvent(new ShowToastEvent({
          message: 'Please resolve all drive contentions before saving.',
          variant: 'error',
          mode: 'dismissable',
        }));
        return;
      }
  
      this.closeResolveContentionsModal();
      this.isOpen = false;
  
      let equipmentAllocations = equipmentJob ? equipmentJob.jobAllocations : null;
      let vehicleAllocations = vehicleJob ? vehicleJob.jobAllocations : null;
      const closeEventDetail = {
        drive,
        submissionNotes: this.model.submissionNotes,
        contentionResolution: contentionResolution,
        driveShiftContentionResolution: drive.driveShifts.map(driveShift => driveShift.contentionResolution),
        equipmentAllocations,
        vehicleAllocations
      };
      if(!this.driveHelper.isDriveSubmittedForSubmissionApproval(this.drive)){
        closeEventDetail.status = [DRIVE_STATUS.DRAFT].includes(this.drive.status) ? DRIVE_STATUS.TENTATIVE : this.drive.status;
      } else {
        closeEventDetail.status = this.drive.status;
      }
      const closeEvent = new CustomEvent('save', { detail: closeEventDetail });
      this.dispatchEvent(closeEvent);
    })
  }
}