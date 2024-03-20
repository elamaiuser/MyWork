import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {
  driveChangeRequestQueryModel,
  driveChangeRequestService,
} from 'c/dataService';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { pick, chunk } from 'c/lodash';
import { DRIVE_REQUEST_CHANGE_STATUS } from 'c/slwcConstants';

export default class SlwcSchedulingConsolePendingDriveChangeRequests extends LightningElement {
  @track COLUMNS = [
    { label: 'Name', sortable: true, sortField: 'name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Drive Name', initialWidth: 300, sortable: false, fieldName: 'driveRecordUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: { label: { fieldName: 'driveName' }, target: '_blank' } },
    { label: 'Drive Date', sortable: true, fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
    { label: 'Drive Type', sortable: true, fieldName: 'driveType', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Start Time', sortable: true, fieldName: 'driveStartTime', type: 'time', hideDefaultActions: true, wrapText: true },
    { label: 'End Time', sortable: true, fieldName: 'driveEndTime', type: 'time', hideDefaultActions: true, wrapText: true },
    { label: 'Type', sortable: false, fieldName: 'type', type: 'text', hideDefaultActions: true, wrapText: true },
    {
      label: '', type: 'actionButton', fieldName: 'id', hideDefaultActions: true, initialWidth: 200, typeAttributes: {
        rowActions: [
          {
            name: 'cancelSingle',
            label: 'Cancel',
            variant: 'destructive',
            clickAction: (event) => {
              const record = this.records.find(item => item.id === event.currentTarget.dataset['value']);
              if (!record) return;
              this.handleCancelSingleButton(record);
            }
          },
          {
            name: 'runSingle',
            label: 'Run',
            variant: 'brand',
            clickAction: (event) => {
              const record = this.records.find(item => item.id === event.currentTarget.dataset['value']);
              if (!record) return;
              this.handleRunSingleButton(record);
            }
          }
        ]
      }
    },
  ];

  @track RUN_ALL_RESULT_TABLE_COLUMNS = [
    { label: 'Name', sortable: false, fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Drive Name', initialWidth: 200, sortable: false, fieldName: 'driveRecordUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: { label: { fieldName: 'driveName' }, target: '_blank' } },
    { label: 'Drive Date', sortable: false, fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
    { label: 'Drive Type', sortable: false, fieldName: 'driveType', type: 'text', hideDefaultActions: true, wrapText: true },
    { label: 'Result', initialWidth: 350, sortable: false, fieldName: 'resultMessage', type: 'text', hideDefaultActions: false, wrapText: true },
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
  @track selectedRecordIds = [];
  @track columns = this.COLUMNS;
  @track sortOption = {
    fieldName: 'createdDate',
    sortDirection: 'asc'
  };
  @track generateDriveModalData = {};
  @track runAllModalData = {};
  @track confirmModalData = {};
  @track progressBarData = {};

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
    return 'schedulingConsole:pendingDriveChangeRequest'
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  showProgressBar({
    message,
    processedRecords = 0,
    totalRecords = 0
  }) {
    this.progressBarData = {
      isOpen: true,
      message,
      processedRecords,
      totalRecords
    }
  }

  updateProgressBar({ message, processedRecords }) {
    this.progressBarData = {
      ...this.progressBarData,
      message,
      processedRecords
    }
  }

  hideProgressBar() {
    this.progressBarData = {}
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  fetchData() {
    const territoryKeys = this.territoryKeys;
    if (!territoryKeys.length) {
      return Promise.resolve([]);
    }

    let query = new driveChangeRequestQueryModel();
    query.territoryKeys = territoryKeys;
    query.statuses = [DRIVE_REQUEST_CHANGE_STATUS.PENDING];
    query.types = this.filters.types;
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

        return Promise.all([
          driveChangeRequests
        ]);
      })
      .then(([driveChangeRequests = []]) => {
        driveChangeRequests.forEach((item) => {
          item.recordUrl = '/' + item.id;
          item.driveRecordUrl = '/' + item.driveId;
        });

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

  setLastQuery() {
    slwcUtils.setLastQuery(this.pageName, this.filters);
    slwcUtils.setLastQuery('schedulingConsole', pick(this.filters, ['collectionOperationValues']));
  }

  getLastQuery() {
    let tabQuery = slwcUtils.getLastQuery(this.pageName);
    let schedulingConsoleQuery = slwcUtils.getLastQuery('schedulingConsole');
    let collectionOperationValues = (schedulingConsoleQuery || {}).collectionOperationValues || {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    };
    if (tabQuery && tabQuery.collectionOperationValues) {
      collectionOperationValues.territoryCollectionOperations = tabQuery.collectionOperationValues.territoryCollectionOperations || [];
    }
    return {
      ...tabQuery,
      collectionOperationValues: collectionOperationValues
    }
  }

  handleRowSelection(event) {
    this.selectedRecordIds = (event.detail.selectedRows || []).map(item => item.id);
  }

  handleRunSelectedButton = () => {
    this.showRunAllModal(this.selectedRecordIds);
  }

  handleRunSingleButton = (record) => {
    this.showGenerateDriveModal(record.id);
  }

  handleCancelSelectedButton = () => {
    const recordsToCancel = this.records.filter(item => this.selectedRecordIds?.includes(item.id));
    if(!recordsToCancel.length) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'There are no selected pending drive change requests.',
        variant: 'error',
        mode: 'dismissable',
      }));
      return;
    };

    this.showConfirmModal({
      title: 'Cancel Pending Requests',
      message: 'Are you sure you want to cancel the selected pending Drive Change Requests?',
      onClose: (result) => {
          this.hideConfirmModal();
          if (result) {
            this.showProgressBar({
              message: 'Processing...',
              totalRecords: recordsToCancel.length
            });
            
            const DCR_PER_CHUNK = 10;
            const service = new driveChangeRequestService();
            const promises = chunk(recordsToCancel, DCR_PER_CHUNK).map(dcrChunk => {
              return () => {
                this.updateProgressBar({
                  processedRecords: this.progressBarData.processedRecords + dcrChunk.length
                });

                return service.saveList(dcrChunk.map(dcr => {
                  return {
                    id: dcr.id,
                    status: 'Cancelled'
                  }
                }))
              }
            });

            return Promise.resolve()
            .then(() => {
              return slwcUtils.serial(promises);
            })
            .then(() => {
              this.dispatchEvent(new ShowToastEvent({
                message: 'Cancelled selected Pending Drive Change Requests successfully.',
                variant: 'success',
                mode: 'dismissable'
              }));

              this.handleSearch();
            })
            .finally(() => {
              this.hideProgressBar();
            })
            .catch((error) => {
              this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
              }));
            });
          }
      },
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No'
    });
  }

  handleCancelSingleButton = (record) => {
    this.showConfirmModal({
      title: 'Cancel Pending Request',
      message: 'Are you sure you want to cancel this pending Drive Change Request?',
      onClose: (result) => {
          this.hideConfirmModal();
          if (result) {
            this.showLoading();
            return Promise.resolve()
              .then(() => {            
                let service = new driveChangeRequestService();
                return service.save({
                  id: record.id,
                  status: 'Cancelled'
                })
              })
              .then((result) => {
                if(!result.success) throw result;
                
                this.dispatchEvent(new ShowToastEvent({
                  message: 'Cancelled Pending Drive Change Request successfully.',
                  variant: 'success',
                  mode: 'dismissable',
                }));

                this.handleSearch();
              })
              .catch((error) => {
                this.dispatchEvent(new ShowToastEvent({
                  message: error.message,
                  variant: 'error',
                  mode: 'dismissable',
                }));
              });
          }
      },
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No'
    });
  }

  /* generate drive modal */
  showGenerateDriveModal = (recordId) => {
    this.generateDriveModalData = {
      isOpen: true,
      recordId: recordId
    }
  }

  closeGenerateDriveModal = (event) => {
    const { needToRefreshPage } = event.detail;
    this.generateDriveModalData = {};

    if (needToRefreshPage) {
      this.handleSearch();
    }
  }

  /* run all modal */
  showRunAllModal = (selectedRecordIds = []) => {
    if (!selectedRecordIds.length) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'There are no selected pending drive change requests.',
        variant: 'error',
        mode: 'dismissable',
      }));
      return;
    }

    this.runAllModalData = {
      finishedAll: false,
      records: this.records.filter(item => selectedRecordIds.includes(item.id)),
      processedRecords: [],
      isOpen: true
    }

    this.runNextRecord();
  }

  closeRunAllModal = () => {
    this.runAllModalData = {};
    this.handleSearch();
  }

  runNextRecord = () => {
    if (!this.runAllModalData || !this.runAllModalData.isOpen) return;

    let { records, currentRecordId } = this.runAllModalData;
    let currentRecordIndex = records.findIndex(item => item.id === currentRecordId);
    currentRecordIndex = currentRecordIndex < 0 ? 0 : currentRecordIndex + 1;
    if (currentRecordIndex > records.length - 1) {
      //no more record to run
      this.runAllModalData.currentRecordId = null;
      this.runAllModalData.currentRecord = null;
      this.runAllModalData.finishedAll = true;
      return;
    }

    this.runAllModalData.currentRecordId = null;
    setTimeout(() => {
      this.runAllModalData.currentRecordId = records[currentRecordIndex].id;
      this.runAllModalData.currentRecord = records[currentRecordIndex];
    });
  }

  afterFinishGenerateDriveModalHook = (event) => {
    const { recordId, result, resultMessage } = event.detail; //recordId was modified in generateDriveModal component so cannot use it here
    const { currentRecordId, records } = this.runAllModalData;
    let record = records.find(item => item.id === currentRecordId);
    this.runAllModalData.processedRecords.push({
      ...record,
      resultMessage: resultMessage
    });

    Promise.resolve()
      .then(() => {
        this.runNextRecord();
      })
  }

  /** Confirm Modal **/
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {...confirmModalData,
      isOpen: true
    }
  }

  hideConfirmModal() {
    this.confirmModalData = {};
  }
}