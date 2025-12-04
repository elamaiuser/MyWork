import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {
  driveQueryModel,
  driveService,
  userService,
  approvalService,
  debugLogService
} from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DRIVE_APPROVAL_STATUS } from 'c/slwcConstants';
import { DateTime } from 'c/luxon';
import { pick } from 'c/lodash';
import { DriveHelper } from 'c/slwcDriveGenerator';

export default class SlwcApprovalConsolePendingActionDriveList extends LightningElement {
  COLUMNS = [
    { label: 'Drive Date', sortable: true, fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
    { label: 'Drive Name', sortable: true, sortField: 'name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Pending Action', sortable: false, fieldName: 'pendingAction', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Pending Action Reason Code', sortable: false, fieldName: 'pendingActionReasonCode', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Start Time', sortable: true, fieldName: 'startTimeStr', sortField: 'startTime', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'End Time', sortable: true, fieldName: 'endTimeStr', sortField: 'endTime', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: '# of Staff Requested', sortable: true, fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '# of Staff Scheduled', sortable: false, fieldName: 'staffAllocated', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Vehicle Types', sortable: true, fieldName: 'vehicleTypes', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: '# of Machines Requested', sortable: true, fieldName: 'totalEquipmentRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '# of Machines Allocated', sortable: true, fieldName: 'equipmentAllocated', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Projected Procedures', sortable: true, fieldName: 'totalProceduresProjected', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Projected Products', sortable: true, fieldName: 'totalProductsProjected', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    // { label: 'Planned Productivity', sortable: true, fieldName: 'driveProductivityPlanned', type: 'plannedProductivity', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Designated Approver', sortable: true, fieldName: 'designatedApproverName', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Approval Status', sortable: true, fieldName: 'approvalStatus', type: 'text', hideDefaultActions: true, wrapText: true },
    {
      label: '', type: 'actionButton', fieldName: 'id', hideDefaultActions: true, initialWidth: 100, typeAttributes: {
        rowActions: [
          {
            name: 'details',
            label: 'Details',
            variant: 'base',
            clickAction: (event) => {
              this.handleShowRequestDetailModal(event.currentTarget.dataset['value'], true);
            }
          }
        ]
      }
    } 
  ];

  initialized = false;

  @wire(CurrentPageReference) pageRef;

  @track showSpinner = false;
  @track showDetailsSpinner = false;
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
  @track allowRequestDRDFeedback = false;
  @track confirmModalData = {};

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
    return 'schedulingConsole:pendingActionDrive'
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
        timezone: TIME_ZONE
    });
  }

  renderedCallback() {
    if (!this.initialized) {
      this.initialized = true;
    }
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
          day: 42
        }).toISODate();
      }
    }
  }

  exceptionHandler = (error) => {
    new debugLogService().captureDebugLog(error);
    this.dispatchEvent(new ShowToastEvent({
      message: error.message,
      variant: 'error',
      mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  checkToAllowRequestDRDFeedback(loginUser, record, canApproveReject) {
    const driveHelper = new DriveHelper();
    const isAPSUser = driveHelper.isAPSUser(loginUser);
    this.allowRequestDRDFeedback = canApproveReject && (record.approvalStatus === DRIVE_APPROVAL_STATUS.WAITING_FOR_APS_APPROVAL || record.approvalStatus === DRIVE_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL);
  }

  fetchData() {
    const territoryKeys = this.territoryKeys;
    if (!territoryKeys.length || !this.filters.approvalStatuses || !this.filters.approvalStatuses.length) {
      return Promise.resolve([]);
    }

    let query = new driveQueryModel();
    query.territoryKeys = territoryKeys;
    query.approvalStatuses = this.filters.approvalStatuses;
    query.eventTypes = this.filters.driveTypes;
    query.pendingActions = this.filters.pendingActions;
    query.startDate = this.filters.startDate;
    query.endDate = this.filters.endDate;
    query.limit = 20;
    query.offset = (this.records || []).length;
    query.orderBy = this.sortOption.sortField || this.sortOption.fieldName;
    query.orderAscending = this.sortOption.sortDirection;
    query.accountManagerPortfolioIds = (this.filters.accountManagerPortfolios || []).map(item => { return item.id });
    query.districtManagerPortfolioIds = (this.filters.districtManagerPortfolios || []).map(item => { return item.id });

    let service = new driveService();

    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        result.forEach((item) => {
          item.recordUrl = '/' + item.id;
          item.startTimeStr = this.formatTime(item.startTime);
          item.endTimeStr = this.formatTime(item.endTime);
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

    this.showLoading();
    this.enableInfiniteLoading = false;
    this.records = [];
    this.fetchData()
      .then(result => {
        this.records = result;
        this.enableInfiniteLoading = true;
      })
      .finally(() => {
        this.hideLoading();
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

  handleShowRequestDetailModal(recordId, resetData = false) {
    this.showDetailsSpinner = true;
    let _userService = new userService();
    let _approvalService = new approvalService();
    if(resetData) {
      this.requestDetailModalData = {};
    }
    Promise.all([
      _userService.getLoginUser(),
      _approvalService.canApprove({recordId: recordId})
    ])
    .then(([getLoginUserResult, canApproveResult]) => {
      const record = this.records.find(item => item.id === recordId);
      this.requestDetailModalData = {
        isOpen: true,
        recordId: recordId,
        record
      };

      this.checkToAllowRequestDRDFeedback(getLoginUserResult.returnedData, record, !!canApproveResult.returnedData);
    })
    .catch(e => this.exceptionHandler(e))
    .finally(() => this.showDetailsSpinner = false)
  }

  handleCloseRequestDetailModal(event) {
    const saved = event.detail.result;
    if (saved) {
      this.handleSearch();
    }

    this.requestDetailModalData = {}
  }

  handleRequestDRDFeedback() {
    this.confirmModalData = {
      isOpen: true,
      title: 'Request DRD Feedback',
      message: 'Are you sure to request DRD Feedback?',
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No',
      onClose: (result) => {
        this.closeConfirmModal();
        if (result) {
          let newApprovalStatus = null;
          if(this.requestDetailModalData.record.approvalStatus === DRIVE_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL) {
            newApprovalStatus = DRIVE_APPROVAL_STATUS.DM_WAITING_FOR_DRD_FEEDBACK;
          } else if(this.requestDetailModalData.record.approvalStatus === DRIVE_APPROVAL_STATUS.WAITING_FOR_APS_APPROVAL) {
            newApprovalStatus = DRIVE_APPROVAL_STATUS.APS_WAITING_FOR_DRD_FEEDBACK;
          }
          let service = new driveService();
          this.showDetailsSpinner = true;
          service.save({ 
            id: this.requestDetailModalData.record.id, 
            approvalStatus: newApprovalStatus
           })
          .then((result) => {
            if(!result.success) throw result;
            this.closeConfirmModal();
            this.requestDetailModalData.record.approvalStatus = newApprovalStatus;
          })
          .catch((error) => {
            this.exceptionHandler(error);
          })
          .finally(() => {
              this.showDetailsSpinner = false;
          });
        }
      }
    };
  }

  /** Confirm Modal **/
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {
      ...confirmModalData,
      isOpen: true,
      confirmBtnLabel: confirmModalData.confirmBtnLabel || 'Yes',
      cancelBtnLabel: confirmModalData.cancelBtnLabel || 'No',
    }
  }

  closeConfirmModal() {
    this.confirmModalData = {};
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