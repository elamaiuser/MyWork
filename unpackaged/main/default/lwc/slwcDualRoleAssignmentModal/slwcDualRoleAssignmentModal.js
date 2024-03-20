import { LightningElement, track, api, wire } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { fireEvent } from 'c/pubsub';
import { MANUALLY_CREATED_FROM } from 'c/slwcConstants';

export default class SlwcDualRoleAssignmentModal extends LightningElement {
  @api drive = null;
  @api driveShift = null;

  @track showModal = false;
  @track model = {};
  @track showSpinner = false;
  @track errorMessages = [];
  
  @wire(CurrentPageReference) pageRef;

  get customClass() {
    return {
      modalClass: classNames('slds-modal slds-modal_x-small', {
        'slds-fade-in-open': this.showModal
      }),
      headerClass: classNames('slds-modal__header'),
      footerClass: classNames('slds-modal__footer'),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.showModal
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
    const { drive, driveShift } = detail;
    this.drive = drive;
    this.driveShift = driveShift;
    this.showModal = true;

    this.errorMessages = [];
    this.resetModel(); 
  }

  resetModel = () => {
    this.model = {
      primaryRole: null,
      secondaryRole: null
    };
  }

  handleOnChange(event) {
    event.stopPropagation();
    let value = getValueFromEvent(event);
    this.model[event.currentTarget.name] = value;

    if(event.currentTarget.name === 'primaryRole') {
      this.model.secondaryRole = null;
    }
  }

  handleCancel = () => {
    fireEvent(this.pageRef, 'closeDualRoleAssignmentModal');
    this.showModal = false;
  }

  getJobsToMerge = () => {
    if(!this.driveShift || !this.driveShift.jobs) return {
      primaryRoleJob: null,
      secondaryRoleJob: null
    };

    const primaryRoleJob = this.driveShift.jobs.find(job => {
      return job.resourceRole === this.model.primaryRole && !job.dualRole && job.manuallyCreatedFrom !== MANUALLY_CREATED_FROM.STAFFING_MODAL;
    })

    const secondaryRoleJob = this.driveShift.jobs.find(job => {
      return job.resourceRole === this.model.secondaryRole && !job.dualRole && job.manuallyCreatedFrom !== MANUALLY_CREATED_FROM.STAFFING_MODAL;
    })

    return {
      primaryRoleJob,
      secondaryRoleJob
    }
  }
  
  mergeSecondaryRoleJobToPrimaryRoleJob = (primaryRoleJob, secondaryRoleJob) => {
    if(!primaryRoleJob) return null;
    if(!secondaryRoleJob) return primaryRoleJob;

    let newJob = {
      ...primaryRoleJob,
      dualRole: secondaryRoleJob.resourceRole,
    };

    if(newJob.quantity < secondaryRoleJob.quantity) {
      newJob.quantity = secondaryRoleJob.quantity;
    }
    
    return newJob;
  }

  validate() {
    this.errorMessages = [];

    const allValid = [
        ...this.template.querySelectorAll('lightning-combobox')]
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

    return allValid && !this.errorMessages.length;
  }

  handleSave = () => {
    if(!this.validate()) return;

    const {primaryRoleJob, secondaryRoleJob} = this.getJobsToMerge();
    const newJob = this.mergeSecondaryRoleJobToPrimaryRoleJob(primaryRoleJob, secondaryRoleJob);
    
    const eventValues = { drive: this.drive, driveShift: this.driveShift, newJob: newJob };
    fireEvent(this.pageRef, 'saveDualRoleAssignmentModal', eventValues);

    this.handleCancel();
  }
}