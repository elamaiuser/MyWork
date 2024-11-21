import { LightningElement, api, track } from 'lwc';
import {
  sObjectType,
  debugLogService,
  driveChangeRequestQueryModel,
  driveChangeRequestService,
  userService,
  approvalService
} from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { DRIVE_REQUEST_CHANGE_STATUS, DRIVE_CHANGE_REQUEST_ITEM_TYPE } from 'c/slwcConstants';
export default class SlwcDriveChangeRequestApprovalModal extends LightningElement {
  DRIVE_CHANGE_REQUEST_DETAILS_COLUMNS = [
    { label: 'Field Label', fieldName: 'fieldLabel', type: 'text', wrapText: true},
    { label: 'Old Value', fieldName: 'oldValueDisplay', type: 'text', wrapText: true},
    { label: 'New Value', fieldName: 'newValueDisplay', type: 'text', wrapText: true},
    { label: 'Change Reason', fieldName: 'changeReason', type: 'text', wrapText: true},
    { label: 'Requested By', type: 'text', fieldName: 'lastModifiedByName', wrapText:true },
    { label: 'Requested Date', fieldName: 'lastModifiedDate', type: 'date', wrapText:true, typeAttributes: { year: "numeric", month: "numeric", day: "2-digit", hour: '2-digit',  
    minute: '2-digit', timeZone: TIME_ZONE } }
  ];
  
  @api recordId = null;

  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;
    this.init();
  }

  @track showSpinner = false;
  @track requestDetailModalData = {};
  @track allowRequestDRDFeedback = false;
  @track confirmModalData = {};
  
  connectedCallback() {
  }
  
  exceptionHandler = (error) => {
    new debugLogService().captureDebugLog(error, this.recordId);
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

  init() {
    if(!this.recordId) return;

    let _userService = new userService();
    let _approvalService = new approvalService();
    this.requestDetailModalData = {};
    this.showLoading();
    Promise.all([
      _userService.getLoginUser(),
      this.fetchDriveChangeRequest(),
      _approvalService.canApprove({recordId: this.recordId})
    ])
    .then(([getLoginUserResult, driveChangeRequest, canApproveResult]) => {
      const driveChangeRequestItems = driveChangeRequest.driveChangeRequestItems || [];
      this.requestDetailModalData = {
        record: driveChangeRequest,
        driveChanges: driveChangeRequestItems.filter(item => item.type === DRIVE_CHANGE_REQUEST_ITEM_TYPE.CHANGE),
        driveImpacts: driveChangeRequestItems.filter(item => item.type === DRIVE_CHANGE_REQUEST_ITEM_TYPE.IMPACT)
      };

      this.checkToAllowRequestDRDFeedback(getLoginUserResult.returnedData, driveChangeRequest.status, !!canApproveResult.returnedData);
      
    })
    .catch(e => this.exceptionHandler(e))
    .finally(() => this.hideLoading())
  }

  checkToAllowRequestDRDFeedback(loginUser, status, canApproveReject) {
    const driveHelper = new DriveHelper();
    const isAPSUser = driveHelper.isAPSUser(loginUser);
    this.allowRequestDRDFeedback = canApproveReject && (status === DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL || status === DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL);
  }

  fetchDriveChangeRequest() {
    let service = new driveChangeRequestService();
    let query = new driveChangeRequestQueryModel();
    query.recordIds = [this.recordId];
    query.subQueryIndicator = sObjectType.DRIVE_CHANGE_REQUEST_ITEM;
    query.ignoreHiddenDriveChangeRequestItems = true;
    
    return service.query(query)
    .then(result => {
      return result && result.length > 0 ? result[0] : null;
    })
  }

  handleClose(event) {
    const closeEvent = new CustomEvent('close', {
      detail: {
        result: true
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  }

  showConfirmModal() {
    this.confirmModalData = {
      isOpen: true,
      title: 'Request DRD Feedback',
      message: 'Are you sure to request DRD Feedback?',
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No',
      onClose: (result) => {
        this.closeConfirmModal();
        if (result) {
          this.handleRequestDRDFeedback();
        }
      }
    };
  }

  closeConfirmModal() {
    this.confirmModalData = {};
  }

  handleRequestDRDFeedback() {
    let newStatus = null;
    if(this.requestDetailModalData.record.status === DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL) {
      newStatus = DRIVE_REQUEST_CHANGE_STATUS.DM_WAITING_FOR_DRD_FEEDBACK;
    } else if(this.requestDetailModalData.record.status === DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL) {
      newStatus = DRIVE_REQUEST_CHANGE_STATUS.APS_WAITING_FOR_DRD_FEEDBACK;
    }
    let service = new driveChangeRequestService();
    this.showLoading();
    service.save({ id:this.requestDetailModalData.record.id, status: newStatus })
    .then((result) => {
      if (result.success) {
        this.isOpen = false;
        this.handleClose();
      }
      else {
          this.dispatchEvent(new ShowToastEvent({
              message: 'Drive Change Request Details is updated failed.',
              variant: 'error',
              mode: 'dismissable'
          }));
      }
    })
    .catch((error) => {
      if (error && error.message) {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
      }
    })
    .finally(() => {
        this.hideLoading();
    });
  }
}