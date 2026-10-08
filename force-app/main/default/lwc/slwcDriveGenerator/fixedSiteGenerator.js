import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as autoMapper from 'c/autoMapper';
import { BaseGenerator } from './baseGenerator';
import { Fetch } from './fetch';
import {
  debugLogService, operationDriveLimitService, operationDriveLimitQueryModel,
  staffingConstraintService, staffingConstraintQueryModel
} from 'c/dataService';
import { serial, isNullOrEmpty, generateUUID } from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { get, isEqual, cloneDeep, orderBy, extend, keyBy, remove, difference, uniqBy, uniqueId, isNaN, isFinite } from 'c/lodash';
import { DRIVE_TYPE, FIXED_SITE_APPOINTMENT_PATTERN, OPERATION_TYPE, ASSET_TYPE, DRIVE_STATUS, PENDING_ACTION, DRIVE_APPROVAL_STATUS, PROCEDURE_TYPE, RESOURCE_TYPE, DRIVE_CONTENTION, JOB_ALLOCATION_STATUS } from 'c/slwcConstants';

const DEFAULT_CALENDAR_SETTINGS = {
  timezone: TIME_ZONE,
  firstDay: 0
}

const DRIVE_ACTION_GROUPS_ORDER = [
  ['retrieveDriveSiteAndPopulateCollectionOperation', 'populateSiteCollectionOperation', 'populateDriveCollectionOperation', 'populateCollectionOperationData'],
  ['retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags', 'retrieveFixedSiteProcedureProjections'],
  ['calculate2rbcProjectedProcedures', 'split2rbcProjectedProcedures', 'calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata',
    'applyStaffingComplementAndProposeDriveShifts', 'proposeDriveShifts', 'proposeDriveShiftSlots', 'updateDriveTotalSlots', 'calculateDriveProductivityPlanned',
    'handleTotalVehicleRequestedChanged', 'handleEquipmentRequestedChanged', 'handleDriveShiftsMetadataChanged', 'correctJobAllocationTimes']
]

const DRIVE_FIELD_CHANGE_MAPPING = {
  'driveDate': {
    groups: [
      { actions: ['retrieveDriveSiteAndPopulateCollectionOperation'] },
      { actions: ['retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveFixedSiteProcedureProjections'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'roleTimeVarianceChanged': {
    groups: [
      { actions: [] },
      { actions: ['retrieveRoleTimeData'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'roleTimeDetailChanged': {
    groups: [
      { actions: [] },
      { actions: ['retrieveRoleTimeData'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  // The SDM fetch sits alone in group 1 because groups run serially while actions inside a group run
  // in parallel - the recalculation in group 2 reads what this fetch stores.
  'sdmChanged': {
    groups: [
      { actions: [] },
      { actions: ['retrieveCollectionOperationSDM'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'siteAddressChanged': {
    groups: [
      { actions: [] },
      { actions: ['retrieveDriveSiteAndPopulateCollectionOperation'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: ['correctJobAllocationTimes'] }
    ]
  },
  'travelTimeChanged': {
    groups: [
      { actions: [] },
      { actions: ['retrieveDriveSiteAndPopulateCollectionOperation'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: ['correctJobAllocationTimes'] }
    ]
  },
  'driveSiteId': {
    groups: [
      { actions: ['retrieveDriveSiteAndPopulateCollectionOperation'] },
      { actions: ['retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: ['correctJobAllocationTimes'] }
    ]
  },
  'siteCollectionOperationId': {
     groups: [
      { actions: ['populateSiteCollectionOperation'] },
      { actions: ['retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: ['correctJobAllocationTimes'] }
    ]
  },
  'collectionOperationId': {
     groups: [
      { actions: ['populateSiteCollectionOperation'] },
      { actions: ['retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: ['correctJobAllocationTimes'] }
    ]
  },
  'typeOfDrive': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'startTime': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'endTime': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'wbProjectedProcedures': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'x2rbcProjectedProcedures': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'plateletProjectedProcedures': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'plasmaProjectedProcedures': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'recruitedBy': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['proposeDriveShiftSlots', 'updateDriveTotalSlots'] },
      { actions: [] }
    ]
  },
  'travelTimeIncluded': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'numberOfVehicles': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'numberOf2rbcAssets': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculate2rbcProjectedProcedures', 'calculateTotalProceduresProjected', 'split2rbcProjectedProcedures', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'numberOfPlateletAssets': { //TODO
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'numberOfPlasmaAssets': { //TODO 
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'driveShiftsMetadata': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleDriveShiftsMetadataChanged'] },
      { actions: [] }
    ]
  },
  'totalVehicleRequestedChanged': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleTotalVehicleRequestedChanged'] },
      { actions: [] }
    ]
  },
  'totalEquipmentRequestedChanged': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleEquipmentRequestedChanged'] },
      { actions: [] }
    ]
  },
  'regenerateDrive': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'staffingComplementChanged': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['applyStaffingComplementAndProposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'slotGenerator': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['proposeDriveShiftSlots', 'updateDriveTotalSlots'] },
      { actions: [] }
    ]
  }
}

const DRIVE_SHIFT_FIELD_CHANGE_MAPPING = {
  'lunchBreak': {
    groups: [
      { actions: [] },
      { actions: ['updateLunchBreakSettings', 'populateLunchBreakTime', 'populateShiftTime', 'generateShiftSlots', 'updateDriveTotalSlots', 'populateDriveTime'] },
    ]
  },
  'lunchBreakBeforeDrawHours': {
    groups: [
      { actions: [] },
      {
        actions: [function ($this, driveShift) {
          if (!driveShift) return;

          $this.updateLunchBreakSettings(driveShift);

          if (driveShift.lunchBreakBeforeDrawHours) {
            $this.moveLunchBreakToBeforeDrawHours(driveShift);
            $this.populateShiftTime(driveShift);
            $this.generateShiftSlots(driveShift);
            $this.updateDriveTotalSlots();
            $this.populateDriveTime();
          }
          else {
            $this.moveLunchBreakToDuringDrawHours(driveShift);
            $this.populateShiftTime(driveShift);
            $this.generateShiftSlots(driveShift);
            $this.updateDriveTotalSlots();
            $this.populateDriveTime();
          }
        }]
      },
    ]
  },
  'lunchBreakStartTime': {
    groups: [
      { actions: [] },
      { actions: ['changeLunchBreakStartTime', 'generateShiftSlots', 'updateDriveTotalSlots'] },
    ]
  }
}

class FixedSiteGenerator extends BaseGenerator {
  constructor() {
    const fetch = new Fetch({
      driveType: DRIVE_TYPE.FIXED_SITE
    });
    super({
      fetch,
      DRIVE_ACTION_GROUPS_ORDER,
      DRIVE_FIELD_CHANGE_MAPPING,
      DRIVE_SHIFT_FIELD_CHANGE_MAPPING
    })
  }

  initializeFromOptyId(oppId) {
    console.log('INITIALISING FROM OPPTY');
    this.errorMessages = [];
    return Promise.all([
      this.fetch.retrieveOpportunity(oppId),
      this.fetch.retrieveLoginUser(),
      this.fetch.retrieveCustomSettings()
    ])
      .then(([opp, loginUser, {
        resourceRoleGroups,
        lunchBreakSettings,
        adminSetting,
        staffSetupExcludedRoles
      }]) => {
        if (!opp.drives) {
          return Promise.resolve()
            .then(() => {
              if (this.validateOpty(opp)) {
                this.drive = this.initiateNewDriveFromOpty(opp)
                return Promise.all([
                  this.fetch.retrieveDriveSite(this.drive)
                    .then(driveSite => {
                      this.drive.driveSite = driveSite;
                      return driveSite;
                    })
                ])
                  .then(([driveSite]) => {
                    this.populateDriveCollectionOperation();

                    return Promise.all([
                      driveSite,
                      this.fetch.retrieveTravelTimeIndexItemMap(this.drive),
                      this.fetch.retrieveSameDateDrives(this.drive),
                      this.fetch.retrieveSameDateActivities(this.drive),
                      this.fetch.retrieveCollectionOperationSDM(this.drive),
                      this.fetch.retrieveRoleTimeData(this.drive),
                      this.fetch.retrieveDefaultTags(this.drive),
                      this.fetch.retrieveFixedSiteProcedureProjections(this.drive),
                      this.fetch.retrieveTerritoryCollectionOperations(this.drive)
                    ])
                  })
                  .then(([driveSite, travelTimeIndexItemMap, sameDateDrives, sameDateActivities, staffingDecisionMatrix, roleTimeData, driveTags, fixedSiteProcedureProjections, territoryCollectionOperations]) => {
                    this.initMasterData({
                      loginUser,
                      driveSite,
                      resourceRoleGroups,
                      lunchBreakSettings,
                      adminSetting,
                      travelTimeIndexItemMap,
                      sameDateDrives,
                      sameDateActivities,
                      staffingDecisionMatrix,
                      roleTimeData,
                      driveTags,
                      fixedSiteProcedureProjections,
                      territoryCollectionOperations,
                      staffSetupExcludedRoles
                    });

                    this.populateCollectionOperationData();
                    this.calculateTotalProceduresProjected();
                    this.calculateDriveShiftsMetadata();
                    this.proposeDriveShifts();
                    this.calculateDriveProductivityPlanned();
                    this.populateDriveTerritory();

                    return this.drive;
                  });
              }
            });
        }
        else {
          let drive = opp.drives[0];
          return this.editDrive(drive.id);
        }
      })
  }

  initData(data) {
    if (!data) return;
    let { drive, masterData } = data;
    this.drive = this.processDriveData(drive);
    this.masterData = {
      ...this.masterData,
      ...masterData
    }
    this.masterData.sameDateDrives = (this.masterData.sameDateDrives || []).filter(drive => drive.id !== this.drive.id);

    this.initMasterData(this.masterData);
    this.populateDriveCollectionOperation();
    this.populateDriveTerritory();
    this.populateCollectionOperationData();
    this.initDriveShiftsMetadata();
    this.buildJobTagNames();

    this.backupDriveData(this.drive);
    this.drive.driveShifts.forEach((shift) => {
      this.backupDriveShift(shift);
    });
    return this.drive;
  }

  editDrive(driveId) {
    return Promise.all([
      this.fetch.getDriveDetails(driveId),
      this.fetch.retrieveLoginUser(),
      this.fetch.retrieveCustomSettings()
    ])
      .then(([drive, loginUser, {
        resourceRoleGroups,
        lunchBreakSettings,
        adminSetting,
        staffSetupExcludedRoles
      }]) => {
        this.drive = this.processDriveData(drive);

        return Promise.all([
          this.fetch.retrieveDriveSite(this.drive)
            .then(driveSite => {
              this.drive.driveSite = driveSite;
              return driveSite;
            })
        ])
          .then(([driveSite]) => {
            return Promise.all([
              driveSite,
              this.fetch.retrieveTravelTimeIndexItemMap(this.drive),
              this.fetch.retrieveSameDateDrives(this.drive),
              this.fetch.retrieveSameDateActivities(this.drive),
              this.fetch.retrieveCollectionOperationSDM(this.drive),
              this.fetch.retrieveRoleTimeData(this.drive),
              this.fetch.retrieveDefaultTags(this.drive),
              this.fetch.retrieveFixedSiteProcedureProjections(this.drive),
              this.fetch.retrieveActiveDriveChangeRequest(this.drive),
            ]);
          })
          .then(([driveSite, travelTimeIndexItemMap, sameDateDrives, sameDateActivities, staffingDecisionMatrix, roleTimeData, driveTags, fixedSiteProcedureProjections, activeDriveChangeRequest]) => {
            this.initMasterData({
              loginUser,
              driveSite,
              resourceRoleGroups,
              lunchBreakSettings,
              adminSetting,
              travelTimeIndexItemMap,
              sameDateDrives,
              sameDateActivities,
              staffingDecisionMatrix,
              roleTimeData,
              driveTags,
              fixedSiteProcedureProjections,
              activeDriveChangeRequest,
              staffSetupExcludedRoles
            })
          
            this.populateCollectionOperationData();
            this.initDriveShiftsMetadata(),

            this.buildJobTagNames();
            this.backupDriveData(this.drive);
            this.drive.driveShifts.forEach((shift) => {
              this.backupDriveShift(shift);
            });

            return this.drive;
          })
      })
      .catch(error => {
        new debugLogService().captureDebugLog(error, this.drive?.id);
        this.errorMessages.push('Cannot get drive details.');
      })
  }

  validateOpty(opp) {
    let requiredProperties = [
      { name: 'driveDate', label: 'Drive Date' },
      { name: 'driveSiteId', label: 'Drive Site' },
      { name: 'endTime', label: 'End Time' },
      { name: 'startTime', label: 'Start Time' },
      { name: 'typeOfDrive', label: 'Type of Drive' }
    ];
    let fieldRequiredMessageTempalte = '{label} is required.';
    let optyErrorMessages = [];
    requiredProperties.forEach((property) => {
      if (isNullOrEmpty(opp[property.name])) {
        optyErrorMessages.push(fieldRequiredMessageTempalte.replace('{label}', property.label));
      }
    });
    this.errorMessages = this.errorMessages.concat(optyErrorMessages);
    return optyErrorMessages.length === 0;
  }

  validateCurrentAssignedAssets(properties = [], validateDraftDrive = false) {
    const validateEqipments = (drive, availableEquipments = []) => {
      //validate current assigned equipment
      let { totalRequired, assignedEquipments: currentAssignedEquipments, lockedEquipments } = this.getCurrentAssignedEquipments();
      let assignedEquipmentsValid = currentAssignedEquipments.filter(assignedEquipment => {
        return availableEquipments.find(availableEquipment => availableEquipment.id === assignedEquipment.id);
      });
      let allAssignedEquipmentsValid = assignedEquipmentsValid.length === currentAssignedEquipments.length;

      if (!allAssignedEquipmentsValid || currentAssignedEquipments.length < totalRequired) {
        //slots to be allocated
        let { slotsToAllocate, availableEquipmentsCanBeUsed } = this.helper.preProcessSuggestEquipments(totalRequired, availableEquipments, lockedEquipments);
        
        //try to assign new equipments 
        let drivesWithEquipments = this.helper.suggestEquipments([drive], availableEquipmentsCanBeUsed, slotsToAllocate);
        let newEquipmentJobsMap = {};

        if (drivesWithEquipments && drivesWithEquipments.length) {
          let currentDrive = drivesWithEquipments.find(drive => drive.driveKey == this.drive.key);
          newEquipmentJobsMap = currentDrive.equipmentJobsMap;
        }

        return {
          allAssignedEquipmentsValid: false,
          lockedEquipments: lockedEquipments,
          newEquipmentJobsMap: newEquipmentJobsMap,
        }
      } else if (assignedEquipmentsValid.length > totalRequired) {
        //slots to be allocated
        let { slotsToAllocate, availableEquipmentsCanBeUsed } = this.helper.preProcessSuggestEquipments(totalRequired, assignedEquipmentsValid, lockedEquipments);
        
        //remove redundant equipments
        let drivesWithEquipments = this.helper.suggestEquipments([drive], availableEquipmentsCanBeUsed);
        let newEquipmentJobsMap = {};

        if (drivesWithEquipments && drivesWithEquipments.length) {
          let currentDrive = drivesWithEquipments.find(drive => drive.driveKey == this.drive.key);
          newEquipmentJobsMap = currentDrive.equipmentJobsMap;
        }

        return {
          allAssignedEquipmentsValid: false,
          lockedEquipments: lockedEquipments,
          newEquipmentJobsMap: newEquipmentJobsMap,
        }
      } else {
        return {
          allAssignedEquipmentsValid: true
        }
      }
    }

    const validateVehicles = (drive, availableVehicles = []) => {
      return {
        allAssignedVehiclesValid: true,
        canHandleDriveProjectedRegisteredDonors: true
      }
    }

    if (this.drive.status === DRIVE_STATUS.DRAFT && !validateDraftDrive) return Promise.resolve({
      allAssignedEquipmentsValid: true,
      allAssignedVehiclesValid: true,
      canHandleDriveProjectedRegisteredDonors: true
    });
    const fieldsToCheckChange = ['driveDate', 'doNotUseVehicle'];
    const anyField = properties.find(property => {
      return fieldsToCheckChange.includes(property.targetName);
    })
    if (properties.length && !anyField) return Promise.resolve({
      allAssignedEquipmentsValid: true,
      allAssignedVehiclesValid: true,
      canHandleDriveProjectedRegisteredDonors: true
    });

    const driveDateChanged = properties.find(property => property.targetName === 'driveDate');
    const doNotUseVehicleChanged = properties.find(property => property.targetName === 'doNotUseVehicle');
    const newDrive = {
      ...this.drive,
      driveDate: driveDateChanged ? driveDateChanged.targetValue : this.drive.driveDate,
      doNotUseVehicle: doNotUseVehicleChanged ? !!doNotUseVehicleChanged.targetValue : this.drive.doNotUseVehicle
    };
    return this.helper.getAvailableAssets(this.masterData.vehicles, newDrive)
      .then(({ availableVehicles, availableEquipments = [] }) => {
        const { allAssignedEquipmentsValid, newEquipmentJobsMap, lockedEquipments } = validateEqipments(newDrive, availableEquipments);
        const { allAssignedVehiclesValid, newVehicles, canHandleDriveProjectedRegisteredDonors } = validateVehicles(newDrive, availableVehicles);

        return {
          allAssignedEquipmentsValid,
          newEquipmentJobsMap,
          lockedEquipments,
          allAssignedVehiclesValid,
          newVehicles,
          canHandleDriveProjectedRegisteredDonors
        }
      })
  }

  validateDrive() {
    return Promise.resolve()
      .then(() => {
        let driveLimitQuery = new operationDriveLimitQueryModel();
        driveLimitQuery.effectiveStartDate = this.drive.driveDate;
        driveLimitQuery.effectiveEndDate = this.drive.driveDate;
        driveLimitQuery.collectionOperationIds = [this.drive.collectionOperationId];

        let staffingConstraintQuery = new staffingConstraintQueryModel();
        staffingConstraintQuery.startDate = this.drive.driveDate;
        staffingConstraintQuery.endDate = this.drive.driveDate;
        staffingConstraintQuery.driveTypes = [this.drive.typeOfDrive];
        staffingConstraintQuery.collectionOpIds = [this.drive.collectionOperationId];

        let driveLimitSvc = new operationDriveLimitService();
        let staffingConstraintSvc = new staffingConstraintService();

        return Promise.all([
          driveLimitSvc.query(driveLimitQuery),
          staffingConstraintSvc.query(staffingConstraintQuery),
          this.helper.getAvailableAssets([], this.drive),
          this.helper.getLockedStaffAvailability(this.drive)
        ]);
      })
      .then(([driveLimitResult, staffingConstraintResult, availableAssetsInfo, staffPossibleAllocations]) => {
        availableAssetsInfo.possibleAllocations = (availableAssetsInfo.possibleAllocations || []).concat(staffPossibleAllocations);
        let {
          passed,
          pendingActionReasonCodes
        } = this.helper.validateDrive(this.drive, {
          ...this.masterData,
          driveLimits: driveLimitResult,
          staffingConstraints: staffingConstraintResult,
          availableAssetsInfo,
          availabilityData: {
            possibleAllocations: availableAssetsInfo.possibleAllocations || []
          }
        }, [
          DRIVE_CONTENTION.DRIVE_LIMIT,
          DRIVE_CONTENTION.x2RBC_LIMIT,
          DRIVE_CONTENTION.DOT_LIMIT,
          DRIVE_CONTENTION.CDL_LIMIT,
          DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS,
          DRIVE_CONTENTION.LACKING_EQUIPMENT,
          DRIVE_CONTENTION.INSUFFICIENT_RESOURCES,
          DRIVE_CONTENTION.WITHIN_42_DAYS,
          DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS,
          DRIVE_CONTENTION.PART_OF_LINKED_DRIVE,
          DRIVE_CONTENTION.MULTI_SHIFT_DRIVE,
          DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED,
          DRIVE_CONTENTION.LOCKED_RESOURCE_UNAVAILABLE
        ])

        if (pendingActionReasonCodes && pendingActionReasonCodes.length) {
          this.drive.pendingActionReasonCode = pendingActionReasonCodes.join(";");
          this.drive.pendingActionReasonCodes = pendingActionReasonCodes;

          //HRP-955
          if (!pendingActionReasonCodes.includes(DRIVE_CONTENTION.WITHIN_42_DAYS)) {
            if (pendingActionReasonCodes.includes(DRIVE_CONTENTION.INSUFFICIENT_RESOURCES)) {
              this.drive.routeApprovalRequestTo = 'Request DM evaluation';
            } else {
              this.drive.routeApprovalRequestTo = 'Request APS exception';
            }
          } else {
            this.drive.routeApprovalRequestTo = 'Request APS exception';
          }
          
          if (!this.helper.isAPSUser(this.masterData.loginUser) && this.drive.status === DRIVE_STATUS.DRAFT) {
            this.drive.pendingAction = PENDING_ACTION.DRIVE_SUBMISSION;
            this.drive.approvalStatus = DRIVE_APPROVAL_STATUS.SUBMITTED;
          }
        }  else {
          this.drive.pendingAction = '';
          this.drive.approvalStatus = '';
          this.drive.pendingActionReasonCode = '';
          this.drive.pendingActionReasonCodes = [];
        }

        return this.drive;
      })
  }

  retrieveDriveSiteAndPopulateCollectionOperation() {
    return this.retrieveDriveSite()
      .then(() => {
        this.populateDriveCollectionOperation();
        this.populateCollectionOperationData();
      })
  }

  /** Process data */
  initDriveShiftsMetadata() {
    //reset values
    let driveShiftsMetadata = {
      x2rbcProjectedProcedures: this.drive.x2rbcProjectedProcedures || 0,
      wbProjectedProcedures: this.drive.wbProjectedProcedures || 0,
      plateletProjectedProcedures: this.drive.plateletProjectedProcedures || 0,
      plasmaProjectedProcedures: this.drive.plasmaProjectedProcedures || 0,
      numberOfDriveShifts: 0,
      driveShifts: [],
      resourceRoleGroupRoleTimeDataMap: this.helper.calculateDriveRoleTimeData(this.drive, this.masterData)
    };

    this.drive.driveShifts.forEach((driveShift, index) => {
      let temp = {
        key: uniqueId('drive_shift_'),
        label: `Drive Shift ${index + 1}`,
        driveDate: this.drive.driveDate,
        start: this.helper.newDateTime(this.drive.driveDate, driveShift.startTime, this.masterData.timezoneSidId),
        finish: this.helper.newDateTime(this.drive.driveDate, driveShift.endTime, this.masterData.timezoneSidId),
        startTime: driveShift.startTime,
        endTime: driveShift.endTime,
        x2rbcProjectedProcedures: driveShift.x2rbcProjectedProcedures,
        wbProjectedProcedures: driveShift.wbProjectedProcedures,
        plateletProjectedProcedures: driveShift.plateletProjectedProcedures,
        plasmaProjectedProcedures: driveShift.plasmaProjectedProcedures,
      }

      let rounds = this.generateDriveShiftRounds(temp, driveShift.plateletRounds);
      temp.rounds = rounds;
      temp.numberOfRounds = rounds.length;

      driveShift.driveShiftMetadata = temp;
      driveShiftsMetadata.driveShifts.push(temp);
    });
    driveShiftsMetadata.numberOfDriveShifts = driveShiftsMetadata.driveShifts.length;

    this.drive.driveShiftsMetadata = driveShiftsMetadata;
    this.calculateTotalProceduresProjected(this.drive.driveShiftsMetadata);
    this.drive.driveShiftsMetadata.driveShifts.forEach(driveShift => {
      this.calculateTotalProceduresProjected(driveShift);
      driveShift.resourceRoleGroupRoleTimeDataMap = this.helper.calculateDriveShiftRoleTimeData(
        this.masterData,
        this.drive,
        driveShift
      );
      driveShift.lunchBreakSettings = this.helper.calculateDriveShiftLunchBreakSettings(this.drive, driveShift, this.masterData);
    })
  }

  updateDriveProcedureCapacity() {
    let procedureTypes = [];
    if (this.drive.operationType === OPERATION_TYPE.INTEGRATED) {
      procedureTypes = [PROCEDURE_TYPE.WB, PROCEDURE_TYPE._2RBC, PROCEDURE_TYPE.PLATELET, PROCEDURE_TYPE.PLASMA];
    }
    else if (this.drive.operationType === OPERATION_TYPE.NON_INTEGRATED_APH) {
      procedureTypes = [PROCEDURE_TYPE.PLATELET, PROCEDURE_TYPE.PLASMA];
    }

    let driveProcedureCapacity = 0;
    let driveProcedureCapacityMap = {};
    let tempDriveShifts = cloneDeep(this.drive.driveShiftsMetadata.driveShifts);
    procedureTypes.forEach(procedureType => {
      let setting = (this.masterData.fixedSiteProcedureProjections || []).find((setting) => {
        return setting.procedureType === procedureType;
      });
      if (!setting && procedureType !== PROCEDURE_TYPE.PLATELET) return;

      const procedureTypeCapacity = this.helper.getFixedSiteProcedureTypeCapacity(procedureType, this.masterData);
      const drawHoursInMinutesByProcedureType = this.helper.getDrawHoursInMinutesByProcedureType(this.drive, procedureType, this.masterData);
      const projectedProceduresByProcedureType = this.helper.getProjectedProceduresByProcedureType(this.drive, procedureType)
      let procedureCapacity = 0;
      if (procedureType !== PROCEDURE_TYPE.PLATELET) {
        let noOfStaff = projectedProceduresByProcedureType / (1 - setting.qns / 100) / (1 - setting.deferral / 100) / (drawHoursInMinutesByProcedureType / 60) / procedureTypeCapacity;
        procedureCapacity = noOfStaff * procedureTypeCapacity * (drawHoursInMinutesByProcedureType / 60) * (1 - setting.deferral / 100) * (1 - setting.qns / 100);
      } else {
        let noOfStaff = projectedProceduresByProcedureType / this.helper.getDrivePlateletRounds(this.drive) / procedureTypeCapacity;
        procedureCapacity = noOfStaff * procedureTypeCapacity * this.helper.getDrivePlateletRounds(this.drive);
      }

      if (isNaN(procedureCapacity) || !isFinite(procedureCapacity)) {
        procedureCapacity = 0;
      }

      driveProcedureCapacity = driveProcedureCapacity + procedureCapacity;
      driveProcedureCapacityMap[procedureType] = procedureCapacity;

      this.helper.splitProcedureCapacity(this.drive, tempDriveShifts, driveProcedureCapacityMap, procedureType, this.masterData.timezoneSidId);
    })

    driveProcedureCapacity = Math.round(driveProcedureCapacity);
    this.drive.procedureCapacity = driveProcedureCapacity;

    let remainingProcedureCapacity = driveProcedureCapacity;
    tempDriveShifts.forEach((tempDriveShift, tempDriveShiftIndex) => {
      let driveShift = this.drive.driveShifts[tempDriveShiftIndex];
      let driveShiftProcedureCapacity = 0;
      procedureTypes.forEach(procedureType => {
        const shiftProcedureCapacityByProcedureType = tempDriveShift[procedureType];
        if (shiftProcedureCapacityByProcedureType) {
          driveShiftProcedureCapacity = driveShiftProcedureCapacity + shiftProcedureCapacityByProcedureType;
        }
      });
      driveShift.procedureCapacity = Math.ceil(driveShiftProcedureCapacity);
      if (driveShift.procedureCapacity > remainingProcedureCapacity) {
        driveShift.procedureCapacity = remainingProcedureCapacity;
      }
      remainingProcedureCapacity = remainingProcedureCapacity - driveShift.procedureCapacity;
    })
  }

  /** Generate */
  calculateTotalProceduresProjected(record) {
    if (!record && !this.drive) return;
    if (!record) {
      record = this.drive;
    }
    let x2rbcProjectedProcedures = record.x2rbcProjectedProcedures || 0;
    let wbProjectedProcedures = record.wbProjectedProcedures || 0;
    let plasmaProjectedProcedures = record.plasmaProjectedProcedures || 0;
    let plateletProjectedProcedures = record.plateletProjectedProcedures || 0;

    record.totalProceduresProjected = x2rbcProjectedProcedures + wbProjectedProcedures + plasmaProjectedProcedures + plateletProjectedProcedures;
    record.totalProductsProjected = x2rbcProjectedProcedures * 2 + wbProjectedProcedures + plasmaProjectedProcedures + plateletProjectedProcedures;
  }
  
  /** Drive Shifts metadata */
  calculateDriveShiftsMetadata() {
    //reset values
    let driveShiftsMetadata = {
      x2rbcProjectedProcedures: this.drive.x2rbcProjectedProcedures || 0,
      wbProjectedProcedures: this.drive.wbProjectedProcedures || 0,
      plateletProjectedProcedures: this.drive.plateletProjectedProcedures || 0,
      plasmaProjectedProcedures: this.drive.plasmaProjectedProcedures || 0,
      numberOfDriveShifts: 0,
      driveShifts: [],
      resourceRoleGroupRoleTimeDataMap: this.helper.calculateDriveRoleTimeData(this.drive, this.masterData)
    };
    this.drive.driveShiftsMetadata = driveShiftsMetadata;

    if (this.drive.driveDate && this.drive.startTime && this.drive.endTime) {
      const driveStart = this.helper.newDateTime(this.drive.driveDate, this.drive.startTime, this.masterData.timezoneSidId);
      const driveEnd = this.helper.newDateTime(this.drive.driveDate, this.drive.endTime, this.masterData.timezoneSidId);     
      const totalRounds = this.helper.calculatePlateletRounds(this.drive, this.masterData);

      let numberOfDriveShifts = Math.ceil(totalRounds / 3);
      if (numberOfDriveShifts < 1) {
        numberOfDriveShifts = 1;
      }
      if (numberOfDriveShifts > 2) {
        numberOfDriveShifts = 2;
      }

      let remainingRounds = totalRounds;
      let lastShiftEnd = driveStart;
      let lastRoundEnd = null;
      for (let i = 0; i < numberOfDriveShifts; i++) {
        let numberOfRounds = Math.ceil(remainingRounds / (numberOfDriveShifts - i));
        if (numberOfRounds > remainingRounds) {
          numberOfRounds = remainingRounds;
        }

        let shiftStart = lastShiftEnd;
        let shiftEnd = new Date(shiftStart.getTime() + (numberOfRounds * 3 * 60 * 60000));
        if (i === numberOfDriveShifts - 1) {
          shiftEnd = driveEnd;
        }

        let rounds = this.generateDriveShiftRounds({
          start: lastRoundEnd > shiftStart ? lastRoundEnd : shiftStart,
          finish: shiftEnd
        }, numberOfRounds);

        driveShiftsMetadata.driveShifts.push({
          key: uniqueId('drive_shift_'),
          label: `Drive Shift ${i + 1}`,
          driveDate: this.drive.driveDate,
          start: shiftStart,
          finish: shiftEnd,
          startTime: this.helper.dateJSToTimeIso(shiftStart, this.masterData.timezoneSidId),
          endTime: this.helper.dateJSToTimeIso(shiftEnd, this.masterData.timezoneSidId),
          numberOfRounds: rounds.length,
          rounds: rounds
        })

        remainingRounds = remainingRounds - numberOfRounds;
        lastShiftEnd = shiftEnd;
        lastRoundEnd = rounds.length > 0 ? rounds[rounds.length - 1].end : null
      }

      driveShiftsMetadata.numberOfDriveShifts = driveShiftsMetadata.driveShifts.length;

      this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
      this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE.WB, this.masterData.timezoneSidId);
      this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE.PLATELET, this.masterData.timezoneSidId);
      this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE.PLASMA, this.masterData.timezoneSidId);

      this.calculateTotalProceduresProjected(driveShiftsMetadata);
      driveShiftsMetadata.driveShifts.forEach(driveShift => {
        this.calculateTotalProceduresProjected(driveShift);
        driveShift.resourceRoleGroupRoleTimeDataMap = this.helper.calculateDriveShiftRoleTimeData(
          this.masterData,
          this.drive,
          driveShift,
          driveShiftsMetadata.driveShifts
      );
        driveShift.lunchBreakSettings = this.helper.calculateDriveShiftLunchBreakSettings(this.drive, driveShift, this.masterData);
      })
    }
  }

  split2rbcProjectedProcedures() {
    if (!this.drive.driveShiftsMetadata) return;

    this.drive.driveShiftsMetadata.x2rbcProjectedProcedures = this.drive.x2rbcProjectedProcedures;
    this.helper.splitProjectedProcedures(this.drive, this.drive.driveShiftsMetadata.driveShifts, this.drive.driveShiftsMetadata, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
  }

  calculate2rbcProjectedProcedures() {
    if (isNullOrEmpty(this.drive.x2rbcProjectedProcedures)) {
      this.drive.x2rbcProjectedProcedures = 0;
      return;
    }
  }

  /** Resource Requirement **/
  initResourceQuantityMap() {
    this.mapResourceQuantity = new Map();
    this.mapVolunteerQuantity = new Map();
    this.mapAssetQuantity = new Map();

    this.drive.driveShiftsMetadata.driveShifts.forEach(driveShift => {
      this.mapResourceQuantity.set(driveShift.key, new Map());
      this.mapVolunteerQuantity.set(driveShift.key, new Map());
    });
  }

  calculateResourceQuantity(skipCalculateResourceRoles = false, jobsUpdatedViaDualRoleChangeMap = {}) {
    this.calculateVehicleRelatedQuantity();
    this.calculateEquipmentQuantity();

    if(skipCalculateResourceRoles) {
      const staffingComplementChanged = this.drive.staffingComplementChanged || {};
      const driveShiftsMetadata = this.drive.driveShiftsMetadata;
      driveShiftsMetadata.driveShifts.forEach((driveShift, driveShiftIndex) => {
        let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
        const staffingComplement = staffingComplementChanged[driveShiftIndex];
        Object.keys(staffingComplement).forEach(resourceRole => {
          const { quantity, systemQuantity, isManuallyCreated, manuallyCreatedFrom } = staffingComplement[resourceRole]; //preserve properties for manually created jobs
          resourceQuantityMap.set(resourceRole, {
            quantity: quantity,
            systemQuantity: systemQuantity,
            isManuallyCreated: isManuallyCreated,
            manuallyCreatedFrom: manuallyCreatedFrom
          });
        })
      })
    } else {
      this.calculateApheresisStaffQuantity();
      this.calculateApheresisChargeQuantity();  
    }

    this.calculateVolunteerDonorAmbassadors();

    if(jobsUpdatedViaDualRoleChangeMap) {
      this.restoreDualRoleModification(jobsUpdatedViaDualRoleChangeMap);
    }

    const systemGeneratedStaffingComplementChanges = this.helper.getDriveSystemGeneratedStaffingComplementChanges({
      ...this.drive,
      driveShifts: Array.from(this.mapResourceQuantity.values()).map(mapResourceQuantity => {
        const jobs = [];
        mapResourceQuantity.forEach((staffingComplement, resourceRole) => {
          jobs.push({
            resourceRole,
            ...staffingComplement,
            systemQuantity: staffingComplement.quantity,
            dualRole: staffingComplement.dualRole || ''
          })
        });

        return {
          jobs
        }
      })
    }, this.masterData.backupDrive, { isDriveGettingRegenerated : this.isRegenerateDriveChange });
    if(!systemGeneratedStaffingComplementChanges.newJobs.length && 
      !systemGeneratedStaffingComplementChanges.changedJobs.length && 
      !systemGeneratedStaffingComplementChanges.deletedJobs.length) {
        this.restoreJobsQuantity(skipCalculateResourceRoles ? this.masterData.backupDrive : this.drive);
    } 
  }

  //Will work at the time of dual role modification save
  restoreDualRoleModification(jobsUpdatedViaDualRoleChangeMap = {}) {
    if(jobsUpdatedViaDualRoleChangeMap) {
      const driveShiftsMetadata = this.drive.driveShiftsMetadata;
      Object.keys(jobsUpdatedViaDualRoleChangeMap).forEach(driveShiftIndex => {
        const driveShiftMetadata =  driveShiftsMetadata?.driveShifts?.[driveShiftIndex];
        let resourceQuantityMap = this.mapResourceQuantity.get(driveShiftMetadata?.key);
        if(!resourceQuantityMap) return;

        let tempResourceQuantityMap = cloneDeep(resourceQuantityMap);
        let roles = orderBy(jobsUpdatedViaDualRoleChangeMap[driveShiftIndex], [item => item.isManuallyCreated], ['asc']);
        roles.forEach(item => {
          tempResourceQuantityMap.delete(item.resourceRole);
          tempResourceQuantityMap.set(item.resourceRole, cloneDeep({
            ...resourceRoleQuantityAfterRegenreted,
            quantity: quantity,
            isCreatedOrUpdatedViaDualRoleChange: true
          }));
        });
        this.mapResourceQuantity.set(driveShiftMetadata?.key, new Map([...tempResourceQuantityMap]));
      });
    }
  }

  calculateVehicleRelatedQuantity() {
    let numberOfVehicles = this.drive.numberOfVehicles || 0;
    this.mapAssetQuantity.set("Vehicle", numberOfVehicles);
  }

  calculateEquipmentQuantity() {
    if ([OPERATION_TYPE.INTEGRATED].includes(this.drive.operationType)) {
      let noOf2rbcAssets = this.drive.numberOf2rbcAssets || 0;
      this.mapAssetQuantity.set("Equipment - 2RBC Asset", noOf2rbcAssets);
    }

    // if ([OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH].includes(this.drive.operationType)) {
    //   let noOfPlateletAssets = this.drive.numberOfPlateletAssets || 0;
    //   let noOfPlasmaAssets = this.drive.numberOfPlasmaAssets || 0;

    //   this.mapAssetQuantity.set("Equipment - Platelet Asset", noOfPlateletAssets);
    //   this.mapAssetQuantity.set("Equipment - Plasma Asset", noOfPlasmaAssets);
    // }
  }

  calculateApheresisStaffQuantity() {
    if (!this.drive.driveDate || !this.drive.startTime || !this.drive.endTime) return;

    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    let totalApheresisStaff = 0;

    //Calculate Platelet Staff count Separately and add it to 'totalApheresisStaff'
    const plateletProcedureProjected = this.helper.getProjectedProceduresByProcedureType(this.drive, PROCEDURE_TYPE.PLATELET);
    const plateletRoundCapacity = this.helper.getFixedSiteProcedureTypeCapacity(PROCEDURE_TYPE.PLATELET, this.masterData);
    const plateletRounds = this.helper.getDrivePlateletRounds(this.drive);
    if(!isNaN(plateletProcedureProjected) || isFinite(plateletProcedureProjected)) { 
      totalApheresisStaff = plateletProcedureProjected / plateletRounds / plateletRoundCapacity;
    }

    // Calculate other Staff counts and add on top of 'totalApheresisStaff' value
    (this.masterData.fixedSiteProcedureProjections || []).forEach((setting) => {
      const procedureTypeCapacity = this.helper.getFixedSiteProcedureTypeCapacity(setting.procedureType, this.masterData);
      const drawHoursInMinutesByProcedureType = this.helper.getDrawHoursInMinutesByProcedureType(this.drive, setting.procedureType, this.masterData);
      const projectedProceduresByProcedureType = this.helper.getProjectedProceduresByProcedureType(this.drive, setting.procedureType)
      let noOfStaff = 0;
      if (setting.procedureType !== PROCEDURE_TYPE.PLATELET) {
        noOfStaff += projectedProceduresByProcedureType / (1 - setting.qns / 100) / (1 - setting.deferral / 100) / (drawHoursInMinutesByProcedureType / 60) / procedureTypeCapacity;
      } 

      if (isNaN(noOfStaff) || !isFinite(noOfStaff)) {
        noOfStaff = 0;
      }

      let isResourceRoleApplied = ([OPERATION_TYPE.INTEGRATED].includes(this.drive.operationType)
        && [PROCEDURE_TYPE.WB, PROCEDURE_TYPE._2RBC].includes(setting.procedureType))
        || ([OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH].includes(this.drive.operationType)
          && [PROCEDURE_TYPE.PLATELET, PROCEDURE_TYPE.PLASMA].includes(setting.procedureType));
      if (isResourceRoleApplied) {
        totalApheresisStaff = totalApheresisStaff + noOfStaff;
      }
    });

    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
      resourceQuantityMap.set('Apheresis', {
        quantity: Math.round(totalApheresisStaff)
      })
    });
  }

  calculateApheresisChargeQuantity() {
    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
      resourceQuantityMap.set('Apheresis Charge', {
        quantity: 1
      })
    });
  }

  calculateVolunteerDonorAmbassadors() {
    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let volunteerQuantityMap = this.mapVolunteerQuantity.get(driveShift.key);
      let drawHours = this.helper.calculateDrawHours(driveShift, this.masterData);
      if(drawHours <= 0) return;
      if (!this.masterData.staffingDecisionMatrix) return;

      let totalProceduresProjected = driveShift.totalProceduresProjected;
      let nrVolunteerFixedSiteBandLower = this.masterData.staffingDecisionMatrix.nrVolunteerFixedSiteBandLower;
      let nrVolunteerFixedSiteBandUpper = this.masterData.staffingDecisionMatrix.nrVolunteerFixedSiteBandUpper;
      let noOfVolunteerDonorAmbassadors = 0;

      if (totalProceduresProjected < nrVolunteerFixedSiteBandLower) {
        noOfVolunteerDonorAmbassadors = 0;
      }
      else if (nrVolunteerFixedSiteBandLower <= totalProceduresProjected && totalProceduresProjected <= nrVolunteerFixedSiteBandUpper) {
        noOfVolunteerDonorAmbassadors = 1;
      }
      else {
        noOfVolunteerDonorAmbassadors = 2;
      }

      volunteerQuantityMap.set('Donor Ambassador', noOfVolunteerDonorAmbassadors);
    });
  }

  /** Generate drive shifts & jobs */
  applyStaffingComplementAndProposeDriveShifts() {
    const staffingComplementChanged = this.drive.staffingComplementChanged;
    if(!staffingComplementChanged) return;

    this.proposeDriveShifts({
      skipCalculateResourceRoles: true,
      skipGenerateSlots: false
    })
  }

  proposeDriveShifts({
    skipCalculateResourceRoles = false,
    skipGenerateSlots = false
  } = {}) {

    let jobsUpdatedViaDualRoleChangeMap = {};
    this.drive.driveShifts.forEach((driveShift, driveShiftIndex) => {
      if(!jobsUpdatedViaDualRoleChangeMap[driveShiftIndex]) {
        jobsUpdatedViaDualRoleChangeMap[driveShiftIndex] = [];
      }

      driveShift.jobs.forEach(job => {
        if(job.resourceRole && job.isCreatedOrUpdatedViaDualRoleChange) {
          jobsUpdatedViaDualRoleChangeMap[driveShiftIndex].push(cloneDeep(job));
        }
      })
    });

    this.initResourceQuantityMap();
    this.calculateResourceQuantity(skipCalculateResourceRoles, jobsUpdatedViaDualRoleChangeMap);

    this.drive.driveShifts = this.buildMultiDriveShifts();

    if(!skipGenerateSlots && !this.masterData.skipGenerateSlots) {
      this.drive.driveShifts.forEach((driveShift) => {
        this.generateShiftSlots(driveShift);
      })
  
      this.updateDriveTotalSlots();
    }
  
    this.populateDriveTime();
    this.updateDriveProcedureCapacity();
    this.updateDriveRequestedResources();
  }

  buildMultiDriveShifts() {
    let driveShiftsMetadata = this.drive.driveShiftsMetadata;
    let driveShifts = [];

    driveShiftsMetadata.driveShifts.forEach((driveShiftMetadata, index) => {
      const originalDriveShift = this.drive.driveShifts[index];
      let proposedDriveShift = {
        ...autoMapper.autoMapperInstance.initiateModel('sked_Drive_Shift__c'),
        id: null,
        key: originalDriveShift?.key || generateUUID(),
        validities: [],
        driveShiftMetadata: driveShiftMetadata,
        driveDate: this.drive.driveDate,
        start: driveShiftMetadata.start,
        finish: driveShiftMetadata.finish,
        startTime: driveShiftMetadata.startTime,
        endTime: driveShiftMetadata.endTime,
        plateletRounds: driveShiftMetadata.numberOfRounds,
        x2rbcProjectedProcedures: driveShiftMetadata.x2rbcProjectedProcedures,
        wbProjectedProcedures: driveShiftMetadata.wbProjectedProcedures,
        plateletProjectedProcedures: driveShiftMetadata.plateletProjectedProcedures,
        plasmaProjectedProcedures: driveShiftMetadata.plasmaProjectedProcedures
      };

      this.populateDriveShiftTags(proposedDriveShift);
      this.populateDriveShiftJobs(proposedDriveShift, index);
      this.updateShiftMobileSetup(proposedDriveShift);
      this.applyRoleTimeForSingleDriveShift(proposedDriveShift);
      this.calculateTotalProceduresProjected(proposedDriveShift);
      this.populateLunchBreakTime(proposedDriveShift, { restoreLunchBreak: true });
      this.populateShiftTime(proposedDriveShift);
      
      proposedDriveShift.jobs = proposedDriveShift.jobs
      .filter(item => {
        if (index === 0) return true;
        return item.resourceRole || item.volunteerRole;
      })
      .map(item => {
        return {
          ...item,
          id: null,
          key: generateUUID()
        }
      });
   
      driveShifts.push(proposedDriveShift);
    })

    driveShifts.forEach((driveShift, index) => {
      if (this.drive.driveShifts[index]) {
        let originalDriveShift = this.drive.driveShifts[index];
        driveShift.id = originalDriveShift.id;
        driveShift.key = originalDriveShift.key;

        driveShift.slots = originalDriveShift.slots;
        driveShift.canGenerateSlots = driveShift.slots?.length > 0;
        driveShift.default2rbcSlots = originalDriveShift.default2rbcSlots;
        driveShift.defaultWbSlots = originalDriveShift.defaultWbSlots;
        driveShift.defaultPlasmaSlots = originalDriveShift.defaultPlasmaSlots;
        driveShift.defaultPlateletSlots = originalDriveShift.defaultPlateletSlots;

        let availableOriginalJobs = [ ...(originalDriveShift.jobs || []) ];

        //clone jobs but need to replace key or id.
        if (driveShift.jobs && driveShift.jobs.length) {
          driveShift.jobs.forEach((job) => {
            let originalJob = this.helper.findJob(job, availableOriginalJobs);
            if (originalJob) {
              job.id = originalJob.id;
              job.key = originalJob.key;
              availableOriginalJobs = availableOriginalJobs.filter(
                  item => item.id !== originalJob.id
              );

              (originalJob.jobTags || []).forEach(originalJobTag => {
                if (originalJobTag.systemCreated && originalJobTag.tag && originalJobTag.tag.type !== 'Physical Location Type') {
                  const found = job.jobTags.find(jobTag => {
                    return jobTag.tagId === originalJobTag.tagId;
                  })
                  if (!found) {
                    job.jobTags.push(originalJobTag);
                  }
                }
              })

              if (originalJob.jobAllocations && originalJob.jobAllocations.length) {
                job.jobAllocations = [...originalJob.jobAllocations];
                this.applyJobTimeToJobAllocations(job);
              }
            }
          });
        }
      }

      this.buildJobTagNames(driveShift);
      this.updateShiftMobileSetup(driveShift);
    });

    return driveShifts;
  }

  populateDriveShiftTags(driveShift) {
    driveShift.driveShiftTags = this.helper.calculateDriveShiftTags(this.masterData);
  }

  populateDriveShiftJobs(driveShift, driveShiftIndex) {
    const driveShiftMetadata = driveShift.driveShiftMetadata;
    let jobTagsMap = this.helper.calculateJobTagsMap(this.masterData);
    let jobTemplate = {
      driveSiteId: this.drive.driveSiteId,
      collectionOperationId: this.drive.collectionOperationId,
      address: this.drive.driveSite?.address,
      latitude: this.drive.driveSite?.geoLocationLatitude,
      longitude: this.drive.driveSite?.geoLocationLongitude,
      jobAllocationTimeSource: false,
      isManuallyCreated: false,
      manuallyCreatedFrom: ''
    }

    let jobs = [];
    const mapResourceQuantity = this.mapResourceQuantity.get(driveShiftMetadata.key);
    mapResourceQuantity.forEach(({ quantity, systemQuantity, isManuallyCreated, manuallyCreatedFrom }, mergedJobType) => {
      if (quantity > 0) {
        let { jobType, jobSubtype } = this.helper.splitMergedJobType(mergedJobType);
        let job = (driveShift.jobs || []).find(driveShiftJob => {
          if (jobSubtype) {
            return driveShiftJob.resourceRole === jobType && driveShiftJob.procedureType === jobSubtype;
          }
          return driveShiftJob.resourceRole === jobType;
        });
        if (!job) {
          job = cloneDeep(jobTemplate);
          job.key = generateUUID();
        }

        job.jobTags = cloneDeep(jobTagsMap[RESOURCE_TYPE.PERSON]);
        job.tagNames = job.jobTags.map(item => item.tag.name).join(', ');
        job.resourceRole = jobType;
        job.procedureType = jobSubtype;
        job.quantity = quantity;
        job.systemQuantity = systemQuantity || job.quantity;
        job.isManuallyCreated = !!isManuallyCreated;
        job.manuallyCreatedFrom = manuallyCreatedFrom;
        jobs.push(job);
      }
    });

    const originalDriveShift = this.drive.driveShifts[driveShiftIndex];
    const mapVolunteerQuantity = this.mapVolunteerQuantity.get(driveShiftMetadata.key);
    mapVolunteerQuantity.forEach((quantity, volunteerRole) => {
      let job = (driveShift.jobs || []).find(driveShiftJob => driveShiftJob.volunteerRole == volunteerRole);
      if (!job) {
        job = cloneDeep(jobTemplate);
        job.key = generateUUID();
      }
      job.jobTags = cloneDeep(jobTagsMap[RESOURCE_TYPE.PERSON]);
      job.tagNames = job.jobTags.map(item => item.tag.name).join(', ');
      job.volunteerRole = volunteerRole;
      const originalJob = this.helper.findJob(job, originalDriveShift?.jobs || []);
      let volunteerJobQuantityRetainNeeded = false;
      if (volunteerRole === 'Donor Ambassador') {
        //HRP-10534: Retain Fixed Site Volunteer Value if Zero
        //HRP-13119: Retain Fixed Site Volunteer if they are locked
        if (originalJob && (originalJob.quantity === 0 || originalJob.isLocked)) {
          job.redcrossVolunteerQuantity = originalJob.redcrossVolunteerQuantity;
          job.sponsorVolunteerQuantity = originalJob.sponsorVolunteerQuantity;
          job.quantity = originalJob.quantity;
          job.isLocked = originalJob.isLocked;
          job.volunteerAdjustmentReason = originalJob.volunteerAdjustmentReason;
          job.isOtherVolunteerAdjustmentReasonSelected = originalJob.isOtherVolunteerAdjustmentReasonSelected;
          volunteerJobQuantityRetainNeeded = true;
        } else {
          job.redcrossVolunteerQuantity = quantity || 0;
          job.sponsorVolunteerQuantity = job.sponsorVolunteerQuantity || 0;
          job.quantity = (job.redcrossVolunteerQuantity || 0) + (job.sponsorVolunteerQuantity || 0);
        }
      }
      if (quantity > 0 || volunteerJobQuantityRetainNeeded) {
        jobs.push(job);
      }
    });

    this.mapAssetQuantity.forEach((quantity, mergedJobType) => {
      if (quantity > 0) {
        let { jobType, jobSubtype } = this.helper.splitMergedJobType(mergedJobType);

        let job = (driveShift.jobs || []).find(driveShiftJob => {
          if (jobSubtype) {
            return driveShiftJob.assetType === jobType && driveShiftJob.equipmentSubtype === jobSubtype;
          }
          return driveShiftJob.assetType === jobType;
        });

        if (!job) {
          job = cloneDeep(jobTemplate);
          job.key = generateUUID();
        }
        job.assetType = jobType;
        job.equipmentSubtype = jobSubtype;
        if (job.assetType === ASSET_TYPE.EQUIPMENT) {
          job.jobTags = cloneDeep(jobTagsMap[ASSET_TYPE.EQUIPMENT]);
        } else {
          job.jobTags = cloneDeep(jobTagsMap[ASSET_TYPE.VEHICLE]);
        }
        job.tagNames = job.jobTags.map(item => item.tag.name).join(', ');
        job.quantity = quantity;
        jobs.push(job);
      }
    });

    //manually created jobs 
    let manuallyCreatedJobs = (originalDriveShift?.jobs || []).filter(job => {
      const isManuallyCreatedJob = this.helper.isManuallyCreatedJob(job, this.drive);
      const existed = this.helper.findJob(job, jobs);
      return isManuallyCreatedJob && !existed;
    })
    .map(job => {
      let updatedJob = extend({}, job, jobTemplate);
      return extend(updatedJob, {
        isManuallyCreated: true, 
        manuallyCreatedFrom: job.manuallyCreatedFrom
      });
    });
    driveShift.jobs = jobs.concat(cloneDeep(manuallyCreatedJobs));
  }

  // To create new jobs /update existing jobs after dual role modification
  repopulateJobsAfterDualRoleModification(driveShift, job) {
    let newJob;
    let existingJob = driveShift.jobs?.find(item => item.resourceRole && !item.dualRole && item.resourceRole === job.dualRole);
    if(existingJob) {
      newJob = {
        ...existingJob,
        quantity: existingJob.quantity + job.quantity,
        isCreatedOrUpdatedViaDualRoleChange: true
      };
      const index = driveShift.jobs?.findIndex(item => item.resourceRole && !item.dualRole && item.resourceRole === job.dualRole);
      driveShift.jobs[index] = newJob;
    } else {
      let jobTagsMap = this.helper.calculateJobTagsMap(this.masterData);
      let jobTemplate = {
        driveSiteId: this.drive.driveSiteId,
        collectionOperationId: this.drive.collectionOperationId,
        address: this.drive.driveSite?.address,
        latitude: this.drive.driveSite?.geoLocationLatitude,
        longitude: this.drive.driveSite?.geoLocationLongitude,
        jobAllocationTimeSource: false,
        isCreatedOrUpdatedViaDualRoleChange: true,
        isManuallyCreated: false,
        manuallyCreatedFrom: ''
      };
      newJob = cloneDeep(jobTemplate);
      newJob.key = generateUUID();
      newJob.jobTags = cloneDeep(jobTagsMap[RESOURCE_TYPE.PERSON]);
      newJob.resourceRole = job.dualRole;
      newJob.dualRole = '';

      if (newJob.resourceRole === 'VP/HH') {
        if (job.quantity > 0) {
          newJob.vphhQuantity = job.quantity;
          newJob.aptQuantity = 0
          newJob.quantity = newJob.vphhQuantity + (newJob.aptQuantity || 0);
          newJob.systemQuantity = job.quantity;
        }
      } else {
        if (job.quantity > 0) {
          newJob.quantity = job.quantity;
          newJob.systemQuantity = job.quantity;
        }
      }

      if (newJob.jobTags && newJob.jobTags.length) {
        let tagNameArr = newJob.jobTags.reduce((result, item) => {
          return result.concat(item.tag.name);
        }, []);
        newJob.tagNames = orderBy(tagNameArr, [item => item], ['asc']).join(", ");
      }
      driveShift.jobs.push(newJob);
    }

    this.applyRoleTimeForSingleJob(driveShift, newJob);
    this.onJobChanged(driveShift, newJob);
  }

  generateDriveShiftRounds(driveShift, numberOfRounds = 1) {
    if (!driveShift) return;

    let rounds = [];
    let shiftStart = driveShift.start;
    let shiftEnd = driveShift.finish;
    for (let i = 0; i < numberOfRounds; i++) {
      let roundStart = new Date(shiftStart.getTime() + (i * 3 * 60 * 60000));
      let roundEnd = new Date(roundStart.getTime() + (3 * 60 * 60000)); //3hrs duration
      if (roundStart.getTime() < shiftEnd.getTime()) {
        rounds.push({
          key: uniqueId('round_'),
          label: `Round ${i + 1}`,
          start: roundStart,
          end: roundEnd,
          startTime: this.helper.dateJSToTimeIso(roundStart, this.masterData.timezoneSidId),
          endTime: this.helper.dateJSToTimeIso(roundEnd, this.masterData.timezoneSidId)
        })
      }
    }

    return rounds;
  }
  
  /** Lunch break */
  updateLunchBreakSettings(driveShift) {
    if(!driveShift || !driveShift.driveShiftMetadata || !driveShift.driveShiftMetadata.lunchBreakSettings) return;
    const driveShiftMetadata = driveShift.driveShiftMetadata;
    const lunchBreakSettings = driveShiftMetadata.lunchBreakSettings;
    lunchBreakSettings.lunchBreak = driveShift.lunchBreak;
    lunchBreakSettings.lunchBreakBeforeDrawHours = driveShift.lunchBreakBeforeDrawHours;
  }

  populateLunchBreakTime(driveShift, { 
    restoreLunchBreak = false
  } = {}) {
    if (!driveShift.driveDate || !driveShift.startTime || !driveShift.endTime || !this.drive.driveSite || !this.drive.collectionOperation) return;

    const originalDriveShift = this.drive.driveShifts.find(item => item.key === driveShift.key);
    const driveShiftMetadata = driveShift.driveShiftMetadata;
    const lunchBreakSettings = driveShiftMetadata.lunchBreakSettings;
    if (this.drive.lockLunchBreak && originalDriveShift && restoreLunchBreak) {
      driveShift.lunchBreak = originalDriveShift.lunchBreak;
      driveShift.lunchBreakBeforeDrawHours = originalDriveShift.lunchBreakBeforeDrawHours;
    } else {
      driveShift.lunchBreak = lunchBreakSettings.lunchBreak;
      driveShift.lunchBreakBeforeDrawHours = lunchBreakSettings.lunchBreakBeforeDrawHours;
    }
    driveShift.maximumLunchBreakDuration = lunchBreakSettings.maximumLunchBreakDuration;

    const drawHoursStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    const drawHoursEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    const drawHoursDuration = (drawHoursEnd.getTime() - drawHoursStart.getTime()) / 60000;

    if (driveShift.lunchBreak == false) {
      driveShift.lunchBreakStartTime = null;
      driveShift.lunchBreakEndTime = null;
      driveShift.lunchBreakDuration = null;
    }
    else {
      let coMaxLunchBreakDuration = lunchBreakSettings.maximumLunchBreakDuration;
      let staffSetup = this.helper.calculateStaffSetup(['Apheresis', 'Apheresis Charge'], driveShift);
      let lunchBreakSetting = this.masterData.lunchBreakSettings.find((setting) => setting.maximumLunchBreakDuration == coMaxLunchBreakDuration);
      let definition = lunchBreakSetting.lunchBreakDefinitions.find(
        (definition) => (definition.minNoOfStaff <= staffSetup && staffSetup <= definition.maxNoOfStaff)
      );

      let lunchBreakStart = null, lunchBreakEnd = null;
      if (driveShift.lunchBreakBeforeDrawHours) {
        driveShift.lunchBreakDuration = lunchBreakSettings.unpaidLunchBreakDuration;
        lunchBreakEnd = drawHoursStart;
        lunchBreakStart = new Date(lunchBreakEnd.getTime() - driveShift.lunchBreakDuration * 60000);
      }
      else {
        driveShift.lunchBreakDuration = definition.lunchBreakDuration;
        let driveDurationBeforeLunch = Math.floor((drawHoursDuration - driveShift.lunchBreakDuration) / 2);
        if (driveDurationBeforeLunch % 15 != 0) {
          driveDurationBeforeLunch = Math.floor(driveDurationBeforeLunch / 15) * 15;
        }
        lunchBreakStart = new Date(drawHoursStart.getTime() + driveDurationBeforeLunch * 60000);
        lunchBreakEnd = new Date(lunchBreakStart.getTime() + driveShift.lunchBreakDuration * 60000);
      }
      this.updateLunchBreakStartEndTime(driveShift, lunchBreakStart, lunchBreakEnd);
    }
  }

  changeLunchBreakStartTime(driveShift) {
    if (!driveShift.driveDate || !driveShift.startTime || !driveShift.endTime) return;

    let lunchBreakStart = this.helper.newDateTime(driveShift.driveDate, driveShift.lunchBreakStartTime, this.masterData.timezoneSidId);
    let lunchBreakEnd = new Date(lunchBreakStart.getTime() + driveShift.lunchBreakDuration * 60000);
    this.updateLunchBreakStartEndTime(driveShift, lunchBreakStart, lunchBreakEnd);
  }

  moveLunchBreakToBeforeDrawHours(driveShift) {
    if (!driveShift.driveDate || !driveShift.startTime || !driveShift.endTime) return;

    driveShift.lunchBreakDuration = this.drive.collectionOperation.unpaidLunchBreakDuration;
    let driveStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let lunchBreakEnd = driveStart;
    let lunchBreakStart = new Date(lunchBreakEnd.getTime() - driveShift.lunchBreakDuration * 60000);
    this.updateLunchBreakStartEndTime(driveShift, lunchBreakStart, lunchBreakEnd);
  }

  moveLunchBreakToDuringDrawHours(driveShift) {
    if (!this.drive.driveSite || !this.drive.collectionOperation) return;

    const driveShiftMetadata = driveShift.driveShiftMetadata;
    const lunchBreakSettings = driveShiftMetadata.lunchBreakSettings;
    let coMaxLunchBreakDuration = lunchBreakSettings.maximumLunchBreakDuration;
    let lunchBreakSetting = this.masterData.lunchBreakSettings.find((setting) => setting.maximumLunchBreakDuration == coMaxLunchBreakDuration);
    let staffSetup = this.helper.calculateStaffSetup(['Apheresis', 'Apheresis Charge'], driveShift);
    let definition = lunchBreakSetting.lunchBreakDefinitions.find(
      (definition) => (definition.minNoOfStaff <= staffSetup && staffSetup <= definition.maxNoOfStaff)
    );
    driveShift.lunchBreakDuration = definition.lunchBreakDuration;

    let drawHoursStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let drawHoursEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    let drawHoursDuration = (drawHoursEnd.getTime() - drawHoursStart.getTime()) / 60000;

    let driveDurationBeforeLunch = Math.floor((drawHoursDuration - driveShift.lunchBreakDuration) / 2);
    if (driveDurationBeforeLunch % 15 != 0) {
      driveDurationBeforeLunch = Math.floor(driveDurationBeforeLunch / 15) * 15;
    }
    let lunchBreakStart = new Date(drawHoursStart.getTime() + driveDurationBeforeLunch * 60000);
    let lunchBreakEnd = new Date(lunchBreakStart.getTime() + driveShift.lunchBreakDuration * 60000);

    this.updateLunchBreakStartEndTime(driveShift, lunchBreakStart, lunchBreakEnd);
  }

  /** Generate slots */
  proposeDriveShiftSlots() {
    if (!this.drive || !this.drive.driveShifts) return;

    this.drive.driveShifts.forEach((driveShift) => {
      this.generateShiftSlots(driveShift);
    })
  }

  generateShiftSlots(driveShift) {
    driveShift.canGenerateSlots = false;

    if ([OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH].includes(this.drive.operationType)
      && !this.drive.driveShiftsMetadata) return;
    if (!driveShift.driveDate || !driveShift.startTime || !driveShift.endTime) return;

    const driveShiftMetadata = driveShift.driveShiftMetadata;
    let shiftStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let shiftEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    if (shiftStart >= shiftEnd) {
      return;
    }

    if (!driveShift.jobs || !driveShift.jobs.length) return;
    if (driveShift.equipment == undefined || driveShift.equipment == null) {
      return;
    }

    driveShift.canGenerateSlots = true;

    let plateletSlots = [];
    let _2rbcSlots = [];
    let wbSlots = [];
    let plasmaSlots = [];
    let excludedTimeRanges = this.generateExcludedTimeRangesFromPlateletRounds(driveShift);

    if (this.drive.operationType === OPERATION_TYPE.INTEGRATED) {
      plateletSlots = this.generatePlateletSlots(driveShift);
      plasmaSlots = this.generatePlasmaSlots(driveShift, excludedTimeRanges);
      wbSlots = this.generateWbSlots(driveShift, excludedTimeRanges);
      _2rbcSlots = this.generate2rbcSlots(driveShift, excludedTimeRanges);
    }
    else if (this.drive.operationType === OPERATION_TYPE.NON_INTEGRATED_APH) {
      plateletSlots = this.generatePlateletSlots(driveShift);
      plasmaSlots = this.generatePlasmaSlots(driveShift, excludedTimeRanges);
    }

    // this.postProcessGenerateShiftSlots(driveShift, wbSlots, _2rbcSlots);

    if (driveShift.lunchBreak) {
      if (!driveShift.lunchBreakBeforeDrawHours) {
        let coMaxLunchBreakDuration = driveShiftMetadata.lunchBreakSettings.maximumLunchBreakDuration;
        let lunchBreakSetting = this.masterData.lunchBreakSettings.find((setting) => setting.maximumLunchBreakDuration == coMaxLunchBreakDuration);
        let staffSetup = this.helper.calculateStaffSetup(['Apheresis', 'Apheresis Charge'], driveShift);
        let lunchBreakDefinition = lunchBreakSetting?.lunchBreakDefinitions.find(
          (definition) => (definition.minNoOfStaff <= staffSetup && staffSetup <= definition.maxNoOfStaff)
        );

        if (wbSlots && wbSlots.length && lunchBreakDefinition) {
          let slotReductionConfiguration = {
            endTime: this.helper.newDateTime(driveShift.driveDate, driveShift.lunchBreakEndTime, this.masterData.timezoneSidId),
            interval: 60,
            roundConfigurations: [
              { minutesIntoStart: 0 },
              { minutesIntoStart: 30 },
              { minutesIntoStart: 15 },
              { minutesIntoStart: 45 }
            ],
            slotReduction: lunchBreakDefinition.slotReduction,
            startTime: this.helper.newDateTime(driveShift.driveDate, driveShift.lunchBreakStartTime, this.masterData.timezoneSidId)
          };

          this.reduceSlots(wbSlots, slotReductionConfiguration);
        }

        driveShift.signUpReduction = lunchBreakDefinition ? lunchBreakDefinition.slotReduction : null;
      }
      else {
        driveShift.signUpReduction = null;
      }
    }

    driveShift.default2rbcSlots = _2rbcSlots.length;
    driveShift.defaultWbSlots = wbSlots.length;
    driveShift.defaultPlateletSlots = plateletSlots.length;
    driveShift.defaultPlasmaSlots = plasmaSlots.length;
    driveShift.slots = [...plateletSlots, ...plasmaSlots, ..._2rbcSlots, ...wbSlots];
    driveShift.totalSlots = driveShift.slots.length;

    this.backupDriveShift(driveShift);
  }

  generateExcludedTimeRangesFromPlateletRounds(driveShift) {
    if (!driveShift || !this.drive.driveShiftsMetadata) return [];

    let excludedTimeRanges = [];
    let driveShiftIndex = this.drive.driveShifts.findIndex(item => item.key === driveShift.key);
    let driveShiftMetadata = this.drive.driveShiftsMetadata.driveShifts[driveShiftIndex];
    driveShiftMetadata.rounds.forEach(round => {
      let start = round.start;
      let end = new Date(start.getTime() + (1 * 60 * 60000)); //1hr duration
      excludedTimeRanges.push({
        start: round.start,
        end: end,
        startTime: this.helper.dateJSToTimeIso(start, this.masterData.timezoneSidId),
        endTime: this.helper.dateJSToTimeIso(end, this.masterData.timezoneSidId),
      })
    });
    return excludedTimeRanges;
  }

  calculatePlateletGroupsQuantity(allRounds = [], numberOfPlateletAssets = 0) { 
    let remainingNumberOfAssets = numberOfPlateletAssets;
    let groupsQuantity = [];
    allRounds.forEach((round, roundIndex) => {
      let groupQuantity = Math.ceil(remainingNumberOfAssets / (allRounds.length - roundIndex));
      if (groupQuantity > remainingNumberOfAssets) {
        groupQuantity = remainingNumberOfAssets;
      }

      groupsQuantity.push(groupQuantity);

      remainingNumberOfAssets = remainingNumberOfAssets - groupQuantity;
    });
   
    return groupsQuantity;
  }

  generatePlateletSlots(driveShift) {
    let fixedSiteAppointmentPattern = this.drive.driveSite.fixedSiteAppointmentPattern || FIXED_SITE_APPOINTMENT_PATTERN.GROUPED;
    let numberOfPlateletAssets = this.drive.numberOfPlateletAssets || 0;
    let slotDuration = 3 * 60;
    if (!numberOfPlateletAssets) return [];

    let slotTemplate = {
      name: 'Platelet',
      locked: false,
      slotType: 'Platelet',
      status: "Open"
    }

    let slots = [];
    let roundConfigurations = []
    if (fixedSiteAppointmentPattern === FIXED_SITE_APPOINTMENT_PATTERN.GROUPED) {
      if (numberOfPlateletAssets <= 2) {
        roundConfigurations = [
          { minutesIntoStart: 0 }
        ];
      } else {
        roundConfigurations = [
          { minutesIntoStart: 0 },
          { minutesIntoStart: 30 }
        ];
      }
    } else if (fixedSiteAppointmentPattern === FIXED_SITE_APPOINTMENT_PATTERN.EVEN) {
      roundConfigurations = [
        { minutesIntoStart: 0 },
        { minutesIntoStart: 15 },
        { minutesIntoStart: 30 }
      ].slice(0, numberOfPlateletAssets < 3 ? numberOfPlateletAssets : 3);
    } else if (fixedSiteAppointmentPattern === FIXED_SITE_APPOINTMENT_PATTERN.EVEN_4_INTERVAL) {
      roundConfigurations = [
        { minutesIntoStart: 0 },
        { minutesIntoStart: 30 },
        { minutesIntoStart: 15 },
        { minutesIntoStart: 45 }
      ].slice(0, numberOfPlateletAssets < 4 ? numberOfPlateletAssets : 4);
    }

    let driveShiftsMetadata = this.drive.driveShiftsMetadata;
    let driveShiftIndex = this.drive.driveShifts.findIndex(item => item.key === driveShift.key);
    let driveShiftMetadata = driveShiftsMetadata.driveShifts[driveShiftIndex];
    driveShiftMetadata.rounds.forEach(round => {
      let tempStart = round.start;
      const groupsQuantity = this.calculatePlateletGroupsQuantity(roundConfigurations, numberOfPlateletAssets);
      roundConfigurations.forEach((round, roundIndex) => {
        const groupQuantity = groupsQuantity[roundIndex];
        let slotStartTime = new Date(tempStart.getTime() + (round.minutesIntoStart * 60000));
        let slotEndTime = new Date(tempStart.getTime() + slotDuration * 60000);

        slots = slots.concat(this.multiplySlots(driveShift, {
          ...slotTemplate,
          key: generateUUID(),
          startTime: slotStartTime.toISOString(),
          endTime: slotEndTime.toISOString(),
        }, groupQuantity));
      });
    })

    return slots;
  }

  generatePlasmaSlots(driveShift, excludedTimeRanges = []) {
    let numberOfPlasmaAssets = this.drive.numberOfPlasmaAssets || 0;
    if (!numberOfPlasmaAssets) return [];

    let driveShiftStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let driveShiftEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    let driveShiftIndex = this.drive.driveShifts.findIndex(item => item.key === driveShift.key);
    let firstSlotStart, lastSlotStart;
    
    const firstPlateletRoundEnd = new Date(driveShiftStart.getTime() + 60 * 60000); //end after 60m
    firstSlotStart = firstPlateletRoundEnd;
    //need to reduce start time to make sure first slot is at 10 or 40 minutes
    let startInMinutes = firstSlotStart.getMinutes();
    if (startInMinutes > 40) {
      firstSlotStart.setMinutes(40);
      firstSlotStart = new Date(firstSlotStart.getTime() + 30 * 60000);
    } else if (startInMinutes > 10) {
      firstSlotStart.setMinutes(40);
    } else if (startInMinutes >= 0) {
      firstSlotStart.setMinutes(10);
    }
    
    if (driveShiftIndex === this.drive.driveShifts.length - 1) {
      //last shift
      lastSlotStart = new Date(driveShiftEnd.getTime() - 50 * 60000); //50 minutes before Drive Shift End
    } else {
      lastSlotStart = driveShiftEnd;
    }

    return this.generateSlotsByNumberOfAssets(driveShift, {
      roundInterval: 90,
      numberOfGroups: 2,
      groupInterval: 30,
      slotType: 'Plasma',
      slotDuration: 90,
      firstSlotStart: firstSlotStart,
      lastSlotStart: lastSlotStart,
      numberOfAssets: numberOfPlasmaAssets,
      excludedTimeRanges: excludedTimeRanges
    })
  }

  generateWbSlots(driveShift, excludedTimeRanges = []) {
    let wbSetting = (this.masterData.fixedSiteProcedureProjections || []).find((setting) => setting.procedureType === PROCEDURE_TYPE.WB);
    let projectedProcedures = this.helper.getProjectedProceduresByProcedureType(this.drive, PROCEDURE_TYPE.WB);
    let x = isNullOrEmpty(wbSetting) ? 0 : Math.ceil(projectedProcedures / (1 - wbSetting.qns / 100) / (1 - wbSetting.deferral / 100));
    let paddingPercentage = isNullOrEmpty(this.drive.opportunity.slotGenerator) ? this.masterData.adminSetting.callListRecipientNoneFixedSite : this.drive.opportunity.slotGenerator / 100;
    let totalSlots = Math.ceil(x * paddingPercentage);
    let shiftStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let shiftEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);

    let WBConfiguration = {
      interval: 60,
      roundConfigurations: [
        { minutesIntoStart: 0 },
        { minutesIntoStart: 15 },
        { minutesIntoStart: 30 },
        { minutesIntoStart: 45 }
      ],
      slotDuration: 15,
      slotType: "Whole Blood",
      startTime: shiftStart,
      totalSlots: totalSlots,
      excludedTimeRanges: excludedTimeRanges
    }

    const isLastShift = this.drive.driveShifts.findIndex(item => item.key === driveShift.key) === this.drive.driveShifts.length - 1;
    if (isLastShift) {
      WBConfiguration.lastSlotStart = shiftEnd;
      if(this.helper.isDriveSkipLastAppointment(this.drive)) {
        WBConfiguration.lastSlotStart = new Date(shiftEnd.getTime() - (15 * 60000));
      }
    } else {
      WBConfiguration.lastSlotStart = new Date(shiftEnd.getTime() - (15 * 60000));
    }
    
    return this.generateSlots(WBConfiguration);
  }

  generateSlots(configuration) {
    let slots = [];
    let roundCount = 1;
    let slotCount = 0;
    let excludedTimeRanges = configuration.excludedTimeRanges || [];

    while (slotCount < configuration.totalSlots) {
      let configurationIndex = roundCount % configuration.roundConfigurations.length;
      configurationIndex = (configurationIndex == 0 ? configuration.roundConfigurations.length : configurationIndex) - 1;
      let roundConfiguration = configuration.roundConfigurations[configurationIndex];
      let firstSlotStart = new Date(configuration.startTime.getTime() + (roundConfiguration.minutesIntoStart * 60000));
      let tempDt = firstSlotStart;

      if (firstSlotStart > configuration.lastSlotStart) {
        break;
      }

      while (tempDt <= configuration.lastSlotStart) {
        let slot = {
          key: generateUUID(),
          name: configuration.slotType,
          label: '',
          startTime: tempDt.toISOString(),
          endTime: new Date(tempDt.getTime() + configuration.slotDuration * 60000).toISOString(),
          locked: false,
          slotType: configuration.slotType,
          status: "Open"
        }

        if (!this.isTimeExcluded(slot.startTime, excludedTimeRanges)) {
          slots.push(slot);
          slotCount++;
        }

        if (slotCount == configuration.totalSlots) {
          break;
        }

        tempDt = new Date(tempDt.getTime() + configuration.interval * 60000);
      }
      roundCount++;
    }
    return slots;
  }

  reduceSlots(slots, configuration) {
    let totalSlots = 0;
    let startTimeIso = configuration.startTime.toISOString();
    let endTimeIso = configuration.endTime.toISOString();
    slots.forEach((slot) => {
      if (startTimeIso <= slot.startTime && slot.endTime <= endTimeIso) {
        totalSlots++;
      }
    });
    let numberOfReducedSlots = Math.ceil(totalSlots * ((configuration.slotReduction / 100)));
    let reduceSlotCount = 0;
    let roundCount = 1;
    while (reduceSlotCount < numberOfReducedSlots) {
      let configurationIndex = roundCount % configuration.roundConfigurations.length;
      configurationIndex = (configurationIndex == 0 ? configuration.roundConfigurations.length : configurationIndex) - 1;
      let roundConfiguration = configuration.roundConfigurations[configurationIndex];
      let firstSlotStart = new Date(configuration.startTime.getTime() + (roundConfiguration.minutesIntoStart * 60000));
      let tempDt = firstSlotStart;

      while (tempDt < configuration.endTime) {
        let tempISOString = tempDt.toISOString();
        const index = slots.findIndex((slot) => slot.startTime == tempISOString);
        if (index > -1) {
          slots.splice(index, 1);
          reduceSlotCount++;
        }
        if (reduceSlotCount == numberOfReducedSlots) {
          break;
        }

        tempDt = new Date(tempDt.getTime() + configuration.interval * 60000);
      }
      roundCount++;
    }
  }

  postProcessGenerateShiftSlots(driveShift, wbSlots = [], _2rbcSlots = []) {
    _2rbcSlots.forEach(_2rbcSlot => {
      let wbSlotIndex = wbSlots.findIndex(_wbSlot => _wbSlot.startTime === _2rbcSlot.startTime);
      if (wbSlotIndex > -1) {
        wbSlots.splice(wbSlotIndex, 1);
      }
    })

    if (wbSlots.length === 0) {
      _2rbcSlots = [];
    }

    if (_2rbcSlots.length < driveShift.x2rbcProjectedProcedures) {
      driveShift.x2rbcProjectedProcedures = _2rbcSlots.length;
      this.calculateTotalProceduresProjected(driveShift);
    }
  }

  /** Change handlers */
  handleTotalVehicleRequestedChanged() {
    if (!this.drive.totalVehicleRequestedChanged) return;

    //allocate vehicles to job 
    let vehicleJob = null;
    if (this.drive.driveShifts && this.drive.driveShifts.length) {
      vehicleJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE)
    }
    if (vehicleJob) {
      if (!vehicleJob.jobAllocations) {
        vehicleJob.jobAllocations = [];
      }

      vehicleJob.jobAllocations.forEach((jobAllocation) => {
        let newVehicle = this.drive.totalVehicleRequestedChanged.vehicles.find(vehicle => vehicle.id === jobAllocation.resourceId);
        if (!newVehicle) {
          jobAllocation.previousStatus = jobAllocation.status;
          jobAllocation.status = JOB_ALLOCATION_STATUS.DELETED;
        }
      });

      this.drive.totalVehicleRequestedChanged.vehicles.forEach((vehicle) => {
        let existingJobAllocation = vehicleJob.jobAllocations.find(jobAllocation => vehicle.id === jobAllocation.resourceId);
        if (!existingJobAllocation) {
          vehicleJob.jobAllocations.push({
            resourceId: vehicle.id,
            resource: vehicle
          })
        } else {
          if (existingJobAllocation.previousStatus !== JOB_ALLOCATION_STATUS.DELETED && 
            existingJobAllocation.status === JOB_ALLOCATION_STATUS.DELETED) {
            existingJobAllocation.status = existingJobAllocation.previousStatus;
          }
        }
      });
    }

    this.drive.driveShifts.forEach(driveShift => {
      this.updateShiftMobileSetup(driveShift);
    })

    return this.drive;
  }

  handleEquipmentRequestedChanged() {
    if (!this.drive.driveShifts || !this.drive.driveShifts.length || !this.drive.totalEquipmentRequestedChanged) return;

    const { equipmentJobsMap, lockedEquipments = [] } = this.drive.totalEquipmentRequestedChanged;
    //allocate equipments to jobs 
    let equipmentJobs = [];
    if (this.drive.driveShifts && this.drive.driveShifts.length) {
      equipmentJobs = (this.drive.driveShifts[0].jobs || []).filter(job => job.assetType === ASSET_TYPE.EQUIPMENT);
    }
    equipmentJobs.forEach(equipmentJob => {
      let equipments = (equipmentJobsMap[equipmentJob.equipmentSubtype] || {}).equipments || [];

      if (!equipmentJob.jobAllocations) {
        equipmentJob.jobAllocations = [];
      }

      equipmentJob.jobAllocations.forEach((jobAllocation) => {
        const locked = !!lockedEquipments.find(lockedEquipment => {
          return lockedEquipment.id === jobAllocation.resourceId;
        });
        if(locked) return;
        
        let existingEquipment = equipments.find(equipment => equipment.id === jobAllocation.resourceId);
        if (!existingEquipment) {
          jobAllocation.previousStatus = jobAllocation.status;
          jobAllocation.status = JOB_ALLOCATION_STATUS.DELETED;
        }
      });

      equipments.forEach((equipment) => {
        let existingJobAllocation = equipmentJob.jobAllocations.find(jobAllocation => equipment.id === jobAllocation.resourceId);
        if (!existingJobAllocation) {
          equipmentJob.jobAllocations.push({
            resourceId: equipment.id,
            jobId: equipmentJob.id,
            resource: equipment
          })
        } else {
          if (existingJobAllocation.previousStatus !== JOB_ALLOCATION_STATUS.DELETED && 
            existingJobAllocation.status === JOB_ALLOCATION_STATUS.DELETED) {
            existingJobAllocation.status = existingJobAllocation.previousStatus;
          }
        }
      });
    });

    this.drive.driveShifts.forEach(driveShift => {
      this.updateShiftMobileSetup(driveShift);
    })
    this.calculateDriveProductivityPlanned();
    return this.drive;
  }

  onJobChanged(driveShift, job) {
    this.correctJobTime(job, driveShift);
    this.updateShiftMobileSetup(driveShift);

    if(!job.volunteerRole) {
      this.populateLunchBreakTime(driveShift, { restoreLunchBreak: true });     
      this.populateShiftTime(driveShift);
      this.generateShiftSlots(driveShift);
      this.updateDriveTotalSlots();
      this.populateDriveTime();
      this.updateDriveProcedureCapacity();
      this.updateDriveRequestedResources();
      this.calculateDriveProductivityPlanned();
    }

    if(job.resourceRole) {
      this.applyJobTimeToJobAllocations(job);
    }

    this.resetElectContentions();
  }

  handleDriveShiftsMetadataChanged() {
    if (this.drive.driveShiftsMetadata) {
      this.calculateTotalProceduresProjected(this.drive.driveShiftsMetadata);
      this.drive.driveShiftsMetadata.driveShifts.forEach((driveShiftMetadata) => {
        this.calculateTotalProceduresProjected(driveShiftMetadata);
        driveShiftMetadata.resourceRoleGroupRoleTimeDataMap = this.helper.calculateDriveShiftRoleTimeData(
          this.masterData,
          this.drive,
          driveShiftMetadata
        );
        driveShiftMetadata.lunchBreakSettings = this.helper.calculateDriveShiftLunchBreakSettings(this.drive, driveShiftMetadata, this.masterData);
      });
      
      this.drive.x2rbcProjectedProcedures = this.drive.driveShiftsMetadata.x2rbcProjectedProcedures;
      this.drive.wbProjectedProcedures = this.drive.driveShiftsMetadata.wbProjectedProcedures;
      this.drive.plateletProjectedProcedures = this.drive.driveShiftsMetadata.plateletProjectedProcedures;
      this.drive.plasmaProjectedProcedures = this.drive.driveShiftsMetadata.plasmaProjectedProcedures;
    }

    this.proposeDriveShifts();
    this.calculateDriveProductivityPlanned();
    this.calculateTotalProceduresProjected();
  }

  /** Temporary */
  getCurrentAssignedEquipments() {
    return this.helper.getCurrentAssignedEquipments(this.drive);
  }

  compareAndGetDriveChanges() {
    return this.helper.compareAndGetDriveChanges(this.masterData.backupDrive, this.drive);
  }

  retrieveFixedSiteProcedureProjections() {
    return this.fetch.retrieveFixedSiteProcedureProjections(this.drive)
    .then((fixedSiteProcedureProjections = []) => {
      this.masterData.fixedSiteProcedureProjections = fixedSiteProcedureProjections; 
    })
  }

  retrieveDriveSite() {
    return this.fetch.retrieveDriveSite(this.drive)
    .then((driveSite) => {
      this.drive.driveSite = driveSite;
      this.masterData.driveSite = driveSite;
      if (driveSite) {
        this.masterData.timezoneSidId = driveSite.timezoneSidId;
      }

      return this.fetch.retrieveTravelTimeIndexItemMap(this.drive);
    })
    .then((travelTimeIndexItemMap) => {
      this.masterData.travelTimeIndexItemMap = travelTimeIndexItemMap || {};
    });
  }
  
  retrieveSameDateDrives() {
    return this.fetch.retrieveSameDateDrives(this.drive)
    .then((sameDateDrives) => {
      this.masterData.sameDateDrives = sameDateDrives || []; 
    })
  }

  retrieveSameDateActivities() {
    return this.fetch.retrieveSameDateActivities(this.drive)
    .then((sameDateActivities) => {
      this.masterData.sameDateActivities = sameDateActivities || []; 
    })
  }

  retrieveCollectionOperationSDM() {
    return this.fetch.retrieveCollectionOperationSDM(this.drive)
    .then((staffingDecisionMatrix) => {
      this.masterData.staffingDecisionMatrix = staffingDecisionMatrix;
    })
  }

  retrieveRoleTimeData() {
    return this.fetch.retrieveRoleTimeData(this.drive)
    .then((roleTimeData) => {
      this.masterData.roleTimeData = roleTimeData;
      let { roleTimeDetailMap, roleTimeVarianceMap, roleGroupTimeDetailMap, roleGroupTimeVarianceMap } = this.helper.buildRoleTimeDetailMap(this.drive, this.masterData);
      this.masterData.roleTimeDetailMap = roleTimeDetailMap;
      this.masterData.roleTimeVarianceMap = roleTimeVarianceMap;
      this.masterData.roleGroupTimeDetailMap = roleGroupTimeDetailMap;
      this.masterData.roleGroupTimeVarianceMap = roleGroupTimeVarianceMap;
    })
  }

  retrieveDefaultTags() {
    return this.fetch.retrieveDefaultTags(this.drive)
    .then((driveTags) => {
      this.masterData.driveTags = driveTags;
    })
  }
}

export {
  FixedSiteGenerator,
  DRIVE_FIELD_CHANGE_MAPPING
};