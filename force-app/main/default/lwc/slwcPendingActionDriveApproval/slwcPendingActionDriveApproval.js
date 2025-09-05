import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { PENDING_ACTION, DRIVE_CONTENTION, DRIVE_APPROVAL_STATUS } from 'c/slwcConstants';
import { approvalService, debugLogService, driveService, driveQueryModel, userService } from 'c/dataService';
import { DriveHelper } from 'c/slwcDriveGenerator';
export default class SlwcPendingActionDriveApproval extends LightningElement {
  @api recordId;
  // @api recordId = 'a1Z2i000001ihY1EAI';

  @track drive;
  @track loginUser;
  @track canApproveReject = false;
  @track actionsDisabled = false;
  @track showSpinner = false;

  @track rejectAdditionalFields = [
    {
      label: 'Rejection Reason Code',
      type: 'picklist',
      field: 'rejectionReasonCode',
      required: true,
      objectApiName: 'sked_Drive__c',
      picklistFieldApiName: 'sked_Rejection_Reason_Code__c',
      hideIf: (record) => {
        return record.pendingAction === PENDING_ACTION.CANCEL_IN_PROCESS;
      }

    }
  ];

  @track approveAdditionalFields = [];

  get showResolveContentions() {
    return this.drive && this.drive.pendingAction === PENDING_ACTION.DRIVE_SUBMISSION;
  }

  get resolveContentionsReadonly() {
    if(!this.showResolveContentions) return true;
    const driveHelper = new DriveHelper();
    const isAPSUser = driveHelper.isAPSUser(this.loginUser); 
    const waitingForAPSApproval = [DRIVE_APPROVAL_STATUS.WAITING_FOR_APS_APPROVAL, DRIVE_APPROVAL_STATUS.APS_WAITING_FOR_DRD_FEEDBACK, DRIVE_APPROVAL_STATUS.APPROVED, DRIVE_APPROVAL_STATUS.REJECTED].includes(this.drive?.approvalStatus); 
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
    let _approvalService = new approvalService();
    let _driveService = new driveService();
    let _driveQueryModel = new driveQueryModel();
    _driveQueryModel.recordIds = [this.recordId];
    let _userService = new userService();
    
    this.showLoading();
    Promise.all([
      _driveService.query(_driveQueryModel),
      _approvalService.canApprove({recordId: this.recordId}),
      _userService.getLoginUser()
    ])
    .then(([[drive], canApproveRejectResult, getLoginUserResult]) => {
      this.loginUser = getLoginUserResult.returnedData;
      this.canApproveReject = !!canApproveRejectResult.returnedData;
      this.drive = drive;
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleActionDone = () => {
    this.actionsDisabled = true;
    this.init();
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
        });
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
      });
    })
  }
}