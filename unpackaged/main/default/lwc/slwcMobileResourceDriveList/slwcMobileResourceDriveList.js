import { LightningElement, track } from 'lwc';
import { resourceService, resourceQueryModel, resourceSecondaryCollectionOperationService, resourceSecondaryCollectionOperationQueryModel, jobAllocationService, jobAllocationQueryModel } from 'c/dataService';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getValueFromEvent } from 'c/slwcUtils';
import { orderBy, groupBy, compact } from 'c/lodash';
import { JOB_ALLOCATION_STATUS, RESOURCE_TYPE } from 'c/slwcConstants';
import * as slwcDateUtils from 'c/slwcDateUtils';
import searchTemplate from './search.html';
import jobAllocationsTemplate from './jobAllocations.html';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import USER_ID from "@salesforce/user/Id";

const STEP = {
  SEARCH: 1,
  JOB_ALLOCATIONS: 2
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
  [STEP.JOB_ALLOCATIONS]: {
    value: STEP.JOB_ALLOCATIONS,
    label: 'Job Allocations',
    validate: function(scope) {
      return Promise.resolve(true);
    },
    init: function(scope) {
      return scope.initStepViewJobAllocations();
    },
    render: jobAllocationsTemplate
  }
}

export default class SlwcMobileResourceDriveList extends LightningElement {
  @track showSpinner = false;
  @track confirmModalData = {};
  @track step = STEP.SEARCH;

  @track timezoneSidId = TIME_ZONE;
  @track filters = {};
  @track resource = null;
  @track jobAllocations = [];

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
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
    .then(() => {
      if(!this.resource) {
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
    this.filters = {
      driveTypes: ['Fixed Site', 'Mobile'],
      driveDate: null
    }
  }

  retrieveLoginUserResource() {
    let service = new resourceService();
    let query = new resourceQueryModel();
    query.userIds = [USER_ID];
    // query.userIds = ['0053F000003lc8AQAQ'];
    return service.query(query)
    .then(([resource]) => {
      this.resource = resource;
      return resource;
    })
  }

  handleBack(event, initAgain = false) {
    this.step = this.step - 1;

    if(initAgain) {
      this.showLoading();
      STEP_SETTINGS[this.step].init(this)
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }
  }

  handleNext(event, currentStep) {
    if(!currentStep) {
      currentStep = this.step;
    }
    this.showLoading();
    STEP_SETTINGS[currentStep].validate(this)
    .then(result => {
      if(!result) {
        return;
      }

      this.step = currentStep + 1;
      return STEP_SETTINGS[this.step].init(this);
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleFiltersChanged(event) {
    event.stopPropagation();

    if (event.type === 'weekdatechange') {
      this.filters = {
        ...this.filters, 
        startDate: event.detail.startDate,
        endDate: event.detail.endDate
      }
    } else if(event.detail && event.detail.selection) {
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
        ...this.template.querySelectorAll('c-slwc-lookup')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

      return allValid;
    })
  }

  initStepViewJobAllocations = () => {
    //reset values
    this.jobAllocations = [];

    return Promise.resolve()
    .then(() => {
      let resourceSecondaryCOService = new resourceSecondaryCollectionOperationService();
      let resourceSecondaryCOQueryModel = new resourceSecondaryCollectionOperationQueryModel();
      resourceSecondaryCOQueryModel.resourceIds = [this.resource.id];
      resourceSecondaryCOQueryModel.startDate = this.filters.driveDate;
      resourceSecondaryCOQueryModel.endDate = this.filters.driveDate;
      
      return resourceSecondaryCOService.query(resourceSecondaryCOQueryModel);
    })
    .then((resourceSecondaryCOs = []) => {
      const primaryCOId = this.resource.collectionOperationId;
      const secondaryCOIds = resourceSecondaryCOs.map(item => item.collectionOperationId);

      let service = new jobAllocationService();
      let queryModel = new jobAllocationQueryModel();

      queryModel.driveTypes = this.filters.driveTypes;
      queryModel.resourceTypes = [RESOURCE_TYPE.PERSON];
      queryModel.excludedResourceIds = [this.resource.id];
      queryModel.collectionOperationIds = [primaryCOId].concat(secondaryCOIds);
      queryModel.startDate = this.filters.driveDate;
      queryModel.endDate = this.filters.driveDate;
      queryModel.statuses = [JOB_ALLOCATION_STATUS.DISPATCHED, JOB_ALLOCATION_STATUS.CONFIRMED, JOB_ALLOCATION_STATUS.EN_ROUTE, JOB_ALLOCATION_STATUS.CHECKED_IN, JOB_ALLOCATION_STATUS.IN_PROGRESS];

      return service.query(queryModel)
      .then((result = []) => {
        this.jobAllocations = orderBy(result, ['start', 'end'], ['asc', 'asc']);
      })
    })
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