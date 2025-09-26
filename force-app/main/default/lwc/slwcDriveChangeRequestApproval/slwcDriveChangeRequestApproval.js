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
  @track actionsDisabled = false;
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
    const waitingForAPSApproval = [DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL, DRIVE_REQUEST_CHANGE_STATUS.APS_WAITING_FOR_DRD_FEEDBACK].includes(this.driveChangeRequest?.status); 
    return !isAPSUser || !waitingForAPSApproval;
  }

  get resolveContentionActionsReadOnly() {
    return this.actionsDisabled;
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
      //this.canApproveReject = !!canApproveRejectResult.returnedData;
      this.canApproveReject = true;
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
    if(this.resolveContentionsReadonly) {
      this.init();
      return;
    };
  }
  
  handleCanApproveRefreshed(event) {
    const { canApproveReject, driveChangeRequest } = event.detail;
    //this.canApproveReject = canApproveReject;
    this.actionsDisabled = [DRIVE_REQUEST_CHANGE_STATUS.APPROVED, DRIVE_REQUEST_CHANGE_STATUS.REJECTED].includes(driveChangeRequest?.status);
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
        .then(({driveContentions, driveTimeBlockContentions = []}) => {
          if(driveTimeBlockContentions.length > 0) {
            this.dispatchEvent(new ShowToastEvent({
              message: 'Please resolve all time block contentions before saving.',
              variant: 'error',
              mode: 'dismissable',
            }));
            return;
          }

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
      if(!this.showResolveContentions || this.resolveContentionsReadonly) return request;
      const resolveContentionComponent = this.template.querySelector('c-slwc-resolve-drive-contentions');
      return resolveContentionComponent.getData()
            .then(({contentionResolution, drive}) => {
              let _driveService = new driveService();
              return _driveService.save(drive)
              .then(() => {
                return {
                  ...request,
                  sObj: {
                    ...request.sObj,
                    sked_Contention_Resolution__c: contentionResolution,
                  }
                }
            })
        })
    })
  }
}