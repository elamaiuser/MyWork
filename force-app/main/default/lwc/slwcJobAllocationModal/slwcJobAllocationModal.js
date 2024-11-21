import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { cloneDeep } from 'c/lodash';
import { getValueFromEvent } from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcJobAllocationModal extends LightningElement {
  driveHelper = new DriveHelper();

  @track _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  }
  set isOpen(value) {
    this._isOpen = value;
    if (this._isOpen) {
      this.init();
    }
  }
  @api drive = null;
  @api job = null;
  @api jobAllocation = null;
  @api resourceRoleGroups = {};

  @track model = {};
  @track startTimeOptions = {};
  @track errorMessages = [];

  get timezoneSidId() {
    if(!this.drive || !this.drive.driveSite) return null;
    return this.drive.driveSite.timezoneSidId;
  }

  get jobStartTime() {
    if(!this.jobAllocation || !this.job) return null;

    return this.convertDateTimeIsoToTimeISO(this.job.start);

  }

  get jobEndTime() {
    if(!this.jobAllocation || !this.job) return null;

    return this.convertDateTimeIsoToTimeISO(this.job.finish);
  }

  get startWithTravelTime() {
    const ja = this.driveHelper.calculateJATimesWithTravel({
      ...this.model,
      job: this.job
    }, this.drive, {
      timezoneSidId: this.timezoneSidId,
      resourceRoleGroups: this.resourceRoleGroups
    });
    return ja?.start;
  }

  get startTimeWithTravelTime() {
    return this.convertDateTimeIsoToTimeISO(this.startWithTravelTime);
  }

  get endWithTravelTime() {
    const ja = this.driveHelper.calculateJATimesWithTravel({
      ...this.model,
      job: this.job
    }, this.drive, {
      timezoneSidId: this.timezoneSidId,
      resourceRoleGroups: this.resourceRoleGroups
    });
    return ja?.end;
  }

  get endTimeWithTravelTime() {
    return this.convertDateTimeIsoToTimeISO(this.endWithTravelTime);
  }

  @wire(CurrentPageReference) pageRef;

  connectedCallback() {
  }

  disconnectedCallback() {
  }

  /** Custom functions **/
  closeModal() {
    this.dispatchEvent(new CustomEvent('close', {
      detail: {
      }
    }));
  }

  init() {
    this.model = {
      ...this.jobAllocation
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
    this.errorMessages = [];
    const allValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

    if(this.startTimeWithTravelTime && this.endWithTravelTime) {
      if(this.startTimeWithTravelTime >= this.endWithTravelTime) {
        this.errorMessages.push({
          message: 'Start must before End.'
        })
      }
    } 
    return allValid && !this.errorMessages.length;
  }

  handleSave() {
    if(!this.validate()) return;

    let modelToSave = {
      ...this.model,
      start: this.startWithTravelTime,
      end: this.endWithTravelTime,
      duration: DateTime.fromISO(this.endWithTravelTime, {
        zone: this.timezoneSidId
      }).diff(DateTime.fromISO(this.startWithTravelTime, {
        zone: this.timezoneSidId
      })).as('minutes')
    };

    this.dispatchEvent(new CustomEvent('save', {
      detail: modelToSave
    }));
    this.closeModal();
  }

  convertDateTimeIsoToTimeISO(dateTimeIso) {
    if(!dateTimeIso) return null;
    return DateTime.fromISO(dateTimeIso, {
      zone: this.timezoneSidId
    }).toFormat('HH:mm:ss.000');
  }
}