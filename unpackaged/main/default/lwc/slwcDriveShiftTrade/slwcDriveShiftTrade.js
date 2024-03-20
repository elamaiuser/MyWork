import { LightningElement, wire, track, api } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { uniqueId, keyBy, orderBy, compact } from "c/lodash";
import { DateTime } from "c/luxon";
import * as slwcDateUtils from "c/slwcDateUtils";
import * as slwcUtils from "c/slwcUtils";
import TIME_ZONE from "@salesforce/i18n/timeZone";
import USER_ID from "@salesforce/user/Id";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { JOB_ALLOCATION_STATUS, DRIVE_SHIFT_TRADE_TYPE, RESOURCE_TYPE } from 'c/slwcConstants';
import {
  jobAllocationService,
  jobAllocationQueryModel,
  activityResourceService,
  activityResourceQueryModel,
  resourceService,
  resourceQueryModel,
  resourceSecondaryCollectionOperationService,
  resourceSecondaryCollectionOperationQueryModel,
  driveShiftTradeService
} from "c/dataService";
import Confirm from "./confirm.html";
import SelectResource from "./selectResource.html";
import SelectShift from "./selectShift.html";
import SelectType from "./selectType.html";

export default class SlwcDriveShiftTrade extends LightningElement {
  @wire(CurrentPageReference) pageRef;

  @api fullScreen = false;
  @api userResource = null;

  @track timezoneSidId = TIME_ZONE;
  @track model = null;
  @track filters = {
    searchText: "",
    startDate: null,
    endDate: null
  };
  @track listResourcesFiltered = [];
  @track errorMessages = [];
  @track preventSubmit = false;

  showSpinnerCount = 0;

  listResources = [];
  listRequestRecords = [];
  listTradeRecords = [];

  listRequestRecordsMap = {};
  listTradeRecordsMap = {};
  listResourcesMap = {};

  ALLSTEP = {
    STEP1: {
      label: "Select Record Type",
      value: 1,
      function: () => {},
      render: SelectType
    },
    STEP2: {
      label: "Select Record",
      value: 2,
      function: () => this.fetchStep2(),
      render: SelectShift
    },
    STEP3: {
      label: "Select Resource",
      value: 3,
      function: () => this.fetchStep3(),
      render: SelectResource
    },
    STEP4: {
      label: "Select New Record Type",
      value: 4,
      function: () => {},
      render: SelectType
    },
    STEP5: {
      label: "Select New Record",
      value: 5,
      function: () => this.fetchStep5(),
      render: SelectShift
    },
    STEP6: {
      label: "Confirm",
      value: 6,
      function: () => this.validateTradeData(),
      render: Confirm
    }
  };

  step = this.ALLSTEP.STEP1.value;

  @track listStep = [
    this.ALLSTEP.STEP1,
    this.ALLSTEP.STEP2,
    this.ALLSTEP.STEP3,
    this.ALLSTEP.STEP4,
    this.ALLSTEP.STEP5,
    this.ALLSTEP.STEP6
  ];

  get typeOptions() {
    return [DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT, DRIVE_SHIFT_TRADE_TYPE.ACTIVITY].map(type => {
      return {
        label: type,
        value: type 
      }
    })
  }
  
  get stepLabel() {
    const step = Object.values(this.ALLSTEP).find(item => item.value === this.step);
    return (step || {}).label;
  }

  get stepHeader() {
    if(!this.model) return null;
    return `Shift Trade Submission`
  }

  get isStep1() {
    return this.step === 1;
  }

  get isStep2() {
    return this.step === 2;
  }

  get isStep3() {
    return this.step === 3;
  }

  get isStep4() {
    return this.step === 4;
  }

  get isStep5() {
    return this.step === 5;
  }

  get recordSelected() {
    return [
      {
        ...this.model.requestingStaffRecord,
        tradingType: this.model.requestingStaffTradingType,
        isFirst: true
      },
      {
        ...this.model.tradingStaffRecord,
        tradingType: this.model.tradingStaffTradingType,
      }
    ];
  }
  get showSpinner() {
    return this.showSpinnerCount > 0;
  }
  get mode() {
    return "STEP" + this.step;
  }
  get disabledNext() {
    return (
      (this.isStep1 && !this.model.requestingStaffTradingType) || 
      (this.isStep2 && !this.model.requestingStaffRecord) ||
      (this.isStep3 && !this.model.tradingStaff) ||
      (this.isStep4 && !this.model.tradingStaffTradingType) || 
      (this.isStep5 && !this.model.tradingStaffRecord)
    )
  }
  get canConfirmTrade() {
    return !this.preventSubmit;
  }
  get btnConfirmDisabled() {
    return !this.canConfirmTrade;
  }
  get showPrevious() {
    return !this.isStep1;
  }
  get listRecords() {
    if (this.isStep2 && this.listRequestRecords.length) {
      return this.listRequestRecords || null;
    } else if (this.isStep5 && this.listTradeRecords.length) {
      return this.listTradeRecords || null;
    } else {
      return null;
    }
  }
  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  get customClass() {
    return {
      modal: slwcUtils.classNames('slds-grid slds-grid_vertical', {
        'full-screen': this.fullScreen
      })
    }
  }

  connectedCallback() {
    this.init();
  }

  render() {
    return this.ALLSTEP[this.mode].render;
  }

  init() {
    this.clear();
  }
  
  clear() {
    this.model = {
      requestingStaffTradingType: DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT,
      tradingStaffTradingType: DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT,
      contactMethod: null,
      reasonForTrade: null,
      tradingStaff: null,
      tradingStaffRecord: null, //Drive Shift | Activity | On Call
      requestingStaff: null,
      requestingStaffRecord: null, //Drive Shift | Activity | On Call
      tradeRequesterNotes: null,
      contentionAcknowledge: false
    };

    this.filters = {
      searchText: "",
      startDate: null,
      endDate: null
    };

    this.showSpinnerCount = 0;

    this.listResources = [];
    this.listRequestRecords = [];
    this.listTradeRecords = [];
    this.listResourcesFiltered = [];

    this.listRequestRecordsMap = {};
    this.listTradeRecordsMap = {};
    this.listResourcesMap = {};

    this.step = this.ALLSTEP.STEP1.value;

    if (!this.filters.startDate || !this.filters.endDate) {
      const firstDay = this.dateUtils.getFirstDayValue();
      this.filters.startDate = this.dateUtils
        .startOfWeek(DateTime.local(), firstDay)
        .toISODate();
      this.filters.endDate = DateTime.fromISO(this.filters.startDate)
        .plus({
          day: 6
        })
        .toISODate();
    }
  }
  // LOADING
  exceptionHandler = (error) => {
    this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinnerCount++;
  };

  hideLoading = () => {
    this.showSpinnerCount--;
    if (this.showSpinnerCount < 0) {
      this.showSpinnerCount = 0;
    }
  };
  filterResource() {
    this.listResourcesFiltered = orderBy(this.listResources.filter((item) => {
      return item.name
        .toUpperCase()
        .includes(this.filters.searchText.toUpperCase());
    }), ['name'], ['asc']);
  }
  
  fetchStep2() {
    const fetchJobAllocations = () => {
      let query = new jobAllocationQueryModel();
      query.startDate = this.filters.startDate;
      query.endDate = this.filters.endDate;
      query.resourceIds = [this.userResource.id];
      query.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, JOB_ALLOCATION_STATUS.IN_PROGRESS];
      
      let service = new jobAllocationService();
      return service.query(query).then((res) => {
        return (res || []).map(item => {
          item.isJobAllocation = true;
          item.recordUrl = '/' + item.id;
          return item;
        })
      });
    }

    const fetchGroupActivities = () => {
      let query = new activityResourceQueryModel();
      query.startDate = this.filters.startDate;
      query.endDate = this.filters.endDate;
      query.resourceIds = [this.userResource.id];
      query.isGroupActivity = true;

      let service = new activityResourceService();
      return service.query(query).then((res) => {
        return (res || []).map(item => {
          item.isGroupActivity = true;
          item.recordUrl = '/' + item.id;
          return item;
        })      
      });
    }

    const TYPE_FETCH_FUNCTION_MAP = {
      [DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT]: fetchJobAllocations,
      [DRIVE_SHIFT_TRADE_TYPE.ACTIVITY]: fetchGroupActivities
    }
    
    this.showLoading();
    TYPE_FETCH_FUNCTION_MAP[this.model.requestingStaffTradingType]()
    .then((res) => {
      this.listRequestRecords = res;
      this.listRequestRecordsMap = keyBy(this.listRequestRecords, "id");

      //reset
      this.model.requestingStaffRecord = null;
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }
  
  fetchStep3() {
    this.showLoading();
    Promise.resolve()
    .then(() => {
      let queryResource = new resourceQueryModel();
      queryResource.excludedRecordIds = [this.userResource.id];
      queryResource.collectionOpIds = [this.userResource.collectionOperationId];
      queryResource.resourceTypes = [RESOURCE_TYPE.PERSON];

      let service = new resourceService();
      return service.query(queryResource);
    })
    .then((primaryCOResources = []) => {
      let resourceSecondaryCOService = new resourceSecondaryCollectionOperationService();
      let resourceSecondaryCOQueryModel = new resourceSecondaryCollectionOperationQueryModel();
      if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
        resourceSecondaryCOQueryModel.startDate = this.dateUtils.date2dateIso(this.model.requestingStaffRecord.start || this.model.requestingStaffRecord.job.start);
        resourceSecondaryCOQueryModel.endDate = this.dateUtils.date2dateIso(this.model.requestingStaffRecord.end || this.model.requestingStaffRecord.job.finish);
      } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
        resourceSecondaryCOQueryModel.startDate = this.dateUtils.date2dateIso(this.model.requestingStaffRecord.activity.start);
        resourceSecondaryCOQueryModel.endDate = this.dateUtils.date2dateIso(this.model.requestingStaffRecord.activity.finish);
      }

      resourceSecondaryCOQueryModel.collectionOperationIds = [this.userResource.collectionOperationId];
      resourceSecondaryCOQueryModel.excludedResourceIds = [this.userResource.id].concat(primaryCOResources.map(item => item.id));
      resourceSecondaryCOQueryModel.resourceTypes = [RESOURCE_TYPE.PERSON];

      return resourceSecondaryCOService.query(resourceSecondaryCOQueryModel)
      .then((resourceSecondaryCOs = []) => {
        const secondaryResourceIds = resourceSecondaryCOs.map(item => item.resourceId);
        if(secondaryResourceIds.length) {
          let queryResource = new resourceQueryModel();
          queryResource.recordIds = secondaryResourceIds;

          let service = new resourceService();
          return Promise.all([primaryCOResources, service.query(queryResource)]);
        } else {
          return Promise.all([primaryCOResources, []]);
        }
      })
    })
    .then(([primaryCOResources = [], secondaryCOResources = []]) => {
      this.listResources = primaryCOResources.concat(secondaryCOResources);
      this.listResourcesMap = keyBy(this.listResources, "id");
      if (this.model.tradingStaff && this.model.tradingStaff.id) {
        this.listResourcesMap[this.model.tradingStaff.id]["classes"] = "selected-item";
      }
      this.filterResource();
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  fetchStep5() {
    const fetchJobAllocations = () => {
      let query = new jobAllocationQueryModel();
      query.startDate = this.filters.startDate;
      query.endDate = this.filters.endDate;
      query.resourceIds = [this.model.tradingStaff.id];
      query.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, JOB_ALLOCATION_STATUS.IN_PROGRESS];
      
      let service = new jobAllocationService();
      return service.query(query).then((res) => {
        return (res || [])
        .filter(item => item.jobId !== this.model.requestingStaffRecord.jobId)
        .map(item => {
          item.isJobAllocation = true;
          item.recordUrl = '/' + item.id;
          return item;
        })
      });
    }

    const fetchGroupActivities = () => {
      let query = new activityResourceQueryModel();
      query.startDate = this.filters.startDate;
      query.endDate = this.filters.endDate;
      query.resourceIds = [this.model.tradingStaff.id];
      query.isGroupActivity = true;

      let service = new activityResourceService();
      return service.query(query)
      .then((res) => {
        return (res || [])
        .filter(item => item.activityId !== this.model.requestingStaffRecord.activityId)
        .map(item => {
          item.isGroupActivity = true;
          item.recordUrl = '/' + item.id;
          return item;
        })      
      });
    }

    const TYPE_FETCH_FUNCTION_MAP = {
      [DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT]: fetchJobAllocations,
      [DRIVE_SHIFT_TRADE_TYPE.ACTIVITY]: fetchGroupActivities
    }
    
    this.showLoading();
    TYPE_FETCH_FUNCTION_MAP[this.model.tradingStaffTradingType]()
    .then((res) => {
      this.listTradeRecords = res;
      this.listTradeRecordsMap = keyBy(this.listTradeRecords, "id");

      if (this.model.tradingStaffRecord && this.model.tradingStaffRecord.id && this.listTradeRecordsMap[this.model.tradingStaffRecord.id]) {
        this.listTradeRecordsMap[this.model.tradingStaffRecord.id]["classes"] = "selected-item";
      }
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  // HANDLE
  validateTradeData() {
    const validateTradeActivityToAnother = (requestingStaffRecord, tradingStaffRecord) => {
      //make sure Resource 2 isn't allocated to any Activity in Day 1 that overlapped with requestingStaffRecord
      let errorMessages = [];
      const requestingStaffActivity = requestingStaffRecord.activity;
      const requestingStaff = requestingStaffRecord.resource;
      const tradingStaffActivity = requestingStaffRecord.activity;
      const tradingStaff = tradingStaffRecord.resource;
      
      let query = new activityResourceQueryModel();
      query.resourceIds = [tradingStaff.id];
      query.startDate = [requestingStaffActivity.startDate];
      query.endDate = [requestingStaffActivity.endDate];

      let service = new activityResourceService();
      return service.query(query)
      .then((groupActivityResources = []) => {
        const requestingStaffActivityResources = groupActivityResources.filter(item => item.activityId === requestingStaffActivity.id);        
        const tradingStaffExisitingInRequestingActivity = requestingStaffActivityResources.find(item => item.resourceId === tradingStaff.id);
        if(tradingStaffExisitingInRequestingActivity) {
          errorMessages.push(`${tradingStaff.name} is already assigned to Activity ${requestingStaffActivity.activityTitle || requestingStaffActivity.name}.`);
        } else {
          //check for any Resource 2 activities that overlapped with requesting activity
          const otherActivityResources = groupActivityResources.filter(item => item.activityId !== tradingStaffActivity.id);
          const isAnyActivityOverlapped = otherActivityResources.find(item => {
            let start1 = requestingStaffActivity.start,
            start2 = item.activity.start,
            end1 = requestingStaffActivity.finish,
            end2 = item.activity.finish;
      
            return (start1 < end2 && end1 > start2);
          })

          if(isAnyActivityOverlapped) {
            errorMessages.push(`${tradingStaff.name} is already assigned to Activity ${isAnyActivityOverlapped.activity.activityTitle || isAnyActivityOverlapped.activity.name} that overlapped with Activity ${requestingStaffActivity.activityTitle || requestingStaffActivity.name}.`);
          }
        }

        return errorMessages;
      });
    } 

    const validateTradeJobAllocationToAnother = (requestingStaffRecord, tradingStaffRecord) => {
      //make sure Resource 2 isn't allocated to any Job in Day 1 that overlapped with requestingStaffRecord
      let errorMessages = [];
      const requestingStaffJob = requestingStaffRecord.job;
      const requestingStaff = requestingStaffRecord.resource;
      const tradingStaffJob = tradingStaffRecord.job;
      const tradingStaff = tradingStaffRecord.resource;

      return Promise.resolve()
      .then(() => {
        let query = new jobAllocationQueryModel();
        query.statuses = [JOB_ALLOCATION_STATUS.PENDING_DISPATCH, JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, JOB_ALLOCATION_STATUS.IN_PROGRESS];
        query.startDate = requestingStaffJob.driveDate;
        query.endDate = requestingStaffJob.driveDate;
        query.resourceIds = [tradingStaff.id];

        let service = new jobAllocationService();
        return service.query(query)
        .then((jobAllocations = []) => {
          const requestingStaffJobAllocations = jobAllocations.filter(item => item.jobId === requestingStaffJob.id);
          const tradingStaffExisitingInRequestingJob = requestingStaffJobAllocations.find(item => item.resourceId === tradingStaff.id);
          const requestingStaffDriveName = requestingStaffJob.driveName;
          const requestingStaffDriveDate = DateTime.fromFormat(requestingStaffJob.driveDate, 'yyyy-MM-dd').toFormat('MMM dd, yyyy');
          if(tradingStaffExisitingInRequestingJob) {
            errorMessages.push(`${tradingStaff.name} is already assigned to ${requestingStaffDriveName}.`);
          } else {
            const otherJobAllocations = jobAllocations.filter(item => item.jobId !== tradingStaffJob.id);
            const isAnyJobThatHasTradingStaff = otherJobAllocations.find(item => {
              return item.resourceId === tradingStaff.id;
            })
            
            if(isAnyJobThatHasTradingStaff) {
              errorMessages.push(`${tradingStaff.name} is already assigned to ${isAnyJobThatHasTradingStaff.driveName} on ${requestingStaffDriveDate}.`);
            }
          }

          return errorMessages;
        });
      })
    }
    
    const TYPE_VALIDATE_FUNCTION_MAP = {
      [DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT]: validateTradeJobAllocationToAnother,
      [DRIVE_SHIFT_TRADE_TYPE.ACTIVITY]: validateTradeActivityToAnother
    }

    let service = new driveShiftTradeService();
    this.errorMessages = [];
    this.preventSubmit = false;
    this.model.contentionAcknowledge = false;
    this.showLoading();
    Promise.resolve()
    .then(() => {
      const validateRequestingRecordFn = TYPE_VALIDATE_FUNCTION_MAP[this.model.requestingStaffTradingType];
      const validateTradingRecordFn = TYPE_VALIDATE_FUNCTION_MAP[this.model.tradingStaffTradingType];
      
      return Promise.all([
        validateRequestingRecordFn(this.model.requestingStaffRecord, this.model.tradingStaffRecord),
        validateTradingRecordFn(this.model.tradingStaffRecord, this.model.requestingStaffRecord),
        service.validateRequest({
          request: this.buildSaveParams()
        })
      ])
    })
    .then(([requestingRecordErrorMessages = [], tradingRecordErrorMessages = [], validateRequestResponse]) => {
      this.errorMessages = this.errorMessages.concat(requestingRecordErrorMessages);
      this.errorMessages = this.errorMessages.concat(tradingRecordErrorMessages);  
      this.errorMessages = this.errorMessages.map(errorMessage => {
        return {
          message: errorMessage
        }
      });

      let contentions = ((validateRequestResponse || {}).returnedData || []);
      const hardViolations = contentions.filter(item => item.hardViolation);
      const softViolations = contentions.filter(item => !item.hardViolation);

      if(hardViolations.length) {
        this.errorMessages = this.errorMessages.concat(hardViolations.map(item => ({
          message: item.contention
        })));  
      }
      
      if(this.errorMessages.length > 0) {
        //hard stop
        this.preventSubmit = true;
        return;
      }

      //soft stop
      this.preventSubmit = false;
      this.errorMessages = softViolations.map(item => ({
        message: item.contention
      }));  
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  validateConfirmForm() {
    const allValid = [
      ...this.template.querySelectorAll("c-slwc-picklist"),
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("lightning-combobox")
      ]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

  
    return allValid;
  }

  handleSelectRecord(event) {
    const { id } = event.currentTarget.dataset;
    if (this.isStep2) {
      this.listRequestRecords.forEach(record => {
        record["classes"] = "";
      })

      let recordSelected = this.listRequestRecordsMap[id];
      this.model.tradingStaff = null;
      this.model.tradingStaffRecord = null;
      recordSelected["classes"] = "selected-item";

      this.model.requestingStaffRecord = recordSelected;
    } else {
      this.listTradeRecords.forEach(record => {
        record["classes"] = "";
      })

      let recordSelected = this.listTradeRecordsMap[id];
      recordSelected["classes"] = "selected-item";

      this.model.tradingStaffRecord = recordSelected || null;
    }
  }

  buildSaveParams() {
    if(!this.model) return null;

    let dataSave = {
      requestingStaffTradingType: this.model.requestingStaffTradingType,
      tradingStaffTradingType: this.model.tradingStaffTradingType,
      contactMethod: this.model.contactMethod,
      reasonForTrade: this.model.reasonForTrade,
      tradeRequesterNotes: this.model.tradeRequesterNotes,
      requestingStaffId: this.userResource.id,
      tradingStaffId: this.model.tradingStaff.id,
      contentionAcknowledge: !!this.model.contentionAcknowledge
    };
    
    if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
      dataSave.requestingStaffJobAllocationId = this.model.requestingStaffRecord.id;
    } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
      dataSave.requestingStaffNCEId = this.model.requestingStaffRecord.activityId;
    } 

    if(this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
      dataSave.tradingStaffJobAllocationId = this.model.tradingStaffRecord.id;
    } else if(this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
      dataSave.tradingStaffNCEId = this.model.tradingStaffRecord.activityId;
    } 

    return dataSave;
  }

  handleConfirm() {
    const valid = this.validateConfirmForm();
    if (!valid) {
      return;
    }
    const dataSave = this.buildSaveParams();
    let service = new driveShiftTradeService();
    this.showLoading();
    service.save(dataSave).then((result) => {
      if (!result.success) {
        throw result;
      }

      const event = new ShowToastEvent({
        message: `Shift Trade has been submitted successfully.`,
        variant: "success",
        mode: "dismissable"
      });
      this.dispatchEvent(event);

      const closeEvent = new CustomEvent('close', {
        detail: {
          result: true
        }
      });
      this.dispatchEvent(closeEvent);
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleSelectResource(event) {
    const { id } = event.currentTarget.dataset;
    this.listResourcesMap[id]["classes"] = "selected-item";
    if (this.model.tradingStaff && this.model.tradingStaff.id) {
      this.listResourcesMap[this.model.tradingStaff.id]["classes"] = "";
    }
    this.model.tradingStaff = this.listResourcesMap[id];
    this.model.tradingStaffRecord = null;
  }

  handleNext() {
    if (this.step > this.ALLSTEP.length) {
      this.step = 1;
    } else {
      this.step += 1;
    }
    this.ALLSTEP[this.mode].function();
  }

  handlePrev() {
    this.step -= 1;
  }

  handleClose() {
    const closeEvent = new CustomEvent('close', {
      detail: {
        result: false
      }
    });
    this.dispatchEvent(closeEvent);
  }

  handleTypeChanged(event) {
    if(this.isStep1) {
      this.clear();
      this.model.requestingStaffTradingType = slwcUtils.getValueFromEvent(event);
      this.model.tradingStaffTradingType = this.model.requestingStaffTradingType;
    } else if (this.isStep4) {
      this.listRequestRecords.forEach(record => {
        record["classes"] = "";
      })
      this.model.tradingStaffTradingType = slwcUtils.getValueFromEvent(event);
      this.model.tradingStaffRecord = null;
    }
  }

  handleOnChangeModel(event) {
    const eventName = event.target.name;
    if (eventName === "contactMethod") {
      this.model.contactMethod = event.detail.selectedValue;
    } else {
      this.model[eventName] = slwcUtils.getValueFromEvent(event);
    }
  }
  handleOnChangeFilter(event) {
    const eventName = event.target.name;
    if (event.type === "weekdatechange") {
      this.filters.startDate = event.detail.startDate;
      this.filters.endDate = event.detail.endDate;
      this.ALLSTEP[this.mode].function();
    } else if (eventName === "searchText") {
      this.filters.searchText = slwcUtils.getValueFromEvent(event);
      this.filterResource();
    }
  }
}