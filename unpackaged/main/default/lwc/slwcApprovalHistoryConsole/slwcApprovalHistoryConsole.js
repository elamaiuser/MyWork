import { LightningElement, api, wire, track } from 'lwc';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { orderBy } from 'c/lodash';
import { approvalService, commonService } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import USER_ID from "@salesforce/user/Id";
// const USER_ID = '0053F000007PH10QAG';

export default class SlwcApprovalHistoryConsole extends LightningElement {
  @api recordId = null;
  @api objectLabel = null;
  @api rejectActionLabel = 'Reject';
  @api approveActionLabel = 'Approve';
  @api hideComments = false;
  @api rejectAdditionalFields = [];
  @api approveAdditionalFields = [];
  
  @api hookBeforeApprove = null;
  @api hookBeforeSubmitApproveReject = null;
  @api isReadonly = false;
  @api canApproveOrReject = null;
  
  @track showSpinner = false;
  @track columns = [
    // { label: 'Step Name', fieldName: 'step', type: 'url', typeAttributes: {
    //   target: '_blank'
    // }},
    { label: 'Date', sortable: true, fieldName: 'createdDate', type: 'date', typeAttributes: {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      timeZone: TIME_ZONE
    }},
    { label: 'Status', sortable: true, fieldName: 'status', type: 'text' },
    { label: 'Assigned To', type: 'userUrl', fieldName: 'assignedTo', typeAttributes: ['assignedTo'] },
    { label: 'Actual Approver', fieldName: 'actualApprover', type: 'text' },
    { label: 'Comments', wrapText: true, initialWidth: 400, fieldName: 'comments', type: 'textarea' }
  ];

  @track record;
  @track data = [];
  @track sortOption = {};
  @track approvalActionModalData = {
    isOpen: false,
    action: null,
    actionLabel: null
  };
  @track canApproveReject = false;

  get pageTitle() {
    const length = (this.data || []).length;
    return `Approval History (${length})`;
  }

  get actionModalAdditionalFields() {
    if(this.approvalActionModalData && this.approvalActionModalData.action === 'Reject') {
      return this.rejectAdditionalFields;
    } 
    if(this.approvalActionModalData && this.approvalActionModalData.action === 'Approve') {
      return this.approveAdditionalFields;
    } 
    return [];
  }

  get showAssignToMeBtn() {
    return this.record && this.record.designatedApproverId !== USER_ID;
  }

  get showUnassignbtn() {
    return this.record && this.record.designatedApproverId === USER_ID;
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
    this.initSort();
    this.refreshData();
  }

  initSort() {
    this.sortOption = {
      fieldName: 'createdDate',
      sortDirection: 'desc'
    }
  }
  
  refreshData() {
    this.showLoading();

    return Promise.resolve()
      .then(() => {
        let service = new approvalService();
        return Promise.all([
          this.getRecordData(this.recordId),
          service.getApprovalHistoryList({recordId: this.recordId}),
          service.canApprove({recordId: this.recordId})
        ])
      })
      .then(([record, getApprovalHistoryListResult, canApproveResult]) => {
        this.canApproveReject = !this.isReadonly && (!this.canApproveOrReject || this.canApproveOrReject(record)) && !!canApproveResult.returnedData;
        this.record = record;
        this.data = getApprovalHistoryListResult.returnedData;
        this.sortData();
      })
      .catch((error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
      })
      .finally(() => this.hideLoading());
  }

  sortData() {
    if(!this.sortOption) return;
    const fieldName = this.sortOption.fieldName;
    const sortDirection = this.sortOption.sortDirection;
    this.data = orderBy(this.data, [fieldName], [sortDirection]);
  }
  
  getRecordData = (recordId) => {
    let _commonService = new commonService();
    return _commonService.getSObjectName({
      recordId: recordId
    })
    .then(result => {
      this.objectApiName = result;

      let { service, queryModel } = _commonService.getServiceBySObjectName(result);
      queryModel.recordIds = [recordId];

      return service.query(queryModel)
    })
    .then(([result]) => {
      return result;
    })
  }

  handleSortChanged(event) {
    const fieldName = event.detail.fieldName;
    const sortDirection = event.detail.sortDirection;

    this.sortOption = {
      fieldName: fieldName,
      sortDirection: sortDirection
    }

    this.sortData();
  }

  handleApprove() {
    Promise.resolve()
    .then(() => {
      if(this.hookBeforeApprove) {
        return this.hookBeforeApprove();
      } else {
        return true;
      }
    })
    .then((handleNext = false) => {
      if(handleNext) {
        this.approvalActionModalData = {
          isOpen: true,
          action: 'Approve',
          actionLabel: this.approveActionLabel
        };
      }
    })
  }

  handleReject() {
    this.approvalActionModalData = {
      isOpen: true,
      action: 'Reject',
      actionLabel: this.rejectActionLabel
    };
  }

  handleApprovalActionModalClosed(event) {
    const saved = event.detail.result;
    if(saved) {
      this.refreshData();

      this.dispatchEvent(new CustomEvent('actiondone', {
        detail: {
          action: this.approvalActionModalData.action,
          recordId: this.recordId
        }
      }));
    }
    this.approvalActionModalData = {
      isOpen: false
    };
  }

  handleAssignToMe(event) {
    this.showLoading();
    return Promise.resolve()
      .then(() => {
        let service = new approvalService();
        return service.saveDesignatedApprover({
          request: {
            recordId: this.recordId,
            approverId: USER_ID
          }
        })
      })
      .then(() => {
        return this.refreshData();
      })
      .catch((error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
      })
      .finally(() => this.hideLoading());
  }

  handleUnassign(event) {
    this.showLoading();
    return Promise.resolve()
      .then(() => {
        let service = new approvalService();
        return service.saveDesignatedApprover({
          request: {
            recordId: this.recordId,
            approverId: ''
          }
        })
      })
      .then(() => {
        return this.refreshData();
      })
      .catch((error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
      })
      .finally(() => this.hideLoading());
  }
}