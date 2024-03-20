import { LightningElement, track, api, wire } from "lwc";
import { classNames, getValueFromEvent } from "c/slwcUtils";
import * as slwcDateUtils from "c/slwcDateUtils";
import TIME_ZONE from "@salesforce/i18n/timeZone";
import { DriveHelper } from "c/slwcDriveGenerator";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { cloneDeep, groupBy } from "c/lodash";
import {
  staffingConstraintQueryModel,
  staffingConstraintService,
  driveQueryModel,
  driveService,
  activityQueryModel,
  activityService
} from "c/dataService";
import { DRIVE_STATUS } from "c/slwcConstants";

const KEY_SEPERATOR = "__";

export default class SlwcAddStaffingConstraintModal extends LightningElement {
  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  }
  set isOpen(value) {
    this._isOpen = value;
  }

  driveHelper = new DriveHelper();

  @api drive = null;
  @api staffingConstraint = null;
  @api isCreateIndividually = false;

  @track totalStaffRequested = 0;
  @track totalFixedSiteStaffRequested = 0;
  @track totalMobileStaffRequested = 0;

  @track existingStaffingConstraints = [];
  @track mappedStaffingConstraintData = null;
  @track mappedDriveData = null;
  @track mappedActivityData = null;

  @track model = {
    collectionOperation: null,
    driveTypes: [],
    dateOfConstraint: null,
    totalStaffConstraints: 0
  };
  @track timezoneSidId = TIME_ZONE;
  @track showSpinner = false;
  @track errorMessages = [];

  @wire(CurrentPageReference) pageRef;

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  get isEditMode() {
    return this.staffingConstraint && this.staffingConstraint.id;
  }

  get modalHeader() {
    if (this.isEditMode) {
      return "Edit Individual Staffing Constraint";
    } else {
      return "Create Individual Staffing Constraint";
    }
  }

  get saveBtnDisabled() {
    return this.showSpinner;
  }

  get isFulfilledFields() {
    return this.model.id || this.isCreateIndividually;
  }

  get isDriveTypesFieldReadonly() {
    return this.isFulfilledFields && this.model.driveTypes.length > 0;
  }

  get isCollectionOperationFieldReadonly() {
    return this.isFulfilledFields && this.model.collectionOperation;
  }

  get isDateOfConstraintFieldReadonly() {
    return this.isFulfilledFields && this.model.dateOfConstraint;
  }

  get customClass() {
    return {
      modalClass: classNames(
        "slds-modal slds-modal_medium slds-add-staffing-constraint-modal",
        {
          "slds-fade-in-open": this.isOpen
        }
      ),
      headerClass: classNames("slds-modal__header"),
      footerClass: classNames("slds-modal__footer"),
      backdropClass: classNames("slds-backdrop", {
        "slds-backdrop_open": this.isOpen
      }),
      warningIconClass: classNames("slds-add-staffing-constraint-modal__warning-icon"),
      totalStaffConstraintsClass: classNames(
        "slds-size_1-of-2",
        "slds-p-horizontal_small",
        "slds-add-staffing-constraint-modal__total-staff-constraints"
      ),
      totalStaffConstraintWarningMessagesClass : classNames({
        "slds-list_dotted": this.totalStaffConstraintWarningMessages.length > 1
      })
    };
  }

  get showTotalRequestedStaff() {
    return this.model.driveTypes.length === 1 && this.totalStaffRequested;
  }

  get showFixedSiteMobileRequestedStaff() {
    return (
      this.model.driveTypes.length > 1 &&
      (this.totalFixedSiteStaffRequested || this.totalMobileStaffRequested)
    );
  }

  get totalStaffConstraintWarningMessages() {
    const warningMessages = [];
    if (
      this.showTotalRequestedStaff &&
      this.totalStaffRequested > this.model.totalStaffConstraints
    ) {
      warningMessages.push("Total staff constraints is less than total staff requested for the drive");
    }

    if (
      this.showFixedSiteMobileRequestedStaff &&
      this.totalFixedSiteStaffRequested > this.model.totalStaffConstraints
    ) {
      warningMessages.push("Total staff constraints is less than staff requested for fixed site drive");
    }

    if (
      this.showFixedSiteMobileRequestedStaff &&
      this.totalMobileStaffRequested > this.model.totalStaffConstraints
    ) {
      warningMessages.push("Total staff constraints is less than staff requested for mobile drive");
    }

    return warningMessages;
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

  exceptionHandler = (error) => {
    console.log(error);
    if (error && error.message) {
      this.dispatchEvent(
        new ShowToastEvent({
          message: error.message,
          variant: "error",
          mode: "dismissable"
        })
      );
    }
  };

  init = () => {
    this.resetModel();
  };

  resetModel = () => {
    this.dataSaved = false;

    if (this.staffingConstraint) {
      this.model = { ...this.model, ...cloneDeep(this.staffingConstraint) };
    }
  };

  handleOnChange(event) {
    event.stopPropagation();

    if (event.detail && event.detail.selection) {
      this.model[event.currentTarget.name] = event.detail.selection;
    } else {
      let value = getValueFromEvent(event);
      this.model[event.currentTarget.name] = value;

      const { collectionOperation, dateOfConstraint, driveTypes } = this.model;

      if (event.currentTarget.name === 'totalStaffConstraints') {
        return;
      }

      if (collectionOperation?.id && dateOfConstraint && driveTypes.length) {
        this.fetchStafingConstrainData();
      }
    }
  }

  handleCancel = () => {
    const closeEvent = new CustomEvent("close", {
      detail: {
        result: !!this.dataSaved
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  };

  async fetchStafingConstrainData() {
    this.showLoading();
    this.existingStaffingConstraints = [];

    const { collectionOperation, dateOfConstraint, driveTypes } = this.model;

    await Promise.resolve()
      .then(() => {
        const staffingConstraintQuery = new staffingConstraintQueryModel();
        staffingConstraintQuery.startDate = dateOfConstraint;
        staffingConstraintQuery.endDate = dateOfConstraint;
        staffingConstraintQuery.collectionOpIds = [collectionOperation?.id];
        staffingConstraintQuery.driveTypes = driveTypes;

        const driveQuery = new driveQueryModel();
        driveQuery.startDate = dateOfConstraint;
        driveQuery.endDate = dateOfConstraint;
        driveQuery.collectionOpIds = [collectionOperation?.id];
        driveQuery.statuses = [
          DRIVE_STATUS.SYSTEM_GENERATED,
          DRIVE_STATUS.TENTATIVE,
          DRIVE_STATUS.CONFIRMED,
          DRIVE_STATUS.HOLD
        ];

        const activityQuery = new activityQueryModel();
        activityQuery.startDate = dateOfConstraint;
        activityQuery.endDate = dateOfConstraint;
        activityQuery.collectionOperationIds = [collectionOperation?.id];
        activityQuery.isGroupActivity = true;
        activityQuery.reduceFromStaffingConstraint = true;

        const staffingConstraintSvc = new staffingConstraintService();
        const driveSvc = new driveService();
        const activitySvc = new activityService();

        return Promise.all([
          staffingConstraintSvc.query(staffingConstraintQuery),
          driveSvc.query(driveQuery),
          activitySvc.query(activityQuery)
        ]);
      })
      .then(([staffingConstraintResult, driveResult, activityResult]) => {
        this.mappedStaffingConstraintData = groupBy(
          [...staffingConstraintResult],
          (item) =>
            `${item.collectionOperationId}${KEY_SEPERATOR}${item.driveType}${KEY_SEPERATOR}${item.dateOfConstraint}`
        );
        this.mappedDriveData = groupBy(
          [...driveResult],
          (item) =>
            `${item.collectionOperationId}${KEY_SEPERATOR}${item.typeOfDrive}${KEY_SEPERATOR}${item.driveDate}`
        );
        this.mappedActivityData = groupBy(
          [...activityResult], 
          (item) =>
            `${item.collectionOperationId}${KEY_SEPERATOR}${item.startDate}`
        );

        const {
          totalFixedSiteStaffRequested,
          totalStaffRequested,
          totalMobileStaffRequested
        } = this.driveHelper.calculateRequestedStaff(
          this.mappedDriveData,
          this.mappedActivityData,
          collectionOperation?.id,
          driveTypes,
          dateOfConstraint
        );

        this.totalFixedSiteStaffRequested = totalFixedSiteStaffRequested;
        this.totalMobileStaffRequested = totalMobileStaffRequested;
        this.totalStaffRequested = totalStaffRequested;

        driveTypes?.forEach((driveType) => {
          const existingStaffingConstraint =
            this.mappedStaffingConstraintData?.[
              `${collectionOperation?.id}${KEY_SEPERATOR}${driveType}${KEY_SEPERATOR}${dateOfConstraint}`
            ]?.[0];

          if (existingStaffingConstraint) {
            this.existingStaffingConstraints.push(existingStaffingConstraint);
          }
        });
      })
      .catch((error) => {
        console.log(error);
      })
      .finally(() => {
        this.hideLoading();
      });
  }

  validate() {
    this.errorMessages = [];

    const allValid = [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("c-slwc-picklist"),
      ...this.template.querySelectorAll("c-slwc-lookup")
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);

    const { totalStaffConstraints, id } = this.model;

    if (this.existingStaffingConstraints?.length && !id) {
      this.errorMessages.push({
        message: "Staffing Constraint record existed"
      });
    }

    return allValid && !this.errorMessages.length;
  }

  handleSave = async () => {
    await this.fetchStafingConstrainData();

    if (!this.validate()) return;

    const {
      id,
      collectionOperation,
      dateOfConstraint,
      driveTypes,
      totalStaffConstraints
    } = this.model;

    const modelsToSave = driveTypes.map((item) => ({
      ...(id && { id }),
      collectionOperationId: collectionOperation?.id,
      dateOfConstraint,
      totalStaffConstraints,
      driveType: item
    }));

    const service = new staffingConstraintService();

    this.showLoading();

    service
      .saveList(modelsToSave)
      .then((result) => {
        if (result?.success) {
          this.dispatchEvent(
            new ShowToastEvent({
              message: `${
                id ? "Edit" : "Create"
              } staffing constraint successfully.`,
              variant: "success",
              mode: "dismissable"
            })
          );

          this.dataSaved = true;

          this.handleCancel();
        }
      })
      .catch((error) => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  };
}