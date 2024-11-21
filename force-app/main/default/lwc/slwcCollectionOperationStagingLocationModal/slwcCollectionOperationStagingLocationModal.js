import { LightningElement, track, api } from 'lwc';
import { getValueFromEvent } from "c/slwcUtils";
import { cloneDeep } from 'c/lodash';
import { DateTime } from 'c/luxon';
import * as slwcDateUtils from 'c/slwcDateUtils';
import {
  collectionOperationService,
  collectionOperationQueryModel,
  collectionOperationStagingLocationService,
  collectionOperationStagingLocationQueryModel
} from 'c/dataService';
import TIME_ZONE from "@salesforce/i18n/timeZone";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {MAX_MIN_DATES_ISO} from 'c/slwcConstants';

export default class SlwcCollectionOperationStagingLocationModal extends LightningElement {
  @api recordId;

  @track action;
  @track records = [];
  @track originalData = [];
  @track isOpen = false;
  @track isDisableNotRequired = false;
  @track timezoneSidId = TIME_ZONE;
  @track errorMessage;
  @track initialModel;
  @track collectionOperationName;
  @track model = {};

  resetModel() {
    this.model = {
      id: null,
      stagingLocation: null,
      collectionOperation: this.recordId,
      startDate: null,
      endDate: null
    };
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: this.timezoneSidId
    })
  }

  get columns() {
    let columns = [];
    columns.push({ label: 'Staging Location', sortable: true, fieldName: 'stagingLocationRecordUrl', type: 'url', typeAttributes: { label: { fieldName: 'stagingLocationName' }, target: '_blank' }, hideDefaultActions: true });
    columns.push({ label: 'Staging Location Address', sortable: true, fieldName: 'stagingLocationAddress', type: 'text', hideDefaultActions: true });
    columns.push({ label: 'Start Date', sortable: true, fieldName: 'startDate', type: 'date-local', typeAttributes: { day: "numeric", month: "numeric", year: "numeric" }, hideDefaultActions: true });
    columns.push({ label: 'End Date', sortable: true, fieldName: 'endDate', type: 'date-local', typeAttributes: { day: "numeric", month: "numeric", year: "numeric" }, hideDefaultActions: true });

    let rowActions = [];
    rowActions.push({ label: 'Edit', name: 'edit' });
    rowActions.push({ label: 'Delete', name: 'delete' });
    columns.push({
      type: 'action', fieldName: 'key', typeAttributes: { rowActions: rowActions }
    });
    return columns;
  }

  handleRowActions(event) {
    let actionName = event.detail.action.name;
    let record = { ...event.detail.row };

    switch (actionName) {
      case 'edit':
        this.handleEditBtn(record);
        break;
      case 'delete':
        this.handleDeleteBtn(record);
        break;
    }
  }

  handleOnChange(event) {
    event.stopPropagation();

    if (event.detail && event.detail.selection) {
      this.model[event.currentTarget.name] = event.detail.selection;
    } else {
      let value = getValueFromEvent(event);
      this.model[event.currentTarget.name] = value;
    }
  }

  get relatedListHeader() {
    return `Collection Operation Staging Locations (${this.records.length})`;
  }

  get modalPopUpHeader() {
    switch (this.action) {
      case "create":
        return "New Collection Operation Staging Location";
      case "edit":
        return "Edit Collection Operation Staging Location";
      case "delete":
        return "Delete Collection Operation Staging Location";
    }
  }

  get isDeleteModal() {
    return this.action === 'delete';
  }

  get isReadOnlyData() {
    return this.action === 'edit';
  }

  get disableButton() {
    return this.isDisableNotRequired;
  }

  async handleRefresh() {
    await this.init();
    this.isDisableNotRequired = false;
  }

  handleNewBtn() {
    this.action = 'create';
    this.isOpen = true;
    this.resetModel();
  }

  handleCancelBtn() {
    this.isOpen = false;
  }

  handleEditBtn(event) {
    this.action = 'edit';
    this.isOpen = true;

    this.model = {
      id: event.id,
      stagingLocation: event.stagingLocation,
      collectionOperation: this.recordId,
      startDate: event.startDate,
      endDate: event.endDate,
    };
    this.initialModel = cloneDeep(this.model);
  }

  handleDeleteBtn(event) {
    this.action = 'delete';
    this.isOpen = true;

    this.model = {
      id: event.id,
      stagingLocation: event.stagingLocation,
      collectionOperation: this.recordId,
      startDate: event.startDate,
      endDate: event.endDate,
    };
  }

  formatCoslData(record) {
    return {
      ...record,
      stagingLocationId: record.stagingLocationId,
      collectionOperationId: this.recordId,
    };
  }

  showTemporaryDataBeforeValidation() {
    
    let editedRecordIndex = this.records.findIndex(item => item.id === this.model.id);
    let deletedRecord=[];
    if (this.action === 'edit') {
      this.records[editedRecordIndex] = { ...this.records[editedRecordIndex], ...this.model };
    } else if (this.action === 'delete') {
      deletedRecord = this.records.splice(editedRecordIndex, 1);
    } else {
      this.records.push({
        ...this.model,
        stagingLocationId: this.model.stagingLocation?.id,
        stagingLocationAddress: this.model.stagingLocation?.address,
        stagingLocationName: this.model.stagingLocation?.name,
        stagingLocationRecordUrl: '/' + this.model.stagingLocationId
      });
    }
    this.records = [...this.records];
    this.isDisableNotRequired = false;
    this.handleCancelBtn();
  }

  handleConfirmButton() {
    this.isOpen = true;
  }

  handleSaveBtn() {
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
        .then((result) => {
          if (!result || !result.success) {
            throw result;
          }

          this.dispatchEvent(
            new ShowToastEvent({
              message: 'Collection Operation Staging Location changes are applied successfully.',
              variant: "success",
              mode: "dismissable"
            }));
          this.handleCancelBtn();
          this.isDisableNotRequired=false;
        })
        .catch((error) => this.exceptionHandler(error))
        .finally(() => this.handleCancelBtn());
    }
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
    return this.collectionOperationName;
  }

  connectedCallback() {
    this.init();
  }

  init() {
    this.getCollectionOperationName();

    let service = new collectionOperationStagingLocationService();
    let query = new collectionOperationStagingLocationQueryModel();
    query.collectionOperationIds = [this.recordId];
    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        result.forEach((item) => {
          item.stagingLocationRecordUrl = '/' + item.stagingLocationId;
        })
        this.records = result;
        this.originalData = cloneDeep(this.records);
      })
      .catch((error) => {
        console.log(error);
      });
  }

  validateData(tempRecordsOnTheTable) {
    const TODAY = DateTime.fromJSDate(new Date()).toISODate();
    const validValidations = [];
    let hasError = false;
    validValidations.push(
      {
        condition: this.action === 'delete' && !tempRecordsOnTheTable.length,
        errorMessage: 'You cannot delete the last remaining reocrd.'
      },
    );
    let index = 0;
    const lastIndex = tempRecordsOnTheTable.length;
    while (index < lastIndex) {
      let record = tempRecordsOnTheTable[index];
      let hasNext = index + 1 < lastIndex;
      validValidations.push(
        {
          condition: record.endDate <= record.startDate,
          errorMessage: 'End date cannot be prior or equal to start date'
        },
        {
          condition: record.startDate > TODAY && tempRecordsOnTheTable.length === 1,
          errorMessage: 'Start Date must be from today as no other staging location is associated with this collection operation'
        },
        {
          condition: record.endDate > MAX_MIN_DATES_ISO.MAX_DATE_ISO,
          errorMessage: `End date cannot be after ${MAX_MIN_DATES_ISO.MAX_DATE_ISO}`
        },
        {
          condition: record.startDate < MAX_MIN_DATES_ISO.MIN_DATE_ISO,
          errorMessage: `Start date cannot be before ${MAX_MIN_DATES_ISO.MIN_DATE_ISO}`
        },
        {
          condition: hasNext &&
            tempRecordsOnTheTable[index].stagingLocationId === tempRecordsOnTheTable[index + 1].stagingLocationId
            && tempRecordsOnTheTable[index].endDate === tempRecordsOnTheTable[index + 1].endDate
            && tempRecordsOnTheTable[index].startDate === tempRecordsOnTheTable[index + 1].startDate,
          errorMessage: 'This staging location is already associated with the same dates. Try to edit instead!'
        },
        {
          condition: record.endDate < MAX_MIN_DATES_ISO.MAX_DATE_ISO && !hasNext,
          errorMessage: `${this.action === 'delete' ? "Existing" : "New"} COSL record(s) must cover till ${MAX_MIN_DATES_ISO.MAX_DATE_ISO}.`
        },
        {
          condition: hasNext && Math.abs(this.dateUtils.diffDays(tempRecordsOnTheTable[index + 1].startDate, record.endDate)) != 1,
          errorMessage: `COSL period should be continuous and non-overlapping. Please adjust the dates accordingly`
        },
        {
          condition: hasNext && (record.startDate === tempRecordsOnTheTable[index + 1].startDate || record.endDate === tempRecordsOnTheTable[index + 1].endDate),
          errorMessage: `Existing COSL record covers the same start date/end date. Please adjust the dates accordingly`
        });
      index++;
    }

    const validationMatch = validValidations.find(validation => validation.condition);
    if (validationMatch) {
      hasError = true;
      this.errorMessage = validationMatch.errorMessage;
      return this.errorMessage;
    }
    return hasError;
  }

  getCoslToDelete(records) {
    let coslToDelete = [];
    let deletedRecords = this.originalData.filter(item => !records.find(record => record.id === item.id));
    for (let i = 0; i < deletedRecords.length; i++) {
      coslToDelete.push(this.formatCoslData(deletedRecords[i]));
    }
    return coslToDelete;
  }

  getCoslDataToSave(records) {
    let coslToSave = [];
    for (let i = 0; i < records.length; i++) {
      coslToSave.push(this.formatCoslData(records[i]));
    }
    return coslToSave;
  }

  exceptionHandler = (error) => {
    console.log(error);
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