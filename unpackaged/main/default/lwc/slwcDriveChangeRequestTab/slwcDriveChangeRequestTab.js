import {
  LightningElement,
  track,
  api,
  wire
} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
  sObjectType,
  driveChangeRequestQueryModel,
  driveChangeRequestService,
  debugLogService
} from 'c/dataService';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcUtils from 'c/slwcUtils';
import { DRIVE_REQUEST_CHANGE_STATUS, DRIVE_CHANGE_REQUEST_ITEM_TYPE } from 'c/slwcConstants';
import { NavigationMixin } from 'lightning/navigation';

const DRIVE_CHANGE_REQUEST_DETAILS_COLUMNS = [
  { label: 'Field Label', fieldName: 'fieldLabel', type: 'text', wrapText: true},
  { label: 'Old Value', fieldName: 'oldValueDisplay', type: 'text', wrapText: true},
  { label: 'New Value', fieldName: 'newValueDisplay', type: 'text', wrapText: true},
  { label: 'Change Reason', fieldName: 'changeReason', type: 'text', wrapText: true},
  { label: 'Requested By', type: 'text', fieldName: 'lastModifiedByName', wrapText:true },
  { label: 'Requested Date', fieldName: 'lastModifiedDate', type: 'date', wrapText:true, typeAttributes: { year: "numeric", month: "numeric", day: "2-digit", hour: '2-digit',  
  minute: '2-digit', timeZone: TIME_ZONE } }
];

export default class SlwcDriveChangeRequestTab extends NavigationMixin(LightningElement) {
  @api recordId = null;
  // @api recordId = '0062i000008JSa2AAG';

  @track timezoneSidId = TIME_ZONE;
  @track showSpinner = false;
  @track detailsTableColumns = DRIVE_CHANGE_REQUEST_DETAILS_COLUMNS;
  @track driveChangeRequests = [];
  @track selectedDriveChangeRequest = null;
  
  @track confirmModalData = {};
  @track generateDriveModalData = {};

  get isMobile() {
    return slwcUtils.isMobile()
  }

  get isTablet() {
    return slwcUtils.isTablet()
  }

  get isDesktop() {
    return slwcUtils.isDesktop()
  }
  get show1ColumnRequest() {
    return this.isMobile && !this.selectedDriveChangeRequest || this.isDesktop || this.isTablet;
  }
  get show1ColumnTable() {
    return this.isMobile && this.selectedDriveChangeRequest || this.isDesktop || this.isTablet;
  }

  get classButton() {
    return this.isMobile ? 
    'slds-grid slds-grid_align-spread slds-p-around_small slds-border_bottom' : 
    'slds-grid slds-grid_align-end slds-p-around_small slds-border_bottom'; 
  }
  get driveChangeRequestItems() {
    if (!this.selectedDriveChangeRequest) return [];
    return this.selectedDriveChangeRequest.driveChangeRequestItems || [];
  }
  get driveChanges() {
    return this.driveChangeRequestItems.filter(item => item.type === DRIVE_CHANGE_REQUEST_ITEM_TYPE.CHANGE);
  }
  get driveImpacts() {
    return this.driveChangeRequestItems.filter(item => item.type === DRIVE_CHANGE_REQUEST_ITEM_TYPE.IMPACT);
  }
  get driveChangeRequestCount() {
    return this.driveChangeRequests.length;
  }

  get showCancelButton() {
    if (!this.selectedDriveChangeRequest) return false;

    const validStatuses = [
      DRIVE_REQUEST_CHANGE_STATUS.PENDING, 
      DRIVE_REQUEST_CHANGE_STATUS.SUBMITTED, 
      DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL, 
      DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL, 
      DRIVE_REQUEST_CHANGE_STATUS.APS_WAITING_FOR_DRD_FEEDBACK,
      DRIVE_REQUEST_CHANGE_STATUS.DM_WAITING_FOR_DRD_FEEDBACK
    ]

    return validStatuses.includes(this.selectedDriveChangeRequest.status);
  }

  get showCaptureDriveImpactsButton() {
    if (!this.selectedDriveChangeRequest) return false;

    const validStatuses = [
      DRIVE_REQUEST_CHANGE_STATUS.PENDING
    ]

    return validStatuses.includes(this.selectedDriveChangeRequest.status);
  }

  get showAlert() {
    if (this.showSpinner) return false;
    return !this.driveChangeRequests.length;
  }

  get showDriveChangeRequests() {
    return this.driveChangeRequests.length;
  }

  /* PAGE REFERENCE */
  @wire(CurrentPageReference) pageRef;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.currentPageReference = currentPageReference;
    this.recordId = this.currentPageReference.state.c__recordId || this.recordId;
    this.init();
  }
  
  connectedCallback() {
    this.init();
  }

  showLoading() {
    this.showSpinner = true;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  init() {
    if (!this.recordId) return;
    
    this.fetchData()
      .then(() => {
        if (this.driveChangeRequests.length && !this.isMobile) {
          this.handleSelectDriveChangeRequest({
            currentTarget: {
              dataset: {
                value: this.driveChangeRequests[0].id
              }
            }
          })
        }
      });
  }
  
  fetchData() {
    let queryModel = new driveChangeRequestQueryModel();
    queryModel.subQueryIndicator = sObjectType.DRIVE_CHANGE_REQUEST_ITEM;
    queryModel.ignoreHiddenDriveChangeRequestItems = true;
    
    if (this.recordId.startsWith("006")) {
      queryModel.opportunityIds = [this.recordId];
    } 
    else {
      queryModel.driveIds = [this.recordId];
    }
   ``
    let service = new driveChangeRequestService();

    this.showLoading();
    return service.query(queryModel)
      .then(result => {
        this.driveChangeRequests = (result || []).map((dcr => {
          return {
            ...dcr,
            driveContentions: dcr.driveContention ? dcr.driveContention.split(';') : [],
            driveChangeRequestItems: (dcr.driveChangeRequestItems || [])
          }
        }));

        setTimeout(() => this.restoreSelectedDriveChangeRequest());
      })
      .finally(() => this.hideLoading());
  }

  updateDriveChangeRequestSelection() {
    const selectedRequest = this.selectedDriveChangeRequest;
    const allRequestElements = this.template.querySelectorAll('.list-item .item');
    allRequestElements.forEach(el => {
      el.classList.remove('selected');
      
      const elId = el.dataset['value'];
      if (selectedRequest && elId === selectedRequest.id) {
        el.classList.add('selected');
      }
    })
  }

  handleSelectDriveChangeRequest(event) {
    const id = event.currentTarget.dataset['value'];
    const record = this.driveChangeRequests.find(request => request.id === id);
    if (!record) return;

    this.selectedDriveChangeRequest = record;
    this.updateDriveChangeRequestSelection();
  }
  
  restoreSelectedDriveChangeRequest() {
    const selectedRequest = this.selectedDriveChangeRequest;
    if (!selectedRequest) return;

    const record = this.driveChangeRequests.find(request => request.id === selectedRequest.id);
    this.selectedDriveChangeRequest = record;
    this.updateDriveChangeRequestSelection();
  }

  handleRefresh() {
    this.fetchData();
  }

  handleBack() {
     this.selectedDriveChangeRequest = null;
  }

  handleOnChange(event) {
    let targetName = event.target.name;
    let targetValue = slwcUtils.getValueFromEvent(event);
    this.selectedDriveChangeRequest[targetName] = targetValue;
  }

  handleCancelRequest() {
    this.showConfirmModal({
      title: 'Cancel Drive Change Request',
      message: `Are you sure you want to cancel this Drive Change Request?
        Notes: The process to revert the Opportunity will take time.
        Please wait a moment then refreshing the page.
      `,

      onClose: (result) => {
          this.hideConfirmModal();
          if (result) {
            let model = this.selectedDriveChangeRequest;
            model.status = 'Cancelled';
        
            let service = new driveChangeRequestService();
            this.showLoading();
            service.save(model)
              .then(() => {
                  this.dispatchEvent(new ShowToastEvent({
                      message: 'Drive Change Request was cancelled.',
                      variant: 'success',
                      mode: 'dismissable'
                  }));
                  slwcUtils.refreshLightningPage();
              })
              .then(() => {
                this.fetchData();
              })
              .catch(error => {
                this.exceptionHandler(error);
                this[NavigationMixin.Navigate]({
                  type: 'standard__recordPage',
                  attributes: {
                      recordId: this.recordId,
                      actionName: 'view'
                    }
                });
              })
              .finally(() => this.hideLoading());
          }
      }
    });
  }

  handleCaptureDriveImpacts() {
    this.showGenerateDriveModal(this.selectedDriveChangeRequest.id);
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

  hideConfirmModal() {
    this.confirmModalData = {};
  }

  /** Generate Drive Modal */
  showGenerateDriveModal(dcrId) {
    this.generateDriveModalData = {
      isOpen: true,
      dcrId: dcrId
    }
  }

  closeGenerateDriveModal(event) {
    this.generateDriveModalData = {};

    this.handleRefresh();
  }

  exceptionHandler = (error) => {
    new debugLogService().captureDebugLog(error, this.recordId);
    this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
    }));
  }
}