import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { driveShiftTradeQueryModel, driveShiftTradeService } from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { pick } from 'c/lodash';
import { DRIVE_SHIFT_TRADE_TYPE } from 'c/slwcConstants';

export default class SlwcApprovalConsoleOnCallTradeList extends LightningElement {
  COLUMNS = [
    { label: 'Name', sortable: true, fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'On Call Name', fieldName: 'requestingStaffOnCallUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: { label: { fieldName: 'requestingStaffOnCallName' }, target: '_blank' }, hideDefaultActions: true },
    {
      label: 'Start', fieldName: 'requestingStaffOnCallStart', initialWidth: 160, type: 'date', typeAttributes: {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: TIME_ZONE
      }, cellAttributes: { alignment: 'left' }, hideDefaultActions: true
    },
    {
      label: 'End', fieldName: 'requestingStaffOnCallEnd', initialWidth: 160, type: 'date',
      typeAttributes: {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: TIME_ZONE
      }, cellAttributes: { alignment: 'left' }, hideDefaultActions: true
    },
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

  _collectionOperations = [];
  @api
  get collectionOperations() {
    return this._collectionOperations;
  }
  set collectionOperations(value) {
    this._collectionOperations = value;

    if (this.initialized) {
      this.handleSearch();
    }
  }

  @track showSpinner = false;
  @track timezoneSidId = TIME_ZONE;
  @track filters = {}
  @track enableInfiniteLoading = true;
  @track records = [];
  @track columns = this.COLUMNS;
  @track sortOption = {
    fieldName: 'createdDate',
    sortDirection: 'asc'
  };
  @track requestDetailModalData = {};

  get pageName() {
    return 'schedulingConsole:driveShiftTrade'
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

    }
  }

  renderedCallback() {
    if (!this.initialized) {
      this.initialized = true;
    }
  }

  get isValidQueryModel() {
    return this.collectionOperations && this.collectionOperations.length;
  }

  fetchData() {
    const collectionOperationIds = this.collectionOperations.map(item => item.id);
    if (!collectionOperationIds.length) {
      return Promise.resolve([]);
    }

    let query = new driveShiftTradeQueryModel();
    query.types = [DRIVE_SHIFT_TRADE_TYPE.ON_CALL];
    query.collectionOperationIds = collectionOperationIds;
    query.statuses = this.filters.statuses;
    query.submissionStartDate = this.filters.submissionStartDate;
    query.submissionEndDate = this.filters.submissionEndDate;
    query.onCallStartDate = this.filters.onCallStartDate;
    query.onCallEndDate = this.filters.onCallEndDate;
    query.limit = 20;
    query.offset = (this.records || []).length;
    query.orderBy = this.sortOption.fieldName;
    query.orderAscending = this.sortOption.sortDirection;

    let service = new driveShiftTradeService();

    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        result.forEach((item) => {
          item.recordUrl = '/' + item.id;
          item.requestingStaffOnCallUrl = '/' + item.requestingStaffOnCallId;
          item.requestingStaffOnCallName = item.requestingStaffOnCall.name;
          item.requestingStaffOnCallStart = item.requestingStaffOnCall.start;
          item.requestingStaffOnCallEnd = item.requestingStaffOnCall.finish;
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
      fieldName: column.sortField || column.fieldName,
      sortDirection: sortDirection
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
      collectionOperations: this.collectionOperations
    };

    if (!this.isValidQueryModel) return;

    this.showSpinner = true;
    this.enableInfiniteLoading = true;
    this.records = [];
    this.fetchData()
      .then(result => {
        this.records = result;
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
    slwcUtils.setLastQuery(this.pageName, pick(this.filters, []));
  }

  getLastQuery() {
    let tabQuery = slwcUtils.getLastQuery(this.pageName);
    return tabQuery;
  }
}