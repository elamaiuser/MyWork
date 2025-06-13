import { LightningElement, track, api } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { 
  activityService, 
  activityQueryModel, 
  driveService, 
  driveQueryModel, 
  staffingConstraintService, 
  staffingConstraintQueryModel, 
  collectionOperationTimeBlockQueryModel,
  collectionOperationTimeBlockService,
  sObjectType
} from 'c/dataService';
import * as slwcDateUtils from 'c/slwcDateUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { keyBy, groupBy, remove, uniqueId, uniq, min, max, orderBy } from 'c/lodash';
import Step1 from "./step1.html";
import Step2 from "./step2.html";
import Step3 from "./step3.html";
import { DRIVE_TYPE, DRIVE_STATUS } from 'c/slwcConstants';

const DAYS_OF_WEEK = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

export default class SlwcAddRecurrenceStaffingConstraintModal extends LightningElement {
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

  @track model = {
    STEP1: {},
    STEP2: {},
    STEP3: {}
  };
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
      onLoad: () => {},
      validate: () => this.validateStep2(),
      render: Step2
    },
    STEP3: {
      value: 3,
      onLoad: () => this.fetchStep3(),
      validate: () => this.validateStep3(),
      render: Step3
    }
  };

  @track currentStep = this.ALLSTEP.STEP1.value;
  @track listStep = [
    this.ALLSTEP.STEP1,
    this.ALLSTEP.STEP2,
    this.ALLSTEP.STEP3,
    this.ALLSTEP.STEP4,
    this.ALLSTEP.STEP5,
    this.ALLSTEP.STEP6
  ];
  @track daysOfWeekOptions = DAYS_OF_WEEK.map((day) => ({
    label: day, value: day
  }));
  @track timeBlockOptions = []

  get mode() {
    return "STEP" + this.currentStep;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    })
  }

  get modalHeader() {
    return 'Create Recurrence Staffing Constraints';
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

  init = () => {
    this.resetModel();
  }

  resetModel = () => {
    this.dataSaved = false;
    this.model = {
      STEP1: {
        collectionOperation: null,
        driveTypes: [DRIVE_TYPE.MOBILE, DRIVE_TYPE.FIXED_SITE],
        totalStaffConstraints: null
      },
      STEP2: {
        selectedDays: []
      },
      STEP3: {
        filters: {
          startDate: null,
          endDate: null,
          showOnlyErrorRecords: false,
          daysOfWeek: [],
        },
        masterRow: {
          totalStaffConstraints: null
        },
        records: [],
        filteredRecords: []
      }
    };

    this.currentStep = this.ALLSTEP.STEP1.value;
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

  handleStep1ModelOnChange(event) {
    event.stopPropagation();

    if (event.detail && event.detail.selection) {
      this.model.STEP1[event.currentTarget.name] = event.detail.selection;
    } else {
      let value = getValueFromEvent(event);
      this.model.STEP1[event.currentTarget.name] = value;
    }

    if (event.currentTarget.name === 'collectionOperation') {
      this.fetchTimeBlockData();
    }
  }

  handleStep2ModelOnChange = (event) => {
    this.model.STEP2.selectedDays = event.detail.selectedDays || [];
  }

  handleStep3ModelChange = (event) => {
    const key = event.currentTarget.dataset['key'];
    const record = this.model.STEP3.records.find(item => item.key === key);
    if(!record) return;

    let value = getValueFromEvent(event);
    record[event.currentTarget.name] = value;

    this.handleStep3ValidateRecord(record);
  }

  handleStep3DeleteRecord = (event) => {
    const key = event.currentTarget.dataset['key'];
    remove(this.model.STEP3.records, item => item.key === key);

    this.filterStep3Records();
  }

  handleStep3DeleteAllRecord = (event) => {
    const filteredRecordKeys = this.model.STEP3.filteredRecords.map(item => item.key);
    remove(this.model.STEP3.records, item => filteredRecordKeys.includes(item.key));

    this.handleStep3ResetFilters();
  }

  async fetchTimeBlockData() {
    this.showLoading();
    this.timeBlockOptions = [];

    const { collectionOperation } = this.model.STEP1;

    await Promise.resolve()
      .then(() => {
        const collectionOperationTimeBlockQuery = new collectionOperationTimeBlockQueryModel();
        collectionOperationTimeBlockQuery.collectionOperationIds = [collectionOperation?.id];

        const collectionOperationTimeBlockSvc = new collectionOperationTimeBlockService();

        return Promise.all([
          collectionOperationTimeBlockSvc.query(collectionOperationTimeBlockQuery),
        ]);
      })
      .then(([collectionOperationTimeBlockResult]) => {
        this.timeBlockOptions = collectionOperationTimeBlockResult.map(coTimeBlock => {
          return {
            ...coTimeBlock,
            label: coTimeBlock.timeBlock.name,
            value: coTimeBlock.timeBlock.id
          }
        });
      })
      .catch((error) => {
        console.log(error);
      })
      .finally(() => {
        this.hideLoading();
      });
  }

  fetchStaffingConstraintData = () => {
    const dateOfConstraints = uniq(this.model.STEP3.records.map(item => item.dateOfConstraint));
    const collectionOperationIds = uniq(this.model.STEP3.records.map(item => item.collectionOperation.id));
    const driveTypes = uniq(this.model.STEP3.records.map(item => item.driveType));
    const minDateIso = min(dateOfConstraints);
    const maxDateIso = max(dateOfConstraints);

    return Promise.resolve()
      .then(() => {
        const staffingConstraintQuery = new staffingConstraintQueryModel();
        staffingConstraintQuery.startDate = minDateIso;
        staffingConstraintQuery.endDate = maxDateIso;
        staffingConstraintQuery.collectionOpIds = collectionOperationIds;
        staffingConstraintQuery.driveTypes = driveTypes;

        const driveQuery = new driveQueryModel();
        driveQuery.startDate = minDateIso;
        driveQuery.endDate = maxDateIso;
        driveQuery.collectionOpIds = collectionOperationIds;
        driveQuery.eventTypes = driveTypes;
        driveQuery.statuses = [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD];
        driveQuery.subQueryIndicator = sObjectType.DRIVE_SHIFT;

        const activityQuery = new activityQueryModel();
        activityQuery.startDate = minDateIso;
        activityQuery.endDate = maxDateIso;
        activityQuery.collectionOperationIds = collectionOperationIds;
        activityQuery.isGroupActivity = true;
        activityQuery.reduceFromStaffingConstraint = true;

        const staffingConstraintSvc = new staffingConstraintService();
        const driveSvc = new driveService();
        const activitySvc = new activityService();

        return Promise.all([
          staffingConstraintSvc.query(staffingConstraintQuery),
          driveSvc.query(driveQuery),
          activitySvc.query(activityQuery)
        ]);
      })
      .then(([staffingConstraintResult, driveResult, activityResult]) => {
        const { timeBlocks: selectedTimeBlockIds } = this.model.STEP1;
        const validStaffingConstraints = staffingConstraintResult.filter(item => !item.timeBlockId || selectedTimeBlockIds.includes(item.timeBlockId));

        this.mappedStaffingConstraint = keyBy(validStaffingConstraints, 
          (item) => `${item.collectionOperationId}${item.timeBlockId ? '-'+item.timeBlockId : '' }-${item.driveType}-${item.dateOfConstraint}`
        );
        this.mappedDriveData = groupBy([...driveResult], (item) => `${item.collectionOperationId}-${item.typeOfDrive}-${item.driveDate}`);
        this.mappedActivityData = groupBy([...activityResult], (item) => `${item.collectionOperationId}-${item.startDate}`);
      })
  }

  handleStep3ValidateRecord = (record) => {
    record.validations = {
      staffingConstraintExisted: false,
      requestedStaffExceeded: false,
      noOfRequestedStaff: 0,
    }
    const staffingConstraintKey = `${record.collectionOperation.id}${record.timeBlock ? '-'+record.timeBlock.id : ''}-${record.driveType}-${record.dateOfConstraint}`;
    const driveKey = `${record.collectionOperation.id}-${record.driveType}-${record.dateOfConstraint}`;
    const activityKey = `${record.collectionOperation.id}-${record.dateOfConstraint}`;

    const existedStaffingConstraint = this.mappedStaffingConstraint[staffingConstraintKey];
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
    record.validations.staffingConstraintExisted = !!existedStaffingConstraint;
    record.validations.requestedStaffExceeded = noOfRequestedStaff > record.totalStaffConstraints;
  }

  handleStep3ValidateRecords = () => {
    this.showLoading();
    return this.fetchStaffingConstraintData()
      .then(() => {
        this.model.STEP3.records.forEach(record => {
          this.handleStep3ValidateRecord(record);
        });
      })
      .catch(error => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  }

  handleStep3FiltersOnChange = (event) => {
    if(event.currentTarget.name === 'dateRange') {
      const { startDate, endDate } = event.detail;
      this.model.STEP3.filters = {
        ...this.model.STEP3.filters,
        startDate,
        endDate
      }
    } else {
      const value = getValueFromEvent(event);
      this.model.STEP3.filters[event.currentTarget.name] = value;
    }
    
    this.filterStep3Records();
  }

  handleStep3ResetFilters = (event) => {
    const allDateConstraints = this.model.STEP3.records.map(item => item.dateOfConstraint);

    this.model.STEP3.filters = {
      startDate: min(allDateConstraints),
      endDate: max(allDateConstraints),
      showOnlyErrorRecords: false,
      daysOfWeek: [...DAYS_OF_WEEK],
    }

    this.filterStep3Records();
  }

  handleStep3MasterRowModelChange = (event) => {
    const value = getValueFromEvent(event);
    if(event.currentTarget.name === 'totalStaffConstraints') {
      this.model.STEP3.masterRow.totalStaffConstraints = value;
      this.model.STEP3.filteredRecords.forEach(item => {
        item.totalStaffConstraints = value;
        this.handleStep3ValidateRecord(item);
      });
    }
  }

  handleCancel = () => {
    const closeEvent = new CustomEvent('close', {
      detail: {
        result: !!this.dataSaved
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }

  handleSave = () => {
    if (!this.validateStep3()) return;

    const validRecords = this.model.STEP3.records.filter(item => {
      if(!item.validations) return false;
      if(item.validations.staffingConstraintExisted) return false;
      return true;
    })

    let modelsToSave = validRecords.map(item => {
      return {
        collectionOperationId: item.collectionOperation.id,
        timeBlockId: item.timeBlock?.id,
        dateOfConstraint: item.dateOfConstraint,
        driveType: item.driveType,
        totalStaffConstraints: item.totalStaffConstraints
      }
    })

    this.showLoading();
    let service = new staffingConstraintService();
    service.saveList(modelsToSave)
      .then((result) => {
        if (result?.success) {
          this.dispatchEvent(
            new ShowToastEvent({
              message: "Created staffing constraints successfully.",
              variant: "success",
              mode: "dismissable"
            })
          );

          this.dataSaved = true;

          this.handleCancel();
        }
      })
      .catch(error => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  }

  filterStep3Records = () => {
    let allRecords = this.model.STEP3.records;
    const { startDate, endDate, showOnlyErrorRecords, daysOfWeek } = this.model.STEP3.filters;

    this.model.STEP3.filteredRecords = allRecords
      .filter(record => {
        return startDate <= record.dateOfConstraint && record.dateOfConstraint <= endDate;
      })
      .filter(record => {
        return daysOfWeek?.includes(record.weekdayLong);
      })
      .filter(record => {
        if(!showOnlyErrorRecords) return true;
        return record.validations?.staffingConstraintExisted || record.validations?.requestedStaffExceeded;
      });
  }

  fetchStep3 = () => {
    const selectedDays = this.model.STEP2.selectedDays || [];
    if(!selectedDays.length) return;
    
    const originalModel = this.model.STEP1;
    const driveTypes = originalModel.driveTypes;
    this.model.STEP3.records = [];
    orderBy(selectedDays, [dateIso => dateIso], ['asc']).map(dateIso => {
      const weekdayLong = this.dateUtils.dateIso2WeeekDay(dateIso).weekdayLong;

      let coTimeBlocks = []; 
      if (originalModel.timeBlocks?.length) {
        coTimeBlocks = this.timeBlockOptions.filter(coTb => 
          (originalModel.timeBlocks.includes(coTb.timeBlock.id))
          && coTb.effectiveStartDate <= dateIso
          && coTb.effectiveEndDate >= dateIso
        );
      }

      driveTypes.forEach(driveType => {
        const newRecord = {
          key: uniqueId('staffing_constraint_'),
          ...originalModel,
          driveType,
          timeBlockName: '',
          dateOfConstraint: dateIso,
          weekdayLong: weekdayLong,
          validations: {}
        }
        this.model.STEP3.records.push(newRecord);

        if (driveType !== DRIVE_TYPE.FIXED_SITE) {
          if (coTimeBlocks.length) {
            coTimeBlocks.forEach(coTb => {
              if (coTb.timeBlock.daysOfWeek.includes(weekdayLong)) {
                const newRecord = {
                  key: uniqueId(`staffing_constraint_${coTb.timeBlock.id}`),
                  ...originalModel,
                  driveType,
                  timeBlockName: coTb.timeBlock.name,
                  timeBlock: coTb.timeBlock,
                  dateOfConstraint: dateIso,
                  weekdayLong: weekdayLong,
                  validations: {}
                }
                this.model.STEP3.records.push(newRecord);
              }
            })
          }
        }
      })
    })

    this.model.STEP3.masterRow.totalStaffConstraints = null;
    this.handleStep3ValidateRecords()
    .then(() => {
      this.handleStep3ResetFilters();
      this.filterStep3Records();
    });
  }

  validateStep1 = () => {
    const allValid = [
      ...this.template.querySelectorAll('lightning-input'),
      ...this.template.querySelectorAll('c-slwc-lookup'),
      ...this.template.querySelectorAll('c-slwc-multi-picklist'),
      ...this.template.querySelectorAll('c-slwc-picklist')]
      .reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
      }, true);

    return allValid;
  }

  validateStep2 = () => {
    if(this.model.STEP2.selectedDays.length <= 0) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'Please select at least 1 date.',
        variant: 'error',
        mode: 'dismissable',
      }));
      return false;
    }
    return true;
  }

  validateStep3 = () => {
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

    const invalidRecords = this.model.STEP3.records.filter(item => {
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

    const validRecords = this.model.STEP3.records.filter(item => {
      if(!item.validations) return false;
      if(item.validations.staffingConstraintExisted) return false;
      return true;
    })

    if(!validRecords.length) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'There is no valid Staffing Constraint record to save.',
        variant: 'error',
        mode: 'dismissable',
      }));
      return false;
    };

    return true;
  }
}