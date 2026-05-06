import { LightningElement, track, api } from "lwc";
import {
  jobQueryModel,
  jobService,
  activityQueryModel,
  activityService,
  activityCollectionOperationService,
  activityCollectionOperationQueryModel,
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

    // Query activities for "After Hours Call Out Management" type
    // Filter by collection operation, activity's start/end should cover the job start date
    // and include activity resources
    const activityCollectionOperationSvc = new activityCollectionOperationService();
    const activityCollectionOperationQuery = new activityCollectionOperationQueryModel();
    const startDate = DateTime.fromISO(this.job.start).toISODate();

    activityCollectionOperationQuery.collectionOperationIds = [this.job.collectionOperationId];
    activityCollectionOperationQuery.startDate = startDate;
    activityCollectionOperationQuery.endDate = startDate;
    activityCollectionOperationQuery.activityTypes = ["After Hours Call Out Management"];

    return activityCollectionOperationSvc.query(activityCollectionOperationQuery)
      .then((activityCOs) => {
        const activitySvc = new activityService();
        const activityQuery = new activityQueryModel();

        activityQuery.recordIds = (activityCOs || []).map(activityCO => activityCO.activityId);
        activityQuery.subQueryIndicator = sObjectType.ACTIVITY_RESOURCE;

        if (!activityQuery.recordIds.length) {
          return Promise.resolve([]);
        }

        return activitySvc.query(activityQuery).then((activities) => {
          this.activityResources = (activities || [])
            .flatMap((activity) =>
              (activity.activityResources || []).map((ar) => ({
                id: activity.id,
                resource: ar.resource || {},
              }))
            );
        });
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