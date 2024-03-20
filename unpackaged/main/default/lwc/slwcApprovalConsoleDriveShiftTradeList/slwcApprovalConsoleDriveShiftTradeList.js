import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { driveShiftTradeQueryModel, driveShiftTradeService } from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { pick } from 'c/lodash';
import { DRIVE_SHIFT_TRADE_TYPE } from 'c/slwcConstants';

export default class SlwcApprovalConsoleDriveShiftTradeList extends LightningElement {
  COLUMNS = [
    { label: 'Name', sortable: true, sortField: 'name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Requesting Staff', sortable: true, fieldName: 'requestingStaffName', type: 'text', hideDefaultActions: true, wrapText: true, },
    { label: 'Requesting Staff Trading Type', sortable: true, fieldName: 'requestingStaffTradingType', type: 'text', hideDefaultActions: true, wrapText: true, },
    { label: 'Requesting Staff Record', sortable: false, fieldName: 'requestingStaffRecordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'requestingStaffRecordName' }, target: '_blank' } },
    { label: 'Trading Staff', sortable: true, fieldName: 'tradingStaffName', type: 'text', hideDefaultActions: true, wrapText: true, },
    { label: 'Trading Staff Trading Type', sortable: true, fieldName: 'tradingStaffTradingType', type: 'text', hideDefaultActions: true, wrapText: true, },
    { label: 'Trading Staff Record', sortable: false, fieldName: 'tradingStaffRecordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'tradingStaffRecordName' }, target: '_blank' } },
    { label: 'Submitted By', sortable: true, fieldName: 'createdByName', type: 'text', hideDefaultActions: true, wrapText: true },
    {
      label: 'Submission Date', sortable: true, fieldName: 'createdDate', type: 'date', hideDefaultActions: true, typeAttributes: {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: TIME_ZONE
      }
    },
    { label: 'Designated Approver', sortable: true, fieldName: 'designatedApproverName', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Approval Status', sortable: true, fieldName: 'status', type: 'text', hideDefaultActions: true, wrapText: true },
    {
      label: '', type: 'actionButton', fieldName: 'id', hideDefaultActions: true, initialWidth: 100, typeAttributes: {
        rowActions: [
          {
            name: 'details',
            label: 'Details',
            variant: 'base',
            clickAction: (event) => {
              this.handleShowRequestDetailModal(event.currentTarget.dataset['value']);
            }
          }
        ]
      }
    },
  ];

  initialized = false;

  @wire(CurrentPageReference) pageRef;

  @track showSpinner = false;
  @track timezoneSidId = TIME_ZONE;
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
  @track columns = this.COLUMNS;
  @track sortOption = {
    fieldName: 'createdDate',
    sortDirection: 'asc'
  };
  @track requestDetailModalData = {};

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
    return {
      startDate: this.todayIso,
      endDate: this.todayIso
    }
  }

  get pageName() {
    return 'schedulingConsole:driveShiftTrade'
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
        timezone: TIME_ZONE
    });
  }

  get todayIso() {
    return DateTime.fromJSDate(new Date()).toISODate();
  }

  fetchData() {
    const territoryKeys = this.territoryKeys;
    if (!territoryKeys.length) {
      return Promise.resolve([]);
    }

    let query = new driveShiftTradeQueryModel();
    query.territoryKeys = territoryKeys;
    query.statuses = this.filters.statuses;
    // query.driveTypes = this.filters.driveTypes;
    query.tradingEventStartDate = this.todayIso;
    query.tradingEventEndDate = '9999-01-01';
    // query.driveStartDate = this.filters.driveStartDate;
    // query.driveEndDate = this.filters.driveEndDate;
    query.limit = 20;
    query.offset = (this.records || []).length;
    query.orderBy = this.sortOption.sortField || this.sortOption.fieldName;
    query.orderAscending = this.sortOption.sortDirection;

    let service = new driveShiftTradeService();

    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        result.forEach((item) => {
          item.recordUrl = '/' + item.id;
          item.requestingStaffRecord = null;
          if(item.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
            item.requestingStaffRecord = {
              id: item.requestingStaffDriveId,
              name: item.requestingStaffDriveName
            }
          } else if(item.requestingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
            item.requestingStaffRecord = item.requestingStaffNCE;
          }

          if(item.requestingStaffRecord) {
            item.requestingStaffRecordUrl = '/' + item.requestingStaffRecord.id;
            item.requestingStaffRecordName = item.requestingStaffRecord.activityTitle || item.requestingStaffRecord.name;
          }

          item.tradingStaffRecord = null;
          if(item.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.DRIVE_SHIFT) {
            item.tradingStaffRecord = {
              id: item.tradingStaffDriveId,
              name: item.tradingStaffDriveName
            }
          } else if(item.tradingStaffTradingType === DRIVE_SHIFT_TRADE_TYPE.ACTIVITY) {
            item.tradingStaffRecord = item.tradingStaffNCE;
          } 
          if(item.tradingStaffRecord) {
            item.tradingStaffRecordUrl = '/' + item.tradingStaffRecord.id;
            item.tradingStaffRecordName = item.tradingStaffRecord.name;
          }
        })
        return result;
      })
      .catch((error) => {
        console.log(error);
      });
  }

  handleSortChanged(event) {
    const fieldName = event.detail.fieldName;
    const column = this.COLUMNS.find(column => column.fieldName === fieldName);
    const sortDirection = event.detail.sortDirection;

    this.sortOption = {
      fieldName: column.fieldName,
      sortField: column.sortField,
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

  handleSearch(event = {
    detail: {}
  }) {
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
    event.target.isLoading = true;

    let target = event.target;
    this.fetchData()
      .then((result) => {
        if (result.length == 0) {
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

  handleShowRequestDetailModal(recordId) {
    let record = this.records.find(item => item.id === recordId);
    this.requestDetailModalData = {
      isOpen: true,
      recordId: recordId,
      record: record
    };
  }

  handleCloseRequestDetailModal(event) {
    const saved = event.detail.result;
    if (saved) {
      this.handleSearch();
    }

    this.requestDetailModalData = {}
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
}