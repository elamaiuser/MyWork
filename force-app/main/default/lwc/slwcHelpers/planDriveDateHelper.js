import { groupBy, sum, cloneDeep, difference, isObject } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { ACCOUNT_AVAILABILITY_PREFERENCE, ASSET_TYPE, DRIVE_STATUS, DRIVE_TYPE, OPERATION_DRIVE_LIMIT_TYPE } from 'c/slwcConstants';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DriveHelper, SlwcDrivesGenerator } from 'c/slwcDriveGenerator';
import { isNullOrEmpty } from 'c/slwcUtils';

export default class slwcPlanDriveHelper {
  timeBlockIds;
  calendarSettings;
  collectionOperations;
  opportunity;
  driveLimits;
  staffingConstraints;
  drives;
  driveGeneratorInstanceMap;
  accountAvailabilityPreferences;
  collectionOperationTimeBlocks;
  mapDateIsoCollectionOperation = {};
  mapCollectionOperationData = {}

  drivesGeneratorInstance = new SlwcDrivesGenerator();
  driveHelper = new DriveHelper();

  get dateUtils() {
    return slwcDateUtils.getInstance(this.calendarSettings);
  }

  constructor(calendarSettings) {
    this.calendarSettings = calendarSettings;
  }

  initialize = ({
    opportunity,
    collectionOperations = [],
    startDate,
    endDate,
    timeBlockIds = [],
    driveLimits = [],
    staffingConstraints = [],
    mapEquipmentsByDate = {},
    mapVehiclesByDate = {},
    accountAvailabilityPreferences = [],
    collectionOperationTimeBlocks = [],
  }) => {
    return Promise.resolve()
    .then(() => {
      this.timeBlockIds = timeBlockIds;
      this.opportunity = opportunity;
      this.collectionOperations = collectionOperations;
      this.driveLimits = driveLimits;
      this.staffingConstraints = staffingConstraints;
      this.mapEquipmentsByDate = mapEquipmentsByDate;
      this.mapVehiclesByDate = mapVehiclesByDate;
      this.accountAvailabilityPreferences = accountAvailabilityPreferences;
      this.collectionOperationTimeBlocks = collectionOperationTimeBlocks;
      this.drives = this.generateDrives(this.opportunity, {
        startDate,
        endDate
      });

      return this.drivesGeneratorInstance.initialize(this.drives);
    })
    .then(() => {
      this.drivesGeneratorInstance.generateDrives({
        skipGenerateSlots: true
      })
      this.drives = this.drivesGeneratorInstance.drives || [];
      this.driveGeneratorInstanceMap = this.drivesGeneratorInstance.driveGeneratorInstanceMap || {};
    })
  }

  generateDrives(opp, {
    startDate,
    endDate
  }) {
    let drives = [];
    let drive = this.driveHelper.initiateNewDriveFromOpty(opp);
    const diff = this.dateUtils.diffDays(startDate, endDate);
    for (let i = 0; i <= diff; i++) {
      let currentDay = DateTime.fromFormat(startDate, 'yyyy-MM-dd').plus({
        days: i
      });
      let newDrive = cloneDeep(drive);
      newDrive.id = `temp_drive_${i}`;
      newDrive.driveDate = currentDay.toISODate();
      this.driveHelper.populateDriveCollectionOperation(newDrive);

      drives.push(newDrive);
    }

    return drives;
  }

  getDateRange = (selectedMonth) => {
    return {
      startDate: DateTime.fromFormat(selectedMonth, 'yyyy-MM-dd').startOf('month').toISODate(),
      endDate: DateTime.fromFormat(selectedMonth, 'yyyy-MM-dd').endOf('month').toISODate(),
    }
  }

  getCollectionOperations = (driveSite, startDate, endDate) => {
    if(!driveSite || !startDate || !endDate) return [];

    let result = [];
    if(driveSite.collectionOperation) {
      result.push(driveSite.collectionOperation);      
    }
    
    result = result.concat((driveSite.siteCollectionOperations || []).filter(item => {
      return startDate < item.endDate && endDate > item.startDate;
    }).map(item => item.collectionOperation));

    return result;
  }

  findDriveLimitByDay = ({
    collectionOperationId,
    collectionOperationIds = [],
    timeBlockIds: _timeBlockIds,
    driveDate
  }, driveLimits = [], type = null) => {
    if (!collectionOperationId && !collectionOperationIds.length) return null;

    const timeBlockIds = (_timeBlockIds !== undefined ? _timeBlockIds : this.timeBlockIds) ?? [];
    const dayOfWeek = DateTime.fromFormat(driveDate, 'yyyy-MM-dd').toFormat('cccc');
    let driveLimit = null;
    (driveLimits || []).filter(item => {
      let collectionOperationValid = false;
      if(collectionOperationId) {
        collectionOperationValid = collectionOperationId === item.collectionOperationId;
      } else if(collectionOperationIds.length) {
        collectionOperationValid = collectionOperationIds.includes(item.collectionOperationId);
      }

      let timeBlockValid = timeBlockIds.length > 0 ? timeBlockIds.includes(item.timeBlockId) : !item.timeBlockId;

      if (!type) {
        return collectionOperationValid && timeBlockValid && (!item.type || item.type === OPERATION_DRIVE_LIMIT_TYPE.DRIVE_LIMIT);
      }

      return collectionOperationValid && timeBlockValid && item.type === type;
    }).forEach(item => {
      const daysOfWeek = (item.daysOfWeek || '').split(';');
      const isDateRangeValid = (!item.effectiveStartDate || item.effectiveStartDate <= driveDate) && (!item.effectiveEndDate || driveDate <= item.effectiveEndDate);
      const isDayOfWeekValid = daysOfWeek.includes(dayOfWeek);
      const isOverrided = (item.operationDriveLimitOverrides || []).find(item => item.date == driveDate);
      
      if (isOverrided) {
        if(!isNullOrEmpty(isOverrided.quantity)) {
          driveLimit = (driveLimit || 0) + isOverrided.quantity;
        }
      } else {
        if (isDateRangeValid && isDayOfWeekValid) {
          if(!isNullOrEmpty(item.quantity)) {
            driveLimit = (driveLimit || 0) + item.quantity;
          }
        }
      }
    })

    return driveLimit;
  }

  findStaffingConstraintByDay = (dateIso, timeBlockIds = [], staffingConstraints) => {
    if (!dateIso) return 0;

    let foundItem = (staffingConstraints || []).find(item => {
      const isTimeBlockValid = timeBlockIds.length > 0 ? timeBlockIds.includes(item.timeBlockId) : !item.timeBlockId;
      const isDateRangeValid = item.dateOfConstraint === dateIso;
      return isTimeBlockValid && isDateRangeValid;
    })

    return foundItem;
  }

  isOperationHoursValid = (drive, {
    timezoneSidId
  }) => {
    if(!drive) return true;
    if(!drive.collectionOperation) return true;
    
    const minimumDriveStartTime = drive.collectionOperation.minimumDriveStartTime;
    const maximumDriveEndTime = drive.collectionOperation.maximumDriveEndTime;
    const minimumDriveStartDateTime = minimumDriveStartTime ? this.driveHelper.newDateTime(drive.driveDate, minimumDriveStartTime, timezoneSidId) : null;
    const maximumDriveEndDateTime = maximumDriveEndTime ? this.driveHelper.newDateTime(drive.driveDate, maximumDriveEndTime, timezoneSidId) : null;

    let isOutOfOperationalHours = false;
    drive.driveShifts.forEach((driveShift) => {
      let driveShiftStart = new Date(driveShift.start);
      let driveShiftFinish = new Date(driveShift.finish);

      if (minimumDriveStartDateTime && minimumDriveStartDateTime > driveShiftStart) {
        isOutOfOperationalHours = true;
      }
      if (maximumDriveEndDateTime && maximumDriveEndDateTime < driveShiftFinish) {
        isOutOfOperationalHours = true;
      }
    });

    return !isOutOfOperationalHours;
  }

  calculateAvailableResources = (drive, {
    sameDateDrives = [], 
    sameDateActivities = []
  }, staffingConstraints = []) => {
    const staffingConstraint = this.findStaffingConstraintByDay(drive.driveDate, this.timeBlockIds, staffingConstraints);
    const allResources = staffingConstraint ? staffingConstraint.totalStaffConstraints : 0;
    let driveResources = 0;
    sameDateDrives.forEach((drive) => {
      if (this.driveHelper.isFixedSiteDrive(this.opportunity) === this.driveHelper.isFixedSiteDrive(drive)) {
        let totalStaffRequested = drive.totalStaffRequested || 0;
        if(this.checkDriveUseTimeBlock(drive)) {
          totalStaffRequested = 0;
          drive.driveShifts?.forEach(driveShift => {
            if (this.timeBlockIds.includes(driveShift.timeBlockId)) {
              totalStaffRequested += driveShift.staffSetup
            }
          })
        }
        driveResources += totalStaffRequested;
      }
    });
    
    let activityResources = 0;
    sameDateActivities.forEach((activity) => {
      if(!this.timeBlockIds?.length || this.timeBlockIds.includes(activity.timeBlockId)) {
        if (this.driveHelper.isFixedSiteDrive(this.opportunity)) {
          activityResources += activity.fixedSiteStaffQuantity || 0;
        } else {
          activityResources += activity.mobileStaffQuantity || 0;
        }
      }
    });
    return allResources - driveResources - activityResources;
  }
  
  getAvailableVehicles(drive, {
    vehicles = []
  }) {
    let availableVehicles = [...vehicles];
    if (drive.driveSite && drive.driveSite.physicalLocationType === 'Inside') {
      availableVehicles = availableVehicles.filter(vehicle => {
        return vehicle.category !== 'Bus';
      });
    }
    
    return availableVehicles;
  }

  calculateAvailableEquipments = (drive) => {
    const totalEquipments = (this.mapEquipmentsByDate[drive.driveDate] || []).filter((item) => {
      const isDateValid = isNullOrEmpty(item.effectiveDate) || item.effectiveDate <= drive.driveDate;
      if (!isDateValid) return false;

      const inCollectionOperation = drive.collectionOperationId === item.collectionOperationId;
      if(!inCollectionOperation) return false;

      const isDedicatedToFixedSite = !!item.dedicatedToSiteId;
      const driveTypes = [drive.typeOfDrive];

      if (driveTypes.includes(DRIVE_TYPE.MOBILE) && driveTypes.includes(DRIVE_TYPE.FIXED_SITE)) {
        return true;
      } else if (driveTypes.includes(DRIVE_TYPE.MOBILE)) {
        return !isDedicatedToFixedSite;
      } else if (driveTypes.includes(DRIVE_TYPE.FIXED_SITE)) {
        return isDedicatedToFixedSite;
      }

      return true;
    });

    return totalEquipments.length;
  }
  
  proposeVehicles = (drive, vehicles = [], {
    maxDOT,
    maxCDL
  }) => {
    if(!this.driveHelper.isMobileDrive(drive)) return [];

    const drivesWithVehicles = this.driveHelper.calculateNumberOfVehiclesForDrive({
      key: drive.id,
      ...drive.driveShiftsMetadata,
    }, vehicles, {
      maxDOT,
      maxCDL
    });

    if (drivesWithVehicles && drivesWithVehicles.length) {
      let currentDrive = drivesWithVehicles.find(item => item.driveKey == drive.id);
      return currentDrive.vehicles;
    }
    
    return [];
  }

  calculateAvailableVehicles = (availableVehicles = []) => {
    const allVehicles = [];
    const allBuses = [];
    const allMobiles = [];
    availableVehicles.forEach(vehicle => {
      if (vehicle.category === 'Bus') {
        allBuses.push(vehicle);
      } else {
        allMobiles.push(vehicle);
      }

      allVehicles.push(vehicle);
    })

    return {
      availableVehicles: allVehicles.length,
      availableBuses: allBuses.length,
      availableMobiles: allMobiles.length,
    }
  }

  buildDriveCountByStatusList = (driveList) => {
    let groupedDrives = groupBy(driveList, 'status');
    let statuses = [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD];
    return statuses.map(status => {
      return {
        status: status,
        driveCount: (groupedDrives[status] || []).length
      }
    })
  } 

  buildAssetComplements = (mapAssetQuantity) => {
    if(!mapAssetQuantity) return [];

    let result = [];
    mapAssetQuantity.forEach((quantity, assetType) => {
      result.push({
        id: assetType,
        value: quantity || 0
      })
    })

    return result;
  }
  
  buildResourceComplements = (mapResourceQuantity) => {
    if(!mapResourceQuantity) return [];

    let roleMap = new Map();
    mapResourceQuantity.forEach((driveShiftMap, driveShiftKey) => {
      driveShiftMap.forEach((quantity, resourceRole) => {
        if(!roleMap.has(resourceRole)) {
          roleMap.set(resourceRole, 0);
        }

        let currentQuantity = roleMap.get(resourceRole);
        if(resourceRole === 'VP/HH') {
          roleMap.set(resourceRole, currentQuantity + (quantity.aptQuantity || 0) + (quantity.vphhQuantity || 0));
        } else {
          if(isObject(quantity)) {
            roleMap.set(resourceRole, currentQuantity + quantity.quantity || 0);
          } else {
            roleMap.set(resourceRole, currentQuantity + quantity || 0);
          }
        }
      })
    })

    let result = [];
    roleMap.forEach((quantity, resourceRole) => {
      if(quantity > 0) {
        result.push({
          id: resourceRole,
          value: quantity
        });
      }
    });

    return result;
  }

  checkDriveLimitValid = (drive, driveLimit, sameDateDrives) => {
    if (this.driveHelper.isFixedSiteDrive(drive)) {
      return true;
    }

    if (isNullOrEmpty(driveLimit)) return true;
    return driveLimit - sameDateDrives.length > 0;
  }

  checkDriveUseTimeBlock = (drive) => {
    if(!this.timeBlockIds.length) return false;
    if(this.driveHelper.isFixedSiteDrive(drive)) return false;
    return true;
  }

  generateDayStatusMapping = (startDate, endDate) => {
    if (!startDate || !endDate) return {};
    return this.generateDayStatusMappingFromDriveList(this.drives);
  }

  generateDayStatusMappingFromDriveList = (drives = []) => {
    if (!drives || !drives.length) return {};

    const timeBlockIds = this.timeBlockIds;
    const dayStatusMapping = {};

    drives.forEach((drive) => {
      if(this.checkDriveUseTimeBlock(drive)) {
        const availableCOTimeBlocks = this.driveHelper.findAvailableCOTimeBlocks(drive, {
          collectionOperationTimeBlocks: this.collectionOperationTimeBlocks
        });
        const matchSelectedTimeBlock = availableCOTimeBlocks.find(COTimeBlock => this.timeBlockIds.includes(COTimeBlock.timeBlockId));
        if(!matchSelectedTimeBlock) {
          dayStatusMapping[drive.driveDate] = {
            dateIso: drive.driveDate,
            isNotMatchTimeBlock: true
          }
          return;
        }
      }

      const driveGeneratorInstance = this.driveGeneratorInstanceMap[drive.id] || {};
      const driveMasterData = driveGeneratorInstance.masterData;
      const driveLimit = this.findDriveLimitByDay(drive, this.driveLimits);
      const operational2RBCLimit = this.findDriveLimitByDay(drive, this.driveLimits, OPERATION_DRIVE_LIMIT_TYPE.x2RBC_LIMIT);
      const operationalDOTLimit = this.findDriveLimitByDay(drive, this.driveLimits, OPERATION_DRIVE_LIMIT_TYPE.DOT_LIMIT);
      const operationalCDLLimit = this.findDriveLimitByDay(drive, this.driveLimits, OPERATION_DRIVE_LIMIT_TYPE.CDL_LIMIT);

      const sameDateDrives = (driveMasterData.sameDateDrives || []).filter(drive => {
        return [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(drive.status);
      });
      const sameDateMobileDrives = sameDateDrives.filter(drive => {
        return !this.driveHelper.isFixedSiteDrive(drive);
      });
      
      const sameTimeBlockMobileDrives = [];
      sameDateMobileDrives.forEach(drive => {
        const existed = sameTimeBlockMobileDrives.find(item => item.key === drive.key);
        if(existed) return;

        drive.driveShifts.forEach(driveShift => {
          if(timeBlockIds.includes(driveShift.timeBlockId)) {
            sameTimeBlockMobileDrives.push(drive);
          }
        })
      })
      
      const isDriveLimitValid = this.checkDriveLimitValid(drive, driveLimit, (
        timeBlockIds.length > 0 ? sameTimeBlockMobileDrives : sameDateMobileDrives
      ));

      const required2RBC = sum((
        timeBlockIds.length > 0 ? sameTimeBlockMobileDrives : sameDateMobileDrives
      ).map((drive) => (drive.totalEquipmentRequested || 0)));
      const is2RBCLimitValid = isNullOrEmpty(operational2RBCLimit) || operational2RBCLimit - required2RBC > 0;

      const requiredDOT = sum((
        timeBlockIds.length > 0 ? sameTimeBlockMobileDrives : sameDateMobileDrives
      ).map((drive) => (drive.noOfAllocatedDOTVehicles || 0)));
      const isDOTLimitValid = isNullOrEmpty(operationalDOTLimit) || operationalDOTLimit - requiredDOT > 0;

      const requiredCDL = sum((
        timeBlockIds.length > 0 ? sameTimeBlockMobileDrives : sameDateMobileDrives
      ).map((drive) => (drive.noOfAllocatedCDLVehicles || 0)));
      const isCDLLimitValid = isNullOrEmpty(operationalCDLLimit) || operationalCDLLimit - requiredCDL > 0;

      const availableResources = this.calculateAvailableResources(drive, {
        ...driveMasterData,
        sameDateDrives: sameDateDrives
      }, this.staffingConstraints);
      
      const vehicles = this.getAvailableVehicles(drive, {
        ...driveMasterData,
        vehicles: this.mapVehiclesByDate[drive.driveDate] || []
      });   
      const {
        availableBuses,
        availableMobiles,
        availableVehicles,
      } = this.calculateAvailableVehicles(vehicles);

      const availableEquipments = this.calculateAvailableEquipments(drive);
      const proposedVehicles = this.proposeVehicles(drive, vehicles, {
        maxDOT: isNullOrEmpty(operationalDOTLimit) ? undefined : Math.max(operationalDOTLimit - requiredDOT, 0),
        maxCDL: isNullOrEmpty(operationalCDLLimit) ? undefined : Math.max(operationalCDLLimit - requiredCDL, 0)
      });

      let requiredResources = 0;
      drive.driveShifts.forEach(driveShift => {
        const isTimeBlockValid = (timeBlockIds.length > 0 && driveShift.timeBlockId) ? timeBlockIds.includes(driveShift.timeBlockId) : true;
        if(!isTimeBlockValid) return;

        driveShift.jobs.forEach(job => {
          if (job.resourceRole) {
            requiredResources += (job.quantity || 0);
          }
        })
      });

      let requiredVehicles = 0;
      let requiredBuses = 0;
      let requiredMobiles = 0;
      proposedVehicles.forEach(vehicle => {
        if(vehicle.category === 'Bus') {
          requiredBuses += 1;
        } else {
          requiredMobiles += 1;
        }

        requiredVehicles++;
      })

      const isOperationHoursValid = this.isOperationHoursValid(drive, {
        ...driveMasterData,
        sameDateDrives: sameDateDrives
      });

      if(this.driveHelper.isMobileDrive(drive)) {
        if(drive.driveSite && drive.driveSite.physicalLocationType === 'Outside') {
          if(requiredBuses <= 0) {
            requiredBuses = 1;
            requiredVehicles += 1;
          }
        } else if(drive.driveSite && drive.driveSite.physicalLocationType === 'Inside') {
          if(requiredMobiles <= 0) {
            requiredMobiles = 1;
            requiredVehicles += 1;
          }
        } else {
          if(requiredVehicles <= 0) {
            requiredVehicles = 1;
          }
        }  
      }

      const requiredEquipments = driveGeneratorInstance.mapAssetQuantity.get("Equipment");

      const isEnoughVehicles =  requiredVehicles === 0 || (availableVehicles > 0 && availableVehicles - requiredVehicles >= 0);
      const isEnoughBuses =  requiredBuses === 0 || (availableBuses > 0 && availableBuses - requiredBuses >= 0);
      const isEnoughMobiles =  requiredMobiles === 0 || (availableMobiles > 0 && availableMobiles - requiredMobiles >= 0);
      const isEnoughResources = requiredResources === 0 || (availableResources > 0 && availableResources - requiredResources >= 0);
      const isEnoughEquipments = requiredEquipments === 0 || (availableEquipments > 0 && availableEquipments - requiredEquipments >= 0);

      let isAvailable = false;
      if(drive.driveSite && drive.driveSite.physicalLocationType === 'Outside') {
        isAvailable = isDriveLimitValid && is2RBCLimitValid && isDOTLimitValid && isCDLLimitValid && isEnoughBuses && isEnoughResources && isEnoughEquipments;
      } else if(drive.driveSite && drive.driveSite.physicalLocationType === 'Inside') {
        isAvailable = isDriveLimitValid && is2RBCLimitValid && isDOTLimitValid && isCDLLimitValid && isEnoughMobiles && isEnoughResources && isEnoughEquipments;
      } else {
        isAvailable = isDriveLimitValid && is2RBCLimitValid && isDOTLimitValid && isCDLLimitValid && isEnoughVehicles && isEnoughResources && isEnoughEquipments;
      }

      const assetComplements = this.buildAssetComplements(driveGeneratorInstance.mapAssetQuantity);
      const resourceComplements = this.buildResourceComplements(driveGeneratorInstance.mapResourceQuantity);

      dayStatusMapping[drive.driveDate] = {
        dateIso: drive.driveDate,
        isAvailable: isAvailable,
        isNotMatchTimeBlock: false,
        isDriveLimitValid,
        is2RBCLimitValid,
        isDOTLimitValid,
        isCDLLimitValid,
        isEnoughVehicles: isEnoughVehicles,
        isEnoughBuses: isEnoughBuses,
        isEnoughMobiles: isEnoughMobiles,
        isEnoughResources: isEnoughResources,
        isEnoughEquipments,
        isOperationHoursValid: isOperationHoursValid,
        driveLimit: isNullOrEmpty(driveLimit) ? '∞' : driveLimit,
        driveCount: sameDateDrives.length || 0,
        mobileDriveCount: sameDateMobileDrives.length || 0,
        available2RBCDriveCount: isNullOrEmpty(operational2RBCLimit) ? '∞' : operational2RBCLimit,
        required2RBCDriveCount: required2RBC || 0,
        availableDOTDriveCount: isNullOrEmpty(operationalDOTLimit) ? '∞' : operationalDOTLimit,
        requiredDOTDriveCount: requiredDOT || 0,
        availableCDLDriveCount: isNullOrEmpty(operationalCDLLimit) ? '∞' : operationalCDLLimit,
        requiredCDLDriveCount: requiredCDL || 0,
        availableVehicles: availableVehicles || 0,
        requiredVehicles: requiredVehicles || 0,
        availableBuses: availableBuses || 0,
        requiredBuses: requiredBuses || 0,
        availableMobiles: availableMobiles || 0,
        requiredMobiles: requiredMobiles || 0,
        availableResources: availableResources || 0,
        requiredResources: requiredResources || 0,
        availableEquipments: availableEquipments || 0,
        requiredEquipments: requiredEquipments || 0,

        numberOfDriveShifts: drive.driveShifts.length,
        resourceComplements: resourceComplements,
        vehicleComplements: assetComplements.filter(item => item.id === 'Vehicle'),
        equipmentComplements: assetComplements.filter(item => item.id === 'Equipment'),
        driveCountByStatusList: this.buildDriveCountByStatusList(sameDateDrives),
        mobileDriveCountByStatusList: this.buildDriveCountByStatusList(sameDateMobileDrives)
      }

      dayStatusMapping[drive.driveDate].errorMessages = this.generateErrorMessages(dayStatusMapping[drive.driveDate]);
    })

    return dayStatusMapping;
  }

  generateErrorMessages = (dayStatus) => {
    let errorMessages = [];
    
    if(!dayStatus.isDriveLimitValid) {
      errorMessages.push('Exceed Operation Drive Limit');
    }

    if(!dayStatus.is2RBCLimitValid) {
      errorMessages.push('Exceed 2RBC Operational Limit');
    }

    if(!dayStatus.isDOTLimitValid) {
      errorMessages.push('Exceed DOT Operational Limit');
    }

    if(!dayStatus.isCDLLimitValid) {
      errorMessages.push('Exceed CDL Operational Limit');
    }

    if(this.opportunity.driveSite && this.opportunity.driveSite.physicalLocationType !== 'Inside') {
      if(!dayStatus.isEnoughResources || !dayStatus.isEnoughBuses || !dayStatus.isEnoughMobiles) {
        errorMessages.push('Insufficient Resources');
      }
    } else {
      if(!dayStatus.isEnoughResources || !dayStatus.isEnoughVehicles) {
        errorMessages.push('Insufficient Resources');
      }
    }

    if(!dayStatus.isOperationHoursValid) {
      errorMessages.push('Out of Operational Hours');
    }

    return errorMessages;
  }

  generateDayAccountAvailabilityMapping = (_startDate, _endDate) => {
    let daysOfWeekDeclined = (this.opportunity.account && this.opportunity.account.daysOfWeekDeclined) || [];
    let daysOfWeekPreferred = (this.opportunity.account && this.opportunity.account.daysOfWeekPreferred) || [];
    let accountAvailabilityPreferences = this.accountAvailabilityPreferences || [];
    let dayAccountAvailabilityMapping = {};
    let startDate = DateTime.fromISO(_startDate, { zone: this.calendarSettings.timezone });
    let endDate = DateTime.fromISO(_endDate, { zone: this.calendarSettings.timezone });
    let tempDate = startDate;
    while (tempDate.ts <= endDate.ts) {
      let preference = accountAvailabilityPreferences.find(item => item.monthName == tempDate.monthLong);
      if (preference) {
        let isPreferredWeekday = preference.preferredWeekdays && preference.preferredWeekdays.indexOf(tempDate.weekdayLong) > -1;
        let isRestrictedWeekday = preference.restrictedWeekdays && preference.restrictedWeekdays.indexOf(tempDate.weekdayLong) > -1;

        let startOfMonth = tempDate.startOf('month');
        let startOfMonthWeekIndex = tempDate.startOf('month').weekday;
        if (startOfMonthWeekIndex == 7) {
          startOfMonthWeekIndex = 1;
        }
        else {
          startOfMonthWeekIndex = startOfMonthWeekIndex + 1;
        }

        let dayDiff = tempDate.diff(startOfMonth, ['days']).values.days;
        let weekNo = Math.ceil((startOfMonthWeekIndex + dayDiff) / 7);
        let weekName = "Week " + weekNo;

        let idPreferredWeek = preference.preferredWeeks && preference.preferredWeeks.indexOf(weekName) > -1;
        let idRestrictedWeek = preference.restrictedWeeks && preference.restrictedWeeks.indexOf(weekName) > -1;

        let status = ACCOUNT_AVAILABILITY_PREFERENCE.NEUTRAL;
        let isAvailable = false;
        if (isPreferredWeekday || isRestrictedWeekday || idPreferredWeek || idRestrictedWeek) {
          isAvailable = !(isRestrictedWeekday || idRestrictedWeek);
          status = isAvailable ? ACCOUNT_AVAILABILITY_PREFERENCE.PREFERRED : ACCOUNT_AVAILABILITY_PREFERENCE.NOT_PREFERRED;
        }

        dayAccountAvailabilityMapping[tempDate.toISODate()] = {
          isAvailable: isAvailable,
          status: status
        }
      }
      else {
        let status = ACCOUNT_AVAILABILITY_PREFERENCE.NEUTRAL;
        let isAvailable = false;
        if (daysOfWeekDeclined.indexOf(tempDate.weekdayLong) > -1) {
          isAvailable = false;
          status = ACCOUNT_AVAILABILITY_PREFERENCE.NOT_PREFERRED;
        }
        else if (daysOfWeekPreferred.indexOf(tempDate.weekdayLong) > -1) {
          isAvailable = true;
          status = ACCOUNT_AVAILABILITY_PREFERENCE.PREFERRED;
        }
        dayAccountAvailabilityMapping[tempDate.toISODate()] = {
          isAvailable: isAvailable,
          status: status
        }
      }
      tempDate = tempDate.plus({ day: 1 });
    }

    return dayAccountAvailabilityMapping;
  }

  /* DEPRECATED */
  initData_deprecated = (data = {}) => {
    this.opportunity = data.opportunity || null;
    this.accountAvailabilityPreferences = data.accountAvailabilityPreferences || [];
  }
}