import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {
  activityService,
  activityQueryModel,
  availabilityService,
  availabilityQueryModel,
  sObjectType
} from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DateTime } from 'c/luxon';
import { pick } from 'c/lodash';

export default class SlwcCallOutsSchedulingConsole extends LightningElement {
  TABS = {
    DRIVE: 'Drive',
    ACTIVITY: 'Activity'
  }

  DRIVE_COLUMNS = [
    { label: 'Drive Date', sortable: true, fieldName: 'callOutForJobAllocationDriveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
    { label: 'Drive Name', sortable: true, sortField: 'callOutForJobAllocationDriveName', fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'callOutForJobAllocationDriveName' }, target: '_blank' } },
    { label: 'Start Time', sortable: true, fieldName: 'callOutForJobAllocationDriveStartTime', type: 'time', hideDefaultActions: true, wrapText: true },
    { label: 'End Time', sortable: true, fieldName: 'callOutForJobAllocationDriveEndTime', type: 'time', hideDefaultActions: true, wrapText: true },
    { label: 'Resource', sortable: true, sortField: 'resourceName', fieldName: 'resourceRecordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'resourceName' }, target: '_blank'} },
    { label: 'Call Out Type', sortable: true, fieldName: 'callOutType', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Call Out Reason Code', sortable: true, fieldName: 'callOutReasonCode', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Status', sortable: true, fieldName: 'status', type: 'text', hideDefaultActions: true, wrapText: true }
  ];

  ACTIVITY_COLUMNS = [
    { label: 'Activity Name', sortable: true, sortField: 'callOutForActivityTitle', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: {label: { fieldName: 'callOutForActivityTitle' }, target: '_blank' }, hideDefaultActions: true },
    { label: 'Type', sortable: true, fieldName: 'callOutForActivityEventType', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Sub-type', sortable: true, fieldName: 'callOutForActivitySubtype', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Start', sortable: true, fieldName: 'start', initialWidth: 160, type: 'date', typeAttributes: {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      timeZone: TIME_ZONE
    }, cellAttributes: { alignment: 'left', class: { fieldName: 'activityDateClass' } }, hideDefaultActions: true },
    { label: 'End', sortable: true, fieldName: 'finish', initialWidth: 160, type: 'date', typeAttributes: {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: TIME_ZONE
    }, cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Resource', sortable: true, sortField: 'resourceName', fieldName: 'resourceRecordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'resourceName' }, target: '_blank'} },
    { label: 'Call Out Type', sortable: true, fieldName: 'callOutType', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Call Out Reason Code', sortable: true, fieldName: 'callOutReasonCode', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Status', sortable: true, fieldName: 'status', type: 'text', hideDefaultActions: true, wrapText: true }
  ];

  initialized = false;

  @wire(CurrentPageReference) pageRef;

  @track includesAdditionalDays = 1;
  @track showSpinner = false;
  @track timezoneSidId = TIME_ZONE;
  @track currentTab = this.TABS.DRIVE;
  @track filters = {
    collectionOperationValues: {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    },
    startDate: null,
    endDate: null
  }
  @track enableInfiniteLoading = true;
  @track records = [];
  @track offset = 0;

  @track sortOption = {
    fieldName: 'createdDate',
    sortDirection: 'asc'
  };

  get collectionOperations() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => item.collectionOperation);
  }

  get territoryKeys() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => `${item.territoryId}:${item.collectionOperationId}`);
  }

  get collectionOperationFirstDay() {
    if (!this.collectionOperations || !this.collectionOperations.length) return;
    return this.collectionOperations[0].workWeekFirstDay;
  }

  get collectionOperationDateRange() {
    if (!this.filters || !this.filters.startDate || !this.filters.endDate) return {
      startDate: null,
      endDate: null
    };

    return {
      startDate: this.filters.startDate,
      endDate: this.filters.endDate
    }
  }

  get columns() {
    if(this.currentTab === this.TABS.DRIVE) return this.DRIVE_COLUMNS;
    return this.ACTIVITY_COLUMNS;
  }
  
  get pageName() {
    return 'schedulingConsole:callOuts'
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  connectedCallback() {
    //init settings
    if (!this.initialized) {
      let lastSearchQuery = this.getLastQuery();
      if (lastSearchQuery) {
        this.filters = {
          ...this.filters,
          ...lastSearchQuery
        };
      }

      if (!this.filters.collectionOperationValues.territoryCollectionOperations) {
        this.filters.collectionOperationValues.territoryCollectionOperations = [];
      }

      if (!this.filters.startDate || !this.filters.endDate) {
        const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
        this.filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), firstDay).toISODate();
        this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
          day: 6
        }).toISODate();
      }
      this.handleSearch();
    }
  }

  renderedCallback() {
    if (!this.initialized) {
      this.initialized = true;
    }
  }

  get isValidQueryModel() {
    return this.territoryKeys && this.territoryKeys.length;
  }

  fetchData() {
    this.offset = (this.records || []).length;
    const territoryKeys = this.territoryKeys;
    if (!territoryKeys.length) {
      return Promise.resolve([]);
    }

    let query;
    let service;
    if(this.currentTab === this.TABS.DRIVE) {
      service = new availabilityService();
      query = new availabilityQueryModel();
      query.callOutForJobAllocation = true;
      query.territoryKeys = territoryKeys;
      query.startDate = this.filters.startDate;
      query.endDate = this.filters.endDate;
      query.limit = 20;
    } else {
      service = new availabilityService();
      query = new availabilityQueryModel();
      query.callOutForActivity = true;
      //query.territoryKeys = territoryKeys;
      query.startDate = this.filters.startDate;
      query.endDate = this.filters.endDate;
    }

    query.offset = this.offset;
    query.orderBy = this.sortOption.sortField;
    query.orderAscending = this.sortOption.sortDirection;

    if (this.filters.statuses && this.filters.statuses.length) {
      query.statuses = this.filters.statuses;
    }

    if (this.filters.callOutTypes && this.filters.callOutTypes.length) {
      query.callOutTypes = this.filters.callOutTypes;
    }

    if (this.filters.callOutReasonCodes && this.filters.callOutReasonCodes.length) {
      query.callOutReasonCodes = this.filters.callOutReasonCodes;
    }

    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        let filteredResult;
    
        if (this.currentTab === this.TABS.ACTIVITY) {
          service = new activityService();
          query = new activityQueryModel();
          query.recordIds = result.map(record => record.callOutForActivityId);
          query.subQueryIndicator = sObjectType.ACTIVITY_COLLECTION_OPERATION
          return service.query(query).then((queryResult) => {
              filteredResult = result
                  .filter((item) => {
                      let isValidActivity = territoryKeys.includes(item.callOutForActivity.territoryKey);
                      if (!isValidActivity) {
                          let activities = queryResult.filter(activity => activity.id === item.callOutForActivityId);
                          isValidActivity = activities.find(activity => 
                              (activity.activityCollectionOperations || []).find(activityCo =>
                                  territoryKeys.includes(activityCo.territoryKey)
                              )
                          );
                      }

                      if (!isValidActivity) return;

                      const record = item.callOutForActivity;
                      item.recordUrl = '/' + record.id;
                      item.resourceRecordUrl = '/' + item.resourceId;
                      return true;
                  }).slice(0, 20);
                  return filteredResult;
          })
      } else {
            filteredResult = result.map((item) => {
                const record = item.callOutForJobAllocation;
                item.recordUrl = '/' + record.driveId;
                item.resourceRecordUrl = '/' + item.resourceId;
                return item;
            });
        }
        return filteredResult;
    })
    .catch((error) => {
        console.log(error);
    });
  }

  handleSortChanged(event) {
    const fieldName = event.detail.fieldName;
    const column = this.columns.find(column => column.fieldName === fieldName);
    const sortDirection = event.detail.sortDirection;

    this.sortOption = {
      fieldName: column.fieldName,
      sortField: column.sortField || column.fieldName,
      sortDirection: sortDirection
    }
    this.handleSearch();
  }

  handleOnChange(event) {
    if (event.type === 'weekdatechange') {
      this.filters = {
        ...this.filters, 
        startDate: event.detail.startDate,
        endDate: event.detail.endDate
      }
      this.handleSearch();
    }
  }

  handleCollectionOperationChanged(event) {
    this.filters.collectionOperationValues = {
      divisions: event.detail.selectedDivisions,
      arcRegions: event.detail.selectedARCRegions,
      districts: event.detail.selectedDistricts,
      territoryCollectionOperations: event.detail.selectedTerritoryCollectionOperations
    }
    this.handleSearch();
  }

  validateFilters() {
    if (this.filters.startDate) {
      const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
      this.filters.startDate = this.dateUtils.startOfWeek(this.filters.startDate, firstDay).toISODate();
      this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
        day: 6
      }).toISODate();
    }
  }

  handleChangeTab(event) {
    this.currentTab = event.target.value;

    this.handleSearch();
  }

  handleSearch(event = {
    detail: {}
  }) {
    this.validateFilters();
    const { filters } = event.detail;
    this.filters = {
        ...this.filters,
        ...filters,
        territoryKeys: this.territoryKeys
    };

    if (!this.isValidQueryModel) return;
    this.showSpinner = true;
    this.enableInfiniteLoading = false;
    this.records = [];
    this.fetchData()
      .then(result => {
        this.records = result;
        this.enableInfiniteLoading = true;
      })
      .finally(() => {
        this.showSpinner = false;
      });
    
    this.setLastQuery();
  }

  handleLoadMoreData(event) {
    //Display a spinner to signal that data is being loaded
    event.target.isLoading = this.records.length === (this.offset + 20);
    if(!event.target.isLoading) return;

    let target = event.target;
    this.fetchData()
      .then((result) => {
        if (!result || result.length == 0) {
          this.enableInfiniteLoading = false;
        }
        else {
          const currentData = this.records;
          const newData = currentData.concat(result);
          this.records = newData;
        }
      })
      .finally(() => {
        target.isLoading = false;
      });
  }

  setLastQuery() {
    slwcUtils.setLastQuery(this.pageName, this.filters);
    slwcUtils.setLastQuery('schedulingConsole', pick(this.filters, ['collectionOperationValues']));
  }

  getLastQuery() {
    let tabQuery = slwcUtils.getLastQuery(this.pageName);
    let schedulingConsoleQuery = slwcUtils.getLastQuery('schedulingConsole');
    let collectionOperationValues =  (schedulingConsoleQuery || {}).collectionOperationValues || {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    };
    if(tabQuery && tabQuery.collectionOperationValues) {
      collectionOperationValues.territoryCollectionOperations = tabQuery.collectionOperationValues.territoryCollectionOperations || [];
    }
    return {
      ...tabQuery,
      collectionOperationValues: collectionOperationValues
    };
  }

  formatTime(time) {
    if (!time) {
        return '';
    }
    return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
  }
}