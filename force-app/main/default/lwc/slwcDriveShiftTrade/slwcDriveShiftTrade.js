import TIME_ZONE from "@salesforce/i18n/timeZone";
import {
  sObjectType,
  activityQueryModel,
  activityService,
  activityResourceQueryModel,
  activityResourceService,
  availabilityService,
  debugLogService,
  driveShiftQueryModel,
  driveShiftTradeService,
  jobAllocationQueryModel,
  jobAllocationService,
  driveService,
  driveQueryModel,
  territoryCollectionOperationQueryModel,
  territoryCollectionOperationService
} from "c/dataService";
import { keyBy, orderBy, uniqueId, compact, uniq } from "c/lodash";
import { DateTime } from "c/luxon";
import { DRIVE_SHIFT_TRADE_STATUS, DRIVE_SHIFT_TRADE_TYPE, RESOURCE_TYPE, JOB_ALLOCATION_STATUS } from 'c/slwcConstants';
import * as slwcDateUtils from "c/slwcDateUtils";
import * as slwcUtils from "c/slwcUtils";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, api, track, wire } from "lwc";
import Confirm from "./confirm.html";
import SelectResource from "./selectResource.html";
import SelectShift from "./selectShift.html";
import SelectShiftMarketTrade from "./selectShiftMarketTrade.html";
import SelectType from "./selectType.html";
import * as slwcAvailator from 'c/slwcAvailator';

const RESOURCES_LIST_LIMIT = 20;

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
  @track isContentionAcknowledgeRequired = false;
  @track isTATAcknowledgeRequired = false;
  @track isGMHAcknowledgeRequired = false;
  @track isRelocatedAcknowledgeRequired = false;
  @track isUnavailableForCOAcknowledgeRequired = false;
  @track errorMessages = [];
  @track preventSubmit = false;
  @track driveShiftTradeFilers = {
    showOnlyAutoApprovalDSTs: false
  }
  @track enableInfiniteLoading = true;
  showSpinnerCount = 0;

  listResources = [];
  listRequestRecords = [];
  listTradeRecords = [];

  listRequestRecordsMap = {};
  listTradeRecordsMap = {};
  listResourcesMap = {};

  ALLSTEP = {
    STEP1: {
      label: "Select Event Type",
      value: 1,
      function: () => {},
      render: () => SelectType
    },
    STEP2: {
      label: "Select Event",
      value: 2,
      function: () => this.fetchStep2(),
      render: () => SelectShift
    },
    STEP3: {
      label: "Select Resource",
      value: 3,
      function: () => this.fetchStep3(),
      render: () => SelectResource
    },
    STEP4: {
      label: "Select New Event Type",
      value: 4,
      function: () => {},
      render: () => SelectType
    },
    STEP5: {
      label: "Select New Event",
      value: 5,
      function: () => this.fetchStep5(),
      render: () => {
        if(this.isMarketTrade) {
          return SelectShiftMarketTrade;
        }
        return SelectShift
      }
    },
    STEP6: {
      label: "Confirm",
      value: 6,
      function: () => this.validateTradeData(),
      render: () => Confirm
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

  get resourceSelectionColumns() { 
    return [
      { fieldName: 'id', hideLabel: true, type: 'traderSelection', 
        typeAttributes: {
          classes: { fieldName: 'classes' },
          photoUrl: { fieldName: 'photoUrl' },
          name: { fieldName: 'name' },
          category: { fieldName: 'category' },
          clickAction: (event) => this.handleSelectResource(event)
        }
      }
    ];
  }

  get typeOptions() {
    return [DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT, DRIVE_SHIFT_TRADE_TYPE.ACTIVITY, DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY].map(type => {
      return {
        label: type,
        value: type 
      }
    })
  }

  get step4TypeOptions() {
    return [DRIVE_SHIFT_TRADE_TYPE.NONE, DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT, DRIVE_SHIFT_TRADE_TYPE.ACTIVITY]
    .filter(type => this.model?.requestingStaffTradingType !== DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY || type !== DRIVE_SHIFT_TRADE_TYPE.NONE)
    .map(type => {
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
    if(this.isMarketOneSideTrade) {
      return [
        {
          ...this.model.requestingStaffRecord,
          tradingType: this.model.requestingStaffTradingType,
          isNoTradingRecord: [DRIVE_SHIFT_TRADE_TYPE.NONE, DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY].includes(this.model.requestingStaffTradingType)
        }
      ];
    }

    if(this.isMarketTrade && !this.isMarketOneSideTrade) {
      return [
        {
          ...this.model.requestingStaffRecord,
          tradingType: this.model.requestingStaffTradingType,
          isNoTradingRecord: [DRIVE_SHIFT_TRADE_TYPE.NONE, DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY].includes(this.model.requestingStaffTradingType),
          isFirst: true
        },
        {
          ...(
            this.model.tradingStaffRecord.requestingStaffJobAllocationId ? 
              this.model.tradingStaffRecord.requestingStaffJobAllocation : 
              this.model.tradingStaffRecord.requestingStaffNCE
          ),
          isGroupActivity: this.model.tradingStaffRecord.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY,
          isJobAllocation: this.model.tradingStaffRecord.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT,
          isAvailableDay: this.model.tradingStaffRecord.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY,
          tradingType: this.model.tradingStaffRecord.requestingStaffTradingType,
          resource: {
            id: this.model.tradingStaffRecord.requestingStaffId,
            name: this.model.tradingStaffRecord.requestingStaffName
          },
          startDate: this.model.tradingStaffRecord.requestingStaffTradingAvailableDate,
          activity: this.model.tradingStaffRecord.requestingStaffJobAllocationId ? null : this.model.tradingStaffRecord.requestingStaffNCE,
          isNoTradingRecord: this.model.tradingStaffRecord.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY
        }
      ];
    }

    return [
      {
        ...this.model.requestingStaffRecord,
        tradingType: this.model.requestingStaffTradingType,
        isNoTradingRecord: [DRIVE_SHIFT_TRADE_TYPE.NONE, DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY].includes(this.model.requestingStaffTradingType),
        isFirst: true
      },
      {
        ...this.model.tradingStaffRecord,
        tradingType: this.model.tradingStaffTradingType,
        isNoTradingRecord: this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.NONE
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
      (this.isStep4 && !this.model.tradingStaffTradingType) || 
      (this.isStep5 && !this.isMarketTrade && !this.model.tradingStaffRecord)
    )
  }
  get isMarketTrade() {
    const isAfterStep3 = this.step >= this.ALLSTEP.STEP3.value;
    return isAfterStep3 && !this.model.tradingStaff;
  }
  get isMarketOneSideTrade() {
    const isAfterStep3 = this.step >= this.ALLSTEP.STEP3.value;
    return isAfterStep3 && !this.model.tradingStaff && !this.model.tradingStaffRecord;
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
      return this.listRequestRecords || [];
    } else if (this.isStep5 && this.listTradeRecords.length) {
      if(this.isMarketTrade) {
        return (this.listTradeRecords || null).filter(item => {
          if(!this.driveShiftTradeFilers?.showOnlyAutoApprovalDSTs) {
            return true;
          }

          return !item.contentions?.length && !item.requesterNeedToAcknowledge;
        })
      } else {
        return this.listTradeRecords || [];
      }
    } else {
      return [];
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

  get showOutOfAvailableDayTradeWindow() {
    return this.isStep2 && this.model?.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY && this.filters.startDate && this.filters.endDate && this.userResource  
           && this.isOutOfAvailableDaysTradeWindow(this.filters.startDate, this.filters.endDate, this.userResource.primaryRegion.collectionOperationAvailableDayTradeWindow);
  }

  get showWeekDatePicker() {
    return this.isStep2 || this.model.requestingStaffTradingType !== DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY
  }

  connectedCallback() {
    this.init();
  }

  render() {
    return this.ALLSTEP[this.mode].render();
  }

  init() {
    this.clear();
  }
  
  clear() {
    this.model = {
      requestingStaffTradingType: DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT,
      tradingStaffTradingType: DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT,
      contactMethod: null,
      requestingStaffTradeReason: null,
      requestingStaffNotes: null,
      tradingStaff: null,
      tradingStaffRecord: null, //Drive Shift | Activity | On Call
      requestingStaff: null,
      requestingStaffRecord: null, //Drive Shift | Activity | On Call
      contentionAcknowledge: false,
      requestingStaffGMHAcknowledge : false,
      requestingStaffTATAcknowledge : false,
      requesterRelocatedAcknowledge: false,
      requesterUnavailableForCOAcknowledge: false
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
    new debugLogService().captureDebugLog(error);
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

  buildRolesString = (jobAllocation) => {
    const resourceRole = jobAllocation.job.resourceRole;
    const dualRole = jobAllocation.job.dualRole;
    const additionalRoles = jobAllocation.additionalRoles?.split(";") || [];
    return compact(uniq([resourceRole, dualRole, ...additionalRoles])).join(', ');
  };

  filterResource() {
    this.enableInfiniteLoading = true;
    this.listResourcesFiltered = this.paginateResourceList(this.applyFilterResource(), 0);
  }

  applyFilterResource() {
    return orderBy(this.listResources.filter((item) => {
      return item.name
        .toUpperCase()
        .includes(this.filters.searchText.toUpperCase());
    }), ['name'], ['asc'])
  }

  paginateResourceList(resourceList, offset) {
    return (resourceList || []).slice(offset, offset + RESOURCES_LIST_LIMIT);
  }

  handleLoadMoreResourceData(event) {
    event.target.isLoading = true;
    const result = this.fetchMoreResourceData();
    if (result.length == 0) {
        this.enableInfiniteLoading = false;
    }
    else {
        const currentData = this.listResourcesFiltered;
        const newData = currentData.concat(result);
        this.listResourcesFiltered = newData;
    }
    event.target.isLoading = false;
  }

  fetchMoreResourceData() {
    return this.paginateResourceList(this.applyFilterResource(), (this.listResourcesFiltered || []).length);
  }
  
  fetchStep2() {
    const fetchJobAllocations = () => {
      let query = new jobAllocationQueryModel();
      query.startDate = this.filters.startDate;
      query.endDate = this.filters.endDate;
      query.resourceIds = [this.userResource.id];
      query.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, JOB_ALLOCATION_STATUS.IN_PROGRESS];
      query.orderBy = 'startDate';
      query.orderAscending = 'asc';

      let service = new jobAllocationService();
      return service.query(query).then((res) => {
        return (res || []).map(item => {
          item.isJobAllocation = true;
          item.recordUrl = '/' + item.id;
          item.rolesString = this.buildRolesString(item);
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
      query.orderBy = 'startDate';
      query.orderAscending = 'asc';

      let service = new activityResourceService();
      return service.query(query).then((res) => {
        return (res || []).map(item => {
          item.isGroupActivity = true;
          item.recordUrl = '/' + item.id;
          return item;
        })      
      });
    }

    const fetchAvailableDaysWithEvents = () => {
      return Promise.resolve()
      .then(() => {
        let today = DateTime.local().toISODate();
        let coAvailableDayTradeWindow = this.userResource.primaryRegion.collectionOperationAvailableDayTradeWindow;
        let startDate = this.filters.startDate;
        let endDate = this.filters.endDate;
        if (this.isOutOfAvailableDaysTradeWindow(startDate, endDate, coAvailableDayTradeWindow)) {
          return [];
        } else {
          startDate = this.dateUtils.compareDateJS(today, startDate) > 0 ? today : startDate;
          endDate = this.dateUtils.diffDays(today, endDate) > coAvailableDayTradeWindow ? this.dateUtils.dateToStringNative(this.dateUtils.addDay(new Date(today), coAvailableDayTradeWindow)) : endDate;
          const diff = this.dateUtils.diffDays(startDate, endDate);
          const jobs = [];
          for (let i = 0; i <= diff; i++) {
              let currentDay = DateTime.fromFormat(startDate, 'yyyy-MM-dd', {
                  zone: TIME_ZONE
              }).plus({
                  days: i
              });

              const start = currentDay.toUTC().toISO();
              const finish = currentDay.plus({
                  hours: 23,
                  minutes: 59
              }).toUTC().toISO();

              const relocatedCollectionOperationIds = this.findMatchedResourceOverrideOfRequester(currentDay.toISODate(), currentDay.toISODate())
                                                          .map(resourceOverride => resourceOverride.collectionOperationId);

              jobs.push({
                  id: uniqueId(`temp_job_`),
                  start: start,
                  finish: finish,
                  driveDate: currentDay.toISODate(),
                  collectionOperationIds: relocatedCollectionOperationIds.length ? relocatedCollectionOperationIds : [this.userResource.collectionOperationId]
              })
          }

          const requesterCollectionOperationIds = [this.userResource.collectionOperationId];
          const relocatedCollectionOperationIds = this.findMatchedResourceOverrideOfRequester(startDate, endDate).map(resourceOverride => resourceOverride.collectionOperationId);
          requesterCollectionOperationIds.concat(relocatedCollectionOperationIds);

          const availator = slwcAvailator.getInstance({
            mapApis: window.google ? window.google.maps : null,
            considerDateOnly: true
          });

          return availator.fetchResourceDataForTrade(jobs, {
            timezoneSidId: TIME_ZONE,
            collectionOperationIds: requesterCollectionOperationIds,
            resourceIds: [this.userResource.id]
          }).then(() => {
            return availator.buildScheduledAllocations({
              ignoreDedicatedSiteRule: true
            });
          }).then((result) => {
            console.log('>>> fetchResourceDataForTrade', result);
            let availableDays = (result.possibleAllocations || []).map(possibleAl => {
              const availableDate = possibleAl.job.driveDate;
              const relocatedCOs = this.findMatchedResourceOverrideOfRequester(availableDate, availableDate);
              const requiredExceptions = ['RESOURCE_TIME_CONFLICT'];
              const unavailableReasons = (possibleAl.exceptionLog || []).filter(exception => requiredExceptions.includes(exception.exceptionCode));
              return {
                id: `available-${this.userResource.id}-${availableDate}`,
                start: possibleAl.job.start,
                finish: possibleAl.job.finish,
                startDate: this.dateUtils.dateToStringNative(availableDate),
                endDate: this.dateUtils.dateToStringNative(availableDate),
                reallocatedTo: relocatedCOs?.length ? relocatedCOs[0].collectionOperationName : null,
                isAvailableDay: true,
                resource: this.userResource,
                unavailableReasons,
                isDisabled: unavailableReasons.length > 0
              }
            });
            console.log('>>> availableDays', availableDays);
            return orderBy(availableDays, ["startDate"], ["asc"]);
          })
        }
      })
    }

    const TYPE_FETCH_FUNCTION_MAP = {
      [DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT]: fetchJobAllocations,
      [DRIVE_SHIFT_TRADE_TYPE.ACTIVITY]: fetchGroupActivities,
      [DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY]: fetchAvailableDaysWithEvents
    }
    
    this.showLoading();
    TYPE_FETCH_FUNCTION_MAP[this.model.requestingStaffTradingType]()
    .then((res) => {
      this.listRequestRecords = this.resetRecordClasses(res);
      this.listRequestRecordsMap = keyBy(this.listRequestRecords, "id");

      //reset
      this.model.requestingStaffRecord = null;
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }
  
  fetchStep3() {
    this.showLoading();
    this.enableInfiniteLoading = false;
    Promise.resolve()
    .then(() => {
      if (this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
        return [this.model.requestingStaffRecord.collectionOperationId];
      } 
      else if (this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
        if (!!this.model.requestingStaffRecord.activity.collectionOperationId) {
          return [this.model.requestingStaffRecord.activity.collectionOperationId];
        }
        else {
          let query = new activityQueryModel();
          query.recordIds = [this.model.requestingStaffRecord.activity.id];
          query.subQueryIndicator = sObjectType.ACTIVITY_COLLECTION_OPERATION;

          let activitySvc = new activityService();
          return activitySvc.query(query).then((activities) => {
            return (activities || []).flatMap(activity =>
              (activity.activityCollectionOperations || []).map(aco => aco.biomedCollectionOperationId)
            );
          });
        }
      }
      else if (this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY) {
        let foundResourceOverrides = this.findMatchedResourceOverrideOfRequester(this.model.requestingStaffRecord.startDate, this.model.requestingStaffRecord.endDate);
        return foundResourceOverrides?.length ? [foundResourceOverrides[0].collectionOperationId] : [this.userResource.collectionOperationId];
      } 
      else {
        return [this.userResource.collectionOperationId];
      }
    })
    .then((requestingCollectionOperationIds) => {
      const territoryCOQueryModel = new territoryCollectionOperationQueryModel();
      territoryCOQueryModel.collectionOperationIds = requestingCollectionOperationIds;
      territoryCOQueryModel.startDate = this.dateUtils.dateToStringNative(this.model.requestingStaffRecord.startDate);
      territoryCOQueryModel.endDate = this.dateUtils.dateToStringNative(this.model.requestingStaffRecord.endDate);
      const territoryCOService = new territoryCollectionOperationService();
      return territoryCOService.query(territoryCOQueryModel);
    })
    .then((territoryCollectionOperations) => {
      const arcRegionIds = (territoryCollectionOperations || [])
                            .filter(territoryCollectionOperation => territoryCollectionOperation.regionId)
                            .map(territoryCollectionOperation => territoryCollectionOperation.regionId);
      let jobs = [];
      
      if (this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
        jobs = [this.model.requestingStaffRecord];
      } else if (this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY || this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY) {
        jobs = [{
          id: uniqueId(`temp_job_`),
          start: this.model.requestingStaffRecord.start,
          finish: this.model.requestingStaffRecord.finish,
          driveDate: this.model.requestingStaffRecord.startDate
        }];
      } else {
        return [];
      }

      const availator = slwcAvailator.getInstance({
        mapApis: window.google ? window.google.maps : null
      })
  
      return Promise.resolve()
      .then(() => {
        return availator.fetchResourceDataForTrade(jobs,{
          timezoneSidId: this.timezoneSidId,
          arcRegionIds
        })
      })
      .then(() => {
        return availator.buildScheduledAllocations({
          ignoreDedicatedSiteRule: true
        })
      })
      .then((result) => {
        const requiredExceptions = ['RESOURCE_IS_INACTIVE', 'RESOURCE_PENDING_TERMINATION'];
        let validPossibleAllocations = (result.possibleAllocations || []).filter(posAl => !(posAl.exceptionLog || []).some(exception => requiredExceptions.includes(exception.exceptionCode)));
        
        validPossibleAllocations = validPossibleAllocations.filter(posAl => {
          return posAl.resource?.resourceType === RESOURCE_TYPE.PERSON && posAl.resource?.id !== this.userResource.id;
        });
  
        return validPossibleAllocations.map(posAl => posAl.resource); 
      })
    })
    .then((resources) => {
      this.listResources = resources;
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
    let startDate = this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY ? this.model.requestingStaffRecord.startDate : this.filters.startDate;
    let endDate = this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY ? this.model.requestingStaffRecord.startDate : this.filters.endDate;
    const fetchJobAllocations = () => {
      let query = new jobAllocationQueryModel();
      query.startDate = startDate;
      query.endDate = endDate;
      query.resourceIds = [this.model.tradingStaff.id];
      query.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, JOB_ALLOCATION_STATUS.IN_PROGRESS];
      query.orderBy = 'startDate';
      query.orderAscending = 'asc';

      let service = new jobAllocationService();
      return service.query(query).then((res) => {
        return (res || [])
        .filter(item => item.jobId !== this.model.requestingStaffRecord.jobId)
        .map(item => {
          item.isJobAllocation = true;
          item.recordUrl = '/' + item.id;
          item.rolesString = this.buildRolesString(item);
          return item;
        })
      });
    }

    const fetchGroupActivities = () => {
      let query = new activityResourceQueryModel();
      query.startDate = startDate;
      query.endDate = endDate;
      query.resourceIds = [this.model.tradingStaff.id];
      query.isGroupActivity = true;
      query.orderBy = 'startDate';
      query.orderAscending = 'asc';

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
    const validateDriveShiftTrades = (driveShiftTrades = []) => {
      const recordsToValidate = driveShiftTrades.map(item => {
        let dataSave = {
          id: item.id,
          requestingStaffTradingType: item.requestingStaffTradingType,
          tradingStaffTradingType: this.model.requestingStaffTradingType,
          requestingStaffId: item.requestingStaffId,
          tradingStaffId: this.userResource.id,
        };
        
        if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
          dataSave.tradingStaffJobAllocationId = this.model.requestingStaffRecord.id;
        } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
          dataSave.tradingStaffNCEId = this.model.requestingStaffRecord.activityId;
        } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY) {
          dataSave.tradingStaffTradingAvailableDate = this.model.requestingStaffRecord.startDate;
        }
    
        if(item.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
          dataSave.requestingStaffJobAllocationId = item.requestingStaffJobAllocationId;
        } else if(item.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
          dataSave.requestingStaffNCEId = item.requestingStaffNCEId;
        } else if(item.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY) {
          dataSave.requestingStaffTradingAvailableDate = item.requestingStaffTradingAvailableDate;
        }
        
        return dataSave;
      })
      let service = new driveShiftTradeService();
      return service.validateShiftTrades({
        request: {
          shiftTrades: recordsToValidate
        }
      })
      .then((res) => {
        const shiftTradeValidationResults = res?.returnedData?.shiftTradeValidationResults || [];
        return driveShiftTrades.map((item, index) => {
          const shiftTradeValidationResult = shiftTradeValidationResults[index];
          item.contentions = [];
          item.requesterNeedToAcknowledge = shiftTradeValidationResult?.requestingStaffGuaranteedMinHrsForfeited || shiftTradeValidationResult?.requestingStaffTurnaroundViolation || 
                                            shiftTradeValidationResult?.requestingStaffRelocated || shiftTradeValidationResult?.requestingStaffUnavailableForCO;

          const contentions = (shiftTradeValidationResult?.contentions ||[]).map(item => {
            return {
              ...item,
              message: item.contention
            }
          });
          const hardViolations = contentions.filter(item => item.hardViolation);
          const softViolations = contentions.filter(item => !item.hardViolation);
    
          if(hardViolations.length) {
            item.contentions = hardViolations;
            return item;
          }

          if(softViolations.length) {
            item.contentions = softViolations;
            return item;
          }
  
          return item;
        });
      });
    }

    const fetchDriveShiftTrades = () => {
      let query = new driveShiftQueryModel();
      query.tradingEventStartDate = this.filters.startDate;
      query.tradingEventEndDate = this.filters.endDate;
      query.excludedRequestingStaffIds = [this.userResource.id];
      query.statuses = [DRIVE_SHIFT_TRADE_STATUS.SUBMITTED];
      query.onlyOneSideTrade = true;
      query.excludeAvailableDayOneSideTrade = this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY;

      let service = new driveShiftTradeService();
      return service.query(query)
      .then((res) => {
        return validateDriveShiftTrades(res);
      }).then((res) => {
        return (res || [])
        .map(item => {
          item.isDriveShiftTrade = true;
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
    Promise.resolve()
    .then(() => {
      if(this.isMarketTrade) {
        this.driveShiftTradeFilers = {
          showOnlyAutoApprovalDSTs: false
        };
        return fetchDriveShiftTrades()
      } else {
        return TYPE_FETCH_FUNCTION_MAP[this.model.tradingStaffTradingType]()
      }
    })
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
    let service = new driveShiftTradeService();
    this.errorMessages = [];
    this.preventSubmit = false;
    this.model.contentionAcknowledge = false;
    this.model.requestingStaffGMHAcknowledge = false;
    this.model.requestingStaffTATAcknowledge = false;
    this.model.requesterRelocatedAcknowledge = false;
    this.model.requesterUnavailableForCOAcknowledge = false;
    this.showLoading();
    
    return service.validateShiftTrades({
      request: {
        shiftTrades: [this.buildSaveParams()]
      }
    })
    .then((validateRequestResponse) => {
      let shiftTradeValidationResults = validateRequestResponse?.returnedData?.shiftTradeValidationResults || [];
      let shiftTradeValidationResult = shiftTradeValidationResults.length > 0 ? shiftTradeValidationResults[0] : null;
      this.isTATAcknowledgeRequired = !this.isMarketOneSideTrade && (
        this.isMarketTrade ? shiftTradeValidationResult?.tradingStaffTurnaroundViolation : shiftTradeValidationResult?.requestingStaffTurnaroundViolation
      );
      this.isGMHAcknowledgeRequired = !this.isMarketOneSideTrade && (
        this.isMarketTrade ? shiftTradeValidationResult?.tradingStaffGuaranteedMinHrsForfeited : shiftTradeValidationResult?.requestingStaffGuaranteedMinHrsForfeited
      );
      this.isRelocatedAcknowledgeRequired = !this.isMarketOneSideTrade && (
        this.isMarketTrade ? shiftTradeValidationResult?.tradingStaffRelocated : shiftTradeValidationResult?.requestingStaffRelocated
      );
      this.isUnavailableForCOAcknowledgeRequired = !this.isMarketOneSideTrade && (
        this.isMarketTrade ? shiftTradeValidationResult?.tradingStaffUnavailableForCO : shiftTradeValidationResult?.requestingStaffUnavailableForCO
      );

      let contentions = shiftTradeValidationResult?.contentions || [];
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
      this.isContentionAcknowledgeRequired = !this.isMarketOneSideTrade && this.errorMessages.length;
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

  handleSelectRecord = (event) => {
    const { id } = event.currentTarget.dataset;
    if (this.isStep2) {
      let recordSelected = this.listRequestRecordsMap[id];
      if (recordSelected.isDisabled) {
        return;
      }
      this.listRequestRecords = this.resetRecordClasses(this.listRequestRecords);

      if(this.model.requestingStaffRecord?.id === id) {
        //deselect
        this.model.requestingStaffRecord = null;
        this.model.tradingStaff = null;
        this.model.tradingStaffRecord = null;
        this.listTradeRecords = [...this.listTradeRecords];
        return;
      }

      this.model.tradingStaff = null;
      this.model.tradingStaffRecord = null;
      this.appendClasses(recordSelected, ["selected-item"]);

      this.model.requestingStaffRecord = recordSelected;
      this.listTradeRecords = [...this.listTradeRecords];
    } else {
      this.listTradeRecords = this.resetRecordClasses(this.listTradeRecords);

      if(this.model.tradingStaffRecord?.id === id) {
        //deselect
        this.model.tradingStaffRecord = null;
        this.listTradeRecords = [...this.listTradeRecords];
        return;
      }

      let recordSelected = this.listTradeRecordsMap[id];
      this.appendClasses(recordSelected, ["selected-item"]);
      this.model.tradingStaffRecord = recordSelected || null;
      this.listTradeRecords = [...this.listTradeRecords];
    }
  }

  buildSaveParams() {
    if(!this.model) return null;

    if(this.isMarketTrade && !this.isMarketOneSideTrade) {
      let dataSave = {
        id: this.model.tradingStaffRecord.id,
        tradingStaffTradingType: this.model.requestingStaffTradingType,
        requestingStaffTradingType: this.model.tradingStaffRecord?.requestingStaffTradingType,
        tradingStaffId: this.userResource.id,
        requestingStaffId: this.model.tradingStaffRecord.requestingStaffId,
        contactMethod: this.model.contactMethod,
        tradingStaffTradeReason: this.model.requestingStaffTradeReason,
        tradingStaffNotes: this.model.requestingStaffNotes,
        contentionAcknowledge: !!this.model.contentionAcknowledge,
        tradingStaffTATAcknowledge: !!this.model.requestingStaffTATAcknowledge,
        tradingStaffGMHAcknowledge: !!this.model.requestingStaffGMHAcknowledge,
        traderRelocatedAcknowledge: !!this.model.requesterRelocatedAcknowledge,
        traderUnavailableForCOAcknowledge: !!this.model.requesterUnavailableForCOAcknowledge
      };
      
      if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
        dataSave.tradingStaffJobAllocationId = this.model.requestingStaffRecord.id;
      } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
        dataSave.tradingStaffNCEId = this.model.requestingStaffRecord.activityId;
      } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY) {
        dataSave.tradingStaffTradingAvailableDate = this.model.requestingStaffRecord.startDate;
      }
  
      if(this.model.tradingStaffRecord?.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
        dataSave.requestingStaffJobAllocationId = this.model.tradingStaffRecord?.requestingStaffJobAllocationId;
      } else if(this.model.tradingStaffRecord?.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
        dataSave.requestingStaffNCEId = this.model.tradingStaffRecord?.requestingStaffNCEId;
      } else if(this.model.tradingStaffRecord?.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY) {
        dataSave.requestingStaffTradingAvailableDate = this.model.tradingStaffRecord?.requestingStaffTradingAvailableDate;
      }

      return dataSave;
    } 

    let dataSave = {
      requestingStaffTradingType: this.model.requestingStaffTradingType,
      tradingStaffTradingType: this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.NONE ? '' : this.model.tradingStaffTradingType,
      contactMethod: this.model.contactMethod,
      requestingStaffTradeReason: this.model.requestingStaffTradeReason,
      requestingStaffNotes: this.model.requestingStaffNotes,
      requestingStaffId: this.userResource.id,
      tradingStaffId: this.model.tradingStaff?.id,
      contentionAcknowledge: !!this.model.contentionAcknowledge,
      requestingStaffTATAcknowledge: !!this.model.requestingStaffTATAcknowledge,
      requestingStaffGMHAcknowledge: !!this.model.requestingStaffGMHAcknowledge,
      requesterRelocatedAcknowledge: !!this.model.requesterRelocatedAcknowledge,
      requesterUnavailableForCOAcknowledge: !!this.model.requesterUnavailableForCOAcknowledge
    };
    
    if(this.model.requestingStaffTradingType && this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
      dataSave.requestingStaffJobAllocationId = this.model.requestingStaffRecord.id;
    } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
      dataSave.requestingStaffNCEId = this.model.requestingStaffRecord.activityId;
    } else if(this.model.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY) {
      dataSave.requestingStaffTradingAvailableDate = this.model.requestingStaffRecord.startDate;
    }

    if(this.model.tradingStaffTradingType && this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
      dataSave.tradingStaffJobAllocationId = this.model.tradingStaffRecord?.id;
    } else if(this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
      dataSave.tradingStaffNCEId = this.model.tradingStaffRecord?.activityId;
    } 

    if(this.isMarketOneSideTrade) {
      delete dataSave.contactMethod;
      delete dataSave.tradingStaffTradingType;
      delete dataSave.contentionAcknowledge;
      delete dataSave.requestingStaffTATAcknowledge;
      delete dataSave.requestingStaffGMHAcknowledge;
      delete dataSave.requesterRelocatedAcknowledge;
      delete dataSave.requesterUnavailableForCOAcknowledge;
      delete dataSave.tradingStaffJobAllocationId;
      delete dataSave.tradingStaffNCEId;
      delete dataSave.tradingStaffTradingAvailableDate;

      dataSave.isOneSideTrade = true;
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

      return service.autoProcessRequest({
        request: {
          id: result.returnedData[0].Id,
          ...dataSave
        }
      });
    })
    .then((result) => {
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
    if(this.model.tradingStaff?.id === id) {
      this.listResourcesMap[id]["classes"] = "";
      //deselect
      this.model.tradingStaff = null;
      this.model.tradingStaffRecord = null;
      return;
    }

    this.listResourcesMap[id]["classes"] = "selected-item";
    if (this.model.tradingStaff && this.model.tradingStaff.id) {
      this.listResourcesMap[this.model.tradingStaff.id]["classes"] = "";
    }
    this.model.tradingStaff = this.listResourcesMap[id];
    this.model.tradingStaffRecord = null;
  }

  handleNext() {
    if(this.step === this.ALLSTEP.STEP3.value && this.isMarketTrade) {
      this.step = this.ALLSTEP.STEP5.value;
      this.ALLSTEP[this.mode].function();
      return;
    }

    if(this.step === this.ALLSTEP.STEP4.value) {
      if(this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.NONE) {
        this.model.tradingStaffRecord = {
          tradingType: this.model.tradingStaffTradingType,
          resource: this.model.tradingStaff
        }

        this.step = this.ALLSTEP.STEP6.value;
        this.ALLSTEP[this.mode].function();
        return;
      }
    }

    if (this.step > this.ALLSTEP.length) {
      this.step = 1;
    } else {
      this.step += 1;
    }
    this.ALLSTEP[this.mode].function();
  }

  handlePrev() {
    if(this.step === this.ALLSTEP.STEP6.value) {
      if(this.model.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.NONE && !this.isMarketTrade) {
        this.step = this.ALLSTEP.STEP4.value;
        return;
      }
    }

    if(this.step === this.ALLSTEP.STEP5.value) {
      if(this.isMarketTrade) {
        this.step = this.ALLSTEP.STEP3.value;
        return;
      }
    }

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
      this.listRequestRecords = this.resetRecordClasses(this.listRequestRecords);
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
      this.filters = {...this.filters, startDate: event.detail.startDate, endDate: event.detail.endDate};
      this.ALLSTEP[this.mode].function();
    } else if (eventName === "searchText") {
      this.filters.searchText = slwcUtils.getValueFromEvent(event);
      this.filterResource();
    }
  }
  handleDriveShiftTradeFiltersChanged(event) {
    const eventName = event.target.name;
    this.driveShiftTradeFilers[eventName] = slwcUtils.getValueFromEvent(event);
  }
  isOutOfAvailableDaysTradeWindow(startDate, endDate, tradeWindowDaysNo) {
    let today = DateTime.local().toISODate();
    return this.dateUtils.diffDays(today, startDate) > tradeWindowDaysNo || this.dateUtils.compareDateJS(today, endDate) > 0;
  }
  findMatchedResourceOverrideOfRequester(startDate, endDate) {
    return (this.userResource.resourceOverrides || []).filter(resourceOverride => 
      (!resourceOverride.startDate || this.dateUtils.compareDateJS(resourceOverride.startDate, endDate) <= 0) &&
      (!resourceOverride.endDate || this.dateUtils.compareDateJS(resourceOverride.endDate, startDate) >= 0));
  }
  resetRecordClasses(records) {
    return records.map(record => {
      let classes = [];
      if (record.isDisabled) {
        classes.push("record-disabled");
      }

      record.classes = classes.join(' ');
      return record;
    });
  }
  appendClasses(record, classes) {
    record.classes = [...(record.classes || "").split(' '), ...classes].join(' ');
  }
}