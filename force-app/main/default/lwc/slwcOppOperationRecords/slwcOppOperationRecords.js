import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { sObjectType, operationRecordService, operationRecordQueryModel } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SlwcOppOperationRecords extends LightningElement {
  @api recordId;

  @track showSpinnerCount = 0;
  @track operationRecords = [];
  @track confirmModalData = {};
  @track operationRecordModalData = {};

  get showSpinner() {
    return this.showSpinnerCount > 0;
  }

  get pageHeader() {
    let numberOfRecords = (this.operationRecords || []).length;
    return `Operation Records (${numberOfRecords})`;
  }

  /* PAGE REFERENCE */
  @wire(CurrentPageReference) pageRef;

  connectedCallback() {
    // this.recordId = 'a1Z2i000001eqdPEAQ';

    if (this.recordId) {
      this.initialize(this.recordId);
    }
  }

  disconnectedCallback() {
  }

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.currentPageReference = currentPageReference;
    let recordId = this.currentPageReference.state.c__recordId;
    this.initialize(recordId);
  }

  exceptionHandler = (error) => {
    this.dispatchEvent(new ShowToastEvent({
      message: error.message,
      variant: 'error',
      mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinnerCount++;
  }

  hideLoading = () => {
    this.showSpinnerCount--;
    if (this.showSpinnerCount < 0) {
      this.showSpinnerCount = 0;
    }
  }

  initialize(recordId) {
    if (!recordId) return;
    this.refreshData()
  }

  refreshData() {
    this.showLoading();
    Promise.resolve()
      .then(() => {
        let serivce = new operationRecordService();
        let queryModel = new operationRecordQueryModel();
        queryModel.driveIds = [this.recordId];

        return serivce.query(queryModel)
      })
      .then((result) => {
        this.operationRecords = result || [];
      })
      .catch(error => this.exceptionHandler(error))
      .finally(this.hideLoading);
  }

  handleWidgetActions(event) {
    let actionName = event.currentTarget.dataset['action'];
    let recordId = event.currentTarget.dataset['value'];
    let row = this.operationRecords.find(item => item.id === recordId);

    switch (actionName) {
        case 'edit':
            this.viewOperationRecord(row);
            break;
        case 'delete':
            this.deleteOperationRecord(row);
            break;
    }
  }

  viewOperationRecord(opertionRecord) {
    this.handleShowOperationRecordModal(opertionRecord);
  }

  deleteOperationRecord(opertionRecord) {
    this.showConfirmModal({
      title: 'Delete Operation Record',
      message: 'Are you sure you want to delete this Operation Record?',
      onClose: (result) => {
          this.hideConfirmModal();
          if (result) {
            this.showLoading();
            Promise.resolve()
              .then(() => {
                let serivce = new operationRecordService();
                return serivce.delete({
                  id: opertionRecord.id
                })
              })
              .then((result) => {
                if(!result || !result.success) {
                  throw result;
                }
                return this.refreshData();
              })
              .catch(error => this.exceptionHandler(error))
              .finally(this.hideLoading);
          }
      },
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No'
    });
  }

  /* Operation Record modal */
  handleShowOperationRecordModal(operationRecord) {
    this.operationRecordModalData = {
      isOpen: true,
      job: {
        driveId: this.recordId,
        driveShiftId: operationRecord.driveShiftId
      }
    }
  }
  
  handleCloseOperationRecordModal() {
    this.operationRecordModalData = {};
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