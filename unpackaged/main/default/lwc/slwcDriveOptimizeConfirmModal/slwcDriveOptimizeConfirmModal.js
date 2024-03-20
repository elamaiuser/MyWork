import { LightningElement, api, track } from 'lwc';
import { classNames } from 'c/slwcUtils';
import { pick, cloneDeep, extend, orderBy } from 'c/lodash';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { collectionOperationQueryModel, collectionOperationService, optimizationRunService } from 'c/dataService';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcUtils from 'c/slwcUtils';

const TABS = {
  DRIVE_LIST: 'driveList',
  SETTINGS: 'settings'
};

export default class SlwcDriveOptimizeConfirmModal extends LightningElement {
  _isOpen = false;
  @api 
  get isOpen() {
    return this._isOpen;
  };
  set isOpen(value) {
    this._isOpen = value;

    if(!!value) {
      setTimeout(() => {
        this.initialize();
      });
    }
  }
  @api drives = [];
  @api collectionOperationId = null;
  @api handleOnClose = null;
  @api startDate;
  @api endDate; 
  
  @track showSpinner = false;

  defaultSettings = null;
  @track settings = null;
  @track driveList = [];
  @track selectedDriveIds = [];
  @track currentTab = TABS.DRIVE_LIST;

  get TABS() {
    return TABS;
  }

  get columns() {
    let results = [];
    results.push({ label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true });
    results.push({ label: 'Drive Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }, hideDefaultActions: true });
    results.push({ label: 'Optimization Status', fieldName: 'optimizationStatus', type: 'text', hideDefaultActions: true, wrapText: true });
    results.push({ label: 'Event Type', fieldName: 'typeOfDrive', type: 'text', hideDefaultActions: true, wrapText: true });
    results.push({ label: 'Vehicle Types', fieldName: 'vehicleTypes', type: 'text', hideDefaultActions: true, wrapText: true });
    results.push({ label: 'Min Shift Start', fieldName: 'minShiftStart', type: 'date', typeAttributes: { hour: "numeric", minute: "2-digit", timeZone: TIME_ZONE }, hideDefaultActions: true });
    results.push({ label: 'Max Shift End', fieldName: 'maxShiftEnd', type: 'date', typeAttributes: { hour: "numeric", minute: "2-digit", timeZone: TIME_ZONE }, hideDefaultActions: true });
    results.push({ label: 'Staff Requested', fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true });
    results.push({ label: 'Staff Scheduled', fieldName: 'staffAllocated', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true });
    return results;
  }

  get customClass() {
    return {
      modalClass: classNames('slds-modal', 'slds-modal_large', {
        'slds-fade-in-open': this.isOpen
      }),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      }),
      driveListTab: slwcUtils.classNames('slds-tabs_default__item', {
        'slds-is-active': this.showDriveListTab
      }),
      settingsTab: slwcUtils.classNames('slds-tabs_default__item', {
          'slds-is-active': this.showSettingsTab
      })
    }
  }

  get showDriveListTab() {
    return this.currentTab === TABS.DRIVE_LIST;
  }

  get showSettingsTab() {
    return this.currentTab === TABS.SETTINGS;
  }

  get btnRemoveLabel() {
    return `Remove (${this.selectedDriveIds.length} selected)`;
  }

  get btnRemoveDisabled() {
    return this.selectedDriveIds.length === 0;
  }

  connectedCallback() {
  }

  initialize() {
    this.currentTab = TABS.DRIVE_LIST;
    this.getDefaultSettings()
      .then(() => {
        this.initialized = true;
        this.settings = cloneDeep(this.defaultSettings);
        this.driveList = orderBy([...this.drives], ['driveDate', 'minShiftStart', 'maxShiftEnd'], ['asc', 'asc', 'asc']);
      })
  }

  getDefaultSettings() {
    let query = new collectionOperationQueryModel();
    query.recordIds = [this.collectionOperationId];
    let service = new collectionOperationService();
    this.showSpinner = true;
    return service.query(query)
      .then((result) => {
        const fields = [
          'accountPreferencesScore',
          'geographicPreferencesScore',
          'locationPreferencesScore',
          'seniorityRankScore',
          'accountRestrictions',
          'locationRestrictions',
          'maximumWeeklyHours',
          'ptoAvailability',
          'roleCertificationMatch',
          'rolePriorities'
        ]
        this.defaultSettings = pick(result[0], fields);
      })
      .finally(() => this.showSpinner = false);
  }

  handleRowSelection(event) {
    this.selectedDriveIds = (event.detail.selectedRows || []).map(item => item.id);
  }

  handleRemove() {
    if (this.selectedDriveIds.length === this.driveList.length) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'Need at least 1 drive to optimize.',
        variant: 'error',
        mode: 'dismissable'
      }));
      return;
    }

    this.driveList = this.driveList.filter(item => !this.selectedDriveIds.includes(item.id));
    this.selectedDriveIds = [];
  }

  handleOnSettingChange(event) {
    this.settings = extend(this.settings, event.detail);
  }

  handleTabChange(event) {
    const newTab = event.currentTarget.dataset['value'];
    this.currentTab = newTab;
    this.selectedDriveIds = []
  }
  handleConfirm = () => {
    this.showSpinner = true;
    return Promise.resolve()
      .then(() => {
        let service = new optimizationRunService();
        return service.initiateOptimizationRun({
          request: {
            driveIds: this.driveList.map(item => item.id),
            startDate: this.startDate,
            endDate: this.endDate,
            optimizationSetting: this.settings
          }
        })
      })
      .then(() => {
        this.dispatchEvent(new ShowToastEvent({
          message: 'The Optimization Batch has kicked off, you will receive an email alert when the process has been completed.',
          variant: 'success',
          mode: 'dismissable'
        }));

        if (this.handleOnClose) {
          this.handleOnClose(true);
        }
        this.isOpen = false;
      })
      .catch((error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
      })
      .finally(() => {
        this.showSpinner = false;
      })
  }

  handleClose = () => {
    if (this.handleOnClose) {
      this.handleOnClose(false);
    }
    this.isOpen = false;
  }
}