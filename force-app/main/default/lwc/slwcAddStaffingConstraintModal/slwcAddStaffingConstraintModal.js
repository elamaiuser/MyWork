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
  activityService,
  collectionOperationTimeBlockQueryModel,
  collectionOperationTimeBlockService,
  sObjectType
} from "c/dataService";
import { DRIVE_TYPE, DRIVE_STATUS } from 'c/slwcConstants';

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

  @track timeBlockOptions = [];
  @track existingStaffingConstraints = [];
  @track mappedStaffingConstraintData = null;
  @track mappedDriveData = null;
  @track mappedActivityData = null;

  @track model = {
    collectionOperation: null,
    timeblockId: null,
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

  get isTimeBlockFieldReadonly() {
    return this.isFulfilledFields && this.model.timeBlockId;
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
    }

    const { collectionOperation, dateOfConstraint, driveTypes } = this.model;

    if (event.currentTarget.name === 'totalStaffConstraints') {
      return;
    }

    if (event.currentTarget.name === 'timeBlockId') {
      this.calculateRequestedStaff();
      return;
    }

    if (collectionOperation?.id && dateOfConstraint) {
      this.fetchTimeBlockData();

      if (driveTypes.length) { 
        this.fetchStafingConstrainData();
      }
    }
  }

  handleCancel = (savedModels = null) => {
    const closeEvent = new CustomEvent("close", {
      detail: {
        result: !!this.dataSaved,
        ...(savedModels && { savedModels })
      }
    });
    this.dispatchEvent(closeEvent);
    this.isOpen = false;
  };

  async fetchTimeBlockData() {
    this.showLoading();
    let timeBlockOptions = [];

    const { collectionOperation, dateOfConstraint } = this.model;

    await Promise.resolve()
      .then(() => {
        const collectionOperationTimeBlockQuery = new collectionOperationTimeBlockQueryModel();
        collectionOperationTimeBlockQuery.effectiveStartDate = dateOfConstraint;
        collectionOperationTimeBlockQuery.effectiveEndDate = dateOfConstraint;
        collectionOperationTimeBlockQuery.collectionOperationIds = [collectionOperation?.id];

        const collectionOperationTimeBlockSvc = new collectionOperationTimeBlockService();

        return Promise.all([
          collectionOperationTimeBlockSvc.query(collectionOperationTimeBlockQuery),
        ]);
      })
      .then(([collectionOperationTimeBlockResult]) => {
        collectionOperationTimeBlockResult.forEach(coTimeBlock => {
          const weekdayLong = this.dateUtils.dateIso2WeeekDay(dateOfConstraint).weekdayLong;
          if (coTimeBlock.timeBlock.daysOfWeek.includes(weekdayLong)) {
            timeBlockOptions.push({
              ...coTimeBlock.timeBlock,
              label: coTimeBlock.timeBlock.name,
              value: coTimeBlock.timeBlock.id
            });
          }
        });

        if (timeBlockOptions.length) {
          timeBlockOptions.unshift({ label: '--None--', value: "" });
        }
        this.timeBlockOptions = timeBlockOptions;
      })
      .catch((error) => {
        console.log(error);
      })
      .finally(() => {
        this.hideLoading();
      });
  }

  async fetchStafingConstrainData() {
    this.showLoading();
    this.existingStaffingConstraints = [];

    const { collectionOperation, dateOfConstraint, driveTypes, timeBlockId } = this.model;

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
        if (timeBlockId) {
          driveQuery.subQueryIndicator = sObjectType.DRIVE_SHIFT
        }

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
            `${item.collectionOperationId}${item.timeBlockId ? KEY_SEPERATOR + item.timeBlockId : ''}${KEY_SEPERATOR}${item.driveType}${KEY_SEPERATOR}${item.dateOfConstraint}`
        );
        this.mappedDriveData = groupBy(
          [...driveResult],
          (item) => {
            let typeOfDrive = this.driveHelper.isFixedSiteDrive(item) ? DRIVE_TYPE.FIXED_SITE : DRIVE_TYPE.MOBILE;
            return `${item.collectionOperationId}${KEY_SEPERATOR}${typeOfDrive}${KEY_SEPERATOR}${item.driveDate}`
          }
        );
        this.mappedActivityData = groupBy(
          [...activityResult], 
          (item) =>
            `${item.collectionOperationId}${KEY_SEPERATOR}${item.startDate}`
        );

        this.calculateRequestedStaff();
      })
      .catch((error) => {
        console.log(error);
      })
      .finally(() => {
        this.hideLoading();
      });
  }

  calculateRequestedStaff() {
    const { collectionOperation, dateOfConstraint, driveTypes, timeBlockId } = this.model;

    const {
      totalFixedSiteStaffRequested,
      totalStaffRequested,
      totalMobileStaffRequested
    } = this.driveHelper.calculateRequestedStaff(
      this.mappedDriveData,
      this.mappedActivityData,
      collectionOperation?.id,
      timeBlockId,
      driveTypes,
      dateOfConstraint
    );

    this.totalFixedSiteStaffRequested = totalFixedSiteStaffRequested;
    this.totalMobileStaffRequested = totalMobileStaffRequested;
    this.totalStaffRequested = totalStaffRequested;

    driveTypes?.forEach((driveType) => {
      const existingStaffingConstraint =
        this.mappedStaffingConstraintData?.[
          `${collectionOperation?.id}${timeBlockId ? KEY_SEPERATOR + timeBlockId : ''}${KEY_SEPERATOR}${driveType}${KEY_SEPERATOR}${dateOfConstraint}`
        ]?.[0];

      if (existingStaffingConstraint) {
        this.existingStaffingConstraints.push(existingStaffingConstraint);
      }
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
      timeBlockId,
      dateOfConstraint,
      driveTypes,
      totalStaffConstraints
    } = this.model;

    const modelsToSave = [];
    driveTypes.forEach(driveType => {
      if (!timeBlockId || driveType !== DRIVE_TYPE.FIXED_SITE) {
        const model = {
          ...(id && { id }),
          collectionOperationId: collectionOperation?.id,
          timeBlockId,
          dateOfConstraint,
          totalStaffConstraints,
          driveType
        }
        modelsToSave.push(model);
      }
    })

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

          this.handleCancel(modelsToSave);
        }
      })
      .catch((error) => this.exceptionHandler(error))
      .finally(() => this.hideLoading());
  };
}