import TIME_ZONE from '@salesforce/i18n/timeZone';
import USER_ID from "@salesforce/user/Id";
import { activityResourceQueryModel, activityResourceService, resourceQueryModel, resourceService } from 'c/dataService';
import { orderBy } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { classNames, getValueFromEvent } from 'c/slwcUtils';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, api, track } from 'lwc';
import callOutTemplate from './callOut.html';
import searchTemplate from './search.html';
import selectAllocationTemplate from './selectAllocation.html';

const STEP = {
  SEARCH: 1,
  SELECT_ALLOCATION: 2,
  CALL_OUT_FORM: 3,
}

const EVENT_TYPE = {
  ACTIVITY: 'Activity',
  DRIVE: 'Drive'
}

const STEP_SETTINGS = {
  [STEP.SEARCH]: {
    value: STEP.SEARCH,
    label: 'Search',
    validate: function(scope) {
      return scope.validateStepSearch();
    },
    init: function(scope) {
      return scope.initStepSearch();
    },
    render: searchTemplate
  },
  [STEP.SELECT_ALLOCATION]: {
    value: STEP.SELECT_ALLOCATION,
    label: 'Select Activity',
    validate: function(scope) {
      return scope.validateStepSelectAllocation();
    },
    init: function(scope) {
      return scope.initStepSelectAllocation();
    },
    render: selectAllocationTemplate
  },
  [STEP.CALL_OUT_FORM]: {
    value: STEP.CALL_OUT_FORM,
    label: 'Call Out',
    validate: function(scope) {
      return scope.validateStepCallOut();
    },
    init: function(scope) {
      return scope.initStepCallOut();
    },
    render: callOutTemplate
  }
}

export default class slwcMobileActivityCallOut extends LightningElement {
  @api fullScreen = false;

  @track showSpinner = false;
  @track confirmModalData = {};
  @track step = STEP.SEARCH;
  @track timezoneSidId = TIME_ZONE;

  @track filters = {};
  
  @track allocations = [];
  @track selectedAllocationData = null;
  
  @track callOutData = null;
  
  @track resources = [];
  @track filteredResources = [];
  @track selectedResource = null;
  @track selectResourceFilters = {
    searchText: ''
  };
  
  get customClass() {
    return {
      modal: classNames('slds-modal slds-fade-in-open', {
        'full-screen': this.fullScreen
      }),
    }
  }

  get nextButtonDisabled() {
    if(this.step === STEP.SELECT_ALLOCATION) {
      if(!this.selectedAllocationData) return true;
    }

    return false;
  }

  render() {
    return STEP_SETTINGS[this.step].render;
  }

  connectedCallback() {
    this.init();
  }
  
  exceptionHandler = (error) => {
    this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinner = true;
  };

  hideLoading = () => {
    this.showSpinner = false;
  };

  init() {
    this.showLoading();
    Promise.all([
      this.retrieveLoginUserResource()
    ])
    .then(([resource]) => {
      if(!resource) {
        this.showConfirmModal({
          mode: 'error',
          title: 'Error',
          message: 'This screen cannot be loaded as you do not have an Active Resource record associated. Please contact your administrator for assistance.',
          confirmBtnLabel: 'none',
          cancelBtnLabel: 'none'
        });

        return;
      }


      this.initFilters();
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  initFilters() {
    const today = DateTime.fromObject({
      zone: TIME_ZONE
    }).toISODate();

    this.filters = {
      collectionOperation: null,
      eventType: EVENT_TYPE.ACTIVITY,
      eventDate: today,
    }
  }

  retrieveLoginUserResource() {
    let service = new resourceService();
    let query = new resourceQueryModel();
    query.userIds = [USER_ID];
    return service.query(query)
    .then(([resource]) => {
      this.resource = resource;
      return resource;
    })
  }

  handleBack(initAgain = false) {
    this.step = this.step - 1;

    if(initAgain === true) {
      this.showLoading();
      STEP_SETTINGS[this.step].init(this)
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }
  }

  handleNext(event, forceStep) {
    this.showLoading();
    STEP_SETTINGS[this.step].validate(this)
    .then(result => {
      if(!result) {
        return;
      }

      this.step = forceStep ?? (this.step + 1);
      return STEP_SETTINGS[this.step].init(this);
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleFiltersChanged(event) {
    event.stopPropagation();

    if(event.detail && event.detail.selection) {
      this.filters[event.currentTarget.name] = event.detail.selection;
    } else {
      let value = getValueFromEvent(event);
      this.filters[event.currentTarget.name] = value;
    }
  }

  initStepSearch = () => {
    return Promise.resolve();
  }

  validateStepSearch = () => {
    return Promise.resolve()
    .then(() => {
      const allValid = [
        ...this.template.querySelectorAll('lightning-input'), 
        ...this.template.querySelectorAll('c-slwc-multi-picklist'),
        ...this.template.querySelectorAll('c-slwc-lookup'),
        ...this.template.querySelectorAll('lightning-radio-group')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

      return allValid;
    })
  }

  initStepSelectAllocation = () => {
    //reset values
    this.allocations = [];
    this.selectedAllocationData = null;
    
    return Promise.resolve()
    .then(() => {
      let service = new activityResourceService();
      let queryModel = new activityResourceQueryModel();
      queryModel.startDate = this.filters.eventDate;
      queryModel.endDate = this.filters.eventDate;
      queryModel.collectionOperationIds = this.filters.collectionOperation ? [this.filters.collectionOperation.id] : [];
      queryModel.resourceIds = [this.resource.id];
      return service.query(queryModel)
        .then((result = []) => {      
          result = orderBy(result, ['startDate', (item) => {
            return item.activity.activityTitle || item.activity.name;
          }], ['asc', 'asc']);
          this.allocations = result;
        });
    })
  }

  validateStepSelectAllocation = () => {
    return Promise.resolve(!!this.selectedAllocationData)
  }

  handleSelectAllocation = (event) => {
    const { id } = event.currentTarget.dataset;
    const allocation = this.allocations.find(item => item.id === id);

    if(!allocation) return;

    this.selectedAllocationData = {
      activityResourceId: allocation.resourceId,
      activityResource: allocation,
      activity: allocation.activity,
      callOutModalData: {
        driveDate: allocation.activity.startDate,
        resourceId: allocation.resourceId,
        duration: allocation.resource?.dailyTimeOffHours
      }
    };

    this.handleNext();
  }

  initStepCallOut = () => {
    //reset values
    this.callOutData = null;
 
    return Promise.resolve()
    .then(() => {
      let service = new resourceService();
      let queryModel = new resourceQueryModel();
      queryModel.recordIds = [this.selectedAllocationData.callOutModalData.resourceId];
      return service.query(queryModel)
        .then(([resource]) => {
          this.selectedAllocationData.callOutModalData.duration = resource.dailyTimeOffHours;
        });
    })
  }

  handleBackCallOutModal = () => {
    this.handleBack();
  }

  validateStepCallOut = () => {
    return Promise.resolve(true)
  }

  handleSaveCallOutModal = (event) => {
    const { callOutType, callOutReason, callOutNotes, callOutReceivedDateTime, timeOffPlan, timeOffReasonCode, usePtoForCallOut, hasTimeOffPlans } = event.detail;

    let params = {
      resourceId: this.selectedAllocationData.callOutModalData.resourceId,
      activityId: this.selectedAllocationData.activity.id,
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

    this.showLoading();
    let service = new resourceService();
    return service.saveCallOut({
      request: params
    })
    .then((res) => {
      this.handleNext(null, STEP.SEARCH);
    })
    .catch(error => this.exceptionHandler(error))
    .finally(() => this.hideLoading());
  }

  /** Confirm Modal **/
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {
      ...confirmModalData,
      isOpen: true
    }
  }

  hideConfirmModal() {
    this.confirmModalData = {};
  }
}