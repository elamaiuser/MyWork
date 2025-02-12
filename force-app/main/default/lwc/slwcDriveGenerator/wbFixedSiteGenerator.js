import TIME_ZONE from '@salesforce/i18n/timeZone';
import { BaseGenerator } from './baseGenerator';
import * as autoMapper from 'c/autoMapper';
import { debugLogService, operationDriveLimitService, operationDriveLimitQueryModel, 
  staffingConstraintService, staffingConstraintQueryModel } from 'c/dataService';
import { isNullOrEmpty, generateUUID } from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { cloneDeep, difference, uniqueId, extend } from 'c/lodash';
import { Fetch } from './fetch';
import { PROCEDURE_TYPE, DRIVE_STATUS, ASSET_TYPE, PENDING_ACTION, DRIVE_APPROVAL_STATUS, RESOURCE_TYPE, DRIVE_TYPE, RESOURCE_ROLE_GROUP, DRIVE_CONTENTION, JOB_ALLOCATION_STATUS } from 'c/slwcConstants';

const DEFAULT_CALENDAR_SETTINGS = {
  timezone: TIME_ZONE,
  firstDay: 0
}

const DRIVE_ACTION_GROUPS_ORDER = [
  ['retrieveDriveSiteAndPopulateCollectionOperation', 'populateSiteCollectionOperation', 'populateDriveCollectionOperation', 'populateCollectionOperationData'],
  ['retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags'],
  ['calculateNumberOf2rbcAssets', 'calculate2rbcProjectedProcedures', 'splitScheduledDonors', 'split2rbcProjectedProcedures', 'calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata',
    'applyStaffingComplementAndProposeDriveShifts', 'proposeDriveShifts', 'proposeDriveShiftSlots', 'updateDriveTotalSlots', 'calculateDriveProductivityPlanned',
    'handleEquipmentRequestedChanged', 'handleDriveShiftsMetadataChanged', 'correctJobAllocationTimes']
]

const DRIVE_FIELD_CHANGE_MAPPING = {
  'driveDate': {
    groups: [
      { actions: ['retrieveDriveSiteAndPopulateCollectionOperation'] },
      { actions: ['retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData'] },
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
  'projectedRegisteredDonors': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['splitScheduledDonors', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
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
      { actions: ['calculateTotalProceduresProjected', 'calculateNumberOf2rbcAssets', 'calculatePreferredNumberOf2rbcAssets', 'calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
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
  'aptRequired': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
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
  'totalEquipmentRequestedChanged': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleEquipmentRequestedChanged'] },
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
  'numberOf2rbcAssets': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculate2rbcProjectedProcedures', 'calculateTotalProceduresProjected', 'split2rbcProjectedProcedures', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'IMPACT': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
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
  // 'startTime': {
  //     groups: [
  //         { actions: [] },
  //         { actions: ['populateLunchBreakTime', 'populateShiftTime', 'checkOverlapAndGenerateShiftSlots', 'updateDriveTotalSlots', 'populateDriveTime'] }
  //     ]
  // },
  // 'endTime': {
  //     groups: [
  //         { actions: [] },
  //         { actions: ['populateLunchBreakTime', 'populateShiftTime', 'checkOverlapAndGenerateShiftSlots', 'updateDriveTotalSlots', 'populateDriveTime'] }
  //     ]
  // },
  'lunchBreak': {
    groups: [
      { actions: [] },
      { actions: ['updateLunchBreakSettings', 'populateLunchBreakTime', 'populateShiftTime', 'populateDriveTime', 'updateDriveStaffCapacity', 'updateDriveAverageStaffCapacity', 'updateDriveMaxRoleCapacity', 'updateDriveExcessStaffCapacity', 'generateShiftSlots', 'updateDriveTotalSlots'] },
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
            $this.populateDriveTime();
            $this.updateDriveStaffCapacity();
            $this.updateDriveAverageStaffCapacity();
            $this.updateDriveMaxRoleCapacity();
            $this.updateDriveExcessStaffCapacity();
            $this.generateShiftSlots(driveShift);
            $this.updateDriveTotalSlots()
          }
          else {
            $this.moveLunchBreakToDuringDrawHours(driveShift);
            $this.populateShiftTime(driveShift);
            $this.populateDriveTime();
            $this.updateDriveStaffCapacity();
            $this.updateDriveAverageStaffCapacity();
            $this.updateDriveMaxRoleCapacity();
            $this.updateDriveExcessStaffCapacity();
            $this.generateShiftSlots(driveShift);
            $this.updateDriveTotalSlots();
          }
        }]
      },
    ]
  },
  'lunchBreakStartTime': {
    groups: [
      { actions: [] },
      { actions: ['changeLunchBreakStartTime', 'updateDriveStaffCapacity', 'updateDriveAverageStaffCapacity', 'updateDriveMaxRoleCapacity', 'updateDriveExcessStaffCapacity', 'generateShiftSlots', 'updateDriveTotalSlots'] },
    ]
  },
}

class WbFixedSiteGenerator extends BaseGenerator {
  constructor() {
    const fetch = new Fetch({
      driveType: DRIVE_TYPE.MOBILE
    });
    super({
      fetch,
      DRIVE_ACTION_GROUPS_ORDER,
      DRIVE_FIELD_CHANGE_MAPPING,
      DRIVE_SHIFT_FIELD_CHANGE_MAPPING
    })
  }

  initializeFromOptyId(oppId) {
    this.errorMessages = [];

    return Promise.all([
      this.fetch.retrieveOpportunity(oppId),
      this.fetch.retrieveLoginUser()
    ])
      .then(([opp, loginUser]) => {
        if (!opp.drives) {
          return Promise.resolve()
            .then(() => {
              if (this.validateOpty(opp)) {
                this.drive = this.initiateNewDriveFromOpty(opp);
                return Promise.all([
                  this.fetch.retrieveDriveSite(this.drive)
                    .then(driveSite => {
                      this.drive.driveSite = driveSite;
                    }),
                  this.fetch.retrieveCustomSettings()
                ])
                  .then(([driveSite, {
                    resourceRoleGroups,
                    lunchBreakSettings,
                    adminSetting,
                    staffSetupExcludedRoles
                  }]) => {
                    this.populateDriveCollectionOperation();
                    this.populateCollectionOperationData();

                    return Promise.all([
                      driveSite,
                      resourceRoleGroups,
                      lunchBreakSettings,
                      adminSetting,
                      staffSetupExcludedRoles,
                      this.fetch.retrieveTravelTimeIndexItemMap(this.drive),
                      this.fetch.retrieveSameDateDrives(this.drive),
                      this.fetch.retrieveSameDateActivities(this.drive),
                      this.fetch.retrieveCollectionOperationSDM(this.drive),
                      this.fetch.retrieveRoleTimeData(this.drive),
                      this.fetch.retrieveDefaultTags(this.drive),
                      this.fetch.retrieveTerritoryCollectionOperations(this.drive)
                    ])
                  })
                  .then(([driveSite, resourceRoleGroups, lunchBreakSettings, adminSetting, staffSetupExcludedRoles, travelTimeIndexItemMap, sameDateDrives, sameDateActivities, staffingDecisionMatrix, roleTimeData, driveTags, territoryCollectionOperations]) => {
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
                      territoryCollectionOperations,
                      staffSetupExcludedRoles
                    })

                    this.calculateTotalProceduresProjected();
                    this.calculateDriveShiftsMetadata();
                    this.calculateNumberOf2rbcAssets();
                    this.calculatePreferredNumberOf2rbcAssets();
                
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
    this.calculatePreferredNumberOf2rbcAssets();

    this.backupDriveData(this.drive);
    this.drive.driveShifts.forEach((shift) => {
      this.backupDriveShift(shift);
    });
    return this.drive;
  }

  editDrive(driveId) {
    return Promise.all([
      this.fetch.getDriveDetails(driveId),
      this.fetch.retrieveLoginUser()
    ])
      .then(([drive, loginUser]) => {
        this.drive = this.processDriveData(drive);
  
        return Promise.all([
          this.fetch.retrieveDriveSite(this.drive)
            .then(driveSite => {
              this.drive.driveSite = driveSite;
            }),
          this.fetch.retrieveCustomSettings()
        ])
        .then(([driveSite, {
          resourceRoleGroups,
          lunchBreakSettings,
          adminSetting,
          staffSetupExcludedRoles
        }]) => {

          return Promise.all([
            driveSite,
            resourceRoleGroups,
            lunchBreakSettings,
            adminSetting,
            staffSetupExcludedRoles,
            this.fetch.retrieveTravelTimeIndexItemMap(this.drive),
            this.fetch.retrieveSameDateDrives(this.drive),
            this.fetch.retrieveSameDateActivities(this.drive),
            this.fetch.retrieveCollectionOperationSDM(this.drive),
            this.fetch.retrieveRoleTimeData(this.drive),
            this.fetch.retrieveDefaultTags(this.drive),
            this.fetch.retrieveActiveDriveChangeRequest(this.drive)
          ]);
        })
        .then(([driveSite, resourceRoleGroups, lunchBreakSettings, adminSetting, staffSetupExcludedRoles, travelTimeIndexItemMap, sameDateDrives, sameDateActivities, staffingDecisionMatrix, roleTimeData, driveTags, activeDriveChangeRequest]) => {
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
            activeDriveChangeRequest,
            staffSetupExcludedRoles
          })
          
          this.populateCollectionOperationData();
          this.calculatePreferredNumberOf2rbcAssets();
          this.initDriveShiftsMetadata();
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
      { name: 'anticipatedRegisteredDonors', label: 'Anticipated Registered Donors' },
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
        let { slotsToAllocate, availableEquipments: availableEquipmentsCanBeUsed } = this.helper.preProcessSuggestEquipments(totalRequired, availableEquipments, lockedEquipments);
        
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
        let { slotsToAllocate, availableEquipments: availableEquipmentsCanBeUsed } = this.helper.preProcessSuggestEquipments(totalRequired, assignedEquipmentsValid, lockedEquipments);
        
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

    if(this.drive.status === DRIVE_STATUS.DRAFT && !validateDraftDrive) return Promise.resolve({
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
        staffingConstraintQuery.driveTypes = [DRIVE_TYPE.MOBILE];
        staffingConstraintQuery.collectionOpIds = [this.drive.collectionOperationId];

        let driveLimitSvc = new operationDriveLimitService();
        let staffingConstraintSvc = new staffingConstraintService();

        return Promise.all([
          driveLimitSvc.query(driveLimitQuery),
          staffingConstraintSvc.query(staffingConstraintQuery)
        ]);
      })
      .then(([driveLimitResult, staffingConstraintResult]) => {
        let {
          passed,
          pendingActionReasonCodes
        } = this.helper.validateDrive(this.drive, {
          ...this.masterData,
          driveLimits: driveLimitResult,
          staffingConstraints: staffingConstraintResult
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
          DRIVE_CONTENTION.DUAL_ROLE_REMOVAL,
          DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED,
          DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY
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
        } else {
          this.drive.pendingAction = '';
          this.drive.approvalStatus = '';
          this.drive.pendingActionReasonCode = '';
          this.drive.pendingActionReasonCodes = [];
        }

        return this.drive;
      })
  }

  submitDrive() {
    return this.helper.getAvailableAssets([], this.drive)
      .then(({ availableEquipments = [] }) => {
        let drives = [this.drive];
        let driveChanges = [];

        //equipments
        let drivesWithEquipments = this.helper.suggestEquipments(drives, availableEquipments);
        if (drivesWithEquipments && drivesWithEquipments.length) {
          let currentDrive = drivesWithEquipments.find(drive => drive.driveKey == this.drive.key);

          driveChanges.push({
            targetName: 'totalEquipmentRequestedChanged',
            targetValue: {
              equipmentJobsMap: currentDrive.equipmentJobsMap
            }
          })
        }

        return this.onDriveDataChanged(driveChanges)
          .then(() => {
            return {
              showReviewDriveMessage: false,
              drive: this.drive
            }
          })
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
      projectedRegisteredDonors: this.drive.projectedRegisteredDonors || 0,
      x2rbcProjectedProcedures: this.drive.x2rbcProjectedProcedures || 0,
      wbProjectedProcedures: this.drive.wbProjectedProcedures || 0,
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
        donorsScheduled: driveShift.donorsScheduled
      }

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

  calculateDriveShiftStaffCapacity(driveShift, ignoreLunchBreak = false) {
    const driveShiftStaffCapacity = Math.floor(this.helper.calculateStaffCapacity([
      '2RBC', 'VP/HH', 'Charge'
    ], this.drive, driveShift.driveShiftMetadata, 
      new Map()
        .set(driveShift.driveShiftMetadata.key, this.helper.getDriveShiftResourceQuantity(driveShift))
    , this.masterData, ignoreLunchBreak));

    return driveShiftStaffCapacity;
  }
  
  calculateDriveShiftMaxStaffCapacityWithDrawHours(driveShift, ignoreLunchBreak = false) {
    const driveShiftStaffCapacity = this.helper.calculateMaximumStaffCapacityWithDrawHours([
      'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'
    ], this.drive, driveShift.driveShiftMetadata, 
      new Map()
        .set(driveShift.driveShiftMetadata.key, this.helper.getDriveShiftResourceQuantity(driveShift))
    , this.masterData, ignoreLunchBreak);

    return driveShiftStaffCapacity;
  }

  calculateDriveShiftDrawHours(driveShift, ignoreLunchBreak = false) {
    const drawHours = this.helper.calculateDrawHours(driveShift.driveShiftMetadata, this.masterData, driveShift.driveShiftMetadata.lunchBreakSettings);
    return drawHours;
  }
  
  calculateDriveShiftMaxStaffCapacity(driveShift, ignoreLunchBreak = false) {
    const driveShiftStaffCapacity = this.helper.calculateMaximumStaffCapacity([
      'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'
    ], this.drive, driveShift.driveShiftMetadata, 
      new Map()
        .set(driveShift.driveShiftMetadata.key, this.helper.getDriveShiftResourceQuantity(driveShift))
    , this.masterData, ignoreLunchBreak);

    return driveShiftStaffCapacity;
  }

  countDriveShiftStaffs(driveShift, ignoreLunchBreak = false) {
    const driveShiftStaffs = Math.floor(this.helper.countDriveStaffs([
      '2RBC', 'VP/HH', 'Charge'
    ], this.drive, driveShift.driveShiftMetadata, 
      new Map()
        .set(driveShift.driveShiftMetadata.key, this.helper.getDriveShiftResourceQuantity(driveShift))
    , this.masterData, ignoreLunchBreak));

    return driveShiftStaffs;
  }

  updateDriveStaffCapacity() {
    let driveStaffCapacity = 0;
    if (this.masterData && this.masterData.staffingDecisionMatrix) {
      this.drive.driveShifts.forEach((driveShift) => {
        const driveShiftStaffCapacity = this.calculateDriveShiftStaffCapacity(driveShift);
        driveShift.maxDonorCapacity = driveShiftStaffCapacity;
        driveStaffCapacity += driveShiftStaffCapacity;
      });
    }
    this.drive.staffCapacity = driveStaffCapacity;
  }

  updateDriveAverageStaffCapacity() {
    let driveStaffCount = 0;
    if (this.masterData && this.masterData.staffingDecisionMatrix) {
      this.drive.driveShifts.forEach((driveShift) => {
        const driveShiftStaffCount = this.countDriveShiftStaffs(driveShift);
        driveStaffCount += driveShiftStaffCount;
      });
    }
    if(this.drive.staffCapacity && this.drive.staffCapacity > 0 && driveStaffCount > 0) {
      this.drive.averageStaffCapacity = this.drive.staffCapacity / driveStaffCount;
      this.drive.averageStaffCapacity = this.drive.averageStaffCapacity.toFixed(1);
    } else {
      this.drive.averageStaffCapacity = 0;
    }
    
  }

  updateDriveMaxRoleCapacity() {
    let driveMaxStaffCapacity = 0;
    let driveMaxStaffCapacityWithDrawHours = 0;
    let totalDrawHours = 0;
    if (this.masterData && this.masterData.staffingDecisionMatrix) {
      this.drive.driveShifts.forEach((driveShift) => {
        const driveShiftMaxStaffCapacity = this.calculateDriveShiftMaxStaffCapacity(driveShift);
        if(driveShiftMaxStaffCapacity && driveShiftMaxStaffCapacity > driveMaxStaffCapacity){
          driveMaxStaffCapacity = driveShiftMaxStaffCapacity;
        }
        const shiftDrawHours = this.calculateDriveShiftDrawHours(driveShift);
        if(shiftDrawHours){
          totalDrawHours = totalDrawHours + shiftDrawHours;
        }
      });
      if(totalDrawHours > 0){
        driveMaxStaffCapacityWithDrawHours = driveMaxStaffCapacity * totalDrawHours;
      }
    }
    this.drive.maxRoleCapacity = driveMaxStaffCapacity.toFixed(2);
    this.drive.maxRoleCapacityWithDrawHours = driveMaxStaffCapacityWithDrawHours.toFixed(2);
  }

  updateDriveExcessStaffCapacity() {
    if(this.drive.staffCapacity && this.drive.staffCapacity > 0 && this.drive.maxRoleCapacityWithDrawHours && this.drive.maxRoleCapacityWithDrawHours > 0) {
      if(this.drive.projectedRegisteredDonors) {
        this.drive.excessStaffCapacity = (this.drive.staffCapacity - this.drive.projectedRegisteredDonors) / this.drive.maxRoleCapacityWithDrawHours;
      } else {
        this.drive.excessStaffCapacity = this.drive.staffCapacity / this.drive.maxRoleCapacityWithDrawHours;
      }
      this.drive.excessStaffCapacity = this.drive.excessStaffCapacity.toFixed(1);
    } else {
      this.drive.excessStaffCapacity = 0;
    }
  }

  calculateNumberOf2rbcAssets() {
    //reset values
    this.drive.numberOf2rbcAssets = 0;

    const driveDrawHours = this.helper.calculateDrawHours(this.drive, this.masterData);
    if(!driveDrawHours) return;
    if (isNullOrEmpty(this.drive.x2rbcProjectedProcedures)) return;

    const { lockedEquipments } = this.helper.getCurrentAssignedEquipments(this.drive);
    this.drive.numberOf2rbcAssets = Math.ceil(this.drive.x2rbcProjectedProcedures / driveDrawHours);
    if(this.drive.numberOf2rbcAssets < lockedEquipments.length) {
      this.drive.numberOf2rbcAssets = lockedEquipments.length;
    }
    this.calculatePreferredNumberOf2rbcAssets();
  }

  calculatePreferredNumberOf2rbcAssets() {
    //reset values
    this.drive.preferredNumberOf2rbcAssets = 0;

    const driveDrawHours = this.helper.calculateDrawHours(this.drive, this.masterData);
    if(!driveDrawHours) return;
    if (isNullOrEmpty(this.drive.x2rbcProjectedProcedures)) return;

    const { lockedEquipments } = this.helper.getCurrentAssignedEquipments(this.drive);
    this.drive.preferredNumberOf2rbcAssets = Math.ceil(this.drive.x2rbcProjectedProcedures / driveDrawHours);
    if(this.drive.preferredNumberOf2rbcAssets < lockedEquipments.length) {
      this.drive.preferredNumberOf2rbcAssets = lockedEquipments.length;
    }
  }

  calculateTotalProceduresProjected(record) {
    if (!record && !this.drive) return;
    if (!record) {
      record = this.drive;
    }
    let x2rbcProjectedProcedures = record.x2rbcProjectedProcedures || 0;
    let wbProjectedProcedures = record.wbProjectedProcedures || 0;
    record.totalProceduresProjected = x2rbcProjectedProcedures + wbProjectedProcedures;
    record.totalProductsProjected = x2rbcProjectedProcedures * 2 + wbProjectedProcedures;
  }

  /** Drive Shifts metadata */
  calculateDriveShiftsMetadata() {
    //reset values
    let driveShiftsMetadata = {
      projectedRegisteredDonors: this.drive.projectedRegisteredDonors || 0,
      x2rbcProjectedProcedures: this.drive.x2rbcProjectedProcedures || 0,
      wbProjectedProcedures: this.drive.wbProjectedProcedures || 0,
      numberOfDriveShifts: 0,
      driveShifts: [],
      resourceRoleGroupRoleTimeDataMap: this.helper.calculateDriveRoleTimeData(this.drive, this.masterData)
    };
    this.drive.driveShiftsMetadata = driveShiftsMetadata;

    if (this.drive.driveDate && this.drive.startTime && this.drive.endTime) {
      const driveStart = this.helper.newDateTime(this.drive.driveDate, this.drive.startTime, this.masterData.timezoneSidId);
      const maximumShiftLengthThreshold = this.drive.collectionOperation.maximumShiftLengthThreshold;
      const { maxDurationBefore, maxDurationAfter } = this.helper.calculateMinMaxRoleTimeDuration(
        this.drive,
        driveShiftsMetadata.resourceRoleGroupRoleTimeDataMap, 
        [RESOURCE_ROLE_GROUP.SUPERVISORY_ROLES, RESOURCE_ROLE_GROUP.STAFF_ROLES]
      );
      const driveDrawHoursInMinutes = this.helper.calculateDrawHoursInMinutes(this.drive, this.masterData);
      const maxDriveLengthInMinutes = driveDrawHoursInMinutes + maxDurationBefore + maxDurationAfter;
      const noOfShifts = maximumShiftLengthThreshold ? Math.ceil(maxDriveLengthInMinutes / maximumShiftLengthThreshold) : 0;
      let drawDurationPerShift = Math.ceil(driveDrawHoursInMinutes / noOfShifts);
      let timeStep = 15;
      let redudantduration = drawDurationPerShift % timeStep;
      if (redudantduration != 0) {
        drawDurationPerShift = (Math.floor(drawDurationPerShift / timeStep) + 1) * timeStep;
      }

      for (let i = 0; i < noOfShifts; i++) {
        let driveShift = {
          key: uniqueId('drive_shift_'),
          label: `Drive Shift ${i + 1}`,
          driveDate: this.drive.driveDate
        }

        let drawHoursStart, drawHoursEnd;
        if (i == 0) {
          drawHoursStart = driveStart;
        }
        else {
          let previousDriveShift = driveShiftsMetadata.driveShifts[i - 1];
          drawHoursStart = this.helper.newDateTime(this.drive.driveDate, previousDriveShift.endTime, this.masterData.timezoneSidId);
        }
        if (i < noOfShifts - 1) {
          drawHoursEnd = new Date(drawHoursStart.getTime() + drawDurationPerShift * 60000);
        }
        else {
          let remainDuration = driveDrawHoursInMinutes - drawDurationPerShift * driveShiftsMetadata.driveShifts.length;
          drawHoursEnd = new Date(drawHoursStart.getTime() + remainDuration * 60000);
        }
        driveShift.start = drawHoursStart;
        driveShift.finish = drawHoursEnd;
        driveShift.startTime = this.helper.dateJSToTimeIso(drawHoursStart, this.masterData.timezoneSidId);
        driveShift.endTime = this.helper.dateJSToTimeIso(drawHoursEnd, this.masterData.timezoneSidId);

        driveShiftsMetadata.driveShifts.push(driveShift);
      }
    }
    
    driveShiftsMetadata.numberOfDriveShifts = driveShiftsMetadata.driveShifts.length;

    this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
    this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE.WB, this.masterData.timezoneSidId);
    this.helper.splitScheduledDonors(this.drive, driveShiftsMetadata.driveShifts, this.masterData.timezoneSidId);

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

  splitScheduledDonors() {
    if (!this.drive.driveShiftsMetadata) return;

    this.drive.driveShiftsMetadata.projectedRegisteredDonors = this.drive.projectedRegisteredDonors;
    this.helper.splitScheduledDonors(this.drive, this.drive.driveShiftsMetadata.driveShifts, this.masterData.timezoneSidId);
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

    if (isNullOrEmpty(this.drive.numberOf2rbcAssets)) {
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

  calculateResourceQuantity(skipCalculateResourceRoles = false) {
    //assets
    this.calculateEquipmentQuantity();

    //resources
    if(skipCalculateResourceRoles) {
      const staffingComplementChanged = this.drive.staffingComplementChanged || {};
      const driveShiftsMetadata = this.drive.driveShiftsMetadata;
      driveShiftsMetadata.driveShifts.forEach((driveShift, driveShiftIndex) => {
        let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
        const staffingComplement = staffingComplementChanged[driveShiftIndex];
        Object.keys(staffingComplement).forEach(resourceRole => {
          const { quantity, systemQuantity, vphhQuantity, aptQuantity } = staffingComplement[resourceRole];
          if(resourceRole === 'VP/HH') {
            resourceQuantityMap.set('VP/HH', {
              vphhQuantity: vphhQuantity,
              aptQuantity: aptQuantity,
              systemQuantity: systemQuantity
            });
          } else {
            resourceQuantityMap.set(resourceRole, {
              quantity: quantity,
              systemQuantity: systemQuantity
            });
          }
        })
      })
    } else {
      this.calculate2rbcQuantity();
      this.calculateTeamSupervisorQuantity();
      this.calculateVpHhQuantity();
      this.calculateChargeQuantity();
    }
   
    // HRP-10652: WB Fixed Site Drive Generation Code - Volunteer Jobs Generated
    // this.calculateVolunteerDonorAmbassadors();    

    const systemGeneratedStaffingComplementChanges = this.helper.getDriveSystemGeneratedStaffingComplementChanges({
      ...this.drive,
      driveShifts: Array.from(this.mapResourceQuantity.values()).map(mapResourceQuantity => {
        const jobs = [];
        mapResourceQuantity.forEach((staffingComplement, resourceRole) => {
          jobs.push({
            resourceRole,
            ...staffingComplement,
            systemQuantity: resourceRole === 'VP/HH' ? staffingComplement.vphhQuantity + (staffingComplement.aptQuantity || 0) : staffingComplement.quantity,
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

    return true;
  }

  calculateEquipmentQuantity() {
    let noOfEquipments = this.drive.numberOf2rbcAssets || 0;
    this.mapAssetQuantity.set('Equipment', noOfEquipments);
  }

  calculate2rbcQuantity() {
    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    const noOfEquipments = this.mapAssetQuantity.get('Equipment');
    const noOf2rbcStaffs = Math.ceil(noOfEquipments / 2);

    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
      resourceQuantityMap.set('2RBC', {
        quantity: noOf2rbcStaffs
      });
    })
  }

  calculateTeamSupervisorQuantity() {
    if (!this.masterData.staffingDecisionMatrix || isNullOrEmpty(this.masterData.staffingDecisionMatrix.teamSupervisorThreshold)) return;

    const teamSupervisorThreshold = this.masterData.staffingDecisionMatrix.teamSupervisorThreshold;
    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let noOfTeamSupervisors = 0;
      const totalProceduresProjected = driveShift.totalProceduresProjected;

      if(teamSupervisorThreshold > 0 &&
        totalProceduresProjected >= teamSupervisorThreshold &&
        this.drive.driveSite.physicalLocationType.includes('Inside')
      ) {
        noOfTeamSupervisors = 1;
      }
      
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
      resourceQuantityMap.set(this.drive.IMPACT ? 'Drive Lead' : 'Team Supervisor', {
        quantity: noOfTeamSupervisors
      });
    })
  }

  calculateVpHhQuantity(resourceRoles = ['2RBC']) {
    if (!this.masterData.staffingDecisionMatrix || isNullOrEmpty(this.masterData.staffingDecisionMatrix.vpHhCapacity)) return;

    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    driveShiftsMetadata.driveShifts.forEach(driveShiftMetadata => {
      const staffCapacity = this.helper.calculateStaffCapacity(
        resourceRoles,
        this.drive,
        driveShiftMetadata,
        this.mapResourceQuantity,
        this.masterData
      )

      const vpHhCapacity = this.masterData.staffingDecisionMatrix.vpHhCapacity;
      let totalVpHhCapacity = Math.ceil(driveShiftMetadata.donorsScheduled - staffCapacity);
      if (totalVpHhCapacity < 0) 
        totalVpHhCapacity = 0;
      
      const drawHours = this.helper.calculateDrawHours(driveShiftMetadata, this.masterData, driveShiftMetadata.lunchBreakSettings);

      let noOfVpHhStaffs = Math.ceil(totalVpHhCapacity / vpHhCapacity / drawHours);;
      let noOfAptStaffs = 0;

      if(this.drive.aptRequired) {
        noOfAptStaffs = 1;
      }

      let resourceQuantityMap = this.mapResourceQuantity.get(driveShiftMetadata.key);
      resourceQuantityMap.set('VP/HH', {
        vphhQuantity: noOfVpHhStaffs,
        aptQuantity: noOfAptStaffs
      });
    });
  }

  calculateChargeQuantity() {
    if (!this.masterData.staffingDecisionMatrix || isNullOrEmpty(this.masterData.staffingDecisionMatrix.chargeThreshold)) return;

    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
      
      let { quantity: noOf2rbcStaffs } = resourceQuantityMap.get('2RBC');
      let { quantity: noOfTeamSupervisor } = resourceQuantityMap.get('Team Supervisor') || {};
      let { quantity: noOfDriveLeads } = resourceQuantityMap.get('Drive Lead') || {};
      let { vphhQuantity: noOfVpHhStaffs } = resourceQuantityMap.get('VP/HH');
      if(!noOf2rbcStaffs) noOf2rbcStaffs = 0;
      if(!noOfTeamSupervisor) noOfTeamSupervisor = 0;
      if(!noOfDriveLeads) noOfDriveLeads = 0;
      if(!noOfVpHhStaffs) noOfVpHhStaffs = 0;
      
      const noOfStaffWithoutLeaders = noOf2rbcStaffs + noOfVpHhStaffs;
      const noOfLeaders = Math.ceil(noOfStaffWithoutLeaders / 11);
      let noOfCharges = noOfLeaders - noOfTeamSupervisor - noOfDriveLeads;
      if (noOfCharges < 0) {
        noOfCharges = 0;
      }

      resourceQuantityMap.set('Charge', {
        quantity: noOfCharges
      });

      //Recalculate VP/HH
      this.calculateVpHhQuantity(['2RBC', 'Charge']);
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
    if (this.drive.projectedRegisteredDonors) {
      this.initResourceQuantityMap();
      this.calculateResourceQuantity(skipCalculateResourceRoles);

      this.drive.driveShifts = this.buildMultiDriveShifts();
      this.populateDriveTime();
      this.updateDriveStaffCapacity();
      this.updateDriveAverageStaffCapacity();
      this.updateDriveMaxRoleCapacity();
      this.updateDriveExcessStaffCapacity();
      this.updateDriveRequestedResources();

      if(!skipGenerateSlots) {
        this.drive.driveShifts.forEach((driveShift) => {
          this.generateShiftSlots(driveShift);
        })
        this.updateDriveTotalSlots();
      }
    }
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
        x2rbcProjectedProcedures: driveShiftMetadata.x2rbcProjectedProcedures,
        wbProjectedProcedures: driveShiftMetadata.wbProjectedProcedures,
        donorsScheduled: driveShiftMetadata.donorsScheduled
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

        //clone jobs but need to replace key or id.
        if (driveShift.jobs && driveShift.jobs.length) {
          driveShift.jobs.forEach((job) => {
            let originalJob = this.helper.findJob(job, originalDriveShift.jobs);
            if (originalJob) {
              job.id = originalJob.id;
              job.key = originalJob.key;
  
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
    })

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

    // Retain Locked Jobs
    let lockedBackupJobs = ((this.masterData.backupDrive?.driveShifts || [])[driveShiftIndex]?.jobs || []).filter(job => job.isLocked)
    .map(job => {
      let updatedJob = extend({}, job, jobTemplate);
      return extend(updatedJob, {
        isManuallyCreated: job.isManuallyCreated, 
        manuallyCreatedFrom: job.manuallyCreatedFrom
      });
    });
    if(!lockedBackupJobs) jobs = [...lockedBackupJobs];

    const mapResourceQuantity = this.mapResourceQuantity.get(driveShiftMetadata.key);
    Array.from(mapResourceQuantity.keys()).forEach((resourceRole) => {
      let job = (driveShift.jobs || []).find(driveShiftJob => driveShiftJob.resourceRole == resourceRole);
      if (!job) {
        job = cloneDeep(jobTemplate);
        job.key = generateUUID();
      }
      job.jobTags = cloneDeep(jobTagsMap[RESOURCE_TYPE.PERSON]);
      job.resourceRole = resourceRole;

      if (resourceRole === 'VP/HH') {
        let { vphhQuantity, aptQuantity, systemQuantity } = mapResourceQuantity.get(resourceRole);
        if (vphhQuantity > 0 || aptQuantity > 0) {
          job.vphhQuantity = vphhQuantity;
          job.aptQuantity = aptQuantity;
          job.quantity = vphhQuantity + (aptQuantity || 0);
          job.systemQuantity = systemQuantity || job.quantity;
          if(!jobs.find(job => job.resourceRole === resourceRole)) jobs.push(job);
        }
      } else {
        let { quantity, systemQuantity } = mapResourceQuantity.get(resourceRole);
        if (quantity > 0) {
          job.quantity = quantity;
          job.systemQuantity = systemQuantity || job.quantity;
          if(!jobs.find(job => job.resourceRole === resourceRole)) jobs.push(job);
        }
      }
    });

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
      if (volunteerRole === 'Donor Ambassador') {
        job.redcrossVolunteerQuantity = quantity || 0;
        job.sponsorVolunteerQuantity = job.sponsorVolunteerQuantity || 0;
        job.quantity = (job.redcrossVolunteerQuantity || 0) + (job.sponsorVolunteerQuantity || 0);
      }
      if (quantity > 0) {
        if(!jobs.find(job => job.volunteerRole === 'Donor Ambassador')) jobs.push(job);
      }
    });

    this.mapAssetQuantity.forEach((quantity, assetType) => {
      if (quantity > 0) {
        let job = (driveShift.jobs || []).find(driveShiftJob => driveShiftJob.assetType == assetType);
        if (!job) {
          job = cloneDeep(jobTemplate);
          job.key = generateUUID();
        }
        job.assetType = assetType;
        if (job.assetType === ASSET_TYPE.EQUIPMENT) {
          job.equipmentSubtype = '2RBC Asset';
          job.jobTags = cloneDeep(jobTagsMap[ASSET_TYPE.EQUIPMENT]);
        }
        job.quantity = quantity || 0;
        jobs.push(job);
      }
    });
    
    let originalDriveShift = this.drive.driveShifts[driveShiftIndex];
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
      let staffSetup = this.helper.calculateStaffSetup(['2RBC', 'VP/HH', 'Charge'], driveShift);
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

    let coMaxLunchBreakDuration = 30;
    if (this.drive.collectionOperation.lunchBreakDurationMobile) {
      coMaxLunchBreakDuration = this.drive.collectionOperation.lunchBreakDurationMobile;
    }
    let lunchBreakSetting = this.masterData.lunchBreakSettings.find((setting) => setting.maximumLunchBreakDuration == coMaxLunchBreakDuration);
    let staffSetup = this.helper.calculateStaffSetup(['2RBC', 'VP/HH', 'Charge'], driveShift);
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
    if (!driveShift.driveDate || !driveShift.startTime || !driveShift.endTime || !driveShift.maxDonorCapacity) return;
    if (!this.masterData.staffingDecisionMatrix) return;

    const driveShiftMetadata = driveShift.driveShiftMetadata;
    let shiftStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let shiftEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    if (shiftStart >= shiftEnd) {
      return;
    }

    let driveShiftIndex = this.drive.driveShifts.findIndex(item => item.key === driveShift.key);
    let _2rbcDrawHours = (shiftEnd.getTime() - shiftStart.getTime()) / 3600000;
    let _2rbcShiftStart = shiftStart;
    if (driveShiftIndex > 0) {
      let previousDriveShift = this.drive.driveShifts[driveShiftIndex - 1];
      let previousDriveShiftEnd = this.helper.newDateTime(previousDriveShift.driveDate, previousDriveShift.endTime, this.masterData.timezoneSidId);
      if (previousDriveShiftEnd > shiftStart) {
        _2rbcShiftStart = previousDriveShiftEnd;
        _2rbcDrawHours = Math.max((shiftEnd.getTime() - _2rbcShiftStart.getTime()) / 3600000, 0);
      }
    }

    let paddingPercentage = this.masterData.adminSetting.callListRecipient;
    if (this.drive.opportunity && !this.drive.opportunity.callListRecipientExist) {
      paddingPercentage = this.masterData.adminSetting.callListRecipientNone;
    }
    if(!isNullOrEmpty(this.drive.opportunity.slotGenerator)) {
      paddingPercentage = this.drive.opportunity.slotGenerator / 100;
    }
    const driveShiftStaffCapacity = this.calculateDriveShiftStaffCapacity(driveShift, true);
    let totalDefaultSlots = Math.ceil(driveShiftStaffCapacity * paddingPercentage);

    driveShift.slots = [];
    driveShift.canGenerateSlots = true;
    if (driveShift.jobs && driveShift.jobs.length) {
      if (driveShift.lunchBreak == true) {
        if (driveShift.lunchBreakStartTime == undefined || driveShift.lunchBreakEndTime == undefined) {
          driveShift.canGenerateSlots = false;
        }
      }
      if (driveShift.equipment == undefined || driveShift.equipment == null) {
        driveShift.canGenerateSlots = false;
      }
      
      if (driveShift.canGenerateSlots) {
        let _2rbcSlots = this.generate2rbcSlots(driveShift, []);
        const total2RBCSlots = _2rbcSlots.length;
        let totalWbSlots = totalDefaultSlots - total2RBCSlots;

        let WBConfiguration = {
          interval: 60,
          roundConfigurations: [
            { minutesIntoStart: 0 },
            { minutesIntoStart: 30 },
            { minutesIntoStart: 15 },
            { minutesIntoStart: 45 }
          ],
          slotDuration: 15,
          slotType: 'Whole Blood',
          startTime: shiftStart,
          totalSlots: totalWbSlots
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
          
        let wbSlots = this.generateSlots(WBConfiguration);

        if (driveShift.lunchBreak) {
          if (!driveShift.lunchBreakBeforeDrawHours) {
            let coMaxLunchBreakDuration = driveShiftMetadata.lunchBreakSettings.maximumLunchBreakDuration;
            let lunchBreakSetting = this.masterData.lunchBreakSettings.find((setting) => setting.maximumLunchBreakDuration == coMaxLunchBreakDuration);
            let staffSetup = this.helper.calculateStaffSetup(['2RBC', 'VP/HH', 'Charge'], driveShift);
            let lunchBreakDefinition = lunchBreakSetting?.lunchBreakDefinitions.find(
              (definition) => (definition.minNoOfStaff <= staffSetup && staffSetup <= definition.maxNoOfStaff)
            );

            if (wbSlots && wbSlots.length && lunchBreakDefinition) {
              const slotReductionConfiguration = {
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
        driveShift.slots = [..._2rbcSlots, ...wbSlots];
      }
    }

    this.backupDriveShift(driveShift);
  }

  generateSlots(configuration) {
    let slots = [];
    let roundCount = 1;
    let slotCount = 0;

    while (slotCount < configuration.totalSlots) {
      let configurationIndex = roundCount % configuration.roundConfigurations.length;
      configurationIndex = (configurationIndex == 0 ? configuration.roundConfigurations.length : configurationIndex) - 1;
      let roundConfiguration = configuration.roundConfigurations[configurationIndex];
      let firstSlotStart = new Date(configuration.startTime.getTime() + (roundConfiguration.minutesIntoStart * 60000)); //TODO
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
          endTime: new Date(tempDt.getTime() + configuration.slotDuration * 60000).toISOString(), //TODO
          locked: false,
          slotType: configuration.slotType,
          status: "Open"
        }
        slots.push(slot);
        slotCount++;
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

  checkOverlapAndGenerateShiftSlots(driveShift) {
    if (this.drive.driveShifts.length === 1) {
      this.generateShiftSlots(driveShift);
      return;
    }

    let regenerateShifts = [driveShift];
    for (let i = 1; i < this.drive.driveShifts.length; i++) {
      let currentDriveShift = this.drive.driveShifts[i];
      let previousDriveShift = this.drive.driveShifts[i - 1];

      let backupCurrentDriveShift = this.masterData.backupDriveShiftMap[currentDriveShift.key];
      let backupPreviousDriveShift = this.masterData.backupDriveShiftMap[previousDriveShift.key];

      let beforeOverlapeped = backupCurrentDriveShift.startTime < backupPreviousDriveShift.endTime && backupCurrentDriveShift.endTime > backupPreviousDriveShift.startTime;
      let afterOverlapped = currentDriveShift.startTime < previousDriveShift.endTime && currentDriveShift.endTime > previousDriveShift.startTime;
      if (beforeOverlapeped !== afterOverlapped) {
        if (currentDriveShift.key !== driveShift.key) {
          regenerateShifts.push(currentDriveShift);
        }
      } else {
        if (beforeOverlapeped && afterOverlapped && previousDriveShift.endTime !== currentDriveShift.endTime) {
          if (currentDriveShift.key !== driveShift.key) {
            regenerateShifts.push(currentDriveShift);
          }
        }
      }
    }

    regenerateShifts.forEach(item => {
      this.generateShiftSlots(item);
    })

    this.updateDriveTotalSlots();
  }

  /** Change handlers */
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

      this.drive.projectedRegisteredDonors = this.drive.driveShiftsMetadata.projectedRegisteredDonors;
      this.drive.x2rbcProjectedProcedures = this.drive.driveShiftsMetadata.x2rbcProjectedProcedures;
      this.drive.wbProjectedProcedures = this.drive.driveShiftsMetadata.wbProjectedProcedures;

      this.calculateNumberOf2rbcAssets();
      this.calculatePreferredNumberOf2rbcAssets();
    }
    this.proposeDriveShifts();
    this.calculateTotalProceduresProjected();
    this.calculateDriveProductivityPlanned();
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
      this.populateDriveTime();
      this.updateDriveStaffCapacity();
      this.updateDriveAverageStaffCapacity();
      this.updateDriveMaxRoleCapacity();
      this.updateDriveExcessStaffCapacity();
      this.updateDriveRequestedResources();
      this.calculateDriveProductivityPlanned();
      this.generateShiftSlots(driveShift);
      this.updateDriveTotalSlots();
    }

    if(job.resourceRole) {
      this.applyJobTimeToJobAllocations(job);
    }

    this.resetElectContentions();
  }

  /** Temporary */
  getCurrentAssignedEquipments() {
    return this.helper.getCurrentAssignedEquipments(this.drive);
  }

  compareAndGetDriveChanges() {
    return this.helper.compareAndGetDriveChanges(this.masterData.backupDrive, this.drive);
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
  WbFixedSiteGenerator,
  DRIVE_FIELD_CHANGE_MAPPING
}