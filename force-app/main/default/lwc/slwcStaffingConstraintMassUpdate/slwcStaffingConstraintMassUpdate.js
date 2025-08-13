import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { DriveHelper } from "c/slwcDriveGenerator";
import { setLastQuery, getLastQuery, classNames, getValueFromEvent } from "c/slwcUtils";
import { DateTime } from "c/luxon";
import * as slwcDateUtils from "c/slwcDateUtils";
import { find, groupBy } from "c/lodash";
import {
  staffingConstraintQueryModel,
  staffingConstraintService,
  driveQueryModel,
  driveService,
  activityQueryModel,
  activityService
} from "c/dataService";
import TIME_ZONE from "@salesforce/i18n/timeZone";
import { DRIVE_STATUS, DRIVE_TYPE } from "c/slwcConstants";
import { sObjectType } from "c/dataService";

const KEY_SEPERATOR = "__";

export default class SlwcStaffingConstraintMassUpdate extends LightningElement {
  driveHelper = new DriveHelper();

  @track filters = {
    collectionOperationValues: {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: [],
      timeBlocks: []
    },
    driveTypes: [DRIVE_TYPE.FIXED_SITE, DRIVE_TYPE.MOBILE],
    startDate: null,
    endDate: null
  };

  @track mappedStaffingConstraintData = null;
  @track mappedDriveData = null;
  @track mappedActivityData = null;

  @track gridData = [];
  @track staffingConstraintModalData = {};
  @track confirmModalData = {};
  @track addRecurrenceStaffingConstraintModalData = {};
  @track editRecurrenceStaffingConstraintModalData = {};

  @track showSpinner = false;
  initialized = false;

  get pageName() {
    return "staffingConstraint:staffingConstraintMassUpdate";
  }

  get customClass() {
    return {
      containerClass: classNames(
        "slds-staffing-constrain-mass-update__container slds-grow"
      )
    };
  }

  get territoryKeys() {
    if (!this.filters || !this.filters.collectionOperationValues) return [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(
      (item) => `${item.territoryId}:${item.collectionOperationId}`
    );
  }

  get collectionOperationDateRange() {
    if (!this.filters || !this.filters.startDate || !this.filters.endDate)
      return {
        startDate: null,
        endDate: null
      };

    return {
      startDate: this.filters.startDate,
      endDate: this.filters.endDate
    };
  }

  get collectionOperations() {
    if (!this.filters || !this.filters.collectionOperationValues) return [];

    return this.filters.collectionOperationValues.territoryCollectionOperations.map(
      (item) => item.collectionOperation
    );
  }

  get collectionOperationFirstDay() {
    if (!this.collectionOperations || !this.collectionOperations.length) return;
    return this.collectionOperations[0].workWeekFirstDay;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  get daysBetweenDateRange() {
    if (!this.filters.startDate || !this.filters.endDate) return [];

    const result = [];

    let startDate = DateTime.fromFormat(this.filters.startDate, 'yyyy-MM-dd');
    const endDate = DateTime.fromFormat(this.filters.endDate, 'yyyy-MM-dd');
    const diff = this.dateUtils.diffDays(startDate, endDate);
    for (let i = 0; i <= diff; i++) {
      let currentDay = DateTime.fromFormat(this.filters.startDate, 'yyyy-MM-dd').plus({
        days: i
      });
      const dateIso = currentDay.toISODate();
      const shortDayName = currentDay.toFormat('ccc');

      result.push({
        day: shortDayName,
        label: currentDay.toFormat('MM/dd/yyyy'),
        dateIso
      });
    }
    
    return result;
  }

  get isTableVisible() {
    return this.daysBetweenDateRange.length > 0;
  }

  buildGridRowHeader() {
    if (!this.collectionOperations.length || !this.filters.driveTypes.length) {
      return [];
    }

    let result = [];

    this.collectionOperations.forEach(collectionOperation => {
      const selectedTimeBlockIds = this.filters.collectionOperationValues.timeBlocks?.map(item => item.value);

      this.filters.driveTypes.forEach(driveType => {
        let coItem = {
          key: `${collectionOperation.name}_${driveType}`,
          collectionOperationId: collectionOperation.id,
          name: collectionOperation.name,
          driveType: driveType
        }
        result.push(coItem);

        if (driveType !== DRIVE_TYPE.FIXED_SITE) {
          collectionOperation.collectionOperationTimeBlocks?.forEach(coTb => {
            if (selectedTimeBlockIds?.includes(coTb.timeBlock.id)) {
              let coTbItem = {
                key: `${collectionOperation.name}_${coTb.timeBlock.name}_${driveType}`,
                collectionOperationId: collectionOperation.id,
                timeBlockId: coTb.timeBlock.id,
                name: `${collectionOperation.name} - ${coTb.timeBlock.name}`,
                driveType: driveType
              }
              result.push(coTbItem);
            }
          })
        }
      })
    });

    return result;
  }

  buildGridData() {
    const gridRowHeader = this.buildGridRowHeader();

    if (!gridRowHeader.length) {
      return [];
    }

    this.gridData = gridRowHeader.reduce((accumulate, currentRow) => {
      const { collectionOperationId, driveType, timeBlockId } = currentRow;

      return [
        ...accumulate,
        {
          ...currentRow,
          rowData: this.daysBetweenDateRange.map(({ dateIso }, itemIndex) => {
            const existingStaffingConstraint =
              this.mappedStaffingConstraintData?.[ 
                `${collectionOperationId}${timeBlockId ? KEY_SEPERATOR + timeBlockId : ''}${KEY_SEPERATOR}${driveType}${KEY_SEPERATOR}${dateIso}`
              ]?.[0];

            const requestedStaff = this.driveHelper.calculateRequestedStaff(
              this.mappedDriveData,
              this.mappedActivityData,
              collectionOperationId,
              timeBlockId,
              [driveType],
              dateIso
            ).totalStaffRequested;

            return {
              key: `${currentRow.key}_${itemIndex}`,
              data: existingStaffingConstraint
                ? {
                    ...existingStaffingConstraint,
                    requestedStaff
                  }
                : null,
              dateIso,
              classNames: classNames(
                "slds-p-around_x-small slds-staffing-constrain-mass-update__cell",
                {
                  "slds-staffing-constrain-mass-update__cell--active":
                    existingStaffingConstraint,
                  "slds-staffing-constrain-mass-update__cell--warning":
                    existingStaffingConstraint &&
                    requestedStaff >
                      existingStaffingConstraint?.totalStaffConstraints
                }
              )
            };
          }, [])
        }
      ];
    }, []);
  }

  connectedCallback() {
    if (!this.initialized) {
      let lastSearchQuery = this.getLastQueryHandler();
      if (lastSearchQuery) {
        this.filters = {
          ...this.filters,
          ...lastSearchQuery
        };
      }

      if (
        !this.filters.collectionOperationValues.territoryCollectionOperations
      ) {
        this.filters.collectionOperationValues.territoryCollectionOperations =
          [];
      }

      if (!this.filters.startDate || !this.filters.endDate) {
        const firstDay = this.dateUtils.getFirstDayValue(
          this.collectionOperationFirstDay
        );
        this.filters.startDate = this.dateUtils
          .startOfWeek(DateTime.local(), firstDay)
          .toISODate();
        this.filters.endDate = DateTime.fromISO(this.filters.startDate)
          .plus({
            day: 13
          })
          .toISODate();
      }

      this.fetchStafingConstrainData();
    }
  }

  getStaffingConstraintMapItem(collectionOperationKey, dateIso) {
    return this.staffingConstraintMapByCODate?.[collectionOperationKey]?.[
      dateIso
    ];
  }

  fetchStafingConstrainData() {
    const territoryKeys = this.territoryKeys;
    const collectionOpIds = this.collectionOperations.map((item) => item.id);

    if (!territoryKeys || !territoryKeys.length || !this.filters.driveTypes.length) {
      this.gridData = [];
      return;
    }

    this.showSpinner = true;

    const isTimeBlockApplied = this.filters.collectionOperationValues.timeBlocks?.length;

    Promise.resolve()
      .then(() => {
        const staffingConstraintQuery = new staffingConstraintQueryModel();
        staffingConstraintQuery.startDate = this.filters.startDate;
        staffingConstraintQuery.endDate = this.filters.endDate;
        staffingConstraintQuery.collectionOpIds = collectionOpIds;
        staffingConstraintQuery.driveTypes = this.filters.driveTypes;

        const driveQuery = new driveQueryModel();
        driveQuery.startDate = this.filters.startDate;
        driveQuery.endDate = this.filters.endDate;
        driveQuery.collectionOpIds = collectionOpIds;
        driveQuery.statuses = [
          DRIVE_STATUS.SYSTEM_GENERATED,
          DRIVE_STATUS.TENTATIVE,
          DRIVE_STATUS.CONFIRMED,
          DRIVE_STATUS.HOLD
        ];
        if (isTimeBlockApplied) {
          driveQuery.subQueryIndicator = sObjectType.DRIVE_SHIFT;
        }

        const activityQuery = new activityQueryModel();
        activityQuery.startDate = this.filters.startDate;
        activityQuery.endDate = this.filters.endDate;
        activityQuery.collectionOperationIds = collectionOpIds;
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
            `${item.collectionOperationId}${ item.timeBlockId ? KEY_SEPERATOR + item.timeBlockId : '' }${KEY_SEPERATOR}${item.driveType}${KEY_SEPERATOR}${item.dateOfConstraint}`
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

        this.buildGridData();
      })
      .catch((error) => {
        console.log(error);
      })
      .finally(() => {
        this.showSpinner = false;
      });
  }

  renderedCallback() {
    if (!this.initialized) {
      this.initialized = true;
    }
  }

  handleSearch(
    event = {
      detail: {}
    }
  ) {
    const { filters } = event.detail;
    this.filters = {
      ...this.filters,
      ...filters,
      territoryKeys: this.territoryKeys
    };
    this.setLastQuery();
  }

  setLastQuery() {
    setLastQuery(this.pageName, this.filters);
  }

  handleCollectionOperationChanged(event) {
    this.filters.collectionOperationValues = {
      divisions: event.detail.selectedDivisions,
      arcRegions: event.detail.selectedARCRegions,
      districts: event.detail.selectedDistricts,
      territoryCollectionOperations:
        event.detail.selectedTerritoryCollectionOperations
    };

    this.handleSearch();
    this.fetchStafingConstrainData();
  }

  handleTimeBlockChanged(event) {
    this.filters.collectionOperationValues = {
      divisions: event.detail.selectedDivisions,
      arcRegions: event.detail.selectedARCRegions,
      districts: event.detail.selectedDistricts,
      territoryCollectionOperations: event.detail.selectedTerritoryCollectionOperations,
      timeBlocks: event.detail.selectedTimeBlocks
    };

    this.handleSearch();
    this.fetchStafingConstrainData();
  }

  handleDriveTypesChanged(event) {
    this.filters = {
      ...this.filters,
      driveTypes: getValueFromEvent(event)
    };
    this.setLastQuery();
    this.fetchStafingConstrainData();
  }

  handleOnWeekDateChange(event) {
    if (event.type === "weekdatechange") {
      this.filters = {
        ...this.filters,
        startDate: event.detail.startDate,
        endDate: event.detail.endDate
      };
      this.setLastQuery();
      this.fetchStafingConstrainData();
    }
  }

  getLastQueryHandler() {
    return {
      ...getLastQuery(this.pageName)
    };
  }

  showStaffingConstraintModal(modalData) {
    this.staffingConstraintModalData = {
      ...modalData,
      isOpen: true
    };
  }

  handleCreateRecurrenceStaffingConstraints = (event) => {
    this.showAddRecurrenceStaffingConstraintModal();
  };

  handleEditRecurrenceStaffingConstraints = (event) => {
    const { collectionOperationId } = event.currentTarget.dataset;
    const timeBlocks = this.filters.collectionOperationValues.timeBlocks;

    this.showEditRecurrenceStaffingConstraintModal({
      dateRange: this.collectionOperationDateRange,
      collectionOperationId,
      timeBlocks
    });
  };

  handleCreateStaffingConstraint = (event) => {
    const { dateOfConstraint, collectionOperationId, driveType, timeBlockId } =
      event.currentTarget.dataset;
    const collectionOperation = find(this.collectionOperations, {
      id: collectionOperationId
    });

    this.showStaffingConstraintModal({
      staffingConstraint: {
        ...(dateOfConstraint && { dateOfConstraint }),
        ...(driveType && { driveTypes: [driveType] }),
        ...(collectionOperation && { collectionOperation }),
        ...(timeBlockId && { timeBlockId })
      },
      isCreateIndividually:
        dateOfConstraint && collectionOperationId && driveType
    });
  };

  handleEditStaffingConstraint = (event) => {
    const { collectionOperationId, driveType, dateOfConstraint, timeBlockId } = event.currentTarget.dataset;
    const key = `${collectionOperationId}${timeBlockId ? KEY_SEPERATOR + timeBlockId : ''}${KEY_SEPERATOR}${driveType}${KEY_SEPERATOR}${dateOfConstraint}`
    const staffingConstraint = this.mappedStaffingConstraintData?.[key]?.[0];
    const collectionOperation = find(this.collectionOperations, {
      id: staffingConstraint.collectionOperationId
    });

    if (!staffingConstraint) {
      return;
    }

    this.showStaffingConstraintModal({
      staffingConstraint: {
        ...staffingConstraint,
        driveTypes: [staffingConstraint.driveType],
        collectionOperation
      }
    });
  };

  exceptionHandler = (error) => {
    this.dispatchEvent(
      new ShowToastEvent({
        message: error.message,
        variant: "error",
        mode: "dismissable"
      })
    );
  };

  closeStaffingConstraintModal(event) {
    this.staffingConstraintModalData = {};

    if (event.detail.result) {
      this.fetchStafingConstrainData();
    }
  }

  handleDeleteStaffingConstraint(event) {
    const { collectionOperationId, driveType, dateOfConstraint, timeBlockId } = event.currentTarget.dataset;
    const key = `${collectionOperationId}${timeBlockId ? KEY_SEPERATOR + timeBlockId : ''}${KEY_SEPERATOR}${driveType}${KEY_SEPERATOR}${dateOfConstraint}`
    const staffingConstraint = this.mappedStaffingConstraintData?.[key]?.[0];

    if (!staffingConstraint) {
      return;
    }

    this.confirmModalData = {
      isOpen: true,
      title: "Delete Staffing Constraint",
      message: `Are you sure to delete staffing constraint ${staffingConstraint.name}?`,
      confirmBtnLabel: "Yes",
      cancelBtnLabel: "Cancel",
      onClose: (result) => {
        this.closeConfirmModal();

        if (result) {
          const staffingConstraintSvc = new staffingConstraintService();
          this.showSpinner = true;

          staffingConstraintSvc
            .delete(staffingConstraint)
            .then((result) => {
              if (!result.success) throw result;
              this.closeConfirmModal();
              this.fetchStafingConstrainData();
            })
            .catch((error) => {
              this.exceptionHandler(error);
            })
            .finally(() => {
              this.showSpinner = false;
            });
        }
      }
    };
  }

  closeConfirmModal() {
    this.confirmModalData = {};
  }

  /* Add Recurrence Staffing Constraints */
  showAddRecurrenceStaffingConstraintModal = (event) => {
    this.addRecurrenceStaffingConstraintModalData = {
      isOpen: true
    };
  };

  closeAddRecurrenceStaffingConstraintModal = (event) => {
    const saved = event.detail.result;
    if (saved) {
      this.fetchStafingConstrainData();
    }

    this.addRecurrenceStaffingConstraintModalData = {};
  };

  /* Edit Recurrence Staffing Constraints */
  showEditRecurrenceStaffingConstraintModal = (modalData) => {
    this.editRecurrenceStaffingConstraintModalData = {
      isOpen: true,
      ...modalData
    };
  };

  closeEditRecurrenceStaffingConstraintModal = (event) => {
    const saved = event.detail.result;
    if (saved) {
      this.fetchStafingConstrainData();
    }

    this.editRecurrenceStaffingConstraintModalData = {};
  };
}