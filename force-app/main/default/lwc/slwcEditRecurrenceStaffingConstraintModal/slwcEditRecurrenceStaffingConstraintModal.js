import { LightningElement, track, api } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { activityService, activityQueryModel, driveService, driveQueryModel, staffingConstraintService, staffingConstraintQueryModel, } from 'c/dataService';
import * as slwcDateUtils from 'c/slwcDateUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { cloneDeep, keyBy, groupBy, uniq, remove, uniqueId, min, max } from 'c/lodash';
import { DRIVE_TYPE, DRIVE_STATUS } from 'c/slwcConstants';

import Step1 from "./step1.html";
import Step2 from "./step2.html";

const DAYS_OF_WEEK = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

export default class SlwcEditRecurrenceStaffingConstraintModal extends LightningElement {
  _isOpen = true;
  @api
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;

    if (this._isOpen) {
      this.init();
    }
  }

  @api defaultDateRange;
  @api defaultCollectionOperationId;
  @api timeBlocks;

  @track timeBlockOptions = [];
  @track model = {};
  @track timezoneSidId = TIME_ZONE;
  @track showSpinner = false;

  ALLSTEP = {
    STEP1: {
      value: 1,
      onLoad: () => {},
      validate: () => this.validateStep1(),
      render: Step1
    },
    STEP2: {
      value: 2,
      onLoad: () => this.fetchStep2(),
      validate: () => this.validateStep2(),
      render: Step2
    }
  };

  @track daysOfWeekOptions = DAYS_OF_WEEK.map((day) => ({
    label: day, value: day
  }));

  @track currentStep = this.ALLSTEP.STEP1.value;

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    })
  }

  get modalHeader() {
    return 'Edit Recurrence Staffing Constraints';
  }

  get saveBtnDisabled() {
    return this.showSpinner;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal', {
        'slds-fade-in-open': this.isOpen
      }),
      headerClass: classNames('slds-modal__header'),
      footerClass: classNames('slds-modal__footer'),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      }),
      warningMessageClass: classNames(
        "slds-text-color_default",
        "staffing-constraints__warning-message"
      )
    }
  }

  get mode() {
    return "STEP" + this.currentStep;
  }

  render() {
    return this.ALLSTEP[this.mode].render;
  }

  connectedCallback() {
    this.init();
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  exceptionHandler = (error) => {
    if (error && error.message) {
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    }
  }

  handleNext() {
    const passed = !this.ALLSTEP[this.mode].validate || this.ALLSTEP[this.mode].validate();
    if(!passed) return;

    if (this.currentStep > this.ALLSTEP.length) {
      this.currentStep = 1;
    } else {
      this.currentStep += 1;
    }

    this.ALLSTEP[this.mode].onLoad();
  }

  handlePrev() {
    this.currentStep -= 1;
  }

  validateStep1 = () => {
    if(this.model.STEP1.selectedDays.length <= 0) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'Please select at least 1 date.',
        variant: 'error',
        mode: 'dismissable',
      }));
      return false;
    }
    return true;
  }

  init = () => {
    this.resetModel();
  }

  resetModel = () => {
    this.dataSaved = false;

    this.model = {
      STEP1: {
        selectedDays: []
      },
      STEP2: {
        filters: {
          startDate: null,
          endDate: null,
          showOnlyErrorRecords: false,
          daysOfWeek: [],
          driveTypes: [],
          timeBlocks: []
        },
        masterRow: {
          totalStaffConstraints: null
        },
        originalRecords: [],
        records: [],
        filteredRecords: []
      }
    };

    this.currentStep = this.ALLSTEP.STEP1.value;
  }

  handleStep1ModelOnChange = (event) => {
    this.model.STEP1.selectedDays = event.detail.selectedDays || [];
  }

  handleStep2ModelChange = (event) => {
    const key = event.currentTarget.dataset['key'];
    const record = this.model.STEP2.records.find(item => item.key === key);
    if(!record) return;

    let value = getValueFromEvent(event);
    record[event.currentTarget.name] = value;

    this.handleStep2ValidateRecord(record);
  }

  handleStep2DeleteRecord = (event) => {
    const key = event.currentTarget.dataset['key'];
    remove(this.model.STEP2.records, item => item.key === key);

    this.filterStep2Records();
  }

  handleStep2DeleteAllRecord = (event) => {
    const filteredRecordKeys = this.model.STEP2.filteredRecords.map(item => item.key);
    remove(this.model.STEP2.records, item => filteredRecordKeys.includes(item.key));

    this.handleStep2ResetFilters();
  }

  fetchStaffingConstraintData = () => {
    const dateOfConstraints = uniq(this.model.STEP2.records.map(item => item.dateOfConstraint));
    if (!dateOfConstraints?.length) {
      this.mappedDriveData = {};
      this.mappedActivityData = {};
      return Promise.resolve();
    }

    const collectionOperationIds = uniq(this.model.STEP2.records.map(item => item.collectionOperation.id));
    const driveTypes = uniq(this.model.STEP2.records.map(item => item.driveType));
    const minDateIso = min(dateOfConstraints);
    const maxDateIso = max(dateOfConstraints);

    return Promise.resolve()
      .then(() => {
        const driveQuery = new driveQueryModel();
        driveQuery.startDate = minDateIso;
        driveQuery.endDate = maxDateIso;
        driveQuery.collectionOpIds = collectionOperationIds;
        driveQuery.eventTypes = driveTypes;
        driveQuery.statuses = [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD];

        const activityQuery = new activityQueryModel();
        activityQuery.startDate = minDateIso;
        activityQuery.endDate = maxDateIso;
        activityQuery.collectionOperationIds = collectionOperationIds;
        activityQuery.isGroupActivity = true;
        activityQuery.reduceFromStaffingConstraint = true;

        const driveSvc = new driveService();
        const activitySvc = new activityService();

        return Promise.all([
          driveSvc.query(driveQuery),
          activitySvc.query(activityQuery)
        ]);
      })
      .then(([driveResult, activityResult]) => {
        this.mappedDriveData = groupBy([...driveResult], (item) => `${item.collectionOperationId}-${item.typeOfDrive}-${item.driveDate}`);
        this.mappedActivityData = groupBy([...activityResult], (item) => `${item.collectionOperationId}-${item.startDate}`);
      })
  }

  getTimeBlockOptions = () => {
    const timeBlockIds = uniq(this.model.STEP2.records.map(item => item.timeBlockId).filter(item => item));
    let options = [];
    if (this.timeBlocks?.length) {
      this.timeBlocks.forEach(timeBlock => {
        if (timeBlockIds?.includes(timeBlock.value)) {
          options.push({
            ...timeBlock,
            selected: false
          })
        }
      });
    }
    this.timeBlockOptions = options;
  }

  handleStep2ValidateRecord = (record) => {
    record.validations = {
      requestedStaffExceeded: false,
      noOfRequestedStaff: 0,
    }
    const driveKey = `${record.collectionOperation.id}-${record.driveType}-${record.dateOfConstraint}`;
    const activityKey = `${record.collectionOperation.id}-${record.dateOfConstraint}`;

    const sameDateDrives = this.mappedDriveData[driveKey] || [];
    const sameDateActivities = this.mappedActivityData[activityKey] || [];

    let noOfRequestedStaff = 0;
    sameDateDrives.forEach(drive => {
      let totalStaffRequested = drive.totalStaffRequested;
      if (record.timeBlock) {
        totalStaffRequested = 0;
        drive.driveShifts?.forEach(driveShift => {
          if (driveShift.timeBlockId === record.timeBlock.id) {
            totalStaffRequested += driveShift.staffSetup
          }
        })
      }
      noOfRequestedStaff += totalStaffRequested
    });

    sameDateActivities.forEach(activity => {
      if (!record.timeBlock || activity.timeBlockId === record.timeBlock.id) {
        if(record.driveType === DRIVE_TYPE.MOBILE) {
          noOfRequestedStaff += activity.mobileStaffQuantity;
        } else {
          noOfRequestedStaff += activity.fixedSiteStaffQuantity;
        }
      }
    });

    record.validations.noOfRequestedStaff = noOfRequestedStaff;
    record.validations.requestedStaffExceeded = noOfRequestedStaff > record.totalStaffConstraints;
  }

  handleStep2ValidateRecords = () => {
    this.showLoading();
    this.fetchStaffingConstraintData()
      .then(() => {
        this.model.STEP2.records.forEach(record => {
          this.handleStep2ValidateRecord(record);
        });
      })
      .catch(error => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  }

  handleStep2FiltersOnChange = (event) => {
    if(event.currentTarget.name === 'dateRange') {
      const { startDate, endDate } = event.detail;
      this.model.STEP2.filters = {
        ...this.model.STEP2.filters,
        startDate,
        endDate
      }
    } else {
      const value = getValueFromEvent(event);
      this.model.STEP2.filters[event.currentTarget.name] = value;
    }
    
    this.filterStep2Records();
  }

  handleStep2ResetFilters = (event) => {
    const allDateConstraints = this.model.STEP2.records.map(item => item.dateOfConstraint);

    this.model.STEP2.filters = {
      startDate: min(allDateConstraints),
      endDate: max(allDateConstraints),
      showOnlyErrorRecords: false,
      daysOfWeek: [...DAYS_OF_WEEK],
      driveTypes: [DRIVE_TYPE.MOBILE, DRIVE_TYPE.FIXED_SITE],
      timeBlocks: []
    }

    this.filterStep2Records();
  }

  handleMasterRowModelChange = (event) => {
    const value = getValueFromEvent(event);
    if(event.currentTarget.name === 'totalStaffConstraints') {
      this.model.STEP2.masterRow.totalStaffConstraints = value;
      this.model.STEP2.filteredRecords.forEach(item => {
        item.totalStaffConstraints = value;
        this.handleStep2ValidateRecord(item);
      });
    }
  }

  handleCancel = (autoSyncedCoDateKeys = null) => {
    const closeEvent = new CustomEvent('close', {
      detail: {
        result: !!this.dataSaved,
        ...(autoSyncedCoDateKeys && { autoSyncedCoDateKeys })
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }

  buildCoSyncModels() {
    const tbRecords = this.model.STEP2.records.filter(r => r.timeBlockId && r.driveType === DRIVE_TYPE.MOBILE);
    if (!tbRecords.length) return [];

    const totals = new Map();
    tbRecords.forEach(r => {
      totals.set(r.dateOfConstraint, (totals.get(r.dateOfConstraint) || 0) + (r.totalStaffConstraints || 0));
    });

    const coModels = [];
    const autoSyncedKeys = [];
    totals.forEach((total, date) => {
      const coRecord = this.model.STEP2.originalRecords.find(
        r => !r.timeBlockId && r.driveType === DRIVE_TYPE.MOBILE && r.dateOfConstraint === date
      );
      if (!coRecord) return;
      coModels.push({ id: coRecord.id, totalStaffConstraints: total });
      autoSyncedKeys.push(`${coRecord.collectionOperationId}__${date}`);
    });

    this._autoSyncedCoDateKeys = autoSyncedKeys;
    return coModels;
  }

  handleSave = () => {
    if (!this.validateStep2()) return;

    const validRecords = this.model.STEP2.filteredRecords.filter(item => {
      if(!item.validations) return false;
      return true;
    })

    const modelsToDelete = this.model.STEP2.originalRecords.filter(originalItem => {
      const deleted = !this.model.STEP2.records.find(item => item.id === originalItem.id);
      return deleted;
    });

    const coModels = this.buildCoSyncModels();
    const coIds = new Set(coModels.map(m => m.id));

    let modelsToSave = [
      ...validRecords
        .filter(item => !coIds.has(item.id))
        .map(item => ({ id: item.id, totalStaffConstraints: item.totalStaffConstraints })),
      ...coModels
    ];

    this.showLoading();
    let service = new staffingConstraintService();
    service.deleteList(modelsToDelete)
      .then((result) => {
        if (!result?.success) {throw result;}

        return service.saveList(modelsToSave);
      })
      .then((result) => {
        if (result?.success) {
          this.dispatchEvent(
            new ShowToastEvent({
              message: "Edit recurrence staffing constraints successfully.",
              variant: "success",
              mode: "dismissable"
            })
          );

          this.dataSaved = true;

          this.handleCancel(this._autoSyncedCoDateKeys?.length ? this._autoSyncedCoDateKeys : null);
        }
      })
      .catch(error => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  }

  filterStep2Records = () => {
    let allRecords = this.model.STEP2.records;
    const { startDate, endDate, showOnlyErrorRecords, daysOfWeek, driveTypes, timeBlocks } = this.model.STEP2.filters;

    this.model.STEP2.filteredRecords = !allRecords?.length ? []
    : allRecords
      .filter(record => {
        if (driveTypes?.includes(record.driveType)) {
          if (record.driveType === DRIVE_TYPE.MOBILE) {
            return !timeBlocks?.length || timeBlocks?.includes(record.timeBlockId);
          }
          return true;
        }
        return !driveTypes?.length;
      })
      .filter(record => {
        return startDate <= record.dateOfConstraint && record.dateOfConstraint <= endDate;
      })
      .filter(record => {
        return daysOfWeek?.includes(record.weekdayLong);
      })
      .filter(record => {
        if(!showOnlyErrorRecords) return true;
        return record.validations?.requestedStaffExceeded;
      });
  }

  fetchStep2 = () => {
    const selectedDays = this.model.STEP1.selectedDays || [];
    if(!selectedDays.length) return;
    
    this.fetchStaffingConstraints()
    .then(() => {
      return this.getTimeBlockOptions();
    })
    .then(() => {
      return this.handleStep2ValidateRecords();
    })
    .then(() => {
      this.model.STEP2.masterRow.totalStaffConstraints = null;
      this.handleStep2ResetFilters();
      this.filterStep2Records();
    });
  }

  fetchStaffingConstraints = () => {
    this.showLoading();
    return Promise.resolve()
      .then(() => {
        const selectedDays = this.model.STEP1.selectedDays || [];
        if(!selectedDays.length) return;
        
        const staffingConstraintSvc = new staffingConstraintService();
        let staffingConstraintQuery = new staffingConstraintQueryModel();
        staffingConstraintQuery.selectedDates = selectedDays;
        staffingConstraintQuery.collectionOpIds = [this.defaultCollectionOperationId];
        staffingConstraintQuery.orderBy = 'dateOfConstraint';
        staffingConstraintQuery.orderAscending = 'asc';

        return staffingConstraintSvc.query(staffingConstraintQuery)
        .then((result = []) => {
          this.model.STEP2.originalRecords = cloneDeep(result);
          this.model.STEP2.records = result.map(item => {
            return {
              ...item,
              timeBlockName: item.timeBlock?.name,
              weekdayLong: this.dateUtils.dateIso2WeeekDay(item.dateOfConstraint).weekdayLong,
              validations: {}
            }
          });
        });
      })
      .then(() => {
        return this.handleStep2ValidateRecords();
      }).then(() => {
        this.filterStep2Records();
      })
      .catch(error => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  }

  validateStep2 = () => {
    const allValid = [
      ...this.template.querySelectorAll('lightning-input')]
      .reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
      }, true);

    if(!allValid) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'Please check required fields.',
        variant: 'error',
        mode: 'dismissable',
      }));
      return false;
    };

    const invalidRecords = this.model.STEP2.filteredRecords.filter(item => {
      if(!item.validations) return true;
      return false;
    });

    if(invalidRecords.length) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'There are some invalid Staffing Constraint records. Please review.',
        variant: 'error',
        mode: 'dismissable',
      }));
      return false;
    };

    return true;
  }
}