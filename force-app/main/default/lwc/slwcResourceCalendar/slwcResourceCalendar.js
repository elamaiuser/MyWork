import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import * as slwcDateUtils from 'c/slwcDateUtils';
import * as slwcUtils from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { sObjectType, resourceService, resourceQueryModel, 
  jobAllocationService, jobAllocationQueryModel,
  activityResourceService, activityResourceQueryModel } from 'c/dataService';
import _calendarMetadata from './calendarMetadata';
import USER_ID from "@salesforce/user/Id";
import TIME_ZONE from '@salesforce/i18n/timeZone';
import DEFAULT_JOB_EVENT_TYPE_SETTINGS from './eventTypeSettings';
import { JOB_ALLOCATION_STATUS } from 'c/slwcConstants';
import { NavigationMixin } from 'lightning/navigation';

export default class SlwcResourceCalendar extends NavigationMixin(LightningElement) {
  @wire(CurrentPageReference) pageRef;
  
  @api recordId = USER_ID;
  // @api recordId = '0053F000007PH10QAG';

  @track queryModel = {};
  @track hasResult = false;
  @track calendarData = null;
  @track calendarSettings = null;
  @track calendarConfigData = null;
  @track adminSettings = null;
  @track showSpinnerCount = 0;

  @track operationRecordModalData = {};
  @track siteFeedbackModalData = {};
  @track callOutModalData = {};
  @track confirmModalData = {};

  resource;

  get showSpinner() {
    return this.showSpinnerCount > 0;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance(this.calendarSettings);
  }

  get calendarDateRange() {
    return {
      startDate: this.queryModel.startDate,
      endDate: this.queryModel.endDate
    }
  }

  get calendarMetadata() {
    return _calendarMetadata;
  }

  get isValidQueryModel() {
    return !slwcUtils.isNullOrEmpty(this.queryModel) &&
      !slwcUtils.isNullOrEmpty(this.queryModel.startDate) &&
      !slwcUtils.isNullOrEmpty(this.queryModel.endDate)
  }

  get resourceName() {
    return this.resource ? this.resource.name : null
  }

  connectedCallback() {
    registerListener('showOperationRecordModal', this.handleShowOperationRecordModal, this);
    registerListener('showSiteFeedbackModal', this.handleShowSiteFeedbackModal, this);
    registerListener('showCallOutModal', this.handleShowCallOutModal, this);
    registerListener('openDriveWorksheet', this.openDriveWorksheetReport, this);

    if (!this.recordId) {
      //TODO: handle error
      return;
    }

    let settingKeys = ["rac", "adminSetting"];
    let resourceSvc = new resourceService();
    let resourceQuery = new resourceQueryModel();
    resourceQuery.userIds = [this.recordId];

    this.showLoading();
    return Promise.all([
      resourceSvc.getCustomSettings({ settingKeys: settingKeys }),
      resourceSvc.query(resourceQuery)
    ])
      .then(([customSettingsKeyResult, resourceResult]) => {
        if(!resourceResult || !resourceResult.length) {
          this.showConfirmModal({
            mode: 'error',
            title: 'Error',
            message: 'This screen cannot be loaded as you do not have an Active Resource record associated. Please contact your administrator for assistance.',
            confirmBtnLabel: 'none',
            cancelBtnLabel: 'none'
          });
  
          return;  
        }

        this.calendarSettings = customSettingsKeyResult.returnedData.rac;
        this.calendarSettings.timezone = TIME_ZONE;
        
        this.adminSettings = customSettingsKeyResult.returnedData.adminSetting;
        
        this.calendarConfigData = {
          eventTypeSettings: [
            ...DEFAULT_JOB_EVENT_TYPE_SETTINGS, 
            ...customSettingsKeyResult.returnedData.rac.eventTypeSettings.map(item => {
              return {
                backgroundColor: item.backgroundColor,
                color: item.color,
                eventType: item.eventType,
                objectType: item.objectType,
                showLegend: item.showLegend
              }
            })
          ]
        };

        this.resource = resourceResult[0];

        //trigger change to refresh the calendar
        this.handleOnChange({
          type: 'monthchange',
          detail: {
            selectedDate: DateTime.local().toISODate()
          }
        })
      })
      .catch(error => this.exceptionHandler(error))
      .finally(() => {
        this.hideLoading();
      });
  }

  disconnectedCallback() {
    unregisterAllListeners(true);
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

  handleOnChange(event) {
    if (event.type === 'monthchange') {
      this.queryModel.selectedMonth = event.detail.selectedDate;
      this.queryModel.startDate = this.dateUtils.startOf(this.dateUtils.startOf(this.queryModel.selectedMonth, 'month'), 'week');
      this.queryModel.endDate = this.dateUtils.endOf(this.dateUtils.endOf(this.queryModel.selectedMonth, 'month'), 'week');
    } else {
      this.queryModel[event.target.name] = slwcUtils.getValueFromEvent(event);
    }

    this.refresh();
  }

  getResourceData() {
    return Promise.resolve()
    .then(() => {
      if (!this.isValidQueryModel) return;
    
      this.showLoading();
      let service = new jobAllocationService();
      let queryModel = new jobAllocationQueryModel();
      queryModel.resourceIds = [this.resource.id];
      queryModel.startDate = this.queryModel.startDate;
      queryModel.endDate = this.queryModel.endDate;
      queryModel.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.IN_PROGRESS, 
        JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN,
        JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.COMPLETE];
        
      let _activityResourceService = new activityResourceService();
      let _activityResourceQueryModel = new activityResourceQueryModel();
      _activityResourceQueryModel.resourceIds = [this.resource.id];
      _activityResourceQueryModel.startDate = this.queryModel.startDate;
      _activityResourceQueryModel.endDate = this.queryModel.endDate;
      _activityResourceQueryModel.isGroupActivity = true;
        
      return Promise.all([
        service.query(queryModel),
        _activityResourceService.query(_activityResourceQueryModel)
      ])
        .then(([jobAllocationResult, activityResourceResult]) => {
          this.hasResult = true;
          this.calendarData = {
            jobAllocations: (jobAllocationResult || []).map(jobAllocation => {
              jobAllocation.start = jobAllocation.start || jobAllocation.job.start;
              jobAllocation.finish = jobAllocation.end || jobAllocation.job.finish;
              jobAllocation.canCallOut = this.adminSettings.enableResourceCallOut;
              return jobAllocation;
            }),
            activities: (activityResourceResult || []).map(activityResource => {
              activityResource.name = activityResource.activity.activityTitle;
              activityResource.start = activityResource.start || activityResource.activity.start;  
              activityResource.finish = activityResource.finish || activityResource.activity.finish;
              activityResource.objectType = 'activity';
              activityResource.canCallOut = this.adminSettings.enableResourceCallOut;
              return activityResource;  
            })
          }
        })
        .catch(error => this.exceptionHandler(error))
        .finally(() => {
          this.hideLoading();
        });
    })
  }

  refresh() {
    return this.getResourceData();
  }
  
  /* Operation Record modal */
  handleShowOperationRecordModal(event) {
    this.operationRecordModalData = {
      isOpen: true,
      job: event.model.job,
      jobAllocation: event.model
    }
  }
  
  handleCloseOperationRecordModal() {
    this.operationRecordModalData = {};
  }

  /* Site Feedback modal */
  handleShowSiteFeedbackModal(event) {
    this.siteFeedbackModalData = {
      isOpen: true,
      job: event.model.job
    }
  }
  
  handleCloseSiteFeedbackModal() {
    this.siteFeedbackModalData = {};
  }

  /* Call out modal */
  handleShowCallOutModal(event) {
    this.callOutModalData = {
      isOpen: true,
      record: event.model,
      resourceId: event.model.resourceId,
      driveDate: event.model.startDate,
      duration: this.resource.dailyTimeOffHours
    }
  }

  openDriveWorksheetReport(event) {
    this[NavigationMixin.GenerateUrl]({
      type: 'standard__webPage',
      attributes: {
          url: '/apex/generateDriveWorksheetPdf?id=' + event.model.job.driveShiftId
      }
    }).then(url => { window.open(url) });
  }

  handleCloseCallOutModal() {
      this.callOutModalData = {};
  }

  handleSaveCallOutModal(event) {
      const { record } = this.callOutModalData;
      const { callOutType, callOutReason, callOutNotes, callOutReceivedDateTime, timeOffPlan, timeOffReasonCode, usePtoForCallOut, hasTimeOffPlans } = event.detail;

        let params = {
            resourceId: this.resource.id,
            jobId: this.jobId,
            callOutReported: true,
            callOutType: callOutType,
            callOutReason: callOutReason,
            callOutNotes: callOutNotes,
            callOutReceivedDateTime: callOutReceivedDateTime,
            timeOffPlan: timeOffPlan,
            timeOffReasonCode: timeOffReasonCode,
            usePtoForCallOut: usePtoForCallOut,
            hasTimeOffPlans: hasTimeOffPlans
        };

      if(record.objectType === 'jobAllocation') {
        params.jobId = record.jobId;
      }
      
      if(record.objectType === 'activity') {
        params.activityId = record.activityId;
      }
      
      this.showLoading();
      let service = new resourceService();
      service.saveCallOut({
        request: params
      }).then(res => {
        this.dispatchEvent(new ShowToastEvent({
          message: 'Call out successfully.',
          variant: 'success',
          mode: 'dismissable',
        }));

        this.handleCloseCallOutModal();

        return this.refresh();
      })
      .catch(error => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  }

  /* Confirm Modal */
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {...confirmModalData,
        isOpen: true
    }
  }

  hideConfirmModal() {
      this.confirmModalData = {};
  }
}