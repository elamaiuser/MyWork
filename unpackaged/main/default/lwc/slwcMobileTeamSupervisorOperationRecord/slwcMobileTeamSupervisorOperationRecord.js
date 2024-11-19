import { LightningElement, track, api } from 'lwc';
import { dataService, resourceService, resourceQueryModel, operationRecordService, operationRecordQueryModel } from 'c/dataService';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getValueFromEvent, classNames } from 'c/slwcUtils';
import { orderBy } from 'c/lodash';
import searchTemplate from './search.html';
import selectOperationRecordTemplate from './selectOperationRecord.html';
import editOperationRecordTemplate from './editOperationRecord.html';
import USER_ID from "@salesforce/user/Id";

const STEP = {
  SEARCH: 1,
  SELECT_OPERATION_RECORD: 2,
  EDIT_OPERATION_RECORD: 3
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
  [STEP.SELECT_OPERATION_RECORD]: {
    value: STEP.SELECT_OPERATION_RECORD,
    label: 'Select Operation Record',
    validate: function(scope) {
      return scope.validateStepSelectOperationRecord();
    },
    init: function(scope) {
      return scope.initStepSelectOperationRecord();
    },
    render: selectOperationRecordTemplate
  },
  [STEP.EDIT_OPERATION_RECORD]: {
    value: STEP.EDIT_OPERATION_RECORD,
    label: 'Edit Operation Record',
    validate: function(scope) {
      return scope.validateStepEditOperationRecord();
    },
    init: function(scope) {
      return scope.initStepEditOperationRecord();
    },
    render: editOperationRecordTemplate
  }
}

export default class SlwcMobileTeamSupervisorOperationRecord extends LightningElement {
  @api fullScreen = false;

  @track showSpinner = false;
  @track confirmModalData = {};
  @track step = STEP.SEARCH;

  @track operationRecordModalData = {}
  @track filters = {};
  @track operationRecords = [];
  @track selectedOperationRecord = null;

  get customClass() {
    return {
      modal: classNames('slds-modal slds-fade-in-open', {
        'full-screen': this.fullScreen
      }),
    }
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
      this.retrieveCustomSettings(),
      this.retrieveLoginUserResource()
    ])
    .then(([{resourceRoleGroups}, resource]) => {
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

      const isTeamSupervisor = this.isTeamSupervisor(resource, resourceRoleGroups);
      if(!isTeamSupervisor) {
        this.showConfirmModal({
          mode: 'error',
          title: 'Error',
          message: 'Only team supervisor resources can access this form.',
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
      collectionOperation: null,
      driveTypes: ['Fixed Site', 'Mobile'],
      driveDate: null,
      ufid: ''
    }
  }

  isTeamSupervisor(resource, resourceRoleGroups) {
    if(!resource || !resourceRoleGroups) return [];

    const teamSupervisorRoles = resourceRoleGroups['Supervisory roles'] || [];
    const resourceRoles = resource.roles ? resource.roles.split(';') : [];

    const hasAnyTeamSupervisorRole = resourceRoles.find(resourceRole => teamSupervisorRoles.includes(resourceRole));
    return !!hasAnyTeamSupervisorRole;
  }

  retrieveCustomSettings() {
    return Promise.resolve()
      .then(() => {
        let service = new dataService();
        return service.getCustomSettings({ settingKeys: ['resourceRoleGroups'] })
          .then((result) => {
            return {
              resourceRoleGroups: result.returnedData.resourceRoleGroups
            }
          })
      });
  }

  retrieveLoginUserResource() {
    let service = new resourceService();
    let query = new resourceQueryModel();
    query.userIds = [USER_ID];
    // query.userIds = ['0053F000003lc8AQAQ'];
    return service.query(query)
    .then(([resource]) => {
      return resource;
    })
  }

  handleBack(initAgain = false) {
    this.step = this.step - 1;

    if(initAgain) {
      this.showLoading();
      STEP_SETTINGS[this.step].init(this)
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }
  }

  handleNext() {
    this.showLoading();
    STEP_SETTINGS[this.step].validate(this)
    .then(result => {
      if(!result) {
        return;
      }

      this.step = this.step + 1;
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

  handleEditOperationRecord(event) {
    const key = event.currentTarget.dataset['key'];
    this.selectedOperationRecord = this.operationRecords.find(item => item.key === key);

    this.handleNext();
  }

  handleCloseOperationRecordModal(event) {
    this.operationRecordModalData = {};
    this.handleBack(event.detail.result);
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

  initStepSelectOperationRecord = () => {
    //reset values
    this.operationRecords = [];
    this.selectedOperationRecord = null;

    return Promise.resolve()
    .then(() => {
      let service = new operationRecordService();
      let queryModel = new operationRecordQueryModel();
      queryModel.driveTypes = this.filters.driveTypes;
      queryModel.driveUfid = this.filters.ufid;
      queryModel.collectionOperationIds = this.filters.collectionOperation ? [this.filters.collectionOperation.id] : [];
      queryModel.driveStartDate = this.filters.driveDate;
      queryModel.driveEndDate = this.filters.driveDate;

      return service.query(queryModel)
      .then((result = []) => {
        this.operationRecords = orderBy(result, ['driveDate', 'driveShiftStartTime'], ['asc', 'asc']);
      })
    })
  }

  validateStepSelectOperationRecord = () => {
    return Promise.resolve(true)
  }

  initStepEditOperationRecord = () => {
    if(!this.selectedOperationRecord) return ;
    
    this.operationRecordModalData = {
      isOpen: true,
      job: {
        collectionOperationId: this.selectedOperationRecord.collectionOperationId,
        driveId: this.selectedOperationRecord.driveId,
        driveShiftId: this.selectedOperationRecord.driveShiftId,
        driveDate: this.selectedOperationRecord.driveDate
      }
    }
  }

  validateStepEditOperationRecord = () => {
    return Promise.resolve(true)
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