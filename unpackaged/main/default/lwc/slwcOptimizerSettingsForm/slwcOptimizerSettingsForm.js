import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  collectionOperationService,
  collectionOperationQueryModel,
  sObjectType,
  userService,
  dataService
} from "c/dataService";
import { DRIVE_TYPE, OPTIMIZER_SETTING_DISPLAY_TYPE } from "c/slwcConstants";
import { classNames, isNullOrEmpty } from "c/slwcUtils";
import { DriveHelper } from "c/slwcDriveGenerator";
import { orderBy, uniqueId } from "c/lodash";

export default class SlwcOptimizerSettingsForm extends LightningElement {
  driveHelper = new DriveHelper();

  @api recordId;

  @track showSpinner = false;
  @track initialized = false;
  @track collectionOperation;
  @track defaultWeights;
  @track defaultSettings;
  @track loginUser;
  @track readonly = false;
  @track weightLevelSectionExpanded = true; 
  @track mobileSitesSectionExpanded = true; 
  @track fixedSitesSectionExpanded = true;
  @track errorMessages = [];

  get mobileSettings() {
    return this.getOptimizerSettings(DRIVE_TYPE.MOBILE);
  };

  get fixedSiteSettings() {
    return this.getOptimizerSettings(DRIVE_TYPE.FIXED_SITE);
  }

  get customClasses() {
    return {
      weightLevelSection: classNames('slds-section', {
        'slds-is-open': this.weightLevelSectionExpanded
      }),
      mobileSitesSection: classNames('slds-section', {
        'slds-is-open': this.mobileSitesSectionExpanded
      }),
      fixedSitesSection: classNames('slds-section', {
        'slds-is-open': this.fixedSitesSectionExpanded
      })
    }
  }

  getOptimizerSettings(driveType) {
    return orderBy(this.collectionOperation?.collectionOpOptimizerSettings?.filter(item => item.driveType === driveType).map((setting) => {
      return {
        ...setting,
        key: this.getConstraintKey(setting),
        displayOrder: setting.displayOrder ?? Number.MAX_VALUE
      };
    }),
    ["displayOrder"],
    ["asc"]);
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
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  handleWeightChange(event) {
    this.collectionOperation = {
      ...this.collectionOperation,
      ...event.detail
    }
  }

  handleWeightReset() {
    this.collectionOperation = {
      ...this.collectionOperation,
      highWeight: this.defaultWeights.high,
      mediumWeight: this.defaultWeights.medium,
      lowWeight: this.defaultWeights.low
    }
  }

  findConstraint(id) {
    return this.collectionOperation?.collectionOpOptimizerSettings?.find(item => item.id === id);
  }

  getConstraintKey(constraint) {
    return `${constraint.driveType}-${constraint.constraint}`;
  }

  handleConstraintChange(event) {
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

  handleConstraintReset(event) {
    this.collectionOperation.collectionOpOptimizerSettings
      .filter(item => item.driveType === event.detail.driveType)
      .forEach(item => {
        let defaultSetting = this.defaultSettings.find(setting => setting.driveType === item.driveType && setting.constraint === item.constraint);
        if(defaultSetting) {
          if(item.displayType === OPTIMIZER_SETTING_DISPLAY_TYPE.PICKLIST) {
            item.defaultWeight = defaultSetting.defaultWeight;
          } else if(item.displayType === OPTIMIZER_SETTING_DISPLAY_TYPE.CHECKBOX) {
            item.enabled = defaultSetting.enabled;
          }
        }
      });
  }

  validate() {
    this.errorMessages = [];

    if (!isNullOrEmpty(this.collectionOperation.highWeight)
        && this.collectionOperation.highWeight == this.collectionOperation.mediumWeight 
        && this.collectionOperation.mediumWeight == this.collectionOperation.lowWeight) {
      this.errorMessages.push({
        message: 'Low, Medium, and High weights cannot be the same.'
      })
    }

    const allValid = [
      ...this.template.querySelectorAll("c-slwc-optimizer-weight-form"),
      ...this.template.querySelectorAll("c-slwc-optimizer-constraint-form")
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);

    if (!allValid) {
      this.dispatchEvent(
        new ShowToastEvent({
          message: "Please check required fields.",
          variant: "error",
          mode: "dismissable"
        })
      );
    }
    return allValid && !this.errorMessages.length;
  }

  toggleWeightLevelSection = () => {
    this.weightLevelSectionExpanded = !this.weightLevelSectionExpanded;
  }

  toggleFixedSitesSection = () => {
    this.fixedSitesSectionExpanded = !this.fixedSitesSectionExpanded;
  }
  
  toggleMobileSitesSection = () => {
    this.mobileSitesSectionExpanded = !this.mobileSitesSectionExpanded;
  }

  handleSave() {
    if (!this.validate()) {
      return;
    }

    this.showLoading();
    let service = new collectionOperationService();
    service
      .save({
        id: this.collectionOperation.id,
        highWeight: this.collectionOperation.highWeight,
        mediumWeight: this.collectionOperation.mediumWeight,
        lowWeight: this.collectionOperation.lowWeight,
        rolePrioritiesWeight: this.collectionOperation.rolePrioritiesWeight,
        collectionOpOptimizerSettings: this.collectionOperation.collectionOpOptimizerSettings
          .map(item => {
            return {
              ...item,
              id: item.id.startsWith('TEMP_') ? null : item.id,
              optimizerMappedWeight: null
            }
          })
      })
      .then((result) => {
        if(!result.success) throw result;
        const event = new ShowToastEvent({
          message: "Optimizer Setting was updated successfully.",
          variant: "success",
          mode: "dismissable"
        });
        this.dispatchEvent(event);

        this.loadData(false);
      })
      .catch((error) => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  }

  setupAccessPermissions = (loginUser) => {
    if(!loginUser) return;

    if(this.driveHelper.isAdminUser(loginUser)
      || this.driveHelper.isAPSAdmin(loginUser)
      || this.driveHelper.isCollectionManagentUser(loginUser)) {
      this.readonly = false;
      return;
    }

    if(this.driveHelper.isAPSManagement(loginUser)) {
      this.readonly = !loginUser.collectionOperationNames.includes(this.collectionOperation.name);
      return;
    }

    this.readonly = true;
  }

  initDefaultValues(collectionOperation) {
    return {
      ...collectionOperation,
      highWeight: collectionOperation.highWeight || this.defaultWeights.high,
      mediumWeight: collectionOperation.mediumWeight || this.defaultWeights.medium,
      lowWeight: collectionOperation.lowWeight || this.defaultWeights.low,
      collectionOpOptimizerSettings: collectionOperation.collectionOpOptimizerSettings || this.getDefaultOptimizerSettings(),
    };
  }
  
  getDefaultOptimizerSettings() {
    return this.defaultSettings.map(setting => { return {...setting, id: 'TEMP_' + uniqueId()}});
  }

  loadData(isInitilize) {
    let query = new collectionOperationQueryModel();
    query.recordIds = [this.recordId];
    query.subQueryIndicator = sObjectType.COLLECTION_OPERATION_OPTIMIZER_SETTING;

    let service = new collectionOperationService();
    return service.query(query)
      .then(([result]) => {
        if (isInitilize) {
          this.collectionOperation = this.initDefaultValues(result);
          this.setupAccessPermissions(this.loginUser);
        } else {
          this.collectionOperation = result;
        }
      })
  }

  init() {
    this.showLoading();
    
    let _userService = new userService();
    let _dataService = new dataService();
    return Promise.all([
      _userService.getLoginUser(),
      _dataService.getCustomSettings({ settingKeys: ["optimizerDefaultWeights", "optimizerDefaultSettings"]})
    ])
    .then(([loginUserRes, defaultWeights]) => {
      this.loginUser = loginUserRes.returnedData;
      this.defaultWeights = defaultWeights.returnedData.optimizerDefaultWeights;
      this.defaultSettings = defaultWeights.returnedData.optimizerDefaultSettings.optimizerSettings;
      
      return this.loadData(true);
    })
    .catch((error) => this.exceptionHandler(error))
    .finally(() => {
      this.initialized = true;
      this.hideLoading()
    });
  }

  connectedCallback() {
    this.init();
  }
}