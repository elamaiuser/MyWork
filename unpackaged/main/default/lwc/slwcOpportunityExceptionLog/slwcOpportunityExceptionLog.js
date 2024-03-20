import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { opportunityService, opportunityQueryModel, driveService, driveQueryModel, sObjectType } from 'c/dataService';

export default class SlwcOpportunityExceptionLog extends LightningElement {
  @api recordId;

  @track drive = null;
  @track masterData = {
    isReadonly: false,
  }
  @track showSpinner = false;
  
  /* PAGE REFERENCE */
  @wire(CurrentPageReference) pageRef;

  get showAlert() {
    return !this.showSpinner && !this.drive;
  }
  connectedCallback() {
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
  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }
  initialize(recordId) {
    console.log("initialize");
    if (!recordId) return;
    
    this.showLoading();
    Promise.resolve()
      .then(() => {
        if (recordId.startsWith("006")) {
          return this.initializeFromOptyId(recordId);
        } else {
          return this.initializeFromDriveId(recordId);
        }
      })

      .catch(error => console.log(error))
      .finally(this.hideLoading);
  }
  initializeFromOptyId(oppId) {
    let queryModel = new opportunityQueryModel();
    queryModel.recordIds = [oppId];
    queryModel.subQueryIndicator = sObjectType.DRIVE | sObjectType.OPPORTUNITY_CONTACT_ROLE;
    let service = new opportunityService();

    this.showLoading()
    return service.query(queryModel)
      .then((result) => {
        let opp = result[0];
        if (!opp.drives) {
        }
        else {
          let drive = opp.drives[0];
          return this.getDriveDetails(drive.id);
        }
      })
      .catch(error => console.log(error))
      .finally(this.hideLoading);
  }
  initializeFromDriveId(driveId) {
    this.showLoading()
    return this.getDriveDetails(driveId)
      .catch(error => console.log(error))
      .finally(this.hideLoading);
  }
  getDriveDetails(recordId) {
    let service = new driveService();
    let queryModel = new driveQueryModel();
    queryModel.recordIds = [recordId];

    this.showLoading();
    return service.query(queryModel)
      .then((result) => {
        this.drive = result[0];
        this.masterData.isReadonly = this.drive.status === 'Confirmed';
      })
      .catch(error => console.log(error))
      .finally(this.hideLoading);
  }
}