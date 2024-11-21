import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { DRIVE_STATUS } from 'c/slwcConstants';
import { classNames } from 'c/slwcUtils';
import {
  driveService,
  driveQueryModel
} from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class SlwcDriveStatusPath extends NavigationMixin(LightningElement) {
  get STATUS_MAP() {
    return {
      [DRIVE_STATUS.DRAFT]: {
        nextStatuses: [DRIVE_STATUS.CANCEL]
      },
      [DRIVE_STATUS.SYSTEM_GENERATED]: {
        nextStatuses: [DRIVE_STATUS.CANCEL]
      },
      [DRIVE_STATUS.HOLD]: {
        nextStatuses: [DRIVE_STATUS.CANCEL]
      },
      [DRIVE_STATUS.TENTATIVE]: {
        nextStatuses: [DRIVE_STATUS.CANCEL]
      },
      [DRIVE_STATUS.CONFIRMED]: {
        nextStatuses: (this.drive && this.drive.isSurrogate) ? [DRIVE_STATUS.CANCEL, DRIVE_STATUS.COMPLETE] : [DRIVE_STATUS.CANCEL]
      },
      [DRIVE_STATUS.COMPLETE]: {
        defaultSelectedClass: 'slds-is-won',
        nextStatuses: [],
        saveFn: (drive) => this.completeDrive(drive)
      },
      [DRIVE_STATUS.CANCEL]: {
        defaultSelectedClass: 'slds-is-lost',
        nextStatuses: [],
        saveFn: (drive) => this.cancelDrive(drive)
      }
    }
  }
  
  @track showSpinner = false;
  @track currentStatus = null;
  @track statuses = [];
  @track drive = null;
  @track confirmModalData = {};
  @track cancelDriveModalData = {};

  @wire(CurrentPageReference) pageRef;

  /** Initialize **/
  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.currentPageReference = currentPageReference;
    let recordId = this.currentPageReference.attributes.recordId;
    this.initialize(recordId);
  }

  initialize(recordId) {
    if(!recordId) return;
    this.recordId = recordId;
    this.refreshStatuses();

    this.showLoading()
    return this.getDriveData()
    .then(() => {
      this.refreshStatuses();
    })
    .finally(() => this.hideLoading());
  }

  // connectedCallback() {
  //   this.recordId = 'a1Z2i000001itUSEAY';
  //   this.initialize(this.recordId);
  // }
  
  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }
  
  exceptionHandler = (error) => {
    console.log(error);
    if(error && error.message) {
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }
  }

  getDriveData() {
    let service = new driveService();
    let queryModel = new driveQueryModel();
    queryModel.recordIds = [this.recordId];
    return service.query(queryModel)
    .then(([drive]) => {
      this.drive = drive;
      
      //update current status
      this.currentStatus = this.drive.status;
    })
  }
  
  refreshStatuses() {
    const currentStatus = this.currentStatus;
    let nextStatuses = [];
    let previousStatuses = [];
    if(currentStatus) {
      nextStatuses = this.STATUS_MAP[currentStatus].nextStatuses || [];

      const allStatuses = Object.keys(this.STATUS_MAP);
      const currentStatusIndex = allStatuses.findIndex(status => status === currentStatus);
      for(let i = 0; i < currentStatusIndex; i++) {
        previousStatuses.push(allStatuses[i]);
      }
    }
    
    this.statuses = Object.keys(this.STATUS_MAP).map(status => {
      const statusSettings = this.STATUS_MAP[status];
      const isComplete = previousStatuses.includes(status);
      const isActive = status === currentStatus;
      const isIncomplete = !isComplete && !isActive;
      const isDisabled = isComplete || isActive || (isIncomplete && !nextStatuses.includes(status));
      return {
        value: status,
        label: status,
        disabled: !nextStatuses.includes(status),
        class: classNames('slds-path__item', {
          'slds-is-disabled': isDisabled,
          'slds-is-complete': isComplete,
          [`slds-is-current slds-is-active ${statusSettings.defaultSelectedClass}`]: isActive,
          'slds-is-incomplete': isIncomplete,
        })
      }
    })
  }

  handleNavigateToRecord(recordId) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            objectApiName: 'sked_Drive__c',
            actionName: 'view'
        }
    });
  }

  handleStatusClick(event) {
    const value = event.currentTarget.dataset['value'];
    const status = this.statuses.find(item => item.value === value);
    if(!status || status.disabled) return;
    
    const saveFn = this.STATUS_MAP[value].saveFn;
    if(!saveFn) return;
    saveFn(this.drive);
  }

  cancelDrive(drive) {
    this.showCancelDriveModal([drive]);
  }

  completeDrive(drive) {
    this.showConfirmModal({
      title: 'Complete Drive',
      message: 'Are you sure you want to complete this drive?',
      onClose: (result) => {
          this.hideConfirmModal();
          if (result) {
            this.showLoading()
            const service = new driveService();
            service.save({
              id: this.drive.id,
              status: DRIVE_STATUS.COMPLETE
            })
            .then(() => {
              this.handleNavigateToRecord(this.recordId);
            })
            .catch((e) => this.exceptionHandler(e))
            .finally(() => this.hideLoading());
          }
      },
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No'
    });
  }

  /** Cancel Drive Modal */
  showCancelDriveModal = (drives) => {
    this.cancelDriveModalData = {
      shown: true,
      drives: drives || []
    }
  }

  closeCancelDriveModal = (event) => {
      this.cancelDriveModalData = {};
      const result = !!event.detail.result;
      if(result) {
        this.handleNavigateToRecord(this.recordId);
      }
  }

  /** Confirm Modal **/
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {
      ...confirmModalData,
      isOpen: true,
      confirmBtnLabel: confirmModalData.confirmBtnLabel || 'Yes',
      cancelBtnLabel: confirmModalData.cancelBtnLabel || 'No',
    }
  }

  hideConfirmModal() {
    this.confirmModalData = {};
  }
}