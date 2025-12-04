import { LightningElement, track, api } from "lwc";
import {
  jobQueryModel,
  jobService,
  activityQueryModel,
  activityService,
  sObjectType,
} from "c/dataService";
import { DateTime } from "c/luxon";

export default class SlwcMobileCallOutContactInformationForm extends LightningElement {
  @api userId;
  @api jobId;
  @api recordId;

  @track initialized = false;
  @track showSpinner = false;
  @track job;
  @track activityResources = [];
  @track confirmModalData = {};

  get hasActivityResources() {
    return this.activityResources && this.activityResources.length > 0;
  }

  connectedCallback() {
    this.init();
  }

  showLoading = () => {
    this.showSpinner = true;
  };

  hideLoading = () => {
    this.showSpinner = false;
  };

  init() {
    this.showLoading();
    this.retrieveJob()
      .then(() => this.retrieveActivityResources())
      .then(() => (this.initialized = true))
      .catch((error) => this.exceptionHandler(error))
      .finally(this.hideLoading);
  }

  retrieveJob() {
    const service = new jobService();
    const query = new jobQueryModel();
    query.recordIds = [this.jobId];

    return service.query(query).then(([job]) => {
      this.job = job;
      return job;
    });
  }

  retrieveActivityResources() {
    if (!this.job || !this.job.collectionOperationId || !this.job.start) {
      this.activityResources = [];
      return Promise.resolve([]);
    }

    const activitySvc = new activityService();
    const activityQuery = new activityQueryModel();
    const startDate = DateTime.fromISO(this.job.start).toISODate();

    // Query activities for "After Hours Call Out Management" type
    // Filter by collection operation, activity's start/end should cover the job start date
    // and include activity resources
    activityQuery.collectionOperationIds = [this.job.collectionOperationId];
    activityQuery.startDate = startDate;
    activityQuery.endDate = startDate;
    activityQuery.subQueryIndicator = sObjectType.ACTIVITY_RESOURCE;

    return activitySvc.query(activityQuery).then((activities) => {
      this.activityResources = (activities || [])
        .filter(
          (activity) => activity.eventType === "After Hours Call Out Management"
        )
        .flatMap((activity) =>
          (activity.activityResources || []).map((ar) => ({
            id: activity.id,
            resource: ar.resource || {},
          }))
        );
    });
  }

  hideConfirmModal() {
    this.confirmModalData = {};
  }

  exceptionHandler = (error) => {
    this.confirmModalData = {
      mode: "error",
      title: "Error",
      message: error.message,
      confirmBtnLabel: "none",
      cancelBtnLabel: "Close",
      isOpen: true,
      onClose: () => this.hideConfirmModal(),
    };
  };
}
