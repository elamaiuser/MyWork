import { LightningElement, api, track } from 'lwc';
import { classNames } from 'c/slwcUtils';
import { pick, cloneDeep, orderBy, groupBy, uniqueId } from 'c/lodash';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { optimizationRunService, collectionOperationOptimizerSettingQueryModel, collectionOperationOptimizerSettingService, dataService } from 'c/dataService';
import SelectDrives from "./selectDrives.html";
import ConfigureOptimization from "./configureOptimization.html";
import { OPTIMIZER_SETTING_DISPLAY_TYPE } from 'c/slwcConstants';

export default class SlwcDriveOptimizeConfirmModal extends LightningElement {
  _isOpen = false;
  _defaultOptimizationSettings;

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
  @track optimizationSettings = [];
  @track settings = null;
  @track driveList = [];
  @track driveGroups = [];
  @track selectedDrives = [];

  get customClass() {
    return {
      modalClass: classNames('slds-modal', 'slds-modal_large', {
        'slds-fade-in-open': this.isOpen
      }),
      backdropClass: classNames('slds-backdrop', {
        'slds-backdrop_open': this.isOpen
      })
    }
  }

  initialize() {
    this.step = this.ALLSTEP.STEP1.value;
    this.showSpinner = true;
   
    return Promise.all([
        this.getOptimizerSettings(),
        this.getDefaultSettings()
      ])
      .then(([optimizerSettings, defaultSettings]) => {
        this.defaultSettings = defaultSettings.returnedData.optimizerDefaultSettings.optimizerSettings
          .map(setting => {
            return {
              ...setting,
              id: uniqueId()
            }
        });
        this.driveList = orderBy(cloneDeep(this.drives), ['driveDate', 'minShiftStart', 'maxShiftEnd'], ['asc', 'asc', 'asc']);
        this.driveList.forEach((drive) => {
          drive.collectionOperation.collectionOpOptimizerSettings = optimizerSettings.filter(item => item.collectionOperation.id === drive.collectionOperationId);
        });
        this.groupDrives();
      })
      .finally(() => this.showSpinner = false);
  }

  clear() {
    this.driveGroups = [];
    this.selectedDrives = [];
    this.settings = [];
  }

  getDefaultSettings() {
    let _dataService = new dataService();
    return _dataService.getCustomSettings({ settingKeys: ["optimizerDefaultSettings"]});
  }

  getOptimizerSettings() {
    let service = new collectionOperationOptimizerSettingService();
    let query = new collectionOperationOptimizerSettingQueryModel();
    query.collectionOperationIds = this.drives.map(item => item.collectionOperation.id);
    return service.query(query);
  }

  findConstraint(id) {
    return this.optimizationSettings.find(item => item.id === id);
  }
  
  handleOnSettingChange(event) {
    let constraint = this.findConstraint(event.detail.id);
    if(!constraint) {
      return;
    }

    if(constraint.displayType === OPTIMIZER_SETTING_DISPLAY_TYPE.PICKLIST) {
      constraint.defaultWeight = event.detail.value || "";
    } else if(constraint.displayType === OPTIMIZER_SETTING_DISPLAY_TYPE.CHECKBOX) {
      constraint.enabled = event.detail.value;
    }
  }

  handleOnSettingReset() {
    this.optimizationSettings = cloneDeep(this._defaultOptimizationSettings);
  }

  handleConfirm = () => {
    this.showSpinner = true;

    return Promise.resolve()
      .then(() => {
        let service = new optimizationRunService();
        return service.initiateOptimizationRun({
          request: {
            driveIds: this.selectedDrives.map(item => item.id),
            startDate: this.startDate,
            endDate: this.endDate,
            optimizationSettings: this.optimizationSettings
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
        this.clear();
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

    this.clear();
    this.isOpen = false;
  }

  ALLSTEP = {
    STEP1: {
      label: "Select Drives",
      value: 1,
      function: () => {},
      render: () => SelectDrives
    },
    STEP2: {
      label: "Configure Optimization",
      value: 2,
      function: () => {},
      render: () => ConfigureOptimization
    }
  }

  step = this.ALLSTEP.STEP1.value;

  @track listStep = [
    this.ALLSTEP.STEP1,
    this.ALLSTEP.STEP2
  ];

  get stepLabel() {
    const step = Object.values(this.ALLSTEP).find(item => item.value === this.step);
    return (step || {}).label;
  }

  get stepHeader() {
    if (!this.model) return null;
    return `Optimization Confirmation`;
  }

  get isStep1() {
    return this.step === 1;
  }

  get isStep2() {
    return this.step === 2;
  }

  get mode() {
    return "STEP" + this.step;
  }

  get disabledNext() {
    return this.isStep2;
  }

  get showPrevious() {
    return !this.isStep1;
  }

  handleNext() {
    if (this.step < this.listStep.length) {
      this.step += 1;
    }
    
    this.ALLSTEP[this.mode].function();
  }

  handlePrev() {
    this.step -= 1;
  }

  render() {
    return this.ALLSTEP[this.mode].render();
  }

  groupDrives() {
    let driveGroupsByKey = groupBy(this.driveList, (drive) => this.getDriveOptimizationSettingKey(drive));
    this.driveGroups = Object.keys(driveGroupsByKey).map((key, index) => {
      return {
        key: key,
        name: `Group ${index + 1}`,
        drives: driveGroupsByKey[key]
      };
    });
  }

  getCollectionOperationOptimizerSettings(collectionOperation, driveType) {
    let collectionOpOptimizerSettings = collectionOperation.collectionOpOptimizerSettings.length > 0
      ? collectionOperation.collectionOpOptimizerSettings
      : this.defaultSettings;

    return collectionOpOptimizerSettings.filter(item => item.driveType === driveType);
  }

  getDriveOptimizationSettingKey(drive) {
    let optimizerSetting = this.getCollectionOperationOptimizerSettings(drive.collectionOperation, drive.typeOfDrive)
      .map(setting => pick(setting, ['constraint', 'constraintType', 'defaultWeight', 'enabled', 'optimizerMappedWeight']));
    
    return JSON.stringify(optimizerSetting);
  }

  handleOptimize(event) {
    this.selectedDrives = event.detail.selectedDrives;

    let collectionOpOptimizerSettings = this.getCollectionOperationOptimizerSettings(this.selectedDrives[0].collectionOperation, this.selectedDrives[0].typeOfDrive);
    this.optimizationSettings = orderBy(collectionOpOptimizerSettings.map(item => 
      {
        return  {
          ...item,
          displayOrder: item.displayOrder ?? Number.MAX_VALUE
        }
      }),
      ["displayOrder"],
      ["asc"]);
    this._defaultOptimizationSettings = cloneDeep(this.optimizationSettings);
    this.handleNext();
  }
}