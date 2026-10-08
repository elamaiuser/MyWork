import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { driveQueryModel, driveService, siteCollectionOpQueryModel, siteCollectionOpService, siteFeedbackQueryModel, siteFeedbackService } from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { pick } from 'c/lodash';
import { DRIVE_STATUS } from 'c/slwcConstants';

export default class SlwcApprovalConsoleSiteFeedbackList extends LightningElement {
  COLUMNS = [
    { label: 'Name', sortable: true, sortField: 'name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Site', sortable: true, fieldName: 'siteName', type: 'text', hideDefaultActions: true, wrapText: true },
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

  DRIVE_COLUMNS = [
    {label: 'Drive Name', fieldName: 'recordPageUrl', type: 'url', wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' } },
    {label: 'UFID', fieldName: 'ufid', type: 'text', wrapText: true },
    {label: 'Drive Type', fieldName: 'typeOfDrive', type: 'text', wrapText: true, sortable: true },
    {label: 'Drive Status', fieldName: 'status', type: 'text', wrapText: true, sortable: true },
    {label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, wrapText: true, sortable: true }
  ]

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
    return this.collectionOperationIds && this.collectionOperationIds.length;
  }

  get collectionOperations() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => item.collectionOperation);
  }

  get collectionOperationIds() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => item.collectionOperationId);
  }

  get collectionOperationFirstDay() {
    if (!this.collectionOperations || !this.collectionOperations.length) return;
    return this.collectionOperations[0].workWeekFirstDay;
  }

  get collectionOperationDateRange() {
    const today = DateTime.fromJSDate(new Date()).toISODate();
    return {
      startDate: today,
      endDate: today
    }
  }

  get pageName() {
    return 'schedulingConsole:siteFeedback'
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
        timezone: TIME_ZONE
    });
  }

  fetchData() {
    if(!this.collectionOperationIds.length) {
        return Promise.resolve([]);
    }
    
    let siteCoService = new siteCollectionOpService;
    return siteCoService.getRelatedSiteInfo({collectionOperationIds: this.collectionOperationIds, startDate: this.collectionOperationDateRange.startDate, endDate: this.collectionOperationDateRange.endDate})
    .then(siteCOs => {
      let siteIds = siteCOs.returnedData.map(siteCO => siteCO.sked_Site__c);
      let query = new siteFeedbackQueryModel();
      query.siteIds = siteIds;
      query.statuses = this.filters.statuses;
      query.submissionStartDate = this.filters.startDate;
      query.submissionEndDate = this.filters.endDate;
      query.siteName = this.filters.siteName;
      query.limit = 50;
      query.offset = (this.records || []).length;
      query.orderBy = this.sortOption.sortField || this.sortOption.fieldName;
      query.orderAscending = this.sortOption.sortDirection;

      let service = new siteFeedbackService();

      return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        result.forEach((item) => {
          item.recordUrl = '/' + item.id;
        })
        return result;
      });
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
    }

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
      collectionOperationIds: this.collectionOperationIds
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
      recordId: recordId,
      record: this.records.find(item => item.id === recordId)
    };
  }

  handleCloseRequestDetailModal(event) {
    const saved = event.detail.result;
    if (saved) {
      this.handleSearch();
    }

    this.requestDetailModalData = {}
  }

  fetchAPSApprovalWindowAffectedDrives(selectedSiteFeedBack) {
    const service = new driveService();
    return service.getCustomSettings({ settingKeys: ['rtvAPSApprovalWindow']})
    .then((result) => {
      const rtvAPSApprovalWindow = result.returnedData.rtvAPSApprovalWindow;
      let queryModel = new driveQueryModel();
      queryModel.startDate = selectedSiteFeedBack.effectiveStartDate;
      queryModel.endDate = selectedSiteFeedBack.effectiveEndDate;
      queryModel.locationIds = [selectedSiteFeedBack.siteId];
      queryModel.statuses = [DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.DRAFT, DRIVE_STATUS.HOLD, DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE];
      queryModel.onlyWithinDayAmount = rtvAPSApprovalWindow;
  
      return service.query(queryModel);
    })
    .then((drives) => {
      return drives.filter((drive) => {
        let dayOfWeek = DateTime.fromFormat(drive.driveDate, 'yyyy-MM-dd').toFormat('cccc');
        return selectedSiteFeedBack.daysOfWeek && selectedSiteFeedBack.daysOfWeek.includes(dayOfWeek);
      })
      .map((drive) => {
        return {
          ...drive,
          recordPageUrl: '/' + drive.id
        }
      });
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
}