import { LightningElement, track, api } from 'lwc';
import { DateTime } from 'c/luxon';
import { sortBy, cloneDeep, findIndex } from 'c/lodash';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { MAX_MIN_DATES_ISO } from 'c/slwcConstants';
import * as slwcDateUtils from 'c/slwcDateUtils';
import {
  collectionOperationService,
  collectionOperationQueryModel,
  collectionOperationStagingLocationService
} from 'c/dataService';

export default class SlwcColOpStagingLocationRelatedList extends LightningElement {
  @api recordId;

  @track records = [];
  @track model = {};
  @track addColOpStagingLocationModal = {};
  @track isDisableRequired = true;
  @track action;
  @track originalData = [];

  _collectionOperationName;
  @api
  get collectionOperationName() {
    return this._collectionOperationName;
  }
  set collectionOperationName(value) {
    this._collectionOperationName = value;
  }

  get relatedListHeader() {
    return `Collection Operation Staging Locations (${this.records.length})`;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: this.timezoneSidId
    })
  }

  get isDataPresent() {
    return this.records.length > 0;
  }

  connectedCallback() {
    this.getCollectionOperationName();
  }

  getCollectionOperationName() {
    let query = new collectionOperationQueryModel();
    query.recordIds = [this.recordId];
    let service = new collectionOperationService();
    service.query(query)
      .then((result) => {
        this.collectionOperationName = result[0].name;
      })
      .catch((error) => {
        console.log(error);
      });
  }

  handleShowDataTable(event) {
    this.records = event.detail.data;
    this.originalData = event.detail.originalData;
  }

  handleCreateCollectionOperationStagingLocation() {
    this.addColOpStagingLocationModal = {
      isOpen: true,
      isDeleteModal: false,
      action: 'create'
    };
  }

  handleCloseColOpStagingLocationModal(event) {
    this.addColOpStagingLocationModal = {
      isOpen: event.detail
    };
  }

  handleDataChangeAfterEditOrDelete = (event) => {
    let deletedRecord = [];
    const editedRecordModel = {
      recordChanged: event.detail.changedRecords,
      modalAction: event.detail.modalAction,
      initialModel: event.detail.initialModel
    };
    this.action = editedRecordModel.modalAction;
    const editedRecordIndex = this.records.findIndex(item => item.startDate === editedRecordModel.initialModel.startDate
      && item.endDate === editedRecordModel.initialModel.endDate
      && item.stagingLocationId === editedRecordModel.initialModel.stagingLocation?.id);
    let tempRecordArray = [...this.records];
    if (editedRecordModel.modalAction === 'edit') {
      tempRecordArray[editedRecordIndex] = { ...editedRecordModel.recordChanged };
    } else if (editedRecordModel.modalAction === 'delete') {
      deletedRecord = tempRecordArray.splice(editedRecordIndex, 1);
    }
    this.records = tempRecordArray;
    this.isDisableRequired = false;
  }

  handleTableDataAfterCreation = (event) => {
    const newRecord = event.detail.newRecordFromModal;
    this.action = event.detail.modalAction;
    this.model = {
      ... newRecord,
      stagingLocationId: newRecord.stagingLocation?.id,
      stagingLocationAddress: newRecord.stagingLocation?.address,
      stagingLocationName: newRecord.stagingLocation?.name,
      stagingLocationRecordUrl: '/' + newRecord.stagingLocation?.id
    };
    let tempRecordArray = [...this.records];
    tempRecordArray.push({... this.model});
    this.records = tempRecordArray;
    this.addColOpStagingLocationModal = {
      isOpen: false
    };
    this.isDisableRequired = false;
  }
  
  handleRefresh() {
    this.isDisableRequired = true;
    this.records = this.originalData;
  }

  handleSaveBtn(event) {
    if (this.validateData(this.records)) {
      this.dispatchEvent(new ShowToastEvent({
        message: this.errorMessage,
        variant: 'error',
        mode: 'dismissable'
      }));
    } else {
      const coslToModify = this.getCoslDataToSave(this.records);
      const coslToDelete = this.getCoslToDelete(this.records);
      const service = new collectionOperationStagingLocationService();
      return Promise.resolve()
        .then(() => {
          if (coslToDelete.length > 0) {
            return service.deleteList(coslToDelete);
          }
        })
        .then(() => {
          if (coslToModify.length > 0) {
            return service.saveList(coslToModify);
          }
        })
        .then(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              message: 'Collection Operation Staging Location changes are applied successfully. Please refresh the page',
              variant: "success",
              mode: "dismissable"
            }));
          this.originalData = this.records;
          this.isDisableRequired = true;
        })
        .catch((error) => this.exceptionHandler(error))
        .finally(() => this.handleRefresh());
    }
  }

  getIndex(tableArray, currentRecord) {
    return findIndex(tableArray, item => item.startDate === currentRecord.startDate
      && item.endDate === currentRecord.endDate
      && item.stagingLocation?.id === currentRecord.stagingLocation?.id) + 1;
  }

  validateData(tempRecordsOnTheTable) {
    const TODAY = DateTime.fromJSDate(new Date()).toISODate();
    const lastIndex = tempRecordsOnTheTable.length;
    let validValidationList = [];
    let hasError = false;
    let index = 0;
    const tableBeforeSorting = cloneDeep(tempRecordsOnTheTable);
    tempRecordsOnTheTable = sortBy(tempRecordsOnTheTable, item => item.startDate);
    validValidationList.push(
      {
        condition: this.action === 'delete' && !tempRecordsOnTheTable.length,
        errorMessage: 'You cannot delete the last remaining reocrd.'
      },
    );
    while (index < lastIndex) {
      const record = tempRecordsOnTheTable[index];
      const hasNext = index + 1 < lastIndex;
      validValidationList.push(
        {
          condition: record.endDate <= record.startDate,
          errorMessage: `Error at row ${this.getIndex(tableBeforeSorting, record)} : End date cannot be prior or equal to start date.`
        },
        {
          condition: record.startDate > TODAY && tempRecordsOnTheTable.length === 1,
          errorMessage: `Error at row ${this.getIndex(tableBeforeSorting, record)} : Start Date must be from today as no other staging location is associated with this collection operation.`
        },
        {
          condition: record.endDate > MAX_MIN_DATES_ISO.MAX_DATE_ISO,
          errorMessage: `Error at row ${this.getIndex(tableBeforeSorting, record)} : End date cannot be after ${MAX_MIN_DATES_ISO.MAX_DATE_ISO}`
        },
        {
          condition: record.startDate < MAX_MIN_DATES_ISO.MIN_DATE_ISO,
          errorMessage: `Error at row ${this.getIndex(tableBeforeSorting, record)} : Start date cannot be before ${MAX_MIN_DATES_ISO.MIN_DATE_ISO}`
        },
        {
          condition: record.endDate < MAX_MIN_DATES_ISO.MAX_DATE_ISO && !hasNext && !tempRecordsOnTheTable.find(record => record.endDate === MAX_MIN_DATES_ISO.MAX_DATE_ISO),
          errorMessage: `Error at row ${this.getIndex(tableBeforeSorting, record)} : ${this.action === 'delete' ? "Existing" : "New"} COSL record(s) must cover till ${MAX_MIN_DATES_ISO.MAX_DATE_ISO}`
        },
        {
          condition: hasNext && (tempRecordsOnTheTable.slice(index + 1).find(item => item.startDate === record.startDate && item.endDate === record.endDate && item.stagingLocation?.id !== record.stagingLocation?.id)),
          errorMessage: `Another COSL covers the same date range. Please adjust the dates accordingly.`
        },
        {
          condition: hasNext && (tempRecordsOnTheTable.slice(index + 1).find(item => item.startDate === record.startDate && item.endDate === record.endDate && item.stagingLocation?.id === record.stagingLocation?.id)),
          errorMessage: `Duplicate entry for staging location : ${record.stagingLocation?.name}`
        },
        {
          condition: hasNext && !(
            tempRecordsOnTheTable.slice(index + 1).find(item => Math.abs(this.dateUtils.diffDays(item.startDate, record.endDate)) === 1 &&
              record.endDate < item.startDate)
          ),
          errorMessage: `COSL period should be continuous and non-overlapping. Please adjust the dates accordingly.`
        });
      index++;
    }

    const validationMatch = validValidationList.find(validation => validation.condition);
    if (validationMatch) {
      hasError = true;
      this.errorMessage = validationMatch.errorMessage;
      return this.errorMessage;
    }
    return hasError;
  }

  getCoslToDelete = (records) => {
    let coslToDelete = [];
    const deletedRecords = this.originalData?.filter(item => !records.find(record => record.id === item.id)) || [];
    for (let i = 0; i < deletedRecords.length; i++) {
      coslToDelete.push(this.formatCoslData(deletedRecords[i]));
    }
    return coslToDelete;
  }

  getCoslDataToSave = (records) => {
    let coslToSave = [];
    for (let i = 0; i < records.length; i++) {
      coslToSave.push(this.formatCoslData(records[i]));
    }
    return coslToSave;
  }

  formatCoslData = (record) => {
    return {
      ...record,
      stagingLocationId: record.stagingLocationId,
      collectionOperationId: this.recordId,
    };
  }

  exceptionHandler = (error) => {
    if (error && error.message) {
      this.dispatchEvent(
        new ShowToastEvent({
          message: error.message,
          variant: "error",
          mode: "dismissable"
        })
      );
    }
  };

}