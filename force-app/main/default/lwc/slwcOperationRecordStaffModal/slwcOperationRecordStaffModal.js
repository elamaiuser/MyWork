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
  jobQueryModel,
  staffMealAndRestBreakService,
  staffMealAndRestBreakQueryModel
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
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

const COLUMNS = [{
  label: 'Role(s)',
  fieldName: 'rolesStr',
  wrapText: true
}];

const BREAK_TYPE = {
  MEAL_BREAK: 'Meal',
  REST_BREAK: 'Rest'
};

const MAX_MEAL_REST_BREAK_COUNT = {
  MIN_MEAL_REST_BREAK_COUNT: 0,
  MAX_MEAL_BREAK_COUNT: 3,
  MAX_REST_BREAK_COUNT: 6
};

const MEAL_BREAK_FIELD_IDENTIFIERS = ['Meal', 'noOfMealBreaksTaken', 'addMealBreaksTaken', 'enterMealBreakTimes'];
const REST_BREAK_FIELD_IDENTIFIERS = ['Rest', 'noOfRestBreaksTaken', 'addRestBreaksTaken', 'enterRestBreakTimes'];

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
    resourceId: null,
    addMealBreaksTaken: false,
    addRestBreaksTaken: false,
    enterMealBreakTimes: false,
    enterRestBreakTimes: false
  }

  @track COLUMNS = COLUMNS;
  @track errorMessages = [];
  @track mealOrRestBreakTimes = [];
  @track disabledConfigVariable = {};
  @track existingBreakSetting = [];
  @track warningModalData = {};
  @track customErrorModel = {
    showMealBreakError: false,
    showRestBreakError: false
  }

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

  get isLate() {
    if(this.isAbsent) return false;

    return (this.model.actualShiftStart && this.model.scheduledShiftStart && this.model.actualShiftStart > this.model.scheduledShiftStart);
  }

  get isEarly() {
    if(this.isAbsent) return false;

    return (this.model.actualShiftEnd && this.model.scheduledShiftEnd && this.model.actualShiftEnd < this.model.scheduledShiftEnd);
  }

  get requiresEarlyDepartureDateTime() {
    return !slwcUtils.isNullOrEmpty(this.model.earlyDepartureReasons);
  }
  
  get requiresLateArrivalDateTime() {
    return !slwcUtils.isNullOrEmpty(this.model.lateArrivalReasons);
  }

  get resourceLookupDisabled() {
    return !this.model || !this.model.actualRoles || !this.model.actualRoles.length;
  }

  get disableScheduledShiftStartEnd() {
    return !this.model.addedStaff || this.disabled;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: this.model.timezone
    })
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
        premiumsOpPay: this.record.premiumsOpPay || [],
        actualRoles: this.record.actualRoles || [],
        addMealBreaksTaken: !slwcUtils.isNullOrEmpty(this.record.noOfMealBreaksTaken),
        addRestBreaksTaken: !slwcUtils.isNullOrEmpty(this.record.noOfRestBreaksTaken),
      }

      const today = DateTime.fromObject({
        zone: this.model.timezone
      }).toUTC().toISO();

      if(!this.model.lateArrivalDateTimeReceived) {
        this.model.lateArrivalDateTimeReceived = today;
      }

      if(!this.model.earlyDepartureDateTimeReceived) {
        this.model.earlyDepartureDateTimeReceived = today;
      }

      this.initializeCollectionOpConfigVariables();
      this.getExistingStaffMealAndRestBreakSetting()
        .then(existingBreakSetting => {
          this.existingBreakSetting = existingBreakSetting;
          if (this.existingBreakSetting.length) {
            this.model = {
              ...this.model,
              enterMealBreakTimes: this.model.enterMealBreakTimes || this.existingBreakSetting.find(input => input.name.includes('Meal')),
              enterRestBreakTimes: this.model.enterRestBreakTimes || this.existingBreakSetting.find(input => input.name.includes('Rest'))
            }
            this.initializeExistingStaffMealAndBreakSettings(this.existingBreakSetting);
          } 
          if (this.model.enterMealBreakTimes && !this.mealOrRestBreakTimes.mealBreakTimings.length) {
            this.buildMealAndRestBreakArray('noOfMealBreaksTaken');
          }
          if (this.model.enterRestBreakTimes && !this.mealOrRestBreakTimes.restBreakTimings.length) {
            this.buildMealAndRestBreakArray('noOfRestBreaksTaken');
          }
        });

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
    } else if(fieldName === 'scheduledShiftStartDate' || fieldName === 'scheduledShiftStartTime') {
      this.model[fieldName] = value;
      if (this.model.scheduledShiftStartDate && this.model.scheduledShiftStartTime) {
        this.model.scheduledShiftStart = this.driveHelper.newDateTime(this.model.scheduledShiftStartDate, this.model.scheduledShiftStartTime, this.model.timezoneSidId).toISOString();
      } else {
        this.model.scheduledShiftStart = null;
      }
    } else if(fieldName === 'scheduledShiftEndDate' || fieldName === 'scheduledShiftEndTime') {
      this.model[fieldName] = value;
      if (this.model.scheduledShiftEndDate && this.model.scheduledShiftEndTime) {
        this.model.scheduledShiftEnd = this.driveHelper.newDateTime(this.model.scheduledShiftEndDate, this.model.scheduledShiftEndTime, this.model.timezoneSidId).toISOString();
      } else {
        this.model.scheduledShiftEnd = null;
      }
    } else if(fieldName === 'actualShiftStartDate' || fieldName === 'actualShiftStartTime') {
      this.model[fieldName] = value;
      if (this.model.actualShiftStartDate && this.model.actualShiftStartTime) {
        this.model.actualShiftStart = this.driveHelper.newDateTime(this.model.actualShiftStartDate, this.model.actualShiftStartTime, this.model.timezoneSidId).toISOString();
      } else {
        this.model.actualShiftStart = null;
      }
    } else if(fieldName === 'actualShiftEndDate' || fieldName === 'actualShiftEndTime') {
      this.model[fieldName] = value;
      if (this.model.actualShiftEndDate && this.model.actualShiftEndTime) {
        this.model.actualShiftEnd = this.driveHelper.newDateTime(this.model.actualShiftEndDate, this.model.actualShiftEndTime, this.model.timezoneSidId).toISOString();
      } else {
        this.model.actualShiftEnd = null;
      }
    } else if (fieldName === 'noOfMealBreaksTaken') {
      const inputValue = parseInt(value, 10);
      if (inputValue < MAX_MEAL_REST_BREAK_COUNT.MIN_MEAL_REST_BREAK_COUNT || inputValue > MAX_MEAL_REST_BREAK_COUNT.MAX_MEAL_BREAK_COUNT) {
        event.target.setCustomValidity(`Meal Break count must be within ${MAX_MEAL_REST_BREAK_COUNT.MIN_MEAL_REST_BREAK_COUNT} - ${MAX_MEAL_REST_BREAK_COUNT.MAX_MEAL_BREAK_COUNT}`);
        this.disabledConfigVariable.enterMealBreakTimes = true;
        this.model.enterMealBreakTimes = false;
      } else {
        event.target.setCustomValidity('');
        this.initializeCollectionOpConfigVariables();
        this.model[fieldName] = value;
        this.buildMealAndRestBreakArray(fieldName);
      }
    } else if (fieldName === 'noOfRestBreaksTaken') {
      const inputValue = parseInt(value, 10);
      if (inputValue < MAX_MEAL_REST_BREAK_COUNT.MIN_MEAL_REST_BREAK_COUNT || inputValue > MAX_MEAL_REST_BREAK_COUNT.MAX_REST_BREAK_COUNT) {
        event.target.setCustomValidity(`Rest Break count must be within ${MAX_MEAL_REST_BREAK_COUNT.MIN_MEAL_REST_BREAK_COUNT} - ${MAX_MEAL_REST_BREAK_COUNT.MAX_REST_BREAK_COUNT}`);
        this.disabledConfigVariable.enterRestBreakTimes = true;
        this.model.enterRestBreakTimes = false;
      } else {
        event.target.setCustomValidity('');
        this.initializeCollectionOpConfigVariables();
        this.model[fieldName] = value;
        this.buildMealAndRestBreakArray(fieldName);
      }
    } else {
      this.model[fieldName] = value;
      this.initializeCollectionOpConfigVariables();
      this.buildMealAndRestBreakArray(fieldName);
    }
    const isNeededWarningModal = this.isShowWarningModal(fieldName, value);
    this.handleWarningModal(isNeededWarningModal,fieldName);
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
          message: 'Incomplete entry - must provide Actual Shift Start Date/Time and Actual Shift End Date/Time'
        })
      }

      if (!this.model.scheduledShiftStart || !this.model.scheduledShiftEnd) {
        hasError = true;
        this.errorMessages.push({
          message: 'Incomplete entry - must provide Scheduled Shift Start Date/Time and Scheduled Shift End Date/Time'
        })
      }

      if (this.model && ((this.model.actualShiftStart && this.model.actualShiftEnd) || (this.model.scheduledShiftStart && this.model.scheduledShiftEnd))) {
        if(this.model.actualShiftEnd <= this.model.actualShiftStart || this.model.scheduledShiftEnd <= this.model.scheduledShiftStart) {
          hasError = true;
          this.errorMessages.push({
              message: 'Invalid entry - Scheduled/Actual Shift End should be greater than Scheduled/Actual Shift Start'
          })
        } else {
          const durationForActualShiftStartEnd = DateTime.fromISO(this.model.actualShiftEnd, {
            zone: this.operationRecord.timezoneSidId
          }).diff(DateTime.fromISO(this.model.actualShiftStart, {
              zone: this.operationRecord.timezoneSidId
          })).as('minutes');

          const durationForScheduledShiftStartEnd = DateTime.fromISO(this.model.scheduledShiftEnd, {
            zone: this.operationRecord.timezoneSidId
          }).diff(DateTime.fromISO(this.model.scheduledShiftStart, {
              zone: this.operationRecord.timezoneSidId
          })).as('minutes');
  
          if(durationForActualShiftStartEnd > 24 * 60 || durationForScheduledShiftStartEnd > 24 * 60) {
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
          let scheduledShiftStartDate = DateTime.fromISO(this.model.scheduledShiftStart, {
            zone: this.operationRecord.timezoneSidId
          }).toFormat('yyyy-MM-dd');
          let scheduledShiftEndDate = DateTime.fromISO(this.model.scheduledShiftEnd, {
            zone: this.operationRecord.timezoneSidId
          }).toFormat('yyyy-MM-dd');
  
          if (this.operationRecord.lateEndDrive) {
            allowedDriveEndDate = DateTime.fromFormat(this.operationRecord.driveDate, 'yyyy-MM-dd').plus({
              days: 1
            }).toFormat('yyyy-MM-dd');
          }
  
          if (actualShiftStartDate !== this.operationRecord.driveDate || scheduledShiftStartDate !== this.operationRecord.driveDate) {
            hasError = true;
            this.errorMessages.push({
              message: 'Invalid entry - staff time entry not on date of drive'
            })
          }
        
          if(actualShiftEndDate > allowedDriveEndDate || scheduledShiftEndDate > allowedDriveEndDate) {
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
        premiumsOpPay: newRecord.premiumsOpPay,
        actualRoles: newRecord.actualRoles
      }
    }

    let eventModal = new CustomEvent('save', {
      detail: newRecord
    })
    this.dispatchEvent(eventModal)
  }

  handleSave(event) {
    this.customErrorModel = {
      showMealBreakError: !this.isAbsent && this.model.addMealBreaksTaken && this.model.noOfMealBreaksTaken === null,
      showRestBreakError: !this.isAbsent && this.model.addRestBreaksTaken && this.model.noOfRestBreaksTaken === null
    };
    if(this.customErrorModel.showMealBreakError || this.customErrorModel.showRestBreakError) {
      return;
    }
    if (this.validate(this.isSubmit)) {
      let newRecord = {
        ...this.model,
        premiumsOpPay: this.model.premiumsOpPay,
        actualRoles: this.model.actualRoles
      }
      if(!this.isEarly) {
        newRecord.earlyDepartureDateTimeReceived = null;
      }
      if(!this.isLate) {
        newRecord.lateArrivalDateTimeReceived = null;
      }
      let eventModal = new CustomEvent('save', {
        detail: newRecord
      })
      this.dispatchEvent(eventModal);
      if(this.model.enterMealBreakTimes || this.model.enterRestBreakTimes) {
        this.saveStaffMealAndRestBreakSetting();
      }
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

  getExistingStaffMealAndRestBreakSetting() {
    let query = new staffMealAndRestBreakQueryModel();
    query.opRecordStaffIds = [this.record.id];
    let service = new staffMealAndRestBreakService();

    return service.query(query)
    .catch((error) => {
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
      throw error;
    });
  }

  buildTimeObject(index, inputName, startTime, endTime) {
    return {
      location: index,
      name: `${inputName} ${index} Start/End`,
      startTime: startTime ? this.formatTime(startTime) : '',
      endTime: endTime ? this.formatTime(endTime) : ''
    };
  }

  buildMealAndRestBreakArray(fieldName) {
    if (fieldName === 'noOfMealBreaksTaken' || fieldName === 'noOfRestBreaksTaken' || fieldName === 'enterMealBreakTimes' || fieldName === 'enterRestBreakTimes') {
      const inputName = this.getBreakType(fieldName);
      const lastIndex = this.containsRestText(fieldName) ? this.model.noOfRestBreaksTaken : this.model.noOfMealBreaksTaken;
      if(lastIndex > 0) {  
        let mealBreakTimings = this.mealOrRestBreakTimes.mealBreakTimings || [];
        let restBreakTimings = this.mealOrRestBreakTimes.restBreakTimings || [];
        
        if (mealBreakTimings.length > lastIndex && inputName === BREAK_TYPE.MEAL_BREAK) {      
          mealBreakTimings = mealBreakTimings.slice(0, lastIndex);
        }
        if (restBreakTimings.length > lastIndex && inputName === BREAK_TYPE.REST_BREAK) {
          restBreakTimings = restBreakTimings.slice(0, lastIndex);
        }
        let index = 0;
        while(index < lastIndex) {
          const timeObj = this.buildTimeObject(index + 1, inputName, '', '');
          if (inputName === BREAK_TYPE.MEAL_BREAK && !mealBreakTimings[index]) {
            mealBreakTimings.push(timeObj);
          } else if (inputName === BREAK_TYPE.REST_BREAK && !restBreakTimings[index]) {
            restBreakTimings.push(timeObj);
          }
          index++;
        }
        this.mealOrRestBreakTimes.mealBreakTimings = mealBreakTimings;
        this.mealOrRestBreakTimes.restBreakTimings = restBreakTimings;
      }
    }
  }

  initializeExistingStaffMealAndBreakSettings(records) {
    let mealCount = 0;
    let restCount = 0;

    let mealBreakTimings = this.mealOrRestBreakTimes.mealBreakTimings || [];
    let restBreakTimings = this.mealOrRestBreakTimes.restBreakTimings || [];

    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      const inputName = this.getBreakType(record.name);
      let location = 0;

      if (inputName === BREAK_TYPE.MEAL_BREAK) {
        mealCount++;
        location = mealCount;
      } else {
        restCount++;
        location = restCount;
      }
      const timeObj = this.buildTimeObject(location, inputName, record.actualStartTime, record.actualEndTime);
      if (inputName === BREAK_TYPE.MEAL_BREAK && !mealBreakTimings.filter(entry => entry.name.includes(timeObj.name)).length) {
        mealBreakTimings.push(timeObj);
      } else if (inputName === BREAK_TYPE.REST_BREAK && !restBreakTimings.filter(entry => entry.name.includes(timeObj.name)).length) {
        restBreakTimings.push(timeObj);
      }
    }
    if (mealBreakTimings) {
      this.model.noOfMealBreaksTaken = this.model.noOfMealBreaksTaken < mealBreakTimings.length ? mealBreakTimings.length : this.model.noOfMealBreaksTaken;
      this.mealOrRestBreakTimes.mealBreakTimings = mealBreakTimings;
    }
    if (restBreakTimings) {
      this.model.noOfRestBreaksTaken = this.model.noOfRestBreaksTaken < restBreakTimings.length ? restBreakTimings.length : this.model.noOfRestBreaksTaken;
      this.mealOrRestBreakTimes.restBreakTimings = restBreakTimings;
    }
  }

  initializeCollectionOpConfigVariables() {
    const configVariables = {
      addMealBreaksTaken: "collectionOperationRequireNumberOfMealBreaks",
      addRestBreaksTaken: "collectionOperationRequireNumberOfRestBreaks",
      enterMealBreakTimes: "collectionOperationRequireStartEndTimesForMealBreak",
      enterRestBreakTimes: "collectionOperationRequireStartEndTimesForRestBreak"
    };

    for (const [key, value] of Object.entries(configVariables)) {
      this.model[key] = this.operationRecord[value] ? true : this.model[key];
      this.disabledConfigVariable[key] = (this.operationRecord[value] || this.disabled) ? true : false;
    }
  }

  isShowWarningModal(fieldName, value) {
    let hasData = false;
   
    /* Evaluate rules to determine whether to show warning modal */
    const hasMealTimingsPopulated = this.mealOrRestBreakTimes.mealBreakTimings && this.mealOrRestBreakTimes.mealBreakTimings.length > 0 && this.mealOrRestBreakTimes.mealBreakTimings.every(obj=> obj.startTime !== '' || obj.endTime !== '');
    const hasRestTimingsPopulated = this.mealOrRestBreakTimes.restBreakTimings && this.mealOrRestBreakTimes.restBreakTimings.length > 0 && this.mealOrRestBreakTimes.restBreakTimings.every(obj=> obj.startTime !== '' || obj.endTime !== '');
    const rule1 = fieldName === 'addMealBreaksTaken' && !value && (this.model.noOfMealBreaksTaken || hasMealTimingsPopulated);
    const rule2 = fieldName === 'addRestBreaksTaken' && !value && (this.model.noOfRestBreaksTaken || hasRestTimingsPopulated);
    const rule3 = fieldName === 'enterMealBreakTimes' && !value && hasMealTimingsPopulated;
    const rule4 = fieldName === 'enterRestBreakTimes' && !value && hasRestTimingsPopulated;
    if (rule1 || rule2 || rule3 || rule4) {
      hasData = true;
    }
    return hasData;
  }

  showWarningModal(warningModalData) {
    this.warningModalData = {...warningModalData,
      isOpen: true
    }
  }

  hideWarningModal() {
    this.warningModalData = {};
  }

  handleWarningModal(data, fieldName) {
    if (data) {
      this.showWarningModal({
        title: 'Warning!!!',
        message: 'Warning, data entered will be cleared...',
        onClose: (result) => {
          this.hideWarningModal();
          if (result) {
            this.model.noOfMealBreaksTaken = fieldName === 'addMealBreaksTaken' ? null : this.model.noOfMealBreaksTaken;
            this.model.noOfRestBreaksTaken = fieldName === 'addRestBreaksTaken' ? null : this.model.noOfRestBreaksTaken;
            this.mealOrRestBreakTimes.mealBreakTimings = (fieldName === 'addMealBreaksTaken' || fieldName === 'enterMealBreakTimes') ? [] : this.mealOrRestBreakTimes.mealBreakTimings;
            this.mealOrRestBreakTimes.restBreakTimings = (fieldName === 'addRestBreaksTaken' || fieldName === 'enterRestBreakTimes') ? [] : this.mealOrRestBreakTimes.restBreakTimings;
            const breakType = this.getBreakType(fieldName);
            if (this.existingBreakSetting.length) {
              const existingRecord = this.existingBreakSetting.filter(record => record.name.includes(breakType));
              const service = new staffMealAndRestBreakService();
              Promise.resolve()
                .then(() => {
                  return service.deleteList(existingRecord);
                })
                .then((result) => {
                  if (!result.success) throw result;
                })
                .catch((error) => {
                  this.dispatchEvent(new ShowToastEvent({
                    message: error.message,
                    variant: 'error',
                    mode: 'dismissable',
                  }));
                });
            }
          } else {
            /** Revert back the changes according to the fieldNames **/
            this.model.enterMealBreakTimes = fieldName === 'enterMealBreakTimes' ? true : this.model.enterMealBreakTimes;
            this.model.enterRestBreakTimes = fieldName === 'enterRestBreakTimes' ? true : this.model.enterRestBreakTimes;
            this.model.addMealBreaksTaken = fieldName === 'addMealBreaksTaken' ? true : this.model.addMealBreaksTaken;
            this.model.addRestBreaksTaken = fieldName === 'addRestBreaksTaken' ? true : this.model.addRestBreaksTaken;
          }
        },
        confirmBtnLabel: 'Continue',
        cancelBtnLabel: 'Cancel'
      });
    }
  }

  handleMealAndRestBreakTimeChange(event) {
    const index = event.target.dataset.index;
    const fieldName = event.target.dataset.field;
    const value = event.target.value;

    if (fieldName === 'restStartTime') {
      if (!this.mealOrRestBreakTimes.restBreakTimings[index]) {
        this.mealOrRestBreakTimes.restBreakTimings[index] = {};
      } else {
      this.mealOrRestBreakTimes.restBreakTimings[index].startTime = value;
      }
    } else if (fieldName === 'restEndTime') {
      if (!this.mealOrRestBreakTimes.restBreakTimings[index]) {
        this.mealOrRestBreakTimes.restBreakTimings[index] = {};
      }
      this.mealOrRestBreakTimes.restBreakTimings[index].endTime = value;
    }
    else if (fieldName === 'mealStartTime') {
      if (!this.mealOrRestBreakTimes.mealBreakTimings[index]) {
        this.mealOrRestBreakTimes.mealBreakTimings[index] = {};
      }
      this.mealOrRestBreakTimes.mealBreakTimings[index].startTime = value;
    }
    else if (fieldName === 'mealEndTime') {
      if (!this.mealOrRestBreakTimes.mealBreakTimings[index]) {
        this.mealOrRestBreakTimes.mealBreakTimings[index] = {};
      }
      this.mealOrRestBreakTimes.mealBreakTimings[index].endTime = value;
    }
    let isMealBreakStartGreaterThanEnd = this.mealOrRestBreakTimes.mealBreakTimings[index] && this.mealOrRestBreakTimes.mealBreakTimings[index].startTime && this.mealOrRestBreakTimes.mealBreakTimings[index].endTime && this.mealOrRestBreakTimes.mealBreakTimings[index].startTime > this.mealOrRestBreakTimes.mealBreakTimings[index].endTime;
    let isRestBreakStartGreaterThanEnd = this.mealOrRestBreakTimes.restBreakTimings[index] && this.mealOrRestBreakTimes.restBreakTimings[index].startTime && this.mealOrRestBreakTimes.restBreakTimings[index].endTime && this.mealOrRestBreakTimes.restBreakTimings[index].startTime > this.mealOrRestBreakTimes.restBreakTimings[index].endTime;
    if (isMealBreakStartGreaterThanEnd || isRestBreakStartGreaterThanEnd) {
      event.target.setCustomValidity('Break End Time must be After Break Start Time');
    } else {
      event.target.setCustomValidity('');
    }
  }

  saveStaffMealAndRestBreakSetting() {
    let allBreakTimings = [];
    let existingRecords;
    let recordsToDelete;
    const service = new staffMealAndRestBreakService();

    if (!this.mealOrRestBreakTimes.mealBreakTimings.every(obj => obj.startTime === '' || obj.endTime === '')) {
      allBreakTimings = allBreakTimings.concat(this.mealOrRestBreakTimes.mealBreakTimings);
    }
    if (!this.mealOrRestBreakTimes.restBreakTimings.every(obj => obj.startTime === '' || obj.endTime === '')) {
      allBreakTimings = allBreakTimings.concat(this.mealOrRestBreakTimes.restBreakTimings);
    }
    if (allBreakTimings.length) {
      const recordsToSave = allBreakTimings.map((entry) => {
        const breakType = this.getBreakType(entry.name);
        if (this.existingBreakSetting.length) {
          existingRecords = this.existingBreakSetting.find(record => record.name.includes(`${breakType} Break ${entry.location}`));
        }
        return this.formatStaffMealAndRestBreakSetting(breakType, existingRecords, entry);
      });
      if (this.existingBreakSetting && this.existingBreakSetting.length > recordsToSave.length) {
        recordsToDelete = this.existingBreakSetting.filter(existingRecord => !recordsToSave.filter(record => record.id === existingRecord.id).length);
      }
      return Promise.resolve()
        .then(() => {
          if (recordsToDelete && recordsToDelete.length) {
            return service.deleteList(recordsToDelete);
          }
        })
        .then(() => {
          if (recordsToSave && recordsToSave.length) {
            return service.saveList(recordsToSave);
          }
        })
        .then((result) => {
          if (!result || !result.success) {
            throw result;
          }
        })
    } else {
      if (this.existingBreakSetting && this.existingBreakSetting.length) {
        return Promise.resolve()
          .then(() => {
            return service.deleteList(this.existingBreakSetting);
          })
      }
    }
  }

  formatTime(time) {
    if (!time) {
      return '';
    }
    const options = {
      hour: 'numeric',
      minute: 'numeric',
      second: "numeric",
      hourCycle: "h23",
      timeZone: "UTC",
      fractionalSecondDigits: 3
    };

    const dateTime = this.dateUtils.getDateTimeInfo(time);
    return DateTime.fromISO(dateTime.timeIso).toLocaleString(options);
  }

  formatStaffMealAndRestBreakSetting(breakType, existingRecord, currentRecord) {
    return {
      name: existingRecord ? existingRecord?.name : `${breakType} Break ${currentRecord.location}`,
      opRecordStaff: this.record?.id,
      actualStartTime: currentRecord.startTime,
      actualEndTime: currentRecord.endTime,
      breakType: breakType,
      actualStartDate: this.model.actualShiftStartDate,
      actualEndDate: this.model.actualShiftEndDate,
      actualStart: this.driveHelper.newDateTime(this.model.actualShiftStartDate, currentRecord.startTime, this.model.timezoneSidId).toISOString(),
      actualEnd: this.driveHelper.newDateTime(this.model.actualShiftEndDate, currentRecord.endTime, this.model.timezoneSidId).toISOString(),
      id: existingRecord?.id
    }
  }
  
  containsMealText(fieldName) {
    return MEAL_BREAK_FIELD_IDENTIFIERS.filter(identifier => fieldName.includes(identifier)).length > 0;
  }

  containsRestText(fieldName) {
    return REST_BREAK_FIELD_IDENTIFIERS.filter(identifier => fieldName.includes(identifier)).length > 0;
  }

  getBreakType(fieldName) {
    return this.containsMealText(fieldName) ? BREAK_TYPE.MEAL_BREAK : this.containsRestText(fieldName) ? BREAK_TYPE.REST_BREAK : '';
  }

}