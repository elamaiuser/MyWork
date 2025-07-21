import { LightningElement, track, api, wire } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { fireEvent } from 'c/pubsub';
import { MANUALLY_CREATED_FROM } from 'c/slwcConstants';
import { DriveHelper } from 'c/slwcDriveGenerator';

const MODE = {
  DEFAULT: 'default',
  RESOLVE_DRIVE_CONTENTION: 'resolveDriveContention',
}

export default class SlwcDualRoleAssignmentModal extends LightningElement {
  driveHelper = new DriveHelper();

  @api mode = MODE.DEFAULT;
  @api drive = null;
  @api driveShift = null;

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

  @track model = {};
  @track showSpinner = false;
  @track errorMessages = [];
  
  @wire(CurrentPageReference) pageRef;

  get customClass() {
    return {
      modalClass: classNames('slds-modal slds-modal_x-small', {
        'slds-fade-in-open': this.isOpen
      }),
      headerClass: classNames('slds-modal__header'),
      footerClass: classNames('slds-modal__footer'),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      })
    }
  }

  get primaryRoleOptions() {
    return ['2RBC', 'Charge', 'Trainee', 'Driver', 'Driver Support', 'VP/HH', 'Apheresis', 'Plasma'].map(role => {
      return {
        label: role,
        value: role
      }
    })
  }

  get secondaryRoleOptions() {
    if(!this.model || !this.model.primaryRole) return [];

    const roleMap = {
      '2RBC': ['Driver', 'Driver Support', 'OJI'],
      'Charge': ['Driver', 'Driver Support'],
      'Trainee': ['Driver Support'],
      'Driver': ['Competent Driver', 'OJI'],
      'Driver Support': ['OJI'],
      'VP/HH': ['OJI'],
      'Apheresis': ['OJI'],
      'Plasma': ['OJI']
    }

    return (roleMap[this.model.primaryRole] || []).map(role => {
      return {
        label: role,
        value: role
      }
    })
  }

  connectedCallback() {
    registerListener('showDualRoleAssignmentModal', this.init, this);
  } 

  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  init = (detail) => {
    this.errorMessages = [];
    this.resetModel(); 

    if(this.mode === MODE.DEFAULT) {
      const { drive, driveShift } = detail;
      this.drive = drive;
      this.driveShift = driveShift;
      this.isOpen = true;  
    }
  }

  resetModel = () => {
    this.model = {
      primaryRole: null,
      secondaryRole: null,
      quantity: null
    };
  }

  handleOnChange(event) {
    event.stopPropagation();
    let value = getValueFromEvent(event);
    this.model[event.currentTarget.name] = value;

    if(event.currentTarget.name === 'primaryRole') {
      this.model.secondaryRole = null;

      const primaryJob = this.getJobByRole(value);
      if(primaryJob) {
        this.model.quantity = primaryJob.quantity;
      }
    }
  }

  getJobByRole = (role) => {
    if(!this.driveShift || !this.driveShift.jobs) return null;

    return this.driveShift.jobs.find(job => {
      return job.resourceRole === role && !job.dualRole && job.manuallyCreatedFrom !== MANUALLY_CREATED_FROM.STAFFING_MODAL;
    })
  }
  getJobsToMerge = () => {
    if(!this.driveShift || !this.driveShift.jobs) return {
      primaryRoleJob: null,
      secondaryRoleJob: null
    };

    const primaryRoleJob = this.getJobByRole(this.model.primaryRole);
    const secondaryRoleJob = this.getJobByRole(this.model.secondaryRole);

    return {
      primaryRoleJob,
      secondaryRoleJob
    }
  }

  mergeSecondaryRoleJobToPrimaryRoleJob = (primaryRoleJob, secondaryRoleJob, quantity) => {
    if(!primaryRoleJob) return null;
    if(!secondaryRoleJob) return primaryRoleJob;

    return this.driveHelper.generateDualRoleJob(primaryRoleJob, secondaryRoleJob, quantity);
  }

  validate = () =>{
    this.errorMessages = [];

    const allValid = [
        ...this.template.querySelectorAll('lightning-combobox'),
        ...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
    
    const {primaryRoleJob, secondaryRoleJob} = this.getJobsToMerge();
    if(this.model.primaryRole && !primaryRoleJob) {
     this.errorMessages.push({
       message: `Cannot find job ${this.model.primaryRole}`
     }) 
    }
    if(this.model.secondaryRole && !secondaryRoleJob) {
      this.errorMessages.push({
        message: `Cannot find job ${this.model.secondaryRole}`
      }) 
    }

    if(this.model.primaryRole && this.model.secondaryRole && primaryRoleJob && secondaryRoleJob) {
      const maxQuantityOfDualRoleJob = Math.min(primaryRoleJob.quantity, secondaryRoleJob.quantity);
      if(this.model.quantity !== undefined && (
        this.model.quantity <= 0 || this.model.quantity > maxQuantityOfDualRoleJob
      )) {
        this.errorMessages.push({
          message: `The quantity of dual roles must be greater than 0 and less than or equal to ${maxQuantityOfDualRoleJob}`
        }) 
      }
    }

    return allValid && !this.errorMessages.length;
  }

  handleCancel = () => {
    if(this.mode === MODE.DEFAULT) {
      fireEvent(this.pageRef, 'closeDualRoleAssignmentModal');
    } else {
      this.dispatchEvent(new CustomEvent('close', {
        detail: {
        }
      }));
    }
    this.isOpen = false;
  }

  handleSave = () => {
    if(!this.validate()) return;

    const {primaryRoleJob, secondaryRoleJob} = this.getJobsToMerge();
    const {jobsToCreate, jobsToUpdate, jobsToDelete} = this.mergeSecondaryRoleJobToPrimaryRoleJob(primaryRoleJob, secondaryRoleJob, this.model.quantity);
    const eventValues = { 
      drive: this.drive, 
      driveShift: this.driveShift,
      jobsToCreate,
      jobsToUpdate,
      jobsToDelete
    };

    if(this.mode === MODE.DEFAULT) {
      fireEvent(this.pageRef, 'saveDualRoleAssignmentModal', eventValues); 
      this.handleCancel();
    } else {
      this.dispatchEvent(new CustomEvent('save', {
        detail: eventValues
      }));
    }
  }
}