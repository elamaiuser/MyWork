import { LightningElement, api, track } from 'lwc';
import { sObjectType, debugLogService, driveChangeRequestQueryModel, driveChangeRequestService, approvalService, userService, driveService } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { DRIVE_REQUEST_CHANGE_STATUS } from 'c/slwcConstants';
export default class SlwcDriveChangeRequestApproval extends LightningElement {
  // @api recordId = 'a2S2i000000oEU9EAM';
  @api recordId;
  
  @track loginUser;
  @track driveChangeRequest;
  @track canApproveReject = false;
  @track showSpinner = false;

  @track generateDriveModalData = {
    isOpen: false,
    recordId: null
  }

  @track approveAdditionalFields = [];

  get showResolveContentions() {
    return this.canApproveReject;
  }

  get resolveContentionsReadonly() {
    if(!this.showResolveContentions) return true;
    const driveHelper = new DriveHelper();
    const isAPSUser = driveHelper.isAPSUser(this.loginUser); 
    const waitingForAPSApproval = this.driveChangeRequest?.status === DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL; 
    return !isAPSUser || !waitingForAPSApproval;
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

  connectedCallback() {
    this.init();
  }

  init() {
    if (!this.recordId) return;

    let _approvalService = new approvalService();
    let _userService = new userService();
    let _driveChangeRequestService = new driveChangeRequestService();    
    let _driveChangeRequestQueryModel = new driveChangeRequestQueryModel();
    _driveChangeRequestQueryModel.recordIds = [this.recordId];

    this.showLoading();
    Promise.all([
      _approvalService.canApprove({recordId: this.recordId}),
      _userService.getLoginUser(),
      _driveChangeRequestService.query(_driveChangeRequestQueryModel)
    ])
    .then(([canApproveRejectResult, getLoginUserResult, [driveChangeRequest]]) => {
      this.loginUser = getLoginUserResult.returnedData;
      this.canApproveReject = !!canApproveRejectResult.returnedData;
      // this.canApproveReject = true;
      this.driveChangeRequest = driveChangeRequest;

      let approveAdditionalFields = [];
      if (driveChangeRequest.reason) {
        approveAdditionalFields.push({
          label: 'Reason',
          type: 'text',
          field: 'reason',
          value: driveChangeRequest.reason,
          required: false,
          readonly: true
        });
      }
      if (driveChangeRequest.subReason) {
        approveAdditionalFields.push({
          label: 'Sub-reason',
          type: 'text',
          field: 'subReason',
          value: driveChangeRequest.subReason,
          required: false,
          readonly: true
        });
      }
      this.approveAdditionalFields = approveAdditionalFields;
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleActionDone(event) {
    if(this.resolveContentionsReadonly) return;

    const { recordId, action } = event.detail;
    if(action === 'Approve') {
      Promise.resolve()
      .then(() => {
        const resolveContentionComponent = this.template.querySelector('c-slwc-resolve-drive-contentions');
        return resolveContentionComponent.getData()
      })
      .then(({drive}) => {
        if(drive) {
          const service = new driveService();
  
          this.showLoading();
          return service.save(drive)
          .catch(error => this.exceptionHandler(error))
          .finally(this.hideLoading);
        }
      })
    }
  }
  
  showGenerateDriveModal(dcrId) {
    this.generateDriveModalData = {
      isOpen: true,
      recordId: dcrId
    }
  }

  closeGenerateDriveModal() {
    this.generateDriveModalData = {
      isOpen: false
    }
  }

  beforeApproveHook = () => {
    return Promise.resolve()
    .then(() => {
      if(!this.showResolveContentions || this.resolveContentionsReadonly) return true;

      const resolveContentionComponent = this.template.querySelector('c-slwc-resolve-drive-contentions');
      return resolveContentionComponent.getData()
        .then(({driveContentions}) => {
          const anyNotPassedContention = driveContentions.find(item => {
            return !item.passed;
          })
    
          if(anyNotPassedContention) {
            this.dispatchEvent(new ShowToastEvent({
              message: 'Please resolve all drive contentions before approving.',
              variant: 'error',
              mode: 'dismissable',
            }));
          }
    
          return !anyNotPassedContention;
        })
    })
  }

  beforeSubmitApproveRejectHook = (request) => {
    return Promise.resolve()
    .then(() => {
      if(request.action !== 'Approve') return request;
      const resolveContentionComponent = this.template.querySelector('c-slwc-resolve-drive-contentions');
      return resolveContentionComponent.getData()
        .then(({contentionResolution}) => {
          let _driveService = new driveService();
          return _driveService.save({
            id: this.driveChangeRequest.driveId,
            contentionResolution: contentionResolution
          })
          .then(() => {
            return request;
          })
        });
    })
  }
}