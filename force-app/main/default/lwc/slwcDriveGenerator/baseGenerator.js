import { serial, generateUUID, parseJSON, isNullOrEmpty, cloneDeep as cloneDeepUtil } from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { cloneDeep, orderBy, extend, remove, max, compact, groupBy, uniq, omit, pick } from 'c/lodash';
import { DriveHelper } from './helper';
import { DRIVE_STATUS, ASSET_TYPE, DRIVE_SHIFT_TIME_BLOCK_CONTENTION, JOB_ALLOCATION_STATUS, DRIVE_TYPE, DRIVE_REQUEST_CHANGE_STATUS, MANUALLY_CREATED_FROM, OPERATION_TYPE, DRIVE_CONTENTION_RESOLUTION, DRIVE_CHANGE_REQUEST_TYPE, RESOURCE_ROLE_GROUP, DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION } from 'c/slwcConstants';
import {
  sObjectType,
  driveQueryModel,
  driveService,
  slotQueryModel,
  slotService
} from "c/dataService";
import * as slwcDateUtils from 'c/slwcDateUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcAvailator from 'c/slwcAvailator';

class BaseGenerator {
  fetch;
  helper;
  dateUtils;

  DRIVE_ACTION_GROUPS_ORDER;
  DRIVE_FIELD_CHANGE_MAPPING;
  DRIVE_SHIFT_FIELD_CHANGE_MAPPING;

  drive;
  backupDrive;
  masterData = {
    adminSetting: {},
    driveSite: null,
    driveTags: {
      accountTags: [],
      locationTags: []
    },
    isReadonly: false,
    loginUser: {},
    lunchBreakSettings: [],
    resourceRoleGroups: null,
    roleTimeData: null,
    roleTimeDetailMap: {},
    roleTimeVarianceMap: {},
    roleGroupTimeDetailMap: {},
    roleGroupTimeVarianceMap: {},
    sameDateActivities: [],
    sameDateDrives: [],
    staffingDecisionMatrix: null,
    timezoneSidId: null,
    vehicles: [],
    backupDriveShiftMap: {},
    fieldPermissionsMap: {},
    activeDriveChangeRequest: null,
    waitingDriveChangeRequest : null,
    pendingDriveChangeRequest : null,
    staffSetupExcludedRoles: [],
    skipAPTCalculation: true,
    
    redcrossVolunteerMatrix: [],
    skipVolunteerRecalculation: true,

    //fixed site
    fixedSiteProcedureProjections: [],
  };
  mapSlotRecurrenceDates = {};
  errorMessages = [];
  isRegenerateDriveChange = false;

  constructor({
    fetch,
    DRIVE_ACTION_GROUPS_ORDER,
    DRIVE_FIELD_CHANGE_MAPPING,
    DRIVE_SHIFT_FIELD_CHANGE_MAPPING
  }) {
    this.DRIVE_ACTION_GROUPS_ORDER = DRIVE_ACTION_GROUPS_ORDER;
    this.DRIVE_FIELD_CHANGE_MAPPING = DRIVE_FIELD_CHANGE_MAPPING;
    this.DRIVE_SHIFT_FIELD_CHANGE_MAPPING = DRIVE_SHIFT_FIELD_CHANGE_MAPPING;

    this.fetch = fetch;
    this.helper = new DriveHelper();
    this.dateUtils = slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  /** Process Data */
  initMasterData({
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
    fixedSiteProcedureProjections,
    activeDriveChangeRequest,
    territoryCollectionOperations = [],
    staffSetupExcludedRoles,
    redcrossVolunteerMatrix,
    collectionOperationTimeBlocks = []
  }) {
    let masterData = {...this.masterData, 
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
      fixedSiteProcedureProjections,
      activeDriveChangeRequest,
      territoryCollectionOperations,
      staffSetupExcludedRoles,
      redcrossVolunteerMatrix,
      collectionOperationTimeBlocks
    };

    if (this.drive.driveSite) {
      masterData.timezoneSidId = this.drive.driveSite.timezoneSidId;
    }
    
    if (masterData.activeDriveChangeRequest && masterData.activeDriveChangeRequest.status === DRIVE_REQUEST_CHANGE_STATUS.PENDING && masterData.activeDriveChangeRequest.type.includes(DRIVE_CHANGE_REQUEST_TYPE.USER_CHANGE)) {
      masterData.pendingDriveChangeRequest = masterData.activeDriveChangeRequest;
    }  else if(masterData.activeDriveChangeRequest && masterData.activeDriveChangeRequest.status !== DRIVE_REQUEST_CHANGE_STATUS.PENDING){
      masterData.waitingDriveChangeRequest = masterData.activeDriveChangeRequest;
    }
    masterData.adminSetting.callListRecipientNone = masterData.adminSetting.callListRecipientNone / 100;
    masterData.adminSetting.callListRecipient = masterData.adminSetting.callListRecipient / 100;
    masterData.adminSetting.callListRecipientNoneFixedSite = masterData.adminSetting.callListRecipientNoneFixedSite / 100;
    
    let { isReadonly, fieldReadonlyMap, fieldChangeRestrictionMap } = this.helper.buildFieldPermissionsMap(this.drive, masterData);
    masterData.isReadonly = isReadonly;
    masterData.fieldReadonlyMap = fieldReadonlyMap;
    masterData.fieldChangeRestrictionMap = fieldChangeRestrictionMap;

    let { roleTimeDetailMap, roleTimeVarianceMap, roleGroupTimeDetailMap, roleGroupTimeVarianceMap } = this.helper.buildRoleTimeDetailMap(this.drive, masterData);
    masterData.roleTimeDetailMap = roleTimeDetailMap;
    masterData.roleTimeVarianceMap = roleTimeVarianceMap;
    masterData.roleGroupTimeDetailMap = roleGroupTimeDetailMap;
    masterData.roleGroupTimeVarianceMap = roleGroupTimeVarianceMap;

    this.masterData = masterData;
  }

  processDriveData(drive) {
    if (drive.driveShifts && drive.driveShifts.length) {
      drive.driveShifts.forEach((driveShift) => {
        driveShift.canGenerateSlots = driveShift.slots && driveShift.slots.length;
        driveShift.jobs?.forEach(job => {
          if(isNullOrEmpty(job.systemQuantity)) {
            job.systemQuantity = job.quantity;
          }
        });
      });
    } else {
      drive.driveShifts = [];
    }

    if (this.helper.isMobileDrive(drive) && isNullOrEmpty(drive.numberOfVehicles)) {
      drive.numberOfVehicles = drive.totalVehicleRequested;
      drive.preferSystemGeneratedVehicles = true;
    }
    
    return drive;
  }

  //TODO: To be removed
  buildJobTagNames(driveShift) {
    let driveShifts = [];
    if (driveShift) {
      driveShifts = [driveShift];
    } else {
      driveShifts = this.drive.driveShifts;
    }
    driveShifts.forEach((shift) => {
      if (shift.jobs && shift.jobs.length) {
        shift.jobs.forEach((job) => {
          if (job.jobTags && job.jobTags.length) {
            let tagNameArr = job.jobTags.reduce((result, item) => {
              // if (!item.systemCreated) {
              //   result.push(item.tag.name);
              // }
              return result.concat(item.tag.name);
            }, []);
            job.tagNames = orderBy(tagNameArr, [item => item], ['asc']).join(", ");
          }
        });
      }
    });
  }

  backupDriveData(drive) {
    this.masterData.backupDrive = cloneDeep({...drive, tempRedcrossVolunteerRequired: drive.redcrossVolunteerRequired});
  }

  backupDriveShift(driveShift) {
    if (!driveShift) return;

    this.masterData.backupDriveShiftMap[driveShift.key] = cloneDeepUtil(driveShift);
  }

  populateSiteCollectionOperation() {
    this.helper.populateSiteCollectionOperation(this.drive);
    this.populateCollectionOperationData();
  }

  populateDriveCollectionOperation() {
    this.helper.populateDriveCollectionOperation(this.drive);
  }

  populateCollectionOperationData() {
    if (this.drive.collectionOperation) {
      if (!this.drive.maximumLunchBreakDuration) {
        this.drive.maximumLunchBreakDuration = this.drive.collectionOperation.lunchBreakDurationMobile;
      }
  
      if (!this.drive.travelTimeIncluded) {
        this.drive.travelTimeIncluded = this.drive.typeOfDrive === DRIVE_TYPE.MOBILE ? this.drive.collectionOperation.travelTimeIncludedMobile : this.drive.collectionOperation.travelTimeIncludedFixedSite;
      }

      const matchedSiteCO = this.helper.getMatchedSiteCOForDrive(this.drive);
      if (matchedSiteCO) {
        this.drive.collectionOperation = matchedSiteCO.collectionOperation;
      }

      this.drive.IMPACT = false;
      if (this.drive.collectionOperation.IMPACT === true) { 
        if (this.drive.collectionOperation.IMPACTStartDate || this.drive.collectionOperation.IMPACTEndDate) {
          this.drive.IMPACT = (!this.drive.collectionOperation.IMPACTStartDate || this.drive.collectionOperation.IMPACTStartDate <= this.drive.driveDate) &&
            (!this.drive.collectionOperation.IMPACTEndDate || this.drive.collectionOperation.IMPACTEndDate >= this.drive.driveDate) 
        }
      }

      const collectionOperationStagingLocation = (this.drive.collectionOperation.collectionOpStagingLocations || []).find(item => (!item.startDate || item.startDate <= this.drive.driveDate) && (!item.endDate || this.drive.driveDate <= item.endDate));
      if(collectionOperationStagingLocation) {
        this.drive.stagingLocationId = collectionOperationStagingLocation.stagingLocationId;
      }

      const { travelTimeSiteToCoIndex, travelTimeCoToSiteIndex } = this.helper.getTravelTimeIndexData(this.drive, this.masterData);
      this.drive.travelTimeSiteToCOIndexId = travelTimeSiteToCoIndex?.id;
      this.drive.travelTimeCOToSiteIndexId = travelTimeCoToSiteIndex?.id;
    }
  }

  populateDriveTerritory() {
    this.drive.territoryId = this.helper.getDriveTerritory(this.drive, this.masterData.territoryCollectionOperations)?.territoryId;
  }

  applyJobTimeToJobAllocations(job) {
    if (!job || !job.jobAllocations) return;
    job.jobAllocations = job.jobAllocations.map(jobAllocation => {
      const { start, end } = this.helper.calculateJATimesWithTravel({
        ...jobAllocation,
        job
      }, this.drive, this.masterData);
      return {
        ...jobAllocation,
        start: start,
        end: end,
        duration: DateTime.fromISO(end, {
          zone: TIME_ZONE
        }).diff(DateTime.fromISO(start, {
          zone: TIME_ZONE
        })).as('minutes')
      }
    })
  }

  correctJobAllocationTimes() {
    const roleJobAllocations = []
    const roleJobs = [];
    const assetJobs = [];
    const resources = [];
    this.drive.driveShifts?.forEach(driveShift => {
      driveShift.jobs?.forEach(job => {
        if(job.resourceRole) {
          roleJobs.push(job);
          const jas = this.helper.getJobAllocations(job);
          roleJobAllocations.push(...jas);
          jas.forEach(ja => {
            resources.push(ja.resource);
          });
        } else {
          assetJobs.push(job);
        }
      });
    });

    assetJobs.forEach(job => {
      this.applyJobTimeToJobAllocations(job);
    });

    if(!roleJobAllocations.length) {
      return Promise.resolve();
    };  

    const availator = slwcAvailator.getInstance({
      mapApis: window.google ? window.google.maps : null
    });

    return availator.fetchDataForDriveGenerator(this.drive, roleJobs.map(job => {
      return {
        ...job,
        driveDate: this.drive.driveDate,
        start: job.start.toISOString(),
        finish: job.finish.toISOString()
      }
    }), resources)
      .then(() => {
        return availator.buildScheduledAllocations();
      })
      .then((result) => {
        const possibleAllocations = result.possibleAllocations || [];
        roleJobAllocations.forEach(jobAllocation => {
          const posAl = possibleAllocations.find(item => item.resourceId === jobAllocation.resourceId && item.jobId === jobAllocation.jobId);
          if(!posAl) return;
          const { estimatedTravelData, estimatedTravelTimeTo, estimatedTravelTimeBack } = posAl;
          jobAllocation.travelTimeTo = estimatedTravelTimeTo || 0;
          jobAllocation.travelTimeBack = estimatedTravelTimeBack || 0;
          jobAllocation.geoServiceTravelTimeTo = estimatedTravelData?.travelTimeTo,
          jobAllocation.geoServiceTravelTimeBack = estimatedTravelData?.travelTimeBack,
          jobAllocation.geoServiceTravelDistanceTo = estimatedTravelData?.travelDistanceTo,
          jobAllocation.geoServiceTravelDistanceBack = estimatedTravelData?.travelDistanceBack
        });
      })
      .then(() => {
        roleJobs.forEach(job => {
          this.applyJobTimeToJobAllocations(job);
        });    
      });
  }
  
  /** Generate */
  initiateNewDriveFromOpty(opp) {
    let drive = this.helper.initiateNewDriveFromOpty(opp);
    return this.processDriveData(drive);
  }

  applyRoleTimeForSingleJob(driveShift, job) {
    const compareAndGetValue = (fieldName, resourceRoleTimeData, dualRoleTimeData) => {
      if(!fieldName) return 0;
      if(!dualRoleTimeData) return resourceRoleTimeData[fieldName] || 0;
      
      const value1 = resourceRoleTimeData[fieldName] || 0;
      const value2 = dualRoleTimeData[fieldName] || 0;
      return max([value1, value2]);
    }

    const driveShiftMetadata = driveShift.driveShiftMetadata;
    const resourceRoleGroupRoleTimeDataMap = driveShiftMetadata.resourceRoleGroupRoleTimeDataMap;
    if (job.resourceRole) {
      job.leadTime = 0;
      job.travelTime = 0;
      job.setupTime = 0;
      job.breakdownTime = 0;
      job.travelTime2 = 0;
      job.wrapUpTime = 0;
      job.siteLogisticsTo = 0;
      job.siteLogisticsBack = 0;

      const resourceRoleGroup = this.helper.getResourceRoleGroup(job.resourceRole, this.masterData);
      let roleTimeData = resourceRoleGroupRoleTimeDataMap[resourceRoleGroup];
     
      let dualRoleGroup;
      let dualRoleTimeData;
      if(resourceRoleGroup !== RESOURCE_ROLE_GROUP.DRIVING_ROLES && job.dualRole) {
        dualRoleGroup = this.helper.getResourceRoleGroup(job.dualRole, this.masterData);
        dualRoleTimeData = resourceRoleGroupRoleTimeDataMap[dualRoleGroup];
        if(dualRoleGroup === RESOURCE_ROLE_GROUP.DRIVING_ROLES) roleTimeData = cloneDeep(dualRoleTimeData);
      }
    
      job.leadTime = compareAndGetValue('leadTime', roleTimeData, dualRoleTimeData) || job.leadTime;
      job.travelTime = compareAndGetValue('travelTime', roleTimeData, dualRoleTimeData) || job.travelTime;
      job.siteLogisticsTo = compareAndGetValue('siteLogisticsTo', roleTimeData, dualRoleTimeData) || job.siteLogisticsTo;
      job.setupTime = compareAndGetValue('setupTime', roleTimeData, dualRoleTimeData) || job.setupTime;
      job.breakdownTime = compareAndGetValue('breakdownTime', roleTimeData, dualRoleTimeData) || job.breakdownTime;
      job.travelTime2 = compareAndGetValue('travelTime2', roleTimeData, dualRoleTimeData) || job.travelTime2;
      job.siteLogisticsBack = compareAndGetValue('siteLogisticsBack', roleTimeData, dualRoleTimeData) || job.siteLogisticsBack;
      job.wrapUpTime = compareAndGetValue('wrapUpTime', roleTimeData, dualRoleTimeData) || job.wrapUpTime;
    }
  }

  applyRoleTimeForSingleDriveShift(driveShift) {
    if (driveShift.jobs && driveShift.jobs.length) {
      driveShift.jobs.forEach((job) => {
        if (job.resourceRole) {
          this.applyRoleTimeForSingleJob(driveShift, job);
        }
      });
    }
  }
  
  resolveTimeBlockContentions(driveTimeBlockContentions = []) {
    return Promise.resolve()
    .then(() => {
      if(!driveTimeBlockContentions.length) return;

      driveTimeBlockContentions.forEach(contention => {
        const { driveShiftKey, timeBlockId, electNotUseTimeBlock, electOutOfTimeBlock} = contention;
        const driveShift = this.drive.driveShifts?.find(driveShift => driveShift.key === driveShiftKey);

        if(driveShift) {
          driveShift.timeBlockId = timeBlockId;
          let currentContentionResolutions = driveShift.contentionResolution ? driveShift.contentionResolution.split(';') : [];
          remove(currentContentionResolutions, item => item === DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION.ELECT_DRIVE_SHIFT_OUT_OF_TIME_BLOCK);
          remove(currentContentionResolutions, item => item === DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION.ELECT_NOT_USE_DRIVE_SHIFT_TIME_BLOCK);

          if(electNotUseTimeBlock) {
            currentContentionResolutions.push(DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION.ELECT_NOT_USE_DRIVE_SHIFT_TIME_BLOCK);
            driveShift.timeBlockId = '';
          }

          if(electOutOfTimeBlock) {
            currentContentionResolutions.push(DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION.ELECT_DRIVE_SHIFT_OUT_OF_TIME_BLOCK);
          }

          driveShift.contentionResolution = currentContentionResolutions.join(';');
        }
      })

      let currentDriveContentions = this.drive.pendingActionReasonCode ? this.drive.pendingActionReasonCode.split(';') : [];
      remove(currentDriveContentions, item => [
        DRIVE_SHIFT_TIME_BLOCK_CONTENTION.OUT_OF_TIME_BLOCK,
        DRIVE_SHIFT_TIME_BLOCK_CONTENTION.FIT_MULTIPLE_TIME_BLOCKS,
        DRIVE_SHIFT_TIME_BLOCK_CONTENTION.MISSING_TIME_BLOCK
      ].includes(item));
      this.drive.pendingActionReasonCodes = currentDriveContentions;
      this.drive.pendingActionReasonCode = currentDriveContentions.join(';');

      return this.drive;
    })
  }

  populateDriveShiftTimeBlocks(driveShift) {
    if(!this.helper.isDriveUseTimeBlock(this.drive, this.masterData)) {
      return;
    }
    
    const availableTimeBlocks = this.helper.findAvailableTimeBlocks({
      driveDate: this.drive.driveDate,
      collectionOperation: this.drive.collectionOperation,
      startTime: driveShift.startTime,
      endTime: driveShift.endTime
    }, this.masterData);
    
    if (availableTimeBlocks.length > 1) {
      return;
    }

    if (availableTimeBlocks.length === 1) {
      driveShift.timeBlockId = availableTimeBlocks[0].timeBlockId;
      driveShift.timeBlock = availableTimeBlocks[0].timeBlock;
    }

    //availableTimeBlocks.length === 0
    const availableCOTimeBlocks = this.helper.findAvailableCOTimeBlocks(this.drive, this.masterData);

    if (availableCOTimeBlocks.length === 1) {
      driveShift.timeBlockId = availableCOTimeBlocks[0].timeBlockId;
      driveShift.timeBlock = availableCOTimeBlocks[0].timeBlock;
    }
  }

  populateShiftTime(driveShift) {
    if (!driveShift.driveDate || !driveShift.startTime || !driveShift.endTime) return;

    let drawHoursStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let drawHoursEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    let drawHoursDuration = (drawHoursEnd.getTime() - drawHoursStart.getTime()) / 60000;

    let minStart = drawHoursStart;
    let maxEnd = drawHoursEnd;
    if (driveShift.jobs && driveShift.jobs.length) {
      driveShift.jobs.forEach((job) => {
        if (job.resourceRole) {
          let leadTime = job.leadTime ? job.leadTime : 0;
          let setupTime = job.setupTime ? job.setupTime : 0;
          let breakdownTime = job.breakdownTime ? job.breakdownTime : 0;
          let wrapUpTime = job.wrapUpTime ? job.wrapUpTime : 0;
          let travelTime = job.travelTime ? job.travelTime : 0;
          let travelTime2 = job.travelTime2 ? job.travelTime2 : 0;
          let siteLogisticsTo = job.siteLogisticsTo ? job.siteLogisticsTo : 0;
          let siteLogisticsBack = job.siteLogisticsBack ? job.siteLogisticsBack : 0;

          let durationBeforeDrawHours = leadTime + setupTime + travelTime + siteLogisticsTo;
          if (driveShift.lunchBreak && driveShift.lunchBreakBeforeDrawHours) {
            durationBeforeDrawHours += driveShift.lunchBreakDuration;
          }
          job.start = new Date(drawHoursStart.getTime() - durationBeforeDrawHours * 60000);
          job.finish = new Date(drawHoursEnd.getTime() + (breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack) * 60000);

          minStart = minStart > job.start ? job.start : minStart;
          maxEnd = maxEnd < job.finish ? job.finish : maxEnd;
          job.duration = durationBeforeDrawHours + drawHoursDuration + breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack;

          this.applyJobTimeToJobAllocations(job);
        }
      });

      driveShift.jobs.forEach((job) => {
        if (job.assetType || job.volunteerRole) {
          job.duration = (maxEnd.getTime() - minStart.getTime()) / 60000;
          job.start = minStart;
          job.finish = maxEnd;

          this.applyJobTimeToJobAllocations(job);
        }
      });
    }

    driveShift.start = minStart.toISOString();
    driveShift.finish = maxEnd.toISOString();
  }

  populateDriveTime() {
    if(!this.drive || !this.drive.driveShifts || !this.drive.driveShifts.length) return;

    let minShiftStart = this.drive.driveShifts[0].start;
    let maxShiftEnd = this.drive.driveShifts[0].finish;

    this.drive.driveShifts.forEach((driveShift) => {
      if(driveShift.start < minShiftStart) {
        minShiftStart = driveShift.start;
      }
      if(driveShift.finish > maxShiftEnd) {
        maxShiftEnd = driveShift.finish;
      }
    });

    this.drive.driveShifts[0].jobs.forEach((job) => {
      if (job.assetType) {
        job.start = minShiftStart;
        job.finish = maxShiftEnd;
        this.correctJobTime(job, this.drive.driveShifts[0]);
      }
    });

    this.drive.maxShiftEnd = maxShiftEnd;
    this.drive.minShiftStart = minShiftStart;
  }

  correctJobTime(job, driveShift) {
    if(job.start && job.finish && job.duration) return;
    if(job.start && job.finish && !job.duration) {
      job.duration = (new Date(job.finish).getTime() - new Date(job.start).getTime()) / 60000;
      return;
    } 

    job.start = driveShift.start
    job.finish = driveShift.finish
    job.duration = (new Date(job.finish).getTime() - new Date(job.start).getTime()) / 60000;
  }

  /** Post Process */
  updateDriveRequestedResources() {
    let totalStaffRequested = 0;
    let totalEquipmentRequested = 0;
    let totalVehicleRequested = 0;
    this.drive.driveShifts.forEach((driveShift) => {
      const jobs = this.helper.getDriveShiftJobs(driveShift, {
        excludeManuallyCreatedFromStaffingModal: true
      })
  
      jobs.forEach((job) => {
        const quantity = job.quantity || 0;
        if (job.resourceRole) {
          totalStaffRequested += quantity;
        }

        if (job.assetType === ASSET_TYPE.EQUIPMENT) {
          totalEquipmentRequested += quantity;
        }

        if (job.assetType === ASSET_TYPE.VEHICLE) {
          totalVehicleRequested += quantity;
        }
      });
    });

    this.drive.totalStaffRequested = totalStaffRequested;
    this.drive.totalEquipmentRequested = totalEquipmentRequested;
    this.drive.totalVehicleRequested = totalVehicleRequested;
  }
  
  updateDriveTotalSlots() {
    let totalSlots = 0;
    this.drive.driveShifts.forEach((item) => {
      item.totalSlots = 0;
      if (item.slots && item.slots.length) {
        totalSlots += item.slots.length;
        item.totalSlots = item.slots.length;
      }
    });
    this.drive.totalSlots = totalSlots;
  }

  calculateDriveProductivityPlanned() {
    if (!this.drive.driveDate || !this.drive.startTime || !this.drive.endTime) return;
    if (!this.drive.driveShifts || !this.drive.driveShifts.length) return;

    let sum = 0;
    this.drive.driveShifts.forEach((driveShift) => {
      let shiftStart = this.helper.newDateTime(this.drive.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
      let shiftEnd = this.helper.newDateTime(this.drive.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
      let drawDuration = (shiftEnd.getTime() - shiftStart.getTime()) / 60000;
      let lunchBreak = 0;
      if (driveShift.lunchBreak && !driveShift.lunchBreakBeforeDrawHours && driveShift.maximumLunchBreakDuration) {
        lunchBreak = driveShift.maximumLunchBreakDuration;
      }

      const jobs = this.helper.getDriveShiftJobs(driveShift, {
        excludeManuallyCreatedFromStaffingModal: true
      })
      jobs.forEach((job) => {
        if (job.resourceRole) {
          let leadTime = job.leadTime ? job.leadTime : 0;
          let setupTime = job.setupTime ? job.setupTime : 0;
          let breakdownTime = job.breakdownTime ? job.breakdownTime : 0;
          let wrapUpTime = job.wrapUpTime ? job.wrapUpTime : 0;
          let travelTime1 = job.travelTime ? job.travelTime : 0;
          let travelTime2 = job.travelTime2 ? job.travelTime2 : 0;
          let siteLogisticsTo = job.siteLogisticsTo ? job.siteLogisticsTo : 0;
          let siteLogisticsBack = job.siteLogisticsBack ? job.siteLogisticsBack : 0;

          sum += job.quantity * (drawDuration - lunchBreak + travelTime1 + siteLogisticsTo + leadTime + setupTime + breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack);
        }
      });
    });
    if (sum > 0) {
      this.drive.driveProductivityPlanned = this.drive.totalProductsProjected / (sum / 60);
      this.drive.driveProductivityPlanned = +(this.drive.driveProductivityPlanned).toFixed(2);
    }
  }

  updateShiftMobileSetup(driveShift) {
    driveShift.staffSetup = 0;
    driveShift.APTSetup = 0;
    driveShift.volunteerSetup = 0;
    driveShift.vehiclesNeeded = 0;
    driveShift.equipment = 0;

    const jobs = this.helper.getDriveShiftJobs(driveShift, {
      excludeManuallyCreatedFromStaffingModal: true
    })
    jobs.forEach((job) => {
      if (job.resourceRole) {
        if (!this.masterData.staffSetupExcludedRoles.some(item => item.resourceRole === job.resourceRole && item.excludedForStaffAllocated)) {
          driveShift.staffSetup += job.quantity;
        }
        driveShift.APTSetup += (job.aptQuantity || 0);
      }

      if (job.volunteerRole) {
        driveShift.volunteerSetup += job.quantity;
      }
      else if (job.assetType == ASSET_TYPE.VEHICLE) {
        driveShift.vehiclesNeeded += job.quantity;
      }
      else if (job.assetType == ASSET_TYPE.EQUIPMENT) {
        driveShift.equipment += job.quantity;
      }
    });
  }

  updateLunchBreakStartEndTime(driveShift, lunchBreakStart, lunchBreakEnd) {
    driveShift.lunchBreakStartTime = this.helper.dateJSToTimeIso(lunchBreakStart, this.masterData.timezoneSidId);
    driveShift.lunchBreakEndTime = this.helper.dateJSToTimeIso(lunchBreakEnd, this.masterData.timezoneSidId);
  }

  /** Drive actions */
  notifyDriveChanged(changedFromApplyingDCRs = false) {
    document.dispatchEvent(new CustomEvent('driveGenerator:driveChanged', {
      detail: {
        drive: this.drive,
        changedFromApplyingDCRs
      }
    }));

    return this.drive;
  }

  holdDrive() {
    this.drive.status = DRIVE_STATUS.HOLD;
    this.drive.routeApprovalRequestTo = null;
    this.drive.pendingAction = null;
    this.drive.approvalStatus = null;

    return this.drive;
  }

  releaseAllAssetAllocations() {
    if(!this.drive || !this.drive.driveShifts || !this.drive.driveShifts.length) return this.drive;
    const vehicleJob = this.drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.VEHICLE);
    const equipmentJob = this.drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.EQUIPMENT);

    compact([vehicleJob, equipmentJob]).forEach(job => {
     let newJobAllocations = [...job.jobAllocations];
     let jobAllocationKeysToRemove = [];
     newJobAllocations.forEach(jobAllocation => {
      if(jobAllocation.id) {
        jobAllocation.status = JOB_ALLOCATION_STATUS.DELETED;
      } else {
        jobAllocationKeysToRemove.push(jobAllocation.key);
      }
     });
     remove(newJobAllocations, jobAllocation => jobAllocationKeysToRemove.includes(jobAllocation.key));

     job.jobAllocations = newJobAllocations;
    });
    
    return this.notifyDriveChanged();
  }

  checkAndApplyDriveChangeRequest() {
    return Promise.resolve()
    .then(() => {
      if(!this.masterData.waitingDriveChangeRequest) return;

      let driveChanges = this.helper.generateDriveChangesFromDCR(this.drive, this.masterData.waitingDriveChangeRequest);
      return this.onDriveDataChanged(driveChanges, {
        skipNotifyDriveChanged : false, 
        changedFromApplyingDCRs : true
      });
    })        
  }

  /** Change handlers */
  resetElectContentions() {
    const backupDrive = this.masterData.backupDrive;
    const currentDrive = this.drive;
    let currentContentionResolutions = currentDrive.contentionResolution ? currentDrive.contentionResolution.split(';') : [];
    remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_DUAL_ROLE_REMOVAL);
    remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_WITHIN_42_DAYS);
    remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE);
    remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT);

    if(backupDrive) {
      //Drive Date changed or CO changed, reset all contention resolution
      if(currentDrive.driveDate !== backupDrive.driveDate || 
        currentDrive.collectionOperationId !== backupDrive.collectionOperationId) {
        currentContentionResolutions = [];

        this.drive.driveShifts?.forEach(driveShift => {
          driveShift.contentionResolution = ''
        })
      }

      //Out of Operational Hours
      if(currentDrive.startTime < backupDrive.startTime || 
        currentDrive.endTime > backupDrive.endTime) {
        remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_OUT_OF_OPERATIONAL_HOURS);
      }

      //Insufficient Resources
      if(currentDrive.totalStaffRequested > backupDrive.totalStaffRequested) {
        remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_INSUFFICIENT_RESOURCES);
      }

      if(
        currentDrive.projectedRegisteredDonors !== backupDrive.projectedRegisteredDonors ||
        currentDrive.staffCapacity !== backupDrive.staffCapacity ||
        currentDrive.maxRoleCapacityWithDrawHours !== backupDrive.maxRoleCapacityWithDrawHours ||
        currentDrive.excessStaffCapacity !== backupDrive.excessStaffCapacity
      ) {
        remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_EXCESS_STAFF_CAPACITY);
      }

      //Lacking of vehicles
      if(currentDrive.totalVehicleRequested > backupDrive.totalVehicleRequested) {
        remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY);
        remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_USE_RENTAL);
      }

      //Part of Linked Drive
      if(
        currentDrive.totalStaffRequested !== backupDrive.totalStaffRequested ||
        currentDrive.totalVehicleRequested !== backupDrive.totalVehicleRequested ||
        currentDrive.totalEquipmentRequested !== backupDrive.totalEquipmentRequested
      ) {
        remove(currentContentionResolutions, item => item === DRIVE_CONTENTION_RESOLUTION.ELECT_PART_OF_LINKED_DRIVE);
      }
    }

    this.drive.contentionResolution = currentContentionResolutions.join(';');
  }

  onDriveDataChanged(properties, {
    skipNotifyDriveChanged = false, 
    changedFromApplyingDCRs = false, 
    isCalledFromDCRProcessingModal = false
  } = {}) {
    this.isRegenerateDriveChange = isCalledFromDCRProcessingModal && properties.filter(record => record.targetName === 'regenerateDrive').length > 0 ;
    
    this.masterData = {
      ...this.masterData,
      skipVolunteerRecalculation: true
    };

    properties.forEach(property => {
      this.drive[property.targetName] = property.targetValue;

      if (property.targetName === 'name') {
        this.drive[property.targetName] = this.helper.truncateDriveName(this.drive[property.targetName]);
      }
      if (property.targetName === 'aptRequired') {
        this.drive[property.targetName] = (/^(true|1)$/i).test(this.drive[property.targetName]);
      }
      if (property.targetName === 'redcrossVolunteerRequired') {
        this.drive[property.targetName] = (/^(true|1)$/i).test(this.drive[property.targetName]);
      }
      if (property.targetName === 'driveShiftsMetadata') {
        this.masterData = extend(this.masterData, {
          skipAPTCalculation: property.targetValue?.skipAptCalculation ?? false,
          skipVolunteerRecalculation: property.targetValue?.skipVolunteerRecalculation ?? true
        });
      }
      if (property.targetName === 'projectedRegisteredDonors') {
        this.masterData.skipVolunteerRecalculation = false;
      }
    })

    let actionGroups = this.mergeFieldChanged(properties, this.DRIVE_FIELD_CHANGE_MAPPING, this.DRIVE_ACTION_GROUPS_ORDER);
    return this.runActions(actionGroups)
      .then(() => {
        this.resetElectContentions();

        if (!skipNotifyDriveChanged) {
          return this.notifyDriveChanged(changedFromApplyingDCRs);
        }
      })
  }

  onDriveShiftDataChanged(shiftKey, properties) {
    let driveShift = this.drive.driveShifts.find((e) => e.key === shiftKey);
    if (!driveShift) return;

    this.masterData = {
      ...this.masterData,
      skipVolunteerRecalculation: true
    };

    properties.forEach(property => {
      driveShift[property.targetName] = property.targetValue;
      if (property.targetName === 'APTSetup') {
        this.masterData.skipAPTCalculation = true;
      }

      const relevantTargets = ['projectedRegisteredDonors', 'redcrossVolunteerRequired'];
      if (relevantTargets.includes(property.targetName)) {
        this.masterData.skipVolunteerRecalculation = false;
      }
    })

    let actionGroups = this.mergeFieldChanged(properties, this.DRIVE_SHIFT_FIELD_CHANGE_MAPPING);
    return this.runActions(actionGroups, driveShift)
      .then(() => {
        return this.notifyDriveChanged();
      })
  }

  /** Drive Delivery Job actions */
  saveDriveDeliveryJob(driveDeliveryJob) {
    if (!driveDeliveryJob) return;

    let newList = this.drive.driveDeliveryJobs ? [...this.drive.driveDeliveryJobs] : [];
    let target = driveDeliveryJob;
    const index = newList.findIndex((item) => item.key === target.key);
    if (index == -1) {
      newList.push(target);
    }
    else {
      newList[index] = target;
    }
    this.drive.driveDeliveryJobs = newList;

    return this.notifyDriveChanged();
  }

  deleteDriveDeliveryJob(driveDeliveryJob) {
    if (!driveDeliveryJob) return;

    let newList = [...this.drive.driveDeliveryJobs];
    let target = driveDeliveryJob;
    const index = newList.findIndex((item) => item.key === target.key);
    newList.splice(index, 1);
    this.drive.driveDeliveryJobs = newList;

    return this.notifyDriveChanged();
  }

  /** Job actions */
  saveJobDualRole(shiftKey, jobsToCreate = [], jobsToUpdate = [], jobsToDelete = []) {
    if (!shiftKey || (!jobsToCreate.length && !jobsToUpdate.length && !jobsToDelete.length)) return;
    let shift = this.drive.driveShifts.find((e) => e.key == shiftKey);
    let newList = [...shift.jobs];

    const jobsChangedKeys = [];
    jobsToDelete.forEach(({previousJob}) => {
      const jobIndex = newList.findIndex((item) => item.key === previousJob.key);
      if(jobIndex !== -1) {
        newList.splice(jobIndex, 1);
      }
    })

    jobsToUpdate.forEach(({previousJob, newJob}) => {
      const jobIndex = newList.findIndex((item) => item.key === previousJob.key);
      if(jobIndex !== -1) {
        newList[jobIndex] = {
          ...newList[jobIndex],
          ...newJob
        }
        jobsChangedKeys.push(newList[jobIndex].key)
      }
    })

    jobsToCreate.forEach(({newJob}) => { 
      newList.push(newJob);
      jobsChangedKeys.push(newJob.key)
    })

    shift.jobs = newList;
    shift.jobs.forEach(job => {
      if(jobsChangedKeys.includes(job.key)) {
        this.applyRoleTimeForSingleJob(shift, job);
        this.onJobChanged(shift, job);   
      }
    });

    return this.notifyDriveChanged();
  }

  saveJob(shiftKey, job) {
    if (!shiftKey || !job) return;

    let shift = this.drive.driveShifts.find((e) => e.key == shiftKey);
    let newList = this.helper.getDriveShiftJobs(shift, {
      excludeManuallyCreatedFromStaffingModal: true
    });
    let target = job;
    let jobsToBeGenerated = [];
    let backupDriveShift = this.masterData.backupDriveShiftMap[shiftKey];
    const isDualRoleModified = target.isDualRoleModified || target.reducedDualRoleQuantity;

    const prepareMap = (jobs) => {
      if(!jobs) return {};
      let resourceQuantityMap = new Map();

      jobs.forEach(job => {
        resourceQuantityMap.set(this.helper.generateJobKey(job), job.quantity || 0);
      });
      return resourceQuantityMap;
    }

    //Run this block only if dual role is changed
    if(isDualRoleModified) {
      const primaryRoleJobIndex = newList.findIndex((item) => 
        item.resourceRole && 
        item.resourceRole === target.resourceRole && 
        item.dualRole &&
        item.key === target.key
      );
      if(primaryRoleJobIndex === -1) return;

      if(target.dualRole === 'None') {
        target.dualRole = '';

        const dualRoleJobIndex = newList.findIndex((item) => item.resourceRole && item.resourceRole === target.dualRole);
        if(dualRoleJobIndex !== -1) {
          newList.splice(dualRoleJobIndex, 1);
        }

        const backupDualRoleJob = 
        backupDriveShift.jobs?.find(
          (item) =>
            item.key === target.key &&
            item.resourceRole &&
            item.resourceRole === target.resourceRole &&
            item.dualRole
        );
    
        jobsToBeGenerated.push({
          ...backupDualRoleJob,
           quantity: (prepareMap(newList)?.get(backupDualRoleJob.dualRole) || 0) + target.quantity
        }); //will use the dual role as the primary role for the new job

        const otherPrimaryRoleJobIndexes = newList
          .map((item, index) =>
            item.resourceRole === target.resourceRole &&
            !item.dualRole &&
            !item.isManuallyCreated &&
            item.key !== target.key
              ? index
              : -1
          )
          .filter((index) => index !== -1);

        let totalQuantity = 0;
        if(otherPrimaryRoleJobIndexes.length > 0) {
          totalQuantity = otherPrimaryRoleJobIndexes.reduce(
            (sum, index) => sum + (newList[index].quantity || 0),
            0
          );
          target.quantity += totalQuantity;

          for (let i = 0; i < otherPrimaryRoleJobIndexes.length; i++) {
            newList.splice(otherPrimaryRoleJobIndexes[i], 1); 
          }
        }
      } else if (target.reducedDualRoleQuantity) {
        const backupDualRoleJob = 
        backupDriveShift.jobs?.find(
          (item) =>
            item.key === target.key &&
            item.resourceRole &&
            item.resourceRole === target.resourceRole &&
            item.dualRole
        );

        jobsToBeGenerated.push({
          ...backupDualRoleJob,
          dualRole: target.resourceRole,
          quantity: (prepareMap(newList)?.get(backupDualRoleJob.resourceRole) || 0) + target.reducedDualRoleQuantity
        });

        jobsToBeGenerated.push({
          ...backupDualRoleJob,
          quantity: (prepareMap(newList)?.get(backupDualRoleJob.dualRole) || 0) + target.reducedDualRoleQuantity
        });
      } else {
        const dualRoleJobIndex = newList.findIndex((item) => item.resourceRole && item.resourceRole === target.dualRole);
        if(dualRoleJobIndex !== -1) {
          const dualRoleAsPrimaryRoleJob = newList[dualRoleJobIndex];
          if(dualRoleAsPrimaryRoleJob?.quantity <= target.quantity) newList.splice(dualRoleJobIndex, 1);
          else {
            jobsToBeGenerated.push({
              ...dualRoleAsPrimaryRoleJob,
              dualRole: dualRoleAsPrimaryRoleJob.resourceRole,
              quantity: dualRoleAsPrimaryRoleJob?.quantity - target.quantity
            });
          }
        }
          
        const backupDualRoleJob = 
        backupDriveShift.jobs?.find(
          (item) =>
            item.key === target.key &&
            item.resourceRole &&
            item.resourceRole === target.resourceRole &&
            item.dualRole
        );
  
        jobsToBeGenerated.push({
          dualRole: backupDualRoleJob.dualRole,
          quantity: (prepareMap(newList)?.get(backupDualRoleJob.dualRole) || 0) + target.quantity
        });
      }
    }

    target.tagNames = '';
    if (target.jobTags && target.jobTags.length) {

      let tagNameArr = job.jobTags.reduce((result, item) => {
        return result.concat(item.tag.name);
      }, []);
      target.tagNames = orderBy(tagNameArr, [item => item], ['asc']).join(", ");
    }

    const index = newList.findIndex((item) => item.key === target.key);
    let originalJob = null;
    if (index == -1) {
      newList.push(target);
    }
    else {
      originalJob = cloneDeep(newList[index]);
      newList[index] = target;
    }
    shift.jobs = newList;

    if(jobsToBeGenerated.length) {
      jobsToBeGenerated.forEach(job => {
        this.repopulateJobsAfterDualRoleModification(shift, job);
      })
    }

    this.onJobChanged(shift, job, originalJob);

    return this.notifyDriveChanged();
  }

  deleteJob(shiftKey, job) {
    if (!shiftKey || !job) return;
    let shift = this.drive.driveShifts.find((e) => e.key == shiftKey);
    let newList = [...shift.jobs];
    let target = job;
    const index = newList.findIndex((item) => item.key === target.key);
    newList.splice(index, 1);
    shift.jobs = newList;

    this.onJobChanged(shift, { ...job, isDeleted: true });

    return this.notifyDriveChanged();
  }

  /** Drive Shift Tags actions */
  saveDriveShiftTag(shiftKey, driveShiftTag) {
    if (!shiftKey || !driveShiftTag) return;

    let shift = this.drive.driveShifts.find((e) => e.key == shiftKey);
    let newList = [...shift.driveShiftTags];
    let target = driveShiftTag;

    const index = newList.findIndex((item) => item.key === target.key);
    if (index == -1) {
      newList.push(target);
    }
    else {
      newList[index] = target;
    }
    shift.driveShiftTags = newList;

    return this.notifyDriveChanged();
  }

  deleteDriveShiftTag(shiftKey, driveShiftTag) {
    if (!shiftKey || !driveShiftTag) return;
    let shift = this.drive.driveShifts.find((e) => e.key == shiftKey);
    let newList = [...shift.driveShiftTags];
    let target = driveShiftTag;
    const index = newList.findIndex((item) => item.key === target.key);
    newList.splice(index, 1);
    shift.driveShiftTags = newList;

    return this.notifyDriveChanged();
  }

  /** Slot actions */
  generateSlotsByNumberOfAssets(driveShift, configuration) {
    let slots = [];
    let numberOfGroups = configuration.numberOfGroups;
    let roundInterval = configuration.roundInterval;
    let groupInterval = configuration.groupInterval;
    let firstSlotStart = configuration.firstSlotStart;
    let lastSlotStart = configuration.lastSlotStart;
    let numberOfAssets = configuration.numberOfAssets || 0;
    let excludedTimeRanges = configuration.excludedTimeRanges || [];
    let slotType = configuration.slotType;
    let slotDuration = configuration.slotDuration;

    let slotTemplate = {
      name: slotType,
      locked: false,
      slotType: slotType,
      status: "Open"
    }

    let tempStart = firstSlotStart;
    while (tempStart <= lastSlotStart) {
      let remainingNumberOfAssets = numberOfAssets;
      for (let i = 0; i < numberOfGroups; i++) {
        let groupQuantity = Math.ceil(remainingNumberOfAssets / (numberOfGroups - i));
        if (groupQuantity > remainingNumberOfAssets) {
          groupQuantity = remainingNumberOfAssets;
        }

        let slotStartTime = new Date(tempStart.getTime() + (i * groupInterval * 60000));
        let slotEndTime = new Date(slotStartTime.getTime() + slotDuration * 60000);

        if (slotStartTime <= lastSlotStart && !this.isTimeExcluded(slotStartTime.toISOString(), excludedTimeRanges)) {
          slots = slots.concat(this.multiplySlots(driveShift, {
            ...slotTemplate,
            key: generateUUID(),
            startTime: slotStartTime.toISOString(),
            endTime: slotEndTime.toISOString(),
          }, groupQuantity));
        }

        remainingNumberOfAssets = remainingNumberOfAssets - groupQuantity;
      }

      tempStart = new Date(tempStart.getTime() + roundInterval * 60000); //next round
    }

    return slots;
  }

  multiplySlots(driveShift, originalSlot, quantity) {
    let slots = [];
    for (let i = 0; i < quantity; i++) {
      slots.push({
        ...originalSlot,
        key: generateUUID()
      })
    }
    return slots;
  }

  isTimeExcluded(timeValue, excludedTimeRanges = []) {
    return excludedTimeRanges.find(timeRange => {
      return timeRange.start.toISOString() <= timeValue && timeValue < timeRange.end.toISOString();
    });
  }

  generate2rbcSlots(driveShift, excludedTimeRanges = []) {
    let numberOf2rbcAssets = this.drive.numberOf2rbcAssets || 0;
    if (!numberOf2rbcAssets) return [];

    let driveShiftStart = this.helper.newDateTime(driveShift.driveDate, driveShift.startTime, this.masterData.timezoneSidId);
    let driveShiftEnd = this.helper.newDateTime(driveShift.driveDate, driveShift.endTime, this.masterData.timezoneSidId);
    let driveShiftIndex = this.drive.driveShifts.findIndex(item => item.key === driveShift.key);
    let firstSlotStart, lastSlotStart;
    lastSlotStart = new Date(driveShiftEnd.getTime() - 30 * 60000); //30 minutes before Drive Shift End
    // if (driveShiftIndex === 0) {
    //   //first shift
    //   firstSlotStart = new Date(driveShiftStart.getTime() + 60 * 60000); //60 minutes after Drive Shift Start
    // } else {
    //   firstSlotStart = driveShiftStart;
    // }
    firstSlotStart = driveShiftStart;

    
    return this.generateSlotsByNumberOfAssets(driveShift, {
      roundInterval: 60,
      numberOfGroups: 2,
      groupInterval: 30,
      slotType: '2RBC',
      slotDuration: 60,
      firstSlotStart: firstSlotStart,
      lastSlotStart: lastSlotStart,
      numberOfAssets: numberOf2rbcAssets,
      excludedTimeRanges: excludedTimeRanges
    })
  }

  resetSlots(shiftKey) {
    const driveShiftKey = shiftKey;
    const driveShift = this.drive.driveShifts.find(item => item.key === driveShiftKey);
    const backupDriveShift = this.masterData.backupDriveShiftMap[driveShiftKey];
    if (!driveShift) return;

    if (!backupDriveShift) {
      //should not happen
    } else {
      driveShift.slots = cloneDeep(backupDriveShift.slots) || [];
      this.updateDriveTotalSlots();
    }

    this.mapSlotRecurrenceDates = {};
    return this.notifyDriveChanged();
  }

  regenerateSlots(shiftKey) {
    const driveShiftKey = shiftKey;
    const driveShift = this.drive.driveShifts.find(item => item.key === driveShiftKey);
    this.generateShiftSlots(driveShift);
    this.updateDriveTotalSlots();

    this.mapSlotRecurrenceDates = {};
    return this.notifyDriveChanged();
  }
  
  saveSlot(shiftKey, slot, action) {
    if (!shiftKey || !slot) return;

    const driveShiftKey = shiftKey;
    const driveShiftIndex = this.drive.driveShifts.findIndex(item => item.key === driveShiftKey);
    const driveShift = this.drive.driveShifts[driveShiftIndex];
    if (!driveShift) return;

    const isEditSlot = driveShift.slots.find(item => item.key === slot.key);
    if (isEditSlot) {
      const slotKeys = slot.selectedSlotKeys?.length ? slot.selectedSlotKeys : [slot.key];
      slotKeys.forEach(slotKey => {
        let tempSlot = driveShift.slots.find(item => item.key === slotKey);
        let originalSlot = null;
        if(tempSlot.id) {
          originalSlot = cloneDeep(tempSlot);
        }

        //edit
        let updatedSlot = slot;
        if(action === 'unlock') {
          updatedSlot = pick(slot, [
            'locked',
            'fixedSiteLockReason',
            'fixedSiteLockComment',
            'selected',
            'recurrenceDates',
            'recurrenceDriveIds'
          ])
        }

        tempSlot = extend(tempSlot, omit(updatedSlot, ['id', 'key']));    

        this.mapSlotRecurrenceDates[tempSlot.key] = {
          action: tempSlot.id ? 'update' : 'create',
          originalSlot: originalSlot,
          slot: tempSlot,
          driveShiftIndex: driveShiftIndex,
          recurrenceDates: tempSlot.recurrenceDates || [],
          recurrenceDriveIds: tempSlot.recurrenceDriveIds || []
        };
      })
    } else {
      //create
      let tempSlotTemplate = {
        ...{
          status: "Open"
        }, ...slot
      }

      const slotDuration = this.helper.getSlotDurationByType(tempSlotTemplate.slotType);
      tempSlotTemplate.name = tempSlotTemplate.slotType;
      tempSlotTemplate.endTime = new Date(new Date(tempSlotTemplate.startTime).getTime() + slotDuration * 60000).toISOString();

      if(tempSlotTemplate.quantity > 0) {
        Array.from(Array(tempSlotTemplate.quantity), (item, index) => {
          let tempSlot = {
            ...tempSlotTemplate,
            key: generateUUID(),
          }
          delete tempSlot.quantity;

          driveShift.slots.push(tempSlot);

          this.mapSlotRecurrenceDates[tempSlot.key] = {
            action: 'create',
            originalSlot: null,
            slot: tempSlot,
            driveShiftIndex: driveShiftIndex,
            recurrenceDates: tempSlot.recurrenceDates || [],
            recurrenceDriveIds: tempSlot.recurrenceDriveIds || []
          };
        });
      }
    }

    driveShift.slots = [...driveShift.slots];
    this.updateDriveTotalSlots();

    return this.notifyDriveChanged();
  }

  deleteSlot(shiftKey, slot) {
    if (!shiftKey || !slot) return;

    const driveShiftKey = shiftKey;
    const driveShift = this.drive.driveShifts.find(item => item.key === driveShiftKey);
    if (!driveShift) return;

    const slotKeys = slot.selectedSlotKeys?.length ? slot.selectedSlotKeys : [slot.key];
    slotKeys.forEach(slotKey => {
      const [deletedSlot] = remove(driveShift.slots, item => item.key === slotKey);

      driveShift.slots = [...driveShift.slots];
      this.updateDriveTotalSlots();

      if(deletedSlot?.id) {
        this.mapSlotRecurrenceDates[deletedSlot.key] = {
          action: 'delete',
          slot: deletedSlot,
          recurrenceDates: slot.recurrenceDates || [],
          recurrenceDriveIds: slot.recurrenceDriveIds || []
        };
      } else {
        delete this.mapSlotRecurrenceDates[deletedSlot.key];
      }
    })
    
    return this.notifyDriveChanged();
  }

  calculateRecurrenceSlots(drive) {
    const slotsEqual = (slot1, slot2) => {
      if(slot1._appliedRecurrenceData) return false;
      if(slot1.slotType !== slot2.slotType) return false;
      const startTime1 = DateTime.fromISO(slot1.startTime, { zone: slot1.timezoneSidId}).toFormat('HH:mm');
      const startTime2 = DateTime.fromISO(slot2.startTime, { zone: slot2.timezoneSidId}).toFormat('HH:mm');
      return startTime1 === startTime2;
    }

    const mapSlotRecurrenceDates = this.mapSlotRecurrenceDates || {};
    let mapCurrentDrives = {};

    const recurrenceDates = Object.values(mapSlotRecurrenceDates).reduce((accumulative, current) => {
      return [...accumulative, ...current.recurrenceDates];
    }, []);
    const recurrenceDriveIds = Object.values(mapSlotRecurrenceDates).reduce((accumulative, current) => {
      return [...accumulative, ...current.recurrenceDriveIds];
    }, []);
    const today = DateTime.fromObject({
      zone: this.masterData.timezoneSidId
    }).toISODate();

    const validRecurrenceDates = uniq(recurrenceDates).filter(dateIso => dateIso >= today);
    if(!validRecurrenceDates.length) {
      return Promise.resolve([]);
    }

    return Promise.resolve()
      .then(() => {
        const driveQuery = new driveQueryModel();
        driveQuery.recordIds = recurrenceDriveIds;
        driveQuery.selectedDates = validRecurrenceDates;
        driveQuery.eventTypes = [DRIVE_TYPE.FIXED_SITE];
        driveQuery.operationTypes = [OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH, OPERATION_TYPE.NON_INTEGRATED_WB];
        driveQuery.collectionOpIds = [drive.collectionOperationId];
        driveQuery.locationIds = [drive.driveSiteId];
        driveQuery.statuses = [
          DRIVE_STATUS.SYSTEM_GENERATED,
          DRIVE_STATUS.TENTATIVE,
          DRIVE_STATUS.CONFIRMED,
          DRIVE_STATUS.HOLD
        ];
        driveQuery.excludedIds = [this.drive.id];
        driveQuery.isNotLinkedDrive = true;
        driveQuery.subQueryIndicator = sObjectType.DRIVE_SHIFT;

        const driveSvc = new driveService();

        return driveSvc.query(driveQuery);
      })
      .then((drives) => {
        const driveIds = drives.map((drive) => drive.id);

        const slotQuery = new slotQueryModel();
        slotQuery.driveIds = driveIds;

        const slotSvc = new slotService();

        return Promise.all([slotSvc.query(slotQuery), drives]);
      })
      .then(([slots, drives]) => {
        const mapSlotsByDriveId = groupBy(slots, 'driveId');
        const mapDrivesByDate = groupBy(drives, 'driveDate');
        mapCurrentDrives = Object.keys(mapDrivesByDate).reduce((accumulate, driveDate) => {
          const drives = mapDrivesByDate[driveDate];

          accumulate[driveDate] = drives.map((drive) => {
            const driveSlots = mapSlotsByDriveId[drive.id] || [];
            return {
              ...drive,
              slots: driveSlots,
            }
          });

          return accumulate;
        }, {});

        let mapDrivesToSave = {};
        orderBy(Object.keys(this.mapSlotRecurrenceDates), [slotKey => {
          const { action } = this.mapSlotRecurrenceDates[slotKey];
          if(action === 'delete') return 0;
          if(action === 'create') return 1;
          if(action === 'update') return 2;
          return 3;
        }], ['asc']).forEach(slotKey => {
          const { action, originalSlot, slot, recurrenceDates, driveShiftIndex } = this.mapSlotRecurrenceDates[slotKey];
          
          recurrenceDates.forEach(dateIso => {
            const currentDrives = mapCurrentDrives[dateIso];
            if(currentDrives?.length) {
              currentDrives.forEach(currentDrive => {
                if(!mapDrivesToSave[currentDrive.id]) {
                  mapDrivesToSave[currentDrive.id] = {
                    id: currentDrive.id,
                    slots: currentDrive.slots || [],
                    slotsToSave: [],
                    slotsToDelete: [],
                    totalSlots: currentDrive.totalSlots || 0,
                  }
                }
              });
            }
          });

          if(action === 'delete') {
            recurrenceDates.forEach(dateIso => {
              const currentDrives = mapCurrentDrives[dateIso];
              if(currentDrives?.length) {
                currentDrives.forEach(currentDrive => {
                  const slotToDeleteIndex = mapDrivesToSave[currentDrive.id].slots.findIndex(currentSlot => slotsEqual({
                    ...currentSlot, 
                    timezoneSidId: currentDrive.timezone
                  }, {
                    ...slot,
                    timezoneSidId: this.masterData.timezoneSidId
                  }));
                  const slotToDelete = mapDrivesToSave[currentDrive.id].slots[slotToDeleteIndex];

                  if(slotToDelete) {
                    mapDrivesToSave[currentDrive.id].slotsToDelete.push(slotToDelete);
                    mapDrivesToSave[currentDrive.id].slots.splice(slotToDeleteIndex, 1);
                    mapDrivesToSave[currentDrive.id].totalSlots = mapDrivesToSave[currentDrive.id].slots.length;
                  }
                });
              }
            });
          } else if (action === 'create') {
            recurrenceDates.forEach(dateIso => {
              const currentDrives = mapCurrentDrives[dateIso];
              if(currentDrives?.length) {
                currentDrives.forEach(currentDrive => {
                  const currentDriveShiftId = (currentDrive.driveShifts || [])[driveShiftIndex]?.id;
                  if(currentDriveShiftId) {
                    const newStartTime = this.helper.newDateTime(currentDrive.driveDate, slot._startTime, currentDrive.timezone);
                    const slotDuration = this.helper.getSlotDurationByType(slot.slotType);
                    const newSlot = {
                      ...slot,
                      startTime: newStartTime, 
                      endTime: new Date(new Date(newStartTime).getTime() + slotDuration * 60000).toISOString(),
                      id: undefined,
                      driveId: currentDrive.id,
                      driveShiftId: currentDriveShiftId
                    };
                    mapDrivesToSave[currentDrive.id].slotsToSave.push(newSlot);
                    mapDrivesToSave[currentDrive.id].slots.push(newSlot);
                    mapDrivesToSave[currentDrive.id].totalSlots = mapDrivesToSave[currentDrive.id].slots.length;
                  }
                })
              }
            });
          } else if (action === 'update') {
            recurrenceDates.forEach(dateIso => {
              const currentDrives = mapCurrentDrives[dateIso];
              if(currentDrives?.length) {
                currentDrives.forEach(currentDrive => {
                  const slotToUpdate = mapDrivesToSave[currentDrive.id].slots.find(currentSlot => slotsEqual({
                    ...currentSlot, 
                    timezoneSidId: currentDrive.timezone
                  }, {
                    ...originalSlot,
                    timezoneSidId: this.masterData.timezoneSidId
                  }));

                  if(slotToUpdate) {
                    const slotDuration = this.helper.getSlotDurationByType(slotToUpdate.slotType);
                    const newStartTime = this.helper.newDateTime(currentDrive.driveDate, slot._startTime, currentDrive.timezone);
                    mapDrivesToSave[currentDrive.id].slotsToSave.push({
                      ...slotToUpdate,
                      startTime: newStartTime,
                      endTime: new Date(new Date(newStartTime).getTime() + slotDuration * 60000).toISOString(),
                      locked: slot.locked,
                      fixedSiteLockReason: slot.fixedSiteLockReason,
                      fixedSiteLockComment: slot.fixedSiteLockComment,
                      label: slot.label
                    });

                    slotToUpdate._appliedRecurrenceData = true;
                  }
                })
              }
            });
          }
        }); 

        return Object.values(mapDrivesToSave);
      })
      .catch((error) => {
        console.log('>>> calculateRecurrenceSlots', error);
        return [];
      })
  }

  restoreJobsQuantity(backupDrive) {
    if(!backupDrive) return ;

    const driveShiftsMetadata = this.drive.driveShiftsMetadata;
    this.drive.driveShifts?.forEach((driveShift, driveShiftIndex) => {
      const driveShiftMetadata =  driveShiftsMetadata?.driveShifts?.[driveShiftIndex];
      let resourceQuantityMap = this.mapResourceQuantity.get(driveShiftMetadata?.key);
      if(!resourceQuantityMap) return;

      driveShift.jobs?.forEach(job => {
        const jobKey = this.helper.generateJobKey(job);
        const isSystemGeneratedResourceRole = this.helper.isSystemRole(job, this.drive) && job.resourceRole && !job.dualRole;
        if(!isSystemGeneratedResourceRole) return;

        const isDriverJob = this.helper.isDriverJob(job) || this.helper.isDriverSupport(job);
        if(isDriverJob) return;

        const backupDriveShift = backupDrive.driveShifts?.[driveShiftIndex];
        if(!backupDriveShift) {
          return;
        }

        const backupJob = backupDriveShift.jobs?.find(_job => {
          const sameRole = this.helper.isJobsSameRoles(_job, job);
          return sameRole;
        })

        if(!backupJob) return;
        
        if(jobKey === 'VP/HH') {
          resourceQuantityMap.set(jobKey, {
            ...(resourceQuantityMap.get(jobKey) ?? {}),
            quantity: backupJob.quantity,
            vphhQuantity: backupJob.vphhQuantity,
            aptQuantity: backupJob.aptQuantity,
            systemQuantity: backupJob.systemQuantity,
          })
        } else {
          resourceQuantityMap.set(jobKey, {
            ...(resourceQuantityMap.get(jobKey) ?? {}),
            quantity: backupJob.quantity,
            systemQuantity: backupJob.systemQuantity,
          })
        }
      }); 
    })
  }
  
  /** Utils */
  mergeFieldChanged(properties, fieldMapping, actionGroupsOrder) {
    let actionGroups = [];
    properties.forEach((property) => {
      if (fieldMapping[property.targetName]) {
        let fieldActionGroups = fieldMapping[property.targetName].groups;
        for (let i = 0; i < fieldActionGroups.length; i++) {
          let fieldActionGroup = fieldActionGroups[i];
          if (i == actionGroups.length) {
            let actionGroup = {
              actions: []
            };
            actionGroup.actions = [...fieldActionGroup.actions];
            actionGroups.push(actionGroup);
          }
          else {
            let actionGroup = actionGroups[i];
            (fieldActionGroup.actions || []).forEach((action) => {
              if (actionGroup.actions.indexOf(action) == -1) {
                actionGroup.actions.push(action);
              }
            });
          }
        }
      }
    });

    if (actionGroupsOrder) {
      actionGroups.forEach((actionGroup, actionGroupIndex) => {
        let actionsOrder = actionGroupsOrder[actionGroupIndex];
        if (!actionsOrder) return;
        actionGroup.actions = orderBy(actionGroup.actions, [(action) => {
          let order = actionsOrder.indexOf(action);
          return order > -1 ? order : Number.MAX_VALUE;
        }], ['asc']);
      })
    }

    return actionGroups;
  }

  runActions(actionGroups, params) {
    let groupPromises = actionGroups.map((actionGroup) => {
      return () => {
        let promises = [];
        actionGroup.actions.forEach((action) => {
          if (typeof action === 'function') {
            promises.push(action(this, params));
          } else {
            if (this[action]) {
              promises.push(this[action](params));
            }
          }
        })
        return Promise.all(promises);
      }
    });

    if (!groupPromises.length) {
      return Promise.resolve();
    }
    return serial(groupPromises)
  }
}

export {
  BaseGenerator
}