import TIME_ZONE from '@salesforce/i18n/timeZone';
import { BaseGenerator } from './baseGenerator';
import * as autoMapper from 'c/autoMapper';
import { debugLogService, operationDriveLimitService, operationDriveLimitQueryModel, 
  staffingConstraintService, staffingConstraintQueryModel } from 'c/dataService';
import { isNullOrEmpty, generateUUID } from 'c/slwcUtils';
import { cloneDeep, difference, isEmpty, uniqueId, extend, orderBy, remove } from 'c/lodash';
import { Fetch } from './fetch';
import { ACCOUNT_TYPE, ACCOUNT_INDUSTRY_CODE, PROCEDURE_TYPE, DRIVE_STATUS, ASSET_TYPE, PENDING_ACTION, DRIVE_APPROVAL_STATUS, RESOURCE_TYPE, DRIVE_TYPE, DRIVE_CONTENTION, JOB_ALLOCATION_STATUS, VOLUNTEER_TYPE, MANUALLY_CREATED_FROM } from 'c/slwcConstants';

const DEFAULT_CALENDAR_SETTINGS = {
  timezone: TIME_ZONE,
  firstDay: 0
}

const DRIVE_ACTION_GROUPS_ORDER = [
  ['retrieveDriveSiteAndPopulateCollectionOperation', 'populateSiteCollectionOperation', 'populateDriveCollectionOperation', 'populateCollectionOperationData'],
  ['retrieveVehicles', 'retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags'],
  ['calculateNumberOf2rbcAssets', 'calculate2rbcProjectedProcedures', 'splitScheduledDonors', 'split2rbcProjectedProcedures', 'calculateTotalProceduresProjected', 'calculateDriveShiftsMetadata',
     'applyStaffingComplementAndProposeDriveShifts', 'handlePreferSystemGeneratedVehiclesChanged', 'proposeDriveShifts', 'proposeDriveShiftSlots', 'updateDriveTotalSlots', 'calculateDriveProductivityPlanned',
    'handleTotalVehicleRequestedChanged', 'handleEquipmentRequestedChanged', 'handleDriveShiftsMetadataChanged', 'correctJobAllocationTimes']
]

const DRIVE_FIELD_CHANGE_MAPPING = {
  'driveDate': {
    groups: [
      { actions: ['retrieveDriveSiteAndPopulateCollectionOperation'] },
      { actions: ['retrieveVehicles', 'retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData'] },
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
      { actions: ['retrieveVehicles', 'retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: ['correctJobAllocationTimes'] }
    ]
  },
  'siteCollectionOperationId': {
    groups: [
      { actions: ['populateSiteCollectionOperation'] },
      { actions: ['retrieveVehicles', 'retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags'] },
      { actions: ['calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: ['correctJobAllocationTimes'] }
    ]
  },
  'collectionOperationId': {
    groups: [
      { actions: ['populateSiteCollectionOperation'] },
      { actions: ['retrieveVehicles', 'retrieveSameDateDrives', 'retrieveSameDateActivities', 'retrieveCollectionOperationSDM', 'retrieveRoleTimeData', 'retrieveDefaultTags', 'retrieveTerritoryCollectionOperations'] },
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
      { actions: ['calculateNumberOf2rbcAssets','calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'endTime': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['calculateNumberOf2rbcAssets','calculateDriveShiftsMetadata', 'proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
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
  'aptQuantity': {
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
  'doNotUseVehicle': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['proposeDriveShifts', 'calculateDriveProductivityPlanned'] },
      { actions: [] }
    ]
  },
  'preferSystemGeneratedVehicles': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handlePreferSystemGeneratedVehiclesChanged'] },
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
  'redcrossVolunteerRequired': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleRedcrossVolunteerRequirement'] },
      { actions: [] }
    ]
  },
  'redcrossVolunteerQuantity': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleRedcrossVolunteerRequirement'] },
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
      { actions: ['updateLunchBreakSettings', 'populateLunchBreakTime', 'populateShiftTime', 'populateDriveTime', 'updateDriveStaffCapacity', 'updateDriveAverageStaffCapacity', 'updateDriveMaxRoleCapacity','updateDriveExcessStaffCapacity', 'generateShiftSlots', 'updateDriveTotalSlots'] },
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
    ],
  },
  'lunchBreakStartTime': {
    groups: [
      { actions: [] },
      { actions: ['changeLunchBreakStartTime', 'updateDriveStaffCapacity', 'updateDriveAverageStaffCapacity', 'updateDriveMaxRoleCapacity', 'updateDriveExcessStaffCapacity', 'generateShiftSlots', 'updateDriveTotalSlots'] },
    ]
  },

  'APTSetup': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleDriveShiftsMetadataChanged'] },
      { actions: [] }
    ]
  },

  'redcrossVolunteerRequired': {
    groups: [
      { actions: [] },
      { actions: [] },
      { actions: ['handleDriveShiftsMetadataChanged'] },
      { actions: [] }
    ]
  }

}

class MobileGenerator extends BaseGenerator {
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
                      return driveSite;
                    }),
                  this.fetch.retrieveCustomSettings()
                ])
                  .then(([driveSite, {
                    resourceRoleGroups,
                    lunchBreakSettings,
                    adminSetting,
                    staffSetupExcludedRoles,
                    redcrossVolunteerMatrix
                  }]) => {
                    this.populateDriveCollectionOperation();

                    return Promise.all([
                      driveSite,
                      resourceRoleGroups,
                      lunchBreakSettings,
                      adminSetting,
                      staffSetupExcludedRoles,
                      redcrossVolunteerMatrix,
                      this.fetch.retrieveTravelTimeIndexItemMap(this.drive),
                      this.fetch.retrieveVehicles(this.drive),
                      this.fetch.retrieveSameDateDrives(this.drive),
                      this.fetch.retrieveSameDateActivities(this.drive),
                      this.fetch.retrieveCollectionOperationSDM(this.drive),
                      this.fetch.retrieveRoleTimeData(this.drive),
                      this.fetch.retrieveDefaultTags(this.drive),
                      this.fetch.retrieveTerritoryCollectionOperations(this.drive)
                    ])
                  })
                  .then(([driveSite, resourceRoleGroups, lunchBreakSettings, adminSetting, staffSetupExcludedRoles, redcrossVolunteerMatrix, travelTimeIndexItemMap, vehicles, sameDateDrives, sameDateActivities, staffingDecisionMatrix, roleTimeData, driveTags, territoryCollectionOperations]) => {
                    this.initMasterData({
                      loginUser,
                      driveSite,
                      resourceRoleGroups,
                      lunchBreakSettings,
                      adminSetting,
                      travelTimeIndexItemMap,
                      vehicles,
                      sameDateDrives,
                      sameDateActivities,
                      staffingDecisionMatrix,
                      roleTimeData,
                      driveTags,
                      territoryCollectionOperations,
                      staffSetupExcludedRoles,
                      redcrossVolunteerMatrix
                    })

                    this.populateCollectionOperationData();
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
              return driveSite;
            }),
          this.fetch.retrieveCustomSettings()
        ])
        .then(([driveSite, {
          resourceRoleGroups,
          lunchBreakSettings,
          adminSetting,
          staffSetupExcludedRoles,
          redcrossVolunteerMatrix
        }]) => {

          return Promise.all([
            driveSite,
            resourceRoleGroups,
            lunchBreakSettings,
            adminSetting,
            staffSetupExcludedRoles,
            redcrossVolunteerMatrix,
            this.fetch.retrieveTravelTimeIndexItemMap(this.drive),
            this.fetch.retrieveVehicles(this.drive),
            this.fetch.retrieveSameDateDrives(this.drive),
            this.fetch.retrieveSameDateActivities(this.drive),
            this.fetch.retrieveCollectionOperationSDM(this.drive),
            this.fetch.retrieveRoleTimeData(this.drive),
            this.fetch.retrieveDefaultTags(this.drive),
            this.fetch.retrieveActiveDriveChangeRequest(this.drive)
          ]);
        })
        .then(([driveSite, resourceRoleGroups, lunchBreakSettings, adminSetting, staffSetupExcludedRoles, redcrossVolunteerMatrix, travelTimeIndexItemMap , vehicles, sameDateDrives, sameDateActivities, staffingDecisionMatrix, roleTimeData, driveTags, activeDriveChangeRequest]) => {
          this.initMasterData({
            loginUser,
            driveSite,
            resourceRoleGroups,
            lunchBreakSettings,
            adminSetting,
            travelTimeIndexItemMap,
            vehicles,
            sameDateDrives,
            sameDateActivities,
            staffingDecisionMatrix,
            roleTimeData,
            driveTags,
            activeDriveChangeRequest,
            staffSetupExcludedRoles,
            redcrossVolunteerMatrix
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
    const validateEqipments = (drive, availableEquipments = [], availableButNotSharedAssetIds = []) => {
      //validate current assigned equipment
      let { totalRequired, assignedEquipments: currentAssignedEquipments, lockedEquipments } = this.getCurrentAssignedEquipments();
      let availableEquipmentIds = availableEquipments.map(availableEquipment => availableEquipment.id);
      let validAssignedEquipments = currentAssignedEquipments.filter(assignedEquipment => {
        return availableEquipmentIds.includes(assignedEquipment.id) || (availableButNotSharedAssetIds.includes(assignedEquipment.id) && this.helper.isDriveInPathOfLinkedDrive(this.drive))
      });
      let allAssignedEquipmentsValid = validAssignedEquipments.length === currentAssignedEquipments.length;

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
      } else if (validAssignedEquipments.length > totalRequired) {
        //slots to be allocated
        let { slotsToAllocate, availableEquipmentsCanBeUsed } = this.helper.preProcessSuggestEquipments(totalRequired, validAssignedEquipments, lockedEquipments);
        
        //remove redundant equipments
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
      } else {
        return {
          allAssignedEquipmentsValid: true
        }
      }
    }

    const validateVehicles = (drive, availableVehicles = [], driveLimits = [], availableButNotSharedAssetIds = []) => {
      if(drive.doNotUseVehicle) {
        return {
          allAssignedVehiclesValid: false,
          canHandleDriveProjectedRegisteredDonors: false,
          newVehicles: [],
          lockedVehicles: []
        }
      }

      //validate current assigned vehicles
      let { assignedVehicles, totalCurrentAssignedVehiclesCapacity, lockedVehicles } = this.helper.getCurrentAssignedVehicles(drive);
      let { maxDOT, maxCDL } = this.helper.getMaxDOTAndCDLForDrive(drive, {
        ...this.masterData,
        driveLimits
      });
      let maxRegisteredDonors = this.helper.getMaxDonorsScheduledOfDriveShifts(this.drive);
      let availableVehicleIds = availableVehicles.map(availableVehicle => availableVehicle.id);
      let isAllAssignedVehiclesValid = assignedVehicles.every(assignedVehicle => {
        return availableVehicleIds.includes(assignedVehicle.id) || (availableButNotSharedAssetIds.includes(assignedVehicle.id) && this.helper.isDriveInPathOfLinkedDrive(this.drive))
      })

      if (!isAllAssignedVehiclesValid || totalCurrentAssignedVehiclesCapacity < maxRegisteredDonors) {
        let { maxRegisteredDonorsToAllocate, availableVehiclesCanBeUsed, remainingMaxDOT, remainingMaxCDL } = this.helper.preProcessSuggestVehicles(maxRegisteredDonors, availableVehicles, lockedVehicles, {
          maxDOT,
          maxCDL
        });

        //try to assign new vehicles 
        let drivesWithVehicles = this.helper.calculateNumberOfVehiclesForDrive(drive, availableVehiclesCanBeUsed, {
          maxDOT: remainingMaxDOT,
          maxCDL: remainingMaxCDL,
          maxRegisteredDonorsToAllocate
        });
        if (drivesWithVehicles && drivesWithVehicles.length) {
          let currentDrive = drivesWithVehicles.find(drive => drive.driveKey == this.drive.key);
          //if calculateNumberOfVehicles has result, it means that new vehicles can handle drive donors
          return {
            allAssignedVehiclesValid: false,
            newVehicles: currentDrive.vehicles,
            lockedVehicles: lockedVehicles,
            canHandleDriveProjectedRegisteredDonors: true
          }
        } else {
          return {
            allAssignedVehiclesValid: false,
            newVehicles: availableVehiclesCanBeUsed,
            lockedVehicles: lockedVehicles,
            canHandleDriveProjectedRegisteredDonors: false
          }
        }
      }

      return {
        allAssignedVehiclesValid: isAllAssignedVehiclesValid,
        canHandleDriveProjectedRegisteredDonors: true
      }
    }

    if (this.drive.status === DRIVE_STATUS.DRAFT && !validateDraftDrive) return Promise.resolve({
      allAssignedEquipmentsValid: true,
      allAssignedVehiclesValid: true,
      canHandleDriveProjectedRegisteredDonors: true
    });
    const fieldsToCheckChange = ['driveDate', 'doNotUseVehicle', 'preferSystemGeneratedVehicles', 'numberOfVehicles'];
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
    const preferSystemGeneratedVehiclesChaged = properties.find(property => property.targetName === 'preferSystemGeneratedVehicles');
    const numberOfVehiclesChanged = properties.find(property => property.targetName === 'numberOfVehicles');
    const newDrive = {
      ...this.drive,
      driveDate: driveDateChanged ? driveDateChanged.targetValue : this.drive.driveDate,
      doNotUseVehicle: doNotUseVehicleChanged ? !!doNotUseVehicleChanged.targetValue : this.drive.doNotUseVehicle,
      preferSystemGeneratedVehicles: preferSystemGeneratedVehiclesChaged ? !!preferSystemGeneratedVehiclesChaged.targetValue : this.drive.preferSystemGeneratedVehicles,
      numberOfVehicles: numberOfVehiclesChanged ? !!numberOfVehiclesChanged.targetValue : this.drive.numberOfVehicles
    };
    return Promise.all([
      this.fetch.retrieveOperationDriveLimit(newDrive),
      this.helper.getAvailableAssets(this.masterData.vehicles, newDrive)
    ])
      .then(([ driveLimits = [], { availableVehicles = [], availableEquipments = [], availableButNotSharedAssetIds = [] }])  => {
        const { allAssignedEquipmentsValid, newEquipmentJobsMap, lockedEquipments } = validateEqipments(newDrive, availableEquipments, availableButNotSharedAssetIds);
        const { allAssignedVehiclesValid, newVehicles, lockedVehicles, canHandleDriveProjectedRegisteredDonors } = validateVehicles(newDrive, availableVehicles, driveLimits, availableButNotSharedAssetIds);

        return {
          allAssignedEquipmentsValid,
          newEquipmentJobsMap,
          lockedEquipments,
          allAssignedVehiclesValid,
          newVehicles,
          lockedVehicles,
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
          this.helper.getAvailableAssets(this.masterData.vehicles, this.drive)
        ]);
      })
      .then(([driveLimitResult, staffingConstraintResult, availableAssetsInfo]) => {
        let {
          passed,
          pendingActionReasonCodes
        } = this.helper.validateDrive(this.drive, {
          ...this.masterData,
          driveLimits: driveLimitResult,
          staffingConstraints: staffingConstraintResult,
          availableAssetsInfo
        }, [
          DRIVE_CONTENTION.DRIVE_LIMIT,
          DRIVE_CONTENTION.x2RBC_LIMIT,
          DRIVE_CONTENTION.DOT_LIMIT,
          DRIVE_CONTENTION.CDL_LIMIT,
          DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS,
          DRIVE_CONTENTION.LACKING_VEHICLE,
          DRIVE_CONTENTION.LACKING_EQUIPMENT,
          DRIVE_CONTENTION.INSUFFICIENT_RESOURCES,
          DRIVE_CONTENTION.WITHIN_42_DAYS,
          DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS,
          DRIVE_CONTENTION.PART_OF_LINKED_DRIVE,
          DRIVE_CONTENTION.MULTI_SHIFT_DRIVE,
          DRIVE_CONTENTION.DUAL_ROLE_REMOVAL,
          DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED,
          DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS,
          DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO,
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
    return Promise.all([
      this.fetch.retrieveOperationDriveLimit(this.drive),
      this.helper.getAvailableAssets(this.masterData.vehicles, this.drive)
    ])
      .then(([driveLimits = [], { availableVehicles = [], availableEquipments = [] }]) => {
        let { maxDOT, maxCDL } = this.helper.getMaxDOTAndCDLForDrive(this.drive, {
          ...this.masterData,
          driveLimits
        });
        let driveChanges = [];

        //equipments
        let drivesWithEquipments = this.helper.suggestEquipments([this.drive], availableEquipments);
        if (drivesWithEquipments && drivesWithEquipments.length) {
          let currentDrive = drivesWithEquipments.find(drive => drive.driveKey == this.drive.key);

          driveChanges.push({
            targetName: 'totalEquipmentRequestedChanged',
            targetValue: {
              equipmentJobsMap: currentDrive.equipmentJobsMap
            }
          })
        }

        //vehicles
        let currentNoOfVehicles = this.drive.doNotUseVehicle ? 
          0 : 
          this.drive.preferSystemGeneratedVehicles ? 
            this.drive.totalVehicleRequested : 
            this.drive.numberOfVehicles;

        this.drivesWithVehicles = this.helper.calculateNumberOfVehiclesForDrive(this.drive, availableVehicles, {
          maxDOT,
          maxCDL
        });
        if (this.drivesWithVehicles && this.drivesWithVehicles.length) {
          let currentDrive = this.drivesWithVehicles.find(drive => drive.driveKey == this.drive.key);
          let noOfVehicles = currentDrive.vehicles.length;

          driveChanges.push({
            targetName: 'totalVehicleRequestedChanged',
            targetValue: {
              totalVehicleRequested: noOfVehicles,
              vehicles: currentDrive.vehicles
            }
          })

          return this.onDriveDataChanged(driveChanges)
            .then(() => {
              if (currentNoOfVehicles === noOfVehicles || !this.drive.preferSystemGeneratedVehicles || this.drive.doNotUseVehicle) {
                //case 1, new no of Vehicles = current no of Vehicles 
                //proess validate and save drive
                return {
                  showReviewDriveMessage: false,
                  drive: this.drive
                }
              } else {
                //case 2, new no of Vehicles !== current no of Vehicles but still can handle drive donors
                //propose drive shifts again and show message that tell user to review drive again
                return {
                  showReviewDriveMessage: true,
                  drive: this.drive
                }
              }
            })
        } else {
          //assign all current available vehicles
          driveChanges.push({
            targetName: 'totalVehicleRequestedChanged',
            targetValue: {
              totalVehicleRequested: availableVehicles.length,
              vehicles: availableVehicles
            }
          });
          return this.onDriveDataChanged(driveChanges)
            .then(() => {
              return {
                drive: this.drive
              }
            })
        }
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
      APTSetup: this.drive.aptQuantity || 0,
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
        donorsScheduled: driveShift.donorsScheduled,
        APTSetup: driveShift.APTSetup
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
      'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'
    ], this.drive, driveShift.driveShiftMetadata, 
      new Map()
        .set(driveShift.driveShiftMetadata.key, this.helper.getDriveShiftResourceQuantity(driveShift))
    , this.masterData, ignoreLunchBreak));

    return driveShiftStaffCapacity;
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
    this.drive.averageStaffCapacity = this.helper.calculateDriveAverageStaffCapacity(this.drive);
  }

  updateDriveMaxRoleCapacity() {
    const { maxRoleCapacity, maxRoleCapacityWithDrawHours } = this.helper.calculateDriveMaxRoleCapacity(this.drive, this.masterData)

    this.drive.maxRoleCapacity = maxRoleCapacity;
    this.drive.maxRoleCapacityWithDrawHours = maxRoleCapacityWithDrawHours;
  }

  updateDriveExcessStaffCapacity() {
    this.drive.excessStaffCapacity = this.helper.calculateExcessStaffCapacity(this.drive);
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
    } else {
      this.drive.aptQuantity = record.APTSetup;
      this.drive.aptRequired = record.APTSetup > 0 ? true : false; //HRP-14339
    }
    let x2rbcProjectedProcedures = record.x2rbcProjectedProcedures || 0;
    let wbProjectedProcedures = record.wbProjectedProcedures || 0;
    record.totalProceduresProjected = x2rbcProjectedProcedures + wbProjectedProcedures;
    record.totalProductsProjected = x2rbcProjectedProcedures * 2 + wbProjectedProcedures;

    if(!this.masterData.skipAPTCalculation) {
      this.recalculateAPTSettings();
      this.drive.driveShiftsMetadata.APTSetup = this.drive.aptQuantity;
    }
  }
  
  recalculateAPTSettings() {
    if(!this.drive) return;

    let aptQuantity = 0;
    const isEducationDrive = this.drive.account?.type === ACCOUNT_TYPE.EDUCATION;
    const isMiddleOrElemenentaryIndustryCode = this.drive.account?.industryCode === ACCOUNT_INDUSTRY_CODE.MIDDLE_SCHOOL || this.drive.account?.industryCode === ACCOUNT_INDUSTRY_CODE.ELEMENTARY_SCHOOL;
    if(isEducationDrive) {
      if(!isMiddleOrElemenentaryIndustryCode) {
        aptQuantity = Math.floor(this.drive.driveShiftsMetadata.totalProceduresProjected / 40);
      }
    } else {
      if(this.drive.driveShiftsMetadata.totalProceduresProjected >= 40) aptQuantity = 1;
    }
    this.drive.aptQuantity = aptQuantity;
    this.drive.aptRequired = aptQuantity > 0 ? true : false;
  }

  /** Drive Shifts metadata */
  calculateDriveShiftsMetadata() {
    //reset values
    let driveShiftsMetadata = {
      projectedRegisteredDonors: this.drive.projectedRegisteredDonors || 0,
      x2rbcProjectedProcedures: this.drive.x2rbcProjectedProcedures || 0,
      wbProjectedProcedures: this.drive.wbProjectedProcedures || 0,
      APTSetup: this.drive.aptQuantity || 0,
      numberOfDriveShifts: 0,
      driveShifts: [],
      resourceRoleGroupRoleTimeDataMap: this.helper.calculateDriveRoleTimeData(this.drive, this.masterData)
    };
    this.drive.driveShiftsMetadata = driveShiftsMetadata;

    if (this.drive.driveDate && this.drive.startTime && this.drive.endTime) {
      const driveStart = this.helper.newDateTime(this.drive.driveDate, this.drive.startTime, this.masterData.timezoneSidId);
      const maximumShiftLengthThreshold = this.drive.collectionOperation.maximumShiftLengthThreshold;
      const { maxDurationBefore, maxDurationAfter } = this.helper.calculateMinMaxRoleTimeDuration(this.drive, driveShiftsMetadata.resourceRoleGroupRoleTimeDataMap);
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
        driveShift.APTSetup = this.drive.aptQuantity || 0;
        driveShiftsMetadata.driveShifts.push(driveShift);
      }
    }
    
    driveShiftsMetadata.numberOfDriveShifts = driveShiftsMetadata.driveShifts.length;

    this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE._2RBC, this.masterData.timezoneSidId);
    this.helper.splitProjectedProcedures(this.drive, driveShiftsMetadata.driveShifts, driveShiftsMetadata, PROCEDURE_TYPE.WB, this.masterData.timezoneSidId);
    this.helper.splitScheduledDonors(this.drive, driveShiftsMetadata.driveShifts, this.masterData.timezoneSidId);

    this.calculateTotalProceduresProjected(driveShiftsMetadata);
    this.drive.driveShiftsMetadata.APTSetup = this.drive.aptQuantity;
    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      this.calculateTotalProceduresProjected(driveShift);
      driveShift.APTSetup = this.drive.aptQuantity;
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
    this.drive.driveShiftsMetadata.driveShifts.forEach(driveShift => {
      this.mapResourceQuantity.set(driveShift.key, new Map());
    });
    this.mapVolunteerQuantity = new Map();
    this.mapAssetQuantity = new Map();
  }

  calculateResourceQuantity(skipCalculateResourceRoles = false, skipVehicleCalculation = false, backupAndRestoreDualRoles = false) {
    this.calculateDraftDriveGhostVehicleQuantity(skipVehicleCalculation);

    //assets
    this.calculateVehicleQuantity();
    this.calculateEquipmentQuantity();

    //resources
    if(skipCalculateResourceRoles) {
      const staffingComplementChanged = this.drive.staffingComplementChanged || {};
      const driveShiftsMetadata = this.drive.driveShiftsMetadata;
      driveShiftsMetadata.driveShifts.forEach((driveShift, driveShiftIndex) => {
        let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
        const staffingComplement = staffingComplementChanged[driveShiftIndex];
        Object.keys(staffingComplement).forEach(jobKey => {
          const { resourceRole } = this.helper.parseJobKey(jobKey);
          const { quantity, systemQuantity, vphhQuantity, aptQuantity, dualRole, isManuallyCreated, manuallyCreatedFrom, isCreatedOrUpdatedViaDualRoleChange } = staffingComplement[jobKey]; //preserve properties for manually created jobs
          if(resourceRole === 'VP/HH') {
            resourceQuantityMap.set('VP/HH', {
              vphhQuantity: vphhQuantity,
              aptQuantity: aptQuantity,
              systemQuantity: systemQuantity,
              dualRole: dualRole,
              isManuallyCreated: isManuallyCreated,
              manuallyCreatedFrom: manuallyCreatedFrom,
              isCreatedOrUpdatedViaDualRoleChange: isCreatedOrUpdatedViaDualRoleChange
            });
          } else {
            resourceQuantityMap.set(jobKey, {
              quantity: quantity,
              systemQuantity: systemQuantity,
              dualRole: dualRole,
              isManuallyCreated: isManuallyCreated,
              manuallyCreatedFrom: manuallyCreatedFrom,
              isCreatedOrUpdatedViaDualRoleChange: isCreatedOrUpdatedViaDualRoleChange
            });
          }
        })
      })
    } else {
      this.calculateDriverQuantity();
      this.calculate2rbcQuantity();
      this.calculateTeamSupervisorQuantity();
      this.calculateVpHhQuantity();
      this.calculateChargeQuantity();
    }

    // HRP-9187: No longer need to auto generate volunteer jobs
    //HRP-13146: Adding volunteer jobs for mobile drives if Red Cross Volunteer Required is checked by users
    this.calculateVolunteerDonorAmbassadors();
    this.drive.redcrossVolunteerQuantity = this.mapVolunteerQuantity.get(VOLUNTEER_TYPE.DONOR_AMBASSADOR) || 0;

    if(backupAndRestoreDualRoles && this.backupDualRolesMap) {
      this.restoreDualRoles(this.backupDualRolesMap);
    }

    this.generateDualRoles();

    const drive = {
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
    }
    const systemGeneratedStaffingComplementChanges = this.helper.getDriveSystemGeneratedStaffingComplementChanges(drive, this.masterData.backupDrive, { isDriveGettingRegenerated : this.isRegenerateDriveChange });
    if(!systemGeneratedStaffingComplementChanges.newJobs.length && 
      !systemGeneratedStaffingComplementChanges.changedJobs.length && 
      !systemGeneratedStaffingComplementChanges.deletedJobs.length) {
        this.restoreJobsQuantity(skipCalculateResourceRoles ? this.masterData.backupDrive : drive);
    } 
  }

  generateDualRoles() {
    const calculateExcessStaffCapacity = (drive, mapResourceQuantity) => {
      const driveShiftsMetadata = this.drive.driveShiftsMetadata;

    let tempMapResourceQuantityForStaffCapacity = cloneDeep(mapResourceQuantity);//HRP-14869 start
      for (let [key, value] of  tempMapResourceQuantityForStaffCapacity.entries()) {
        if(value.has('VP/HH')){
            if(value.get('VP/HH').aptQuantity !== 0){
              value.get('VP/HH').quantity = value.get('VP/HH').vphhQuantity;
            }
        }
      }//HRP-14869 end
      let staffCapacity = 0;
      driveShiftsMetadata.driveShifts.forEach((driveShiftMetadata) => {
        const driveShiftStaffCapacity = Math.floor(this.helper.calculateStaffCapacity([
          'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'
        ], drive, driveShiftMetadata, tempMapResourceQuantityForStaffCapacity, this.masterData));//HRP-14869
        staffCapacity += driveShiftStaffCapacity;
      });

      let tempDrive = {
        projectedRegisteredDonors: drive.projectedRegisteredDonors,
        staffCapacity: staffCapacity,
        driveShifts: driveShiftsMetadata.driveShifts.map((driveShiftMetadata) => {
          const resourceQuantityMap = mapResourceQuantity.get(driveShiftMetadata?.key);
          const jobs = [];
          Array.from(resourceQuantityMap.keys()).forEach((jobKey) => {
            const {
              resourceRole,
              dualRole
            } = this.helper.parseJobKey(jobKey);
            let { quantity, vphhQuantity, aptQuantity, isManuallyCreated, manuallyCreatedFrom } = resourceQuantityMap.get(jobKey);

            jobs.push({
              resourceRole,
              dualRole,
              isManuallyCreated,
              manuallyCreatedFrom,
              quantity,
              vphhQuantity,
              aptQuantity
            })
          })          
          return {
            ...{
              ...driveShiftMetadata,
              driveShiftMetadata: driveShiftMetadata
            },
            jobs: jobs
          }
        })
      };

      const { maxRoleCapacity, maxRoleCapacityWithDrawHours } = this.helper.calculateDriveMaxRoleCapacity(tempDrive, this.masterData);
      const excessStaffCapacity = this.helper.calculateExcessStaffCapacity({
        ...tempDrive,
        maxRoleCapacity,
        maxRoleCapacityWithDrawHours
      });

      return excessStaffCapacity;
    }

    if(!this.drive.collectionOperation.autoGenerateDualRole) return;
    if(this.drive.collectionOperation.onlyGenerateDualRoleIfOneMachine && this.drive.numberOf2rbcAssets !== 1) return;
    if(this.helper.isDriveAPartOfMultiDaysLinkedDrive(this.drive)) return;
    if(!this.masterData?.staffingDecisionMatrix) return;

    let tempMapResourceQuantity = cloneDeep(this.mapResourceQuantity);
    const excessStaffCapacity = calculateExcessStaffCapacity(this.drive, tempMapResourceQuantity);
    if(excessStaffCapacity < this.masterData.adminSetting.excessStaffCapacityThreshold) return;

    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    let dualRolesAutoGenerated = false;
    driveShiftsMetadata.driveShifts.forEach((driveShiftMetadata, driveShiftIndex) => {
      const resourceQuantityMap = tempMapResourceQuantity.get(driveShiftMetadata?.key);
      const containsManuallyChangedDualRole = this.helper.checkResourceQuantityMapContainsAnyManuallyChangedDualRole(resourceQuantityMap);
      if(containsManuallyChangedDualRole) return;
      
      const contains2RBCAndDriverSupportRoles = this.helper.checkResourceQuantityMapContainsRoles(resourceQuantityMap, ['2RBC', 'Driver Support']);
      const validRoles = this.helper.getValidRolesInResourceQuantityMap(resourceQuantityMap);
      if(!contains2RBCAndDriverSupportRoles || validRoles.length < 4) return;
      
      const driveShift = this.drive.driveShifts[driveShiftIndex];
      const backupDriveShift = this.masterData.backupDriveShiftMap[driveShift?.key];
      const any2RBCAllocations = backupDriveShift?.jobs
        ?.find(job => job.resourceRole === '2RBC' || job.dualRole === '2RBC')
        ?.jobAllocations?.find(jobAllocation => jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED);
      const anyDriverSuppoerAllocations = backupDriveShift?.jobs
        ?.find(job => job.resourceRole === 'Driver Support' || job.dualRole === 'Driver Support')
        ?.jobAllocations?.find(jobAllocation => jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED);
      if(any2RBCAllocations || anyDriverSuppoerAllocations) return;

      const { jobsToCreate, jobsToUpdate, jobsToDelete } = this.helper.generateDualRoleJob({
        resourceRole: '2RBC',
        quantity: resourceQuantityMap.get('2RBC').quantity
      }, {
        resourceRole: 'Driver Support',
        quantity: resourceQuantityMap.get('Driver Support').quantity
      });
      if(!jobsToCreate.length && !jobsToUpdate.length && !jobsToDelete.length) return;

      jobsToDelete.forEach(({previousJob}) => {
        const jobKey = this.helper.generateJobKey(previousJob);
        resourceQuantityMap.delete(jobKey);
      })

      jobsToUpdate.forEach(({previousJob, newJob}) => {
        const previousJobKey = this.helper.generateJobKey(previousJob);
        const jobKey = this.helper.generateJobKey(newJob);
        resourceQuantityMap.set(jobKey, {
          ...resourceQuantityMap.get(previousJobKey),
          ...newJob
        });
        if(previousJobKey !== jobKey) {
          resourceQuantityMap.delete(previousJobKey);
        }
      })

      jobsToCreate.forEach(({newJob}) => {
        const jobKey = this.helper.generateJobKey(newJob);
        resourceQuantityMap.set(jobKey, {
          ...newJob
        });
      })
      
      dualRolesAutoGenerated = true;
    });

    this.drive.dualRolesAutoGenerated = this.drive.dualRolesAutoGenerated || dualRolesAutoGenerated;
    if(dualRolesAutoGenerated) {
      const excessStaffCapacity = calculateExcessStaffCapacity(this.drive, tempMapResourceQuantity);
      if(excessStaffCapacity >= 0) {
        this.mapResourceQuantity = tempMapResourceQuantity;
      }
    }
  }

  restoreDualRoles(backupDualRolesMap = {}) {
    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    Object.keys(backupDualRolesMap).forEach(driveShiftIndex => {
      const driveShiftMetadata =  driveShiftsMetadata?.driveShifts?.[driveShiftIndex];
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShiftMetadata?.key);
      if(!resourceQuantityMap) return;

      let tempResourceQuantityMap = cloneDeep(resourceQuantityMap);
      let tempManuallyCreatedQuantityMap = new Map();
      let backupDualRoles = orderBy(backupDualRolesMap[driveShiftIndex], [item => item.isManuallyCreated], ['asc']);
      backupDualRoles.forEach(item => {
        if(item.isManuallyCreated) return;

        const { resourceRole, dualRole, quantity, isCreatedOrUpdatedViaDualRoleChange } = item;
        const hasResourceRoleAfterRegenerated = tempResourceQuantityMap.has(resourceRole);
        let dualRoleQuantityAfterRegenerated = tempResourceQuantityMap.get(dualRole);
        let resourceRoleQuantityAfterRegenreted = tempResourceQuantityMap.get(resourceRole);
        const canRestore = hasResourceRoleAfterRegenerated && dualRoleQuantityAfterRegenerated;

        if(isCreatedOrUpdatedViaDualRoleChange) {
          tempResourceQuantityMap.delete(resourceRole);
          tempResourceQuantityMap.set(item.resourceRole, cloneDeep({
            ...resourceRoleQuantityAfterRegenreted,
            quantity: quantity,
            isCreatedOrUpdatedViaDualRoleChange: true
          }));
        }

        if(canRestore) {
          const { jobsToCreate, jobsToUpdate, jobsToDelete } = this.helper.generateDualRoleJob({
            resourceRole: resourceRole,
            ...resourceRoleQuantityAfterRegenreted
          }, {
            resourceRole: dualRole,
            ...dualRoleQuantityAfterRegenerated
          });
          
          if(!jobsToCreate.length && !jobsToUpdate.length && !jobsToDelete.length) return;

          jobsToDelete.forEach(({previousJob}) => {
            const jobKey = this.helper.generateJobKey(previousJob);
            tempResourceQuantityMap.delete(jobKey);
          })
    
          jobsToUpdate.forEach(({previousJob, newJob}) => {
            const previousJobKey = this.helper.generateJobKey(previousJob);
            const jobKey = this.helper.generateJobKey(newJob);
            tempResourceQuantityMap.set(jobKey, {
              ...tempResourceQuantityMap.get(previousJobKey),
              ...newJob
            });
            if(previousJobKey !== jobKey) {
              tempResourceQuantityMap.delete(previousJobKey);
            }
          })
    
          jobsToCreate.forEach(({newJob}) => {
            const jobKey = this.helper.generateJobKey(newJob);
            tempResourceQuantityMap.set(jobKey, {
              ...newJob
            });
          })
        }
      });

      backupDualRoles.forEach(item => {
        if(!item.isManuallyCreated) return;

        const { resourceRole, dualRole, quantity, vphhQuantity, aptQuantity, isManuallyCreated, manuallyCreatedFrom } = item;
        if(dualRole) {
          tempResourceQuantityMap.delete(dualRole);
          tempResourceQuantityMap.delete(resourceRole);
          tempManuallyCreatedQuantityMap.set(this.helper.generateJobKey({
            resourceRole,
            dualRole
          }), {
            isManuallyCreated,
            manuallyCreatedFrom,
            resourceRole,
            dualRole,
            quantity,
            vphhQuantity,
            aptQuantity
          })
        } else {
          tempManuallyCreatedQuantityMap.set(resourceRole, {
            isManuallyCreated,
            manuallyCreatedFrom,
            resourceRole,
            dualRole,
            quantity,
            vphhQuantity,
            aptQuantity
          })
        }
      });

      tempResourceQuantityMap.forEach((item, resourceRole) => {
        if(resourceRole === 'VP/HH') {
          item.quantity = item.vphhQuantity + (item.aptQuantity || 0);
        }
      });

      //check if latest Resources still can adapt current drive shift donors, if yes apply tempResourceQuantityMap to this.mapResourceQuantity
      const driveShiftStaffCapacity = Math.floor(this.helper.calculateStaffCapacity([
        'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'
      ], this.drive, driveShiftMetadata, 
        new Map()
          .set(driveShiftMetadata.key, new Map([...tempResourceQuantityMap, ...tempManuallyCreatedQuantityMap]))
      , this.masterData));
      const canAdaptCurrentDriveShiftDonors = driveShiftStaffCapacity >= driveShiftMetadata.donorsScheduled;
      if(canAdaptCurrentDriveShiftDonors) {
        this.mapResourceQuantity.set(driveShiftMetadata?.key, new Map([...tempResourceQuantityMap, ...tempManuallyCreatedQuantityMap]));
      }
    });
  }

  calculateDraftDriveGhostVehicleQuantity(skipVehicleCalculation = false) {
    if (skipVehicleCalculation) {
      let totalVehicleRequested = this.drive.totalVehicleRequestedChanged.totalVehicleRequested;
      if (isNullOrEmpty(totalVehicleRequested) || totalVehicleRequested < 1) {
        if(this.drive.numberOfVehicles > 0) {
          totalVehicleRequested = this.drive.numberOfVehicles;
        } else {
          totalVehicleRequested = 1;
        }
      }

      if (this.drive.doNotUseVehicle) {
        this.drive.totalVehicleRequested = 0;
      } else {
        if(this.drive.preferSystemGeneratedVehicles) {
          this.drive.totalVehicleRequested = totalVehicleRequested;
          this.drive.nnumberOfVehicles = totalVehicleRequested;
        } else {
          this.drive.totalVehicleRequested = this.drive.numberOfVehicles;
        }
      }
      return;
    }

    if (this.drive.status !== DRIVE_STATUS.DRAFT) {
      return;
    }

    if (this.drive.doNotUseVehicle) {
      this.drive.totalVehicleRequested = 0;
      return;
    }

    if (!this.drive.preferSystemGeneratedVehicles) {
      this.drive.totalVehicleRequested = this.drive.numberOfVehicles;
      return;
    }
    
    //validate tags
    const vehicleJobTagIds = this.helper.getVehicleTags(this.masterData.driveTags).map((tag) => {
      return tag.id;
    });
    const vehicles = this.masterData.vehicles;

    let availableVehicles = vehicles.filter(vehicle => {
      const validTagIds = [];
      (vehicle.resourceTags || []).find((resourceTag) => {
        if (resourceTag.startDate <= this.drive.driveDate) {
          validTagIds.push(resourceTag.tagId);
        }
      });

      return difference(vehicleJobTagIds, validTagIds).length === 0;
    })

    this.drivesWithVehicles = this.helper.calculateNumberOfVehiclesForDrive({
      key: this.drive.key,
      ...this.drive.driveShiftsMetadata,
    }, availableVehicles, {});

    if (this.drivesWithVehicles && this.drivesWithVehicles.length) {
      let currentDrive = this.drivesWithVehicles.find(drive => drive.driveKey == this.drive.key);
      let noOfVehicles = currentDrive.vehicles.length;
      this.drive.totalVehicleRequested = noOfVehicles;
      this.drive.numberOfVehicles = noOfVehicles;
    }
    else {
      this.drive.totalVehicleRequested = 1;
      this.drive.numberOfVehicles = 1;
    }
  }

  calculateVehicleQuantity() {
    this.mapAssetQuantity.set('Vehicle', this.drive.doNotUseVehicle ? 
      0 : 
      this.drive.preferSystemGeneratedVehicles ? 
        this.drive.totalVehicleRequested : 
        this.drive.numberOfVehicles);
  }

  calculateEquipmentQuantity() {
    let noOfEquipments = this.drive.numberOf2rbcAssets || 0;
    this.mapAssetQuantity.set('Equipment', noOfEquipments);
  }

  calculateDriverQuantity() {
    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    const numberOfVehicles = this.mapAssetQuantity.get('Vehicle');

    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
      let numberOfDrivers = numberOfVehicles;
      if (numberOfDrivers < 1 && !this.drive.doNotUseVehicle) numberOfDrivers = 1;
  
      resourceQuantityMap.set('Driver', {
        quantity: numberOfDrivers
      });
      if (this.masterData.staffingDecisionMatrix.driverSupportCapacity && this.masterData.staffingDecisionMatrix.driverSupportCapacity > 0) {
        resourceQuantityMap.set('Driver Support', {
          quantity: numberOfDrivers
        });
      }
    })
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

  calculateVpHhQuantity(resourceRoles = ['Driver', 'Driver Support', '2RBC', 'Charge']) {
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
      if(totalVpHhCapacity < 0) totalVpHhCapacity = 0;
      
      const drawHours = this.helper.calculateDrawHours(driveShiftMetadata, this.masterData, driveShiftMetadata.lunchBreakSettings);

      let noOfVpHhStaffs = Math.ceil(totalVpHhCapacity / vpHhCapacity / drawHours);
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShiftMetadata.key);
      resourceQuantityMap.set('VP/HH', {
        vphhQuantity: noOfVpHhStaffs,
        aptQuantity: driveShiftsMetadata.APTSetup
      });
    });
  }

  recalculateVphhQuantity(driveShift, resourceRoles = ['Driver', 'Driver Support', '2RBC', 'Charge']) {
    if (!this.masterData.staffingDecisionMatrix || isNullOrEmpty(this.masterData.staffingDecisionMatrix.vpHhCapacity)) return;

    const driveShiftMetadata = driveShift.driveShiftMetadata;
    const staffCapacity = this.helper.calculateStaffCapacity(
      resourceRoles,
      this.drive,
      driveShiftMetadata,
      new Map()
        .set(driveShiftMetadata.key, this.helper.getDriveShiftResourceQuantity(driveShift)),
      this.masterData
    )

    const vpHhCapacity = this.masterData.staffingDecisionMatrix.vpHhCapacity;
    let totalVpHhCapacity = Math.ceil(driveShiftMetadata.donorsScheduled - staffCapacity);
    if(totalVpHhCapacity < 0) totalVpHhCapacity = 0;
      
    const drawHours = this.helper.calculateDrawHours(driveShiftMetadata, this.masterData, driveShiftMetadata.lunchBreakSettings);

    let noOfVpHhStaffs = Math.ceil(totalVpHhCapacity / vpHhCapacity / drawHours);

    let existingVphhJob = driveShift.jobs.find(job => 
      job.resourceRole === 'VP/HH' && 
      !job.dualRole)

    if(existingVphhJob?.manuallyCreatedFrom === MANUALLY_CREATED_FROM.STAFFING_MODAL) {
      return;
    }

    if(noOfVpHhStaffs > 0) {
      if(existingVphhJob) {
        existingVphhJob.vphhQuantity = noOfVpHhStaffs;
        existingVphhJob.quantity = existingVphhJob.vphhQuantity + (existingVphhJob.aptQuantity ?? 0);
        existingVphhJob.systemQuantity = existingVphhJob.quantity;
      } else {
        let shift = this.drive.driveShifts.find((e) => e.key == driveShift.key);
        const newList = [...shift.jobs];
        let newJob = {
          id: uniqueId('temp_job_'),
          key: generateUUID(),
          resourceRole: 'VP/HH',
          dualRole: '',
          vphhQuantity: noOfVpHhStaffs,
          aptQuantity: 0,
          quantity: noOfVpHhStaffs,
          systemQuantity: noOfVpHhStaffs,
          jobTags: []
        };
        newList.push(newJob);

        shift.jobs = newList;
        shift.jobs.forEach(job => {
          if(newJob.key === job.key) {
            this.applyRoleTimeForSingleJob(shift, job);
          }
        });
      }
    } else {
      if(existingVphhJob) {
        if(existingVphhJob.aptQuantity > 0) {
          existingVphhJob.vphhQuantity = 0;
          existingVphhJob.quantity = existingVphhJob.vphhQuantity + (existingVphhJob.aptQuantity ?? 0);
        } else {
          remove(driveShift.jobs, job => job.key === existingVphhJob.key);
        }
      }
    }
  }

  calculateChargeQuantity() {
    if (!this.masterData.staffingDecisionMatrix || isNullOrEmpty(this.masterData.staffingDecisionMatrix.chargeThreshold)) return;

    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    driveShiftsMetadata.driveShifts.forEach(driveShift => {
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShift.key);
      let { quantity: noOfDrivers } = resourceQuantityMap.get('Driver');
      let { quantity: noOfDriverSupports } = resourceQuantityMap.get('Driver Support') || {};
      let { quantity: noOf2rbcStaffs } = resourceQuantityMap.get('2RBC');
      let { quantity: noOfTeamSupervisor } = resourceQuantityMap.get('Team Supervisor') || {};
      let { quantity: noOfDriveLeads } = resourceQuantityMap.get('Drive Lead') || {};
      let { vphhQuantity: noOfVpHhStaffs } = resourceQuantityMap.get('VP/HH');
      if(!noOfDrivers) noOfDrivers = 0;
      if(!noOfDriverSupports) noOfDriverSupports = 0;
      if(!noOf2rbcStaffs) noOf2rbcStaffs = 0;
      if(!noOfTeamSupervisor) noOfTeamSupervisor = 0;
      if(!noOfDriveLeads) noOfDriveLeads = 0;
      if(!noOfVpHhStaffs) noOfVpHhStaffs = 0;

      const noOfStaffWithoutLeaders = noOfDrivers + noOfDriverSupports + noOf2rbcStaffs + noOfVpHhStaffs;
      const noOfLeaders = Math.ceil(noOfStaffWithoutLeaders / 11);
      let noOfCharges = noOfLeaders - noOfTeamSupervisor - noOfDriveLeads;
      if(noOfCharges < 0) noOfCharges = 0;

      resourceQuantityMap.set('Charge', {
        quantity: noOfCharges
      });

      //Recalculate VP/HH.
      this.calculateVpHhQuantity();
    });
  }

  calculateVolunteerDonorAmbassadors() {
    // if checkbox in unchecked, no need to go for further calculation
    if(!this.drive.redcrossVolunteerRequired) {
      this.mapVolunteerQuantity.set(VOLUNTEER_TYPE.DONOR_AMBASSADOR, 0);
      return;
    }

    const extraVolunteersRecursive = (donorsOverMax, count = 0) => {
      if (donorsOverMax < 40) return count;
      return extraVolunteersRecursive(donorsOverMax - 40, count + 1);
    };

    let noOfVolunteerDonorAmbassadors = this.drive.redcrossVolunteerQuantity || 0;

    const isHighSchoolDrive = this.drive.accountType === ACCOUNT_TYPE.EDUCATION && this.drive.industryCode === ACCOUNT_INDUSTRY_CODE.HIGH_SCHOOL;
    const redcrossVolunteerMatrix = this.masterData.redcrossVolunteerMatrix?.filter(item => item.isHighSchoolDrive === isHighSchoolDrive) || [];

    if(isNullOrEmpty(this.drive.id)) noOfVolunteerDonorAmbassadors = this.drive.redcrossVolunteerQuantity; //In case of drive generation, get quantity from opp
    else if(!this.masterData.skipVolunteerRecalculation && redcrossVolunteerMatrix) {
      const matchedMatrixRecord = redcrossVolunteerMatrix.find(matrix => {
        return matrix.minDonorValue <= this.drive.projectedRegisteredDonors
          && matrix.maxDonorValue >= this.drive.projectedRegisteredDonors
      });

      if(matchedMatrixRecord) {
        noOfVolunteerDonorAmbassadors = matchedMatrixRecord.volunteerQuantity;
      } else {
        const maxDonorValueMatrix = redcrossVolunteerMatrix.reduce((prev, current) => {
          return (prev.maxDonorValue > current.maxDonorValue) ? prev : current;
        });

        if(this.drive.projectedRegisteredDonors > maxDonorValueMatrix.maxDonorValue) {
          const maxVolunteerCount = maxDonorValueMatrix.volunteerQuantity;
          noOfVolunteerDonorAmbassadors = isHighSchoolDrive ? maxVolunteerCount : extraVolunteersRecursive(this.drive.projectedRegisteredDonors - maxDonorValueMatrix.maxDonorValue, maxVolunteerCount);
        } 
      }


      if(this.masterData.backupDrive?.tempRedcrossVolunteerRequired !== this.drive.redcrossVolunteerRequired) {
        const isRequired = this.drive.redcrossVolunteerRequired;
        if(isRequired && noOfVolunteerDonorAmbassadors <= 0) noOfVolunteerDonorAmbassadors = 1;
        if(!isRequired && noOfVolunteerDonorAmbassadors > 0) noOfVolunteerDonorAmbassadors = 0;
      }
    }

    this.mapVolunteerQuantity.set(VOLUNTEER_TYPE.DONOR_AMBASSADOR, noOfVolunteerDonorAmbassadors);
  }

  /** Generate drive shifts & jobs  */
  applyStaffingComplementAndProposeDriveShifts() {
    const staffingComplementChanged = this.drive.staffingComplementChanged;
    if(!staffingComplementChanged) return;

    this.proposeDriveShifts({
      skipCalculateResourceRoles: true,
      skipVehicleCalculation: false,
      backupAndRestoreDualRoles: true,
      skipGenerateSlots: false
    })
  }

  proposeDriveShifts({
    skipCalculateResourceRoles = false,
    skipVehicleCalculation = false,
    backupAndRestoreDualRoles = true,
    skipGenerateSlots = false
  } = {}) {
    if (this.drive.projectedRegisteredDonors) {
      this.backupDualRolesMap = {};
      if(backupAndRestoreDualRoles) {
        this.drive.driveShifts.forEach((driveShift, driveShiftIndex) => {
          if(!this.backupDualRolesMap[driveShiftIndex]) {
            this.backupDualRolesMap[driveShiftIndex] = [];
          }

          driveShift.jobs.forEach(job => {
            if(!job.resourceRole) return;
            
            if(this.helper.isManuallyCreatedJob(job, this.drive)) {
              this.backupDualRolesMap[driveShiftIndex].push({
                resourceRole: job.resourceRole,
                dualRole: job.dualRole,
                quantity: job.quantity,
                vphhQuantity: job.vphhQuantity,
                aptQuantity: job.aptQuantity,
                isManuallyCreated: true,
                manuallyCreatedFrom: job.manuallyCreatedFrom 
              })
            } else {
              if(job.resourceRole && job.dualRole) {
                this.backupDualRolesMap[driveShiftIndex].push({
                  resourceRole: job.resourceRole,
                  dualRole: job.dualRole,
                  quantity: job.quantity
                })
              } else if(job.isCreatedOrUpdatedViaDualRoleChange) {
                this.backupDualRolesMap[driveShiftIndex].push({
                  resourceRole: job.resourceRole,
                  dualRole: job.dualRole,
                  quantity: job.quantity,
                  vphhQuantity: job.vphhQuantity,
                  aptQuantity: job.aptQuantity,
                  isCreatedOrUpdatedViaDualRoleChange: true
                })
              }
            }
          });
        });
      }

      this.initResourceQuantityMap();
      this.calculateResourceQuantity(skipCalculateResourceRoles, skipVehicleCalculation, backupAndRestoreDualRoles);
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
        donorsScheduled: driveShiftMetadata.donorsScheduled,
        APTSetup: this.drive.driveShiftsMetadata.APTSetup
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
    const mapResourceQuantity = this.mapResourceQuantity.get(driveShiftMetadata.key);
    Array.from(mapResourceQuantity.keys()).forEach((jobKey) => {
      const {
        resourceRole,
        dualRole
      } = this.helper.parseJobKey(jobKey);
      let job = (driveShift.jobs || []).find(driveShiftJob => this.helper.isJobsSameRoles(driveShiftJob, {
        resourceRole,
        dualRole
      }));
      if (!job) {
        job = cloneDeep(jobTemplate);
        job.key = generateUUID();
      }
      job.jobTags = cloneDeep(jobTagsMap[RESOURCE_TYPE.PERSON]);
      job.resourceRole = resourceRole;

        if (resourceRole === 'VP/HH') {
          let { vphhQuantity, aptQuantity, dualRole, systemQuantity, isManuallyCreated, manuallyCreatedFrom, isCreatedOrUpdatedViaDualRoleChange } = mapResourceQuantity.get(jobKey);
          if (vphhQuantity > 0 || aptQuantity > 0) {
            job.dualRole = dualRole || '';
            job.vphhQuantity = vphhQuantity;
            job.aptQuantity = aptQuantity;
            job.quantity = vphhQuantity + (aptQuantity || 0);
            job.systemQuantity = systemQuantity || job.quantity;
            job.isManuallyCreated = !!isManuallyCreated;
            job.manuallyCreatedFrom = manuallyCreatedFrom;
            job.isCreatedOrUpdatedViaDualRoleChange = isCreatedOrUpdatedViaDualRoleChange;
            jobs.push(job);
          }
        } else {
          let { quantity, dualRole, systemQuantity, isManuallyCreated, manuallyCreatedFrom, isCreatedOrUpdatedViaDualRoleChange } = mapResourceQuantity.get(jobKey);
          if (quantity > 0) {
            job.quantity = quantity;
            job.dualRole = dualRole || '';
            job.systemQuantity = systemQuantity || job.quantity;
            job.isManuallyCreated = !!isManuallyCreated;
            job.manuallyCreatedFrom = manuallyCreatedFrom;
            job.isCreatedOrUpdatedViaDualRoleChange = isCreatedOrUpdatedViaDualRoleChange;
            jobs.push(job);
          }
        }
      
    });
    let originalDriveShift = this.drive.driveShifts[driveShiftIndex];

    this.mapVolunteerQuantity.forEach((quantity, volunteerRole) => {
      let job = (originalDriveShift?.jobs || []).find(driveShiftJob => driveShiftJob.volunteerRole == volunteerRole);
      if (!job) {
        job = cloneDeep(jobTemplate);
        job.key = generateUUID();
        job.jobTags = cloneDeep(jobTagsMap[RESOURCE_TYPE.PERSON]);
      } else job.jobTags = [...job.jobTags];
      job.tagNames = job.jobTags.map(item => item.tag.name).join(', ');
      job.volunteerRole = volunteerRole;
      if (volunteerRole === VOLUNTEER_TYPE.DONOR_AMBASSADOR) {
        job.redcrossVolunteerQuantity = quantity || 0;
        job.sponsorVolunteerQuantity = job.sponsorVolunteerQuantity || 0;
        job.quantity = (job.redcrossVolunteerQuantity || 0) + (job.sponsorVolunteerQuantity || 0);
        job.systemQuantity = job.quantity;
      }
      if (quantity > 0) {
        jobs.push(job);
      }
    });
    this.mapAssetQuantity.forEach((quantity, assetType) => {
      if (assetType === ASSET_TYPE.VEHICLE || quantity > 0) {
        let job = (driveShift.jobs || []).find(driveShiftJob => driveShiftJob.assetType == assetType);
        if (!job) {
          job = cloneDeep(jobTemplate);
          job.key = generateUUID();
        }
        job.assetType = assetType;
        if (job.assetType === ASSET_TYPE.EQUIPMENT) {
          job.equipmentSubtype = '2RBC Asset';
          job.jobTags = cloneDeep(jobTagsMap[ASSET_TYPE.EQUIPMENT]);
        } else {
          job.jobTags = cloneDeep(jobTagsMap[ASSET_TYPE.VEHICLE]);
        }
        job.quantity = quantity || 0;
        job.systemQuantity = job.quantity;
        jobs.push(job);
      }
    });

    //manually created jobs
    let manuallyCreatedJobs = (originalDriveShift?.jobs || []).filter(job => {
      const isManuallyCreatedJob = this.helper.isManuallyCreatedJob(job, this.drive);
      const existed = this.helper.findJob(job, jobs);
      const isJobTakenCareOf = jobs.find(item => item.key === job.key);
      return isManuallyCreatedJob && !existed && !isJobTakenCareOf;
    })
    .map(job => {
      let updatedJob = extend({}, job, jobTemplate);
      return extend(updatedJob, {
        isManuallyCreated: true, 
        manuallyCreatedFrom: job.manuallyCreatedFrom
      });
    });
    
    driveShift.jobs = jobs.concat(cloneDeep(manuallyCreatedJobs.filter(job => job.quantity > 0)));

    const anyManuallyCreatedJobsHoldCapacity = driveShift.jobs.find(job => {
      return job.resourceRole !== 'VP/HH' && this.helper.isManuallyCreatedJob(job, this.drive) && (
        this.helper.isRoleHoldCapacity(job.resourceRole, this.masterData) ||
        this.helper.isRoleHoldCapacity(job.dualRole, this.masterData) 
      )
    });

    if(anyManuallyCreatedJobsHoldCapacity) {
      this.recalculateVphhQuantity(driveShift);
    }
  }

  // To create new jobs /update existing jobs after dual role modification
  repopulateJobsAfterDualRoleModification(driveShift, job) {
    let newJob;
    let existingJob = driveShift.jobs?.find(item => item.resourceRole && !item.dualRole && item.resourceRole === job.dualRole);
    if(existingJob) {
      newJob = {
        ...existingJob,
        quantity: job.quantity,
        systemQuantity: job.quantity,
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
        newJob.isCreatedOrUpdatedViaDualRoleChange = true;
      }
      driveShift.jobs.push(newJob);
    }

    this.applyRoleTimeForSingleJob(driveShift, newJob);
    this.onJobChanged(driveShift, newJob, null);
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
      let staffSetup = this.helper.calculateStaffSetup(['Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'], driveShift);
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
    let staffSetup = this.helper.calculateStaffSetup(['Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'], driveShift);
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
            let staffSetup = this.helper.calculateStaffSetup(['Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'], driveShift);
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
  handleDriveShiftsMetadataChanged(driveShift = {}) {
    if (this.drive.driveShiftsMetadata) {
      this.calculateTotalProceduresProjected(this.drive.driveShiftsMetadata);
      this.drive.driveShiftsMetadata.APTSetup = !isEmpty(driveShift) ? driveShift.APTSetup : this.drive.aptQuantity;
      this.drive.driveShiftsMetadata.driveShifts.forEach((driveShiftMetadata) => {
        this.calculateTotalProceduresProjected(driveShiftMetadata);
        driveShiftMetadata.APTSetup = !isEmpty(driveShift) ? driveShift.APTSetup : this.drive.aptQuantity;
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

      if(!isEmpty(driveShift)) {
        this.masterData.backupDrive = extend(this.masterData.backupDrive, {
          tempRedcrossVolunteerRequired: this.drive.redcrossVolunteerRequired
        });
        this.drive.redcrossVolunteerRequired = driveShift.redcrossVolunteerRequired;
      }
      
      this.calculateNumberOf2rbcAssets();
      this.calculatePreferredNumberOf2rbcAssets();
    }
    this.proposeDriveShifts();
    this.calculateTotalProceduresProjected();
    this.calculateDriveProductivityPlanned();
    this.updateDriveAptSettings();
  }

  updateDriveAptSettings() {
    this.drive.aptRequired = this.drive.aptQuantity > 0;
  }

  handlePreferSystemGeneratedVehiclesChanged() {
    const backupDrive = this.masterData.backupDrive;
    if(!backupDrive) return;

    if (this.drive.preferSystemGeneratedVehicles) {
      this.drive.numberOfVehicles = backupDrive.totalVehicleRequested;
      this.drive.totalVehicleRequested = backupDrive.totalVehicleRequested;
      
      this.proposeDriveShifts();
      this.calculateDriveProductivityPlanned();
    }
  }

  handleTotalVehicleRequestedChanged() {
    if (!this.drive.projectedRegisteredDonors || !this.drive.totalVehicleRequestedChanged) return;

    const { vehicles, lockedVehicles = [] } = this.drive.totalVehicleRequestedChanged;

    this.drive.impactedVehicleMessages = [];

    this.proposeDriveShifts({
      skipVehicleCalculation: true,
      backupAndRestoreDualRoles: true,
      skipGenerateSlots: false
    });

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
        const locked = !!lockedVehicles.find(lockedVehicle => {
          return lockedVehicle.id === jobAllocation.resourceId;
        });
        if(locked) return;

        let newVehicle = vehicles.find(vehicle => vehicle.id === jobAllocation.resourceId);
        if (!newVehicle) {
          jobAllocation.previousStatus = jobAllocation.status;
          jobAllocation.status = JOB_ALLOCATION_STATUS.DELETED;
        }
      });

      vehicles.forEach((vehicle) => {
        let existingJobAllocation = vehicleJob.jobAllocations.find(jobAllocation => vehicle.id === jobAllocation.resourceId);
        if (!existingJobAllocation) {
          vehicleJob.jobAllocations.push({
            resourceId: vehicle.id,
            jobId: vehicleJob.id,
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

    let beforePlannedProductivity = this.drive.driveProductivityPlanned;
    this.calculateDriveProductivityPlanned();
    let afterPlannedProductivity = this.drive.driveProductivityPlanned;

    if (beforePlannedProductivity !== afterPlannedProductivity) {
      this.drive.impactedVehicleMessages.push(`Planned Drive Productivity changes from ${beforePlannedProductivity} to ${afterPlannedProductivity}.`)
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

  handleRedcrossVolunteerRequirement( job = {} ) {
    const isSpecificVolunteerJob  = (job, volunteerRole) => {
      if(!job) return false;
      return job.volunteerRole === volunteerRole;
    }

    this.initResourceQuantityMap();
    
    if(!isEmpty(job))  {
      if (!isSpecificVolunteerJob(job, VOLUNTEER_TYPE.DONOR_AMBASSADOR)) return;
      this.mapVolunteerQuantity = new Map().set(VOLUNTEER_TYPE.DONOR_AMBASSADOR, job.isDeleted ? 0 : job.redcrossVolunteerQuantity || 0);
    } else this.mapVolunteerQuantity = new Map().set(VOLUNTEER_TYPE.DONOR_AMBASSADOR, this.drive.redcrossVolunteerQuantity || 0);

    const redcrossVolunteerQuantity  = this.mapVolunteerQuantity.get(VOLUNTEER_TYPE.DONOR_AMBASSADOR);
    this.drive.redcrossVolunteerQuantity = redcrossVolunteerQuantity;
    this.drive.redcrossVolunteerRequired = redcrossVolunteerQuantity > 0;

    if(!isEmpty(job) && job.isDeleted) return;

    this.drive.driveShifts.forEach((driveShift) => {
      let driveShiftJobs = cloneDeep(driveShift.jobs);
      let originalJob = cloneDeep(this.helper.findJob({ volunteerRole: VOLUNTEER_TYPE.DONOR_AMBASSADOR }, driveShiftJobs));

      if(!isEmpty(originalJob)) {
        if(originalJob.key === job?.key) return;

        const originalJobIndex = driveShiftJobs.findIndex((item) => item.key === originalJob.key);
        let sponsorVolunteerQuantity = originalJob.sponsorVolunteerQuantity || 0;
        const quantity = redcrossVolunteerQuantity + sponsorVolunteerQuantity;

        if(quantity <= 0) {
          driveShiftJobs.splice(originalJobIndex, 1);
        } else {
          originalJob = {
            ...originalJob,
            redcrossVolunteerQuantity: redcrossVolunteerQuantity,
            sponsorVolunteerQuantity: sponsorVolunteerQuantity,
            quantity: quantity,
            systemQuantity: quantity
          };
          driveShiftJobs[originalJobIndex] = originalJob;
        }
      } else {
        this.populateDriveShiftJobs(driveShift, this.drive.driveShifts.findIndex(item => item.key === driveShift.key));
        driveShiftJobs = [...driveShiftJobs, ...driveShift.jobs];
      }
      driveShift.jobs = driveShiftJobs;
      let volunteerJob = driveShift.jobs.find(job => job.volunteerRole === VOLUNTEER_TYPE.DONOR_AMBASSADOR);
      if(!isEmpty(volunteerJob)) this.correctJobTime(volunteerJob, driveShift);
      this.updateShiftMobileSetup(driveShift);
    });   
  }

  onJobChanged(driveShift, job, originalJob) {
    if(job.assetType === ASSET_TYPE.VEHICLE) {
      if(this.drive.status === DRIVE_STATUS.DRAFT) {
        if(originalJob && originalJob.quantity !== job.quantity) {
          return this.onDriveDataChanged([
            {
              targetName: 'totalVehicleRequestedChanged',
              targetValue: {
                totalVehicleRequested: job.quantity,
                vehicles: []
              }
            }
          ])
        } 
      }
    }
    this.correctJobTime(job, driveShift);
    if(job.resourceRole !== 'VP/HH' && (
      this.helper.isRoleHoldCapacity(job.resourceRole, this.masterData) ||
      this.helper.isRoleHoldCapacity(job.dualRole, this.masterData) 
    )) {
      this.recalculateVphhQuantity(driveShift);
    }
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
      this.calculateTotalProceduresProjected(driveShift);//HRP-14339
    }

    if(job.resourceRole) {
      this.applyJobTimeToJobAllocations(job);
    }

    if(job.volunteerRole) {
      this.handleRedcrossVolunteerRequirement(job);
    }

    this.resetElectContentions();
  }

  /** Temporary */
  getCurrentAssignedVehicles() {
    return this.helper.getCurrentAssignedVehicles(this.drive);
  }

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

  retrieveVehicles() {
    return this.fetch.retrieveVehicles(this.drive)
    .then((vehicles) => {
      this.masterData.vehicles = vehicles || []; 
    })
  }

  retrieveDefaultTags() {
    return this.fetch.retrieveDefaultTags(this.drive)
    .then((driveTags) => {
      this.masterData.driveTags = driveTags;
    })
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

  retrieveTerritoryCollectionOperations() {
    return this.fetch.retrieveTerritoryCollectionOperations(this.drive)
    .then((territoryCollectionOperations) => {
      this.masterData.territoryCollectionOperations = territoryCollectionOperations;
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
}

export {
  MobileGenerator,
  DRIVE_FIELD_CHANGE_MAPPING
}