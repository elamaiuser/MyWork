import {
  LightningElement,
  track,
  api,
  wire
} from 'lwc';
import {
  sObjectType,
  operationRecordService,
  driveService,
  driveQueryModel,
  jobService,
  jobQueryModel
} from "c/dataService";
import {
  CurrentPageReference
} from 'lightning/navigation';
import Edit from './edit.html';
import Create from './create.html';
import {
  getValueFromEvent
} from 'c/slwcUtils';
import {
  keyBy,
  uniqueId,
  remove
} from 'c/lodash';
import * as autoMapper from 'c/autoMapper';
import { DateTime } from 'c/luxon';
import * as slwcUtils from 'c/slwcUtils';
import { DriveHelper } from 'c/slwcDriveGenerator';

const COLUMNS = [{
  label: 'Role(s)',
  fieldName: 'rolesStr',
  wrapText: true
}];

export default class SlwcOperationRecordStaffModal extends LightningElement {
  driveHelper = new DriveHelper();

  @track _isOpen = false;
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

  @api record;
  @api job;
  @api operationRecord;
  @api mapRoleToPremiumOpPay = {};
  @api isSubmit = false;
  @api isReadonly = false;

  @track filter = {
    actualRoles: null,
    queryText: null
  };
  @track roleTableData = [];
  @track model = {
    jobId: null,
    role: null,
    resourceId: null
  }
  @track COLUMNS = COLUMNS;
  @track errorMessages = [];

  showSpinner = false;

  @wire(CurrentPageReference) pageRef;

  get disabled() {
    return this.isAbsent || this.isReadonly;
  }

  get isCreate() {
    return !this.record;
  }

  get disableSave() {
    if (this.isCreate) {
      return !this.model.resourceId
    } else {
      return false;
    }
  }
  get isAbsent() {
    return this.model.absent
  }

  get isEarlyLate() {
    if(this.isAbsent) return false;

    return (this.model.actualShiftStart && this.model.scheduledShiftStart && this.model.actualShiftStart > this.model.scheduledShiftStart) || 
      (this.model.actualShiftEnd && this.model.scheduledShiftEnd && this.model.actualShiftEnd < this.model.scheduledShiftEnd);
  }

  get resourceLookupDisabled() {
    return !this.model || !this.model.actualRoles || !this.model.actualRoles.length;
  }
  
  connectedCallback() {
  }

  render() {
    if (this.isCreate) {
      return Create
    } else {
      return Edit
    }
  }

  init() {
    if(!this.job) return;

    if (this.isCreate) {
      this.filter = {
        queryText: null,
        actualRoles: []
      };

      this.model = {
        // jobId: this.job.id,
        // jobName: this.job.name,
        // role: this.job.resourceRole,
        actualRoles: [],
        resourceId: null,
        premiumsOpPay: []
      }
      this.fetchDriveShift();
    } else {
      this.model = {
        ...this.record,
        premiumsOpPay: this.record.premiumsOpPay && this.record.premiumsOpPay.split(';') || [],
        actualRoles: this.record.actualRoles && this.record.actualRoles.split(';') || [],
      }

      if(this.model.lateEndDriveAndRecordStaffNotMatched) {
        this.errorMessages = [{
          message: 'Late End recorded for the staff person is not consistent with the Late End Drive.'
        }];
      }

      if (slwcUtils.isNullOrEmpty(this.model.actualShiftStartDate)) {
        if (!slwcUtils.isNullOrEmpty(this.model.scheduledShiftStart)) {
          this.model.actualShiftStartDate = DateTime.fromISO(this.model.scheduledShiftStart, { zone: this.model.timezoneSidId }).toISODate();
        }
      }
      if (slwcUtils.isNullOrEmpty(this.model.actualShiftEndDate)) {
        if (!slwcUtils.isNullOrEmpty(this.model.scheduledShiftEnd)) {
          this.model.actualShiftEndDate = DateTime.fromISO(this.model.scheduledShiftEnd, { zone: this.model.timezoneSidId }).toISODate();
        }
      }

      this.validate(this.isSubmit);
    }
  }

  showLoading() {
    this.showSpinner = true;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  handleChange(event) {
    const fieldName = event.currentTarget.name;
    const value = getValueFromEvent(event);
    if(fieldName === 'actualRoles') {
      const previousActualRoles = this.model.actualRoles;
      this.model[fieldName] = value;
      this.model.premiumsOpPay = [...this.populateDefaultPremiumsOpPay(this.model, previousActualRoles)];
    } else if(fieldName === 'actualShiftStartDate' || fieldName === 'actualShiftStartTime'){
      this.model[fieldName] = value;
      if (this.model.actualShiftStartDate && this.model.actualShiftStartTime) {
        this.model.actualShiftStart = this.driveHelper.newDateTime(this.model.actualShiftStartDate, this.model.actualShiftStartTime, this.model.timezoneSidId).toISOString();
      }
    } else if(fieldName === 'actualShiftEndDate' || fieldName === 'actualShiftEndTime'){
      this.model[fieldName] = value;
      if (this.model.actualShiftEndDate && this.model.actualShiftEndTime) {
        this.model.actualShiftEnd = this.driveHelper.newDateTime(this.model.actualShiftEndDate, this.model.actualShiftEndTime, this.model.timezoneSidId).toISOString();
      }
    } else {
      this.model[fieldName] = value;
    }

    this.validate(this.isSubmit);
  }

  validate(isSubmit) {
    const allValid = [
      ...this.template.querySelectorAll('lightning-input'), 
      ...this.template.querySelectorAll('lightning-combobox'),
      ...this.template.querySelectorAll('c-slwc-picklist')]
      .reduce((validSoFar, inputCmp) => {
          inputCmp.reportValidity();
          return validSoFar && inputCmp.checkValidity();
      }, true)

    let hasError = false
    this.errorMessages = [];

    if (this.operationRecord && !this.model.absent) {
      if (!this.operationRecord.lateEndDrive && (this.model.premiumsOpPay && this.model.premiumsOpPay.includes('Late End'))) {
        hasError = true;
        this.errorMessages.push({
          message: 'Late End recorded for the staff person is not consistent with the Late End Drive'
        })
      }

      if (!isSubmit) {
        return allValid && !hasError;
      }

      if (!this.model.actualShiftStart || !this.model.actualShiftEnd) {
        hasError = true;
        this.errorMessages.push({
          message: 'Incomplete entry - must provide start and end time actuals'
        })
      }

      if (this.model && this.model.actualShiftStart && this.model.actualShiftEnd) {
        if(this.model.actualShiftEnd <= this.model.actualShiftStart) {
          hasError = true;
          this.errorMessages.push({
              message: 'Actual Shift End should be greater than Actual Shift Start'
          })
        } else {
          const duration = DateTime.fromISO(this.model.actualShiftEnd, {
            zone: this.operationRecord.timezoneSidId
          }).diff(DateTime.fromISO(this.model.actualShiftStart, {
              zone: this.operationRecord.timezoneSidId
          })).as('minutes');
  
          if(duration > 24 * 60) {
            hasError = true;
            this.errorMessages.push({
              message: 'Invalid entry - greater than 24 hours'
            })
          }
  
          let allowedDriveEndDate = this.model.driveDate;
          let actualShiftStartDate = DateTime.fromISO(this.model.actualShiftStart, {
            zone: this.operationRecord.timezoneSidId
          }).toFormat('yyyy-MM-dd');
          let actualShiftEndDate = DateTime.fromISO(this.model.actualShiftEnd, {
            zone: this.operationRecord.timezoneSidId
          }).toFormat('yyyy-MM-dd');
  
          if (this.operationRecord.lateEndDrive) {
            allowedDriveEndDate = DateTime.fromFormat(this.operationRecord.driveDate, 'yyyy-MM-dd').plus({
              days: 1
            }).toFormat('yyyy-MM-dd');
          }
  
          if (actualShiftStartDate !== this.operationRecord.driveDate) {
            hasError = true;
            this.errorMessages.push({
              message: 'Invalid entry - staff time entry not on date of drive'
            })
          }
        
          if(actualShiftEndDate > allowedDriveEndDate) {
            hasError = true;
            this.errorMessages.push({
              message: 'Invalid entry - staff time entry not on date of drive'
            })
          }
        }
      }
    }

    return allValid && !hasError;
  }

  populateDefaultPremiumsOpPay(model, previousActualRoles = []) {
    if(previousActualRoles.length) {
      previousActualRoles.forEach(role => {
        //remove premium op pay if any
        const premiumsOpPay = this.mapRoleToPremiumOpPay[role];
        if(premiumsOpPay) {
          remove(model.premiumsOpPay, item => item === premiumsOpPay);
        }
      });
    }

    const currentActualRoles = model.actualRoles;
    currentActualRoles.forEach(role => {
      const premiumsOpPay = this.mapRoleToPremiumOpPay[role];
      if(premiumsOpPay && !model.premiumsOpPay.includes(premiumsOpPay)) {
        model.premiumsOpPay.push(premiumsOpPay);
      }
    });
   
    return model.premiumsOpPay;
  }
  
  handleCreate(event) {
    let newRecord = {
      ...this.model,
      premiumsOpPay: this.populateDefaultPremiumsOpPay(this.model)
    }

    if (this.isCreate) {
      newRecord = {
        ...newRecord,
        name: 'New',
        key: uniqueId('staff_'),
        premiumsOpPay: newRecord.premiumsOpPay && newRecord.premiumsOpPay.join(';') || null,
        actualRoles: newRecord.actualRoles && newRecord.actualRoles.join(';') || null
      }
    }

    let eventModal = new CustomEvent('save', {
      detail: newRecord
    })
    this.dispatchEvent(eventModal)
  }
  handleSave(event) {
    if(this.validate(this.isSubmit)) {
      let newRecord = {
        ...this.model,
        premiumsOpPay: this.model.premiumsOpPay && this.model.premiumsOpPay.join(';') || null,
        actualRoles: this.model.actualRoles && this.model.actualRoles.join(';') || null
      }

      let eventModal = new CustomEvent('save', {
        detail: newRecord
      })
      this.dispatchEvent(eventModal)
    }
  }
  closeModal(event) {
    const eventModal = new CustomEvent('close')
    this.dispatchEvent(eventModal)
  }
  buildRoleTableData(driveShift, driveShiftJobs = []) {
    if(!driveShiftJobs.length) return [];
    return [{
      ...driveShift,
      rolesStr: driveShiftJobs.reduce((result, job) => {
        let temp = null;
        if(job.assetType) temp = job.assetType;
        if(job.resourceRole) temp = job.resourceRole;
        if(job.id === this.job.id) {
          temp = temp + ' (current)';
        }

        return temp ? result.concat([temp]) : result;
      }, []).join(', ')
    }]
  }
  fetchDriveShift() {
    let driveShiftQuery = new jobQueryModel();
    driveShiftQuery.driveShiftIds = [this.job.driveShiftId];
    let service = new jobService();
    this.showLoading();
    service.query(driveShiftQuery).then((jobs) => {
      this.roleTableData = this.buildRoleTableData({
        id: this.job.driveShiftId
      }, jobs);
    })
    .finally(() => this.hideLoading());
  }
  handleSearchResources = (searchData) => {
    this.filter.queryText = searchData.searchTerm
    let service = new operationRecordService();
    let request = {
      driveShiftId: this.job.driveShiftId,
      inputDate: this.job.driveDate,
      queryText: this.filter.queryText
    };

    if(this.filter.actualRoles && this.filter.actualRoles.length) {
      request.roles = this.filter.actualRoles;
    }

    return service.getResourceData({
      request: request
    }).then((result) => {
      if(!result || !result.returnedData) return [];
      return autoMapper.autoMapperInstance.mapToArray('sked__Resource__c', result.returnedData.resources);
    });
  }
  handleSelectActualRoles(event) {
    const value = getValueFromEvent(event);

    if (value && value.length) {
      this.filter.actualRoles = value;
      this.model.actualRoles = value;
    } else {
      this.filter.actualRoles = [];
      this.model.actualRoles = [];
    }

    this.filter.queryText = null;
    this.filter.resource = null;
    this.model.resourceId = null
    this.model.resourceName = null
  }
  handleSelectResource(event) {
    this.filter.resource = event.detail.selection;

    if (event.detail.selection) {
      this.model.resourceId = event.detail.selection.id
      this.model.resourceName = event.detail.selection.name
    } else {
      this.model.resourceId = null
      this.model.resourceName = null
    }
  }
}