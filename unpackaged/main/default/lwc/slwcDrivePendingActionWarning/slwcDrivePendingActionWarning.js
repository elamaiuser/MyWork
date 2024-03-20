import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { approvalService, userService, driveService, driveQueryModel, driveChangeRequestService, driveChangeRequestQueryModel } from 'c/dataService';
import { PENDING_ACTION, DRIVE_REQUEST_CHANGE_STATUS } from 'c/slwcConstants';
import { waitUntil} from 'c/slwcUtils';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

export default class SlwcDrivePendingActionWarning extends NavigationMixin(LightningElement) {
  @api recordId;

  @track drive;
  @track driveChangeRequest;
  @track loginUser;
  @track dcrApprovalModalData = {};
  @track confirmModalData = {};
  @track showSpinner = false;
  
  @wire(getRecord, { recordId: '$recordId', fields: [STAGE_FIELD] })
  wiredRecord({ error, data }) {
      this.init();
  }

  @wire(CurrentPageReference) pageRef;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.currentPageReference = currentPageReference;
    this.recordId = this.currentPageReference.attributes.recordId;
    this.init();
  }

  get isOpportunityMode() {
    return this.recordId && this.recordId.startsWith('006');
  }

  get showDCRDetailsButton() {
    if (!this.drive) return false;
    if (!this.driveChangeRequest) return false;

    const driveHelper = new DriveHelper();

    const isAPSUser = driveHelper.isAPSUser(this.loginUser);
    const isOpportunityMode = this.isOpportunityMode;

    return isAPSUser && !isOpportunityMode;
  }

  get showWithdrawApprovalRequestButton() {
    if (!this.drive) return false;

    const driveHelper = new DriveHelper();

    if(driveHelper.isDriveSubmittedForCancelApproval(this.drive)) {
      return true;
    }

    if(driveHelper.isDriveSubmittedForSubmissionApproval(this.drive)) {
      return true;
    }

    return false;
  }

  get warningText() {
    if (!this.drive) return null;
    if (this.driveChangeRequest) {
      return `Drive Change Request has been submitted for Approval. ${this.driveChangeRequest.status}`
    }
    
    const driveHelper = new DriveHelper();

    if(driveHelper.isDriveSubmittedForCancelApproval(this.drive)) {
      return 'Cancel In Process.'
    }

    if(driveHelper.isDriveSubmittedForSubmissionApproval(this.drive)) {
      return `Draft drive has been submitted. ${this.drive.approvalStatus}`;
    }

    return null;
  }

  connectedCallback() {
    // this.recordId = 'a1Z2i000001ihRIEAY';
    // this.init();
  }

  exceptionHandler = (error) => {
    console.log(error);
    if(error && error.message) {
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  init() {
    if (!this.recordId) return;

    let service = new driveService();
    let queryModel = new driveQueryModel();

    if (this.isOpportunityMode) {
      queryModel.opportunityIds = [this.recordId];
    } else {
      queryModel.recordIds = [this.recordId];
    }

    Promise.all([
      this.retrieveDriveChangeRequest(),
      this.retrieveLoginUser(),
      service.query(queryModel)
    ])
      .then(([driveChangeRequest, loginUser, [drive]]) => {
        this.drive = drive;
      })
      .catch(error => this.exceptionHandler(error))
    }

  retrieveDriveChangeRequest() {
    let dcrService = new driveChangeRequestService();
    let dcrQueryModel = new driveChangeRequestQueryModel();
    if (this.isOpportunityMode) {
      dcrQueryModel.opportunityIds = [this.recordId];
    } else {
      dcrQueryModel.driveIds = [this.recordId];
    }

    dcrQueryModel.statuses = [
      DRIVE_REQUEST_CHANGE_STATUS.SUBMITTED,
      DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL,
      DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL,
      DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DRD_FEEDBACK
    ];
    return dcrService.query(dcrQueryModel)
      .then(([driveChangeRequest]) => {
        this.driveChangeRequest = driveChangeRequest;
        return this.driveChangeRequest;
      });
  }

  retrieveLoginUser() {
    let service = new userService();
    return service.getLoginUser()
      .then((result) => {
        this.loginUser = result.returnedData;
        return this.loginUser;
      })
  }

  showDCRDetailsModal() {
    if (!this.driveChangeRequest) return;

    this.dcrApprovalModalData = {
      isOpen: true,
      recordId: this.driveChangeRequest.id
    };
  }

  withdrawApprovalRequest() {
    this.showConfirmModal({
      title: 'Withdraw Approval Request',
      message: `Are you sure you want to withdraw this request?`,

      onClose: (result) => {
          this.hideConfirmModal();
          if (result) {
            this.showLoading();
            
            const approvalSvc = new approvalService();
            return approvalSvc.withdraw({
              request: {
                recordId: this.drive.id
              }
            })
            .then(() => {
              //wait until isPendingApproval returned false
              return waitUntil(() => {
                return approvalSvc.isPendingApproval({
                  recordId: this.drive.id
                })
                .then(result => {
                  return !result.returnedData;
                });
              }, 3000, 100);
            })
            .then(() => {
              const _driveService = new driveService();
              return _driveService.save({
                id: this.drive.id,
                approvalStatus: 'Cancelled'
              })
            })
            .then((result) => {
              if(!result.success) throw result;

              this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
              });
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading)
          }
      }
  });
  }

  handleCloseDCRDetailsModal() {
    this.dcrApprovalModalData = {};
  }

  /** Confirm Modal **/
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {...confirmModalData,
        isOpen: true,
        confirmBtnLabel: confirmModalData.confirmBtnLabel || 'Yes',
        cancelBtnLabel: confirmModalData.cancelBtnLabel || 'No',
    }
  }

  hideConfirmModal() {
      this.confirmModalData = {};
  }
}