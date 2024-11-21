import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { slwcDriveGeneratorHelper } from 'c/slwcDriveGenerator';

let driveGeneratorInstance = {
  drive: null,
  masterData: {
    driveTags: {
      accountTags: [],
      locationTags: []
    },
    isReadonly: false,
    lunchBreakSettings: [],
    resourceRoleGroups: null,
    roleTimeData: null,
    roleTimeDetailMap: null,
    roleTimeVarianceMap: {},
    sameDateActivities: [],
    sameDateDrives: [],
    staffingDecisionMatrix: null,
    timezoneSidId: null,
    vehicles: [],
    backupDriveShiftMap: {},
    fieldReadonlyMap: {}
  },
  errorMessages: []
};

export default class SlwcOpportunityLinkedDrives extends LightningElement {
  @api recordId;

  @track drive = null;
  @track showSpinner = false;

  get masterData() {
    return driveGeneratorInstance.masterData;
  }

  get driveHasGenerated() {
    if(!this.recordId) return false;
    return this.drive && this.drive.id;
  }

  /* PAGE REFERENCE */
  @wire(CurrentPageReference) pageRef;

  connectedCallback() {
    // this.recordId = 'a1Z2i000001ihjnEAA';

    if (this.recordId) {
      this.initialize(this.recordId);
    }
  }

  disconnectedCallback() {
  }

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.currentPageReference = currentPageReference;
    let recordId = this.currentPageReference.state.c__recordId;
    this.initialize(recordId);
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

  initialize(recordId) {
    if (!recordId) return;

    this.showLoading();
    Promise.resolve()
      .then(() => {
        return slwcDriveGeneratorHelper.initialize(recordId)
          .then((result) => {
            driveGeneratorInstance = result.driveGeneratorInstance;
            return result.drive;
          })
      })
      .then((drive) => {
        this.drive = drive;
      })
      .catch(error => this.exceptionHandler(error))
      .finally(this.hideLoading);
  }
}