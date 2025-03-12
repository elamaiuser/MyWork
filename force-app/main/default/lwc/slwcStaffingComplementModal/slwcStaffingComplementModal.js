import { classNames } from 'c/slwcUtils';
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { cloneDeep } from 'c/lodash';

export default class SlwcStaffingComplementModal extends LightningElement {
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

  @api driveGeneratorInstance = {
    drive: null,
    masterData: {
        driveTags: {
        accountTags: [],
        locationTags: []
        },
        isReadonly: false,
        lunchBreakSettings: [],
        resourceRoleGroups: null,
        roleTimeData: null,
        roleTimeDetailMap: null,
        roleTimeVarianceMap: {},
        sameDateActivities: [],
        sameDateDrives: [],
        staffingDecisionMatrix: null,
        timezoneSidId: null,
        vehicles: [],
        backupDriveShiftMap: {},
        adminSetting: {}
    },
    errorMessages: []
  };

  @track showSpinner = false;
  @track dualRoleAssignmentModalData = {};

  get drive() {
    return this.driveGeneratorInstance ? this.driveGeneratorInstance.drive : null;
  }

  get staffingComplement() {
    return this.drive?.driveShifts?.map((driveShift, driveShiftIndex) => {
        return {
            key: driveShift.key,
            name: driveShift.name ?? `Drive Shift ${driveShiftIndex + 1}`,
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

  handleSave = () => {
    const closeEvent = new CustomEvent('save', {
        detail: {
            driveGeneratorInstance: this.driveGeneratorInstance,
            drive: this.drive
        }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }

  showDualRoleAssignmentModal = (event) => {
    const {key} = event.currentTarget.dataset;
    const staffingDetails = this.staffingComplement.find(item => item.key === key);

    this.dualRoleAssignmentModalData = {
        isOpen: true,
        drive: this.drive,
        driveShift: staffingDetails.driveShift
    }
  }

  closeDualRoleAssignmentModal = () => {
    this.dualRoleAssignmentModalData = {
        isOpen: false
    }
  }

  saveDualRoleAssignmentModal = (event) => {
    const { driveShift, jobsToUpdates, jobsToDelete } = event.detail;    
    this.driveGeneratorInstance.saveJobDualRole(driveShift.key, jobsToUpdates, jobsToDelete);

    this.closeDualRoleAssignmentModal();
  }
}