import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {
  approvalService,
  driveChangeRequestQueryModel,
  driveChangeRequestService,
} from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { pick } from 'c/lodash';
import { DRIVE_CHANGE_REQUEST_TYPE } from 'c/slwcConstants';

export default class SlwcApprovalConsoleDriveChangeRequestList extends LightningElement {
  COLUMNS = [
    { label: 'Name', sortable: true, sortField: 'name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Drive Name', sortable: false, fieldName: 'driveRecordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'driveName' }, target: '_blank' } },
    { label: 'Drive Date', sortable: true, fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
    { label: 'Drive Type', sortable: true, fieldName: 'driveType', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Drive Contention', sortable: false, fieldName: 'driveContention', type: 'text', wrapText: true },
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
    {
      label: 'Last Modified Date', sortable: true, fieldName: 'lastModifiedDate', type: 'date', hideDefaultActions: true, typeAttributes: {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: TIME_ZONE
      }
    },
    { label: 'Assigned To', sortable: false, fieldName: 'assignedTo', type: 'text', hideDefaultActions: true, wrapText: true },
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

      if (!this.filters.startDate || !this.filters.endDate) {
        const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
        this.filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), firstDay).toISODate();
        this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
          day: 42
        }).toISODate();
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
      startDate: this.filters.startDate,
      endDate: this.filters.endDate
    }
  }

  get todayIso() {
    return DateTime.fromJSDate(new Date()).toISODate();
  }

  get pageName() {
    return 'schedulingConsole:driveChangeRequest'
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
        timezone: TIME_ZONE
    });
  }

  fetchData() {
    const territoryKeys = this.territoryKeys;
    if (!territoryKeys.length) {
      return Promise.resolve([]);
    }

    let query = new driveChangeRequestQueryModel();
    query.territoryKeys = territoryKeys;
    query.statuses = this.filters.statuses;
    query.driveContentions = this.filters.driveContentions;
    query.driveTypes = this.filters.driveTypes;
    query.driveStartDate = this.filters.startDate;
    query.driveEndDate = this.filters.endDate;
    query.submissionStartDate = this.filters.submissionStartDate;
    query.submissionEndDate = this.filters.submissionEndDate;
    query.limit = 20;
    query.offset = (this.records || []).length;
    query.orderBy = this.sortOption.sortField || this.sortOption.fieldName;
    query.orderAscending = this.sortOption.sortDirection;

    let service = new driveChangeRequestService();

    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((driveChangeRequests) => {
        if (!driveChangeRequests || !driveChangeRequests.length) return [[]];
        
        let approvalSvc = new approvalService();
        return Promise.all([
          driveChangeRequests,
          approvalSvc.getCurrentApprovalData({request: {
            recordIds: driveChangeRequests.map(item => item.id)
          }})
        ]);
      })
      .then(([driveChangeRequests = [], getCurrentApprovalDataResult]) => {
        driveChangeRequests.forEach((item) => {
          item.recordUrl = '/' + item.id;
          item.driveRecordUrl = '/' + item.driveId;
        });

        if (getCurrentApprovalDataResult && getCurrentApprovalDataResult.returnedData) {
          let approvalData = getCurrentApprovalDataResult.returnedData || [];
          approvalData.forEach((item) => {
            let driveChangeRequest = driveChangeRequests.find(dcr => dcr.id === item.recordId);
            if (driveChangeRequest) {
              driveChangeRequest.assignedTo = item.assignedTo;
            }
          });
        }

        return driveChangeRequests;
      })
      .catch((error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
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
    };

    this.handleSearch();
  }

  handleOnChange(event) {
    if (event.type === 'daterangechange') {
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
    this.requestDetailModalData = {
      isOpen: true,
      recordId: recordId
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
    }
  }
}