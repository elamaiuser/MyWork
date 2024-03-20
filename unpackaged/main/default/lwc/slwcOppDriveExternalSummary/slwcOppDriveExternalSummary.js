import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { sObjectType, accountBridgeApiService, accountBridgeApiQueryModel, 
  driveService, driveQueryModel,
  driveBridgeApiService, driveBridgeApiQueryModel,
  siteBridgeApiService, siteBridgeApiQueryModel } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SlwcOppDriveExternalSummary extends LightningElement {
  @api recordId;

  @track showSpinner = false;
  @track driveExternalData = [];

  get pageHeader() {
    return `External Data`;
  }

  /* PAGE REFERENCE */
  @wire(CurrentPageReference) pageRef;

  connectedCallback() {
    //this.recordId = 'a1Z2i000001ihRc';

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
    this.refreshData()
  }

  refreshData() {
    this.showLoading();
    Promise.resolve()
      .then(() => {
        let driveQuery = new driveQueryModel();
        driveQuery.recordIds = [this.recordId];

        let driveSvc = new driveService();
        return driveSvc.query(driveQuery);
      })
      .then(([drive]) => {
        let driveBridgeSvc = new driveBridgeApiService();
        let driveBridgeQueryModel = new driveBridgeApiQueryModel();
        driveBridgeQueryModel.driveIds = [this.recordId];
        //driveBridgeQueryModel.driveIds = ['a2j760000008eGlAAI'];

        let accountBridgeSvc = new accountBridgeApiService();
        let accountBridgeQueryModel = new accountBridgeApiQueryModel();
        accountBridgeQueryModel.accountIds = [drive.accountId];
        //accountBridgeQueryModel.accountIds = ['00176000009kZs7AAE'];

        let siteBridgeSvc = new siteBridgeApiService();
        let siteBridgeQueryModel = new siteBridgeApiQueryModel();
        siteBridgeQueryModel.siteIds = [drive.driveSiteId];
        //siteBridgeQueryModel.siteIds = ['a1L76000000HYhrEAG'];

        return Promise.all([
          accountBridgeSvc.query(accountBridgeQueryModel),
          driveBridgeSvc.query(driveBridgeQueryModel),
          siteBridgeSvc.query(siteBridgeQueryModel)
        ])
      })
      .then(([accountBridgeResult, driveBridgeResult, siteBridgeResult]) => {
        let result = [];

        if (accountBridgeResult && accountBridgeResult.length) {
          accountBridgeResult.forEach((item) => {
            item.type = 'Account'
          });
          result = result.concat(accountBridgeResult);
        }
        if (driveBridgeResult && driveBridgeResult.length) {
          driveBridgeResult.forEach((item) => {
            item.type = 'Drive'
          });
          result = result.concat(driveBridgeResult);
        }
        if (siteBridgeResult && siteBridgeResult.length) {
          siteBridgeResult.forEach((item) => {
            item.type = 'Site'
          });
          result = result.concat(siteBridgeResult);
        }
        this.driveExternalData = result;
      })
      .catch(error => this.exceptionHandler(error))
      .finally(this.hideLoading);
  }
}