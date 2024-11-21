import { LightningElement, track, api } from 'lwc';
import { cloneDeep } from 'c/lodash';
import {
  collectionOperationStagingLocationService,
  collectionOperationStagingLocationQueryModel,
  collectionOperationService,
  collectionOperationQueryModel
} from 'c/dataService';

export default class SlwcCollectionOperationStagingLocationTable extends LightningElement {
  @api recordId;
  @api records = [];
  @api originalData = [];
  @api isDisableRequired;
  @api isDataPresent;

  @track collectionOperationName;
  @track model = {};
  @track initialModel = {};
  @track addColOpStagingLocationModal = {};
 
  get columns() {
    let columns = [];
    columns.push({ label: 'Staging Location Name', sortable: false, fieldName: 'stagingLocationRecordUrl', type: 'url', typeAttributes: { label: { fieldName: 'stagingLocationName' }, target: '_blank' }, hideDefaultActions: true });
    columns.push({ label: 'Staging Location Address', sortable: false, fieldName: 'stagingLocationAddress', type: 'text', hideDefaultActions: true });
    columns.push({ label: 'Start Date', sortable: false, fieldName: 'startDate', type: 'date-local', typeAttributes: { day: "numeric", month: "numeric", year: "numeric" }, hideDefaultActions: true });
    columns.push({ label: 'End Date', sortable: false, fieldName: 'endDate', type: 'date-local', typeAttributes: { day: "numeric", month: "numeric", year: "numeric" }, hideDefaultActions: true });

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

  handleEditBtn(event) {
    this.setModalOperationAndModelData({
      action : 'edit',
      event : event,
      isDeleteModal : false
    });
  }

  handleDeleteBtn(event) {
    this.setModalOperationAndModelData({
      action : 'delete',
      event : event,
      isDeleteModal : true
    });
  }

  setModalOperationAndModelData = ({
    action,
    event,
    isDeleteModal = false
  } = {}) => {

    this.addColOpStagingLocationModal = {
      isOpen: true,
      isDeleteModal: isDeleteModal,
      action: action
    };

    this.model = {
      id: event.id,
      stagingLocation: event.stagingLocation,
      collectionOperation: this.recordId,
      startDate: event.startDate,
      endDate: event.endDate,
    };
    this.initialModel = cloneDeep(this.model);
  }

  connectedCallback() {
    this.init();
  }

  init() {
    let service = new collectionOperationStagingLocationService();
    let query = new collectionOperationStagingLocationQueryModel();
    query.collectionOperationIds = [this.recordId];
    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        if (result.length) {
          this.collectionOperationName = result[0].collectionOperation?.name;
          this.records = result;
          this.originalData = result;
          result.forEach((item) => {
            item.stagingLocationRecordUrl = '/' + item.stagingLocationId;
          })
          this.handleRecordsChange(this.records, this.originalData);
        } else {
          this.getCollectionOperationName();
        }
      })
      .catch((error) => {
        console.log(error);
      });
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

  handleRecordsChange = (records, originalRecords) => {
    const recordsChangeEvent = new CustomEvent('showdatatable', {
      detail: {
        data: records,
        originalData: originalRecords
      }
    });
    this.dispatchEvent(recordsChangeEvent);
  }

  handleSave() {
    const saveFunctionEvent = new CustomEvent('save', {
      detail: ''
    });
    this.dispatchEvent(saveFunctionEvent);
  }

  handleTableDataAfterModalOperation = (event) => {
    const newRecord = event.detail.modalAction == 'edit' ? event.detail.newRecordFromModal : this.model;
    if (event.detail.modalAction == 'edit') {
      this.model = {
        ...newRecord,
        stagingLocationId: newRecord.stagingLocation?.id,
        stagingLocationAddress: newRecord.stagingLocation?.address,
        stagingLocationName: newRecord.stagingLocation?.name,
        stagingLocationRecordUrl: '/' + newRecord.stagingLocation?.id
      };
    }
    const dataChangeEvent = new CustomEvent('datachange', {
      detail: {
        initialModel: this.initialModel,
        modalAction: event.detail.modalAction,
        changedRecords: this.model
      }
    });
    this.dispatchEvent(dataChangeEvent);
    this.addColOpStagingLocationModal = {
      ... this.addColOpStagingLocationModal,
      isOpen: false
    };
    this.isDisableRequired = false;
  }

  handleCloseColOpStagingLocationModal(event) {
    this.addColOpStagingLocationModal = {
        isOpen: event.detail
    };
  }

  async handleCancel() {
    this.isDisableRequired = true;
    await this.init();
  }

}