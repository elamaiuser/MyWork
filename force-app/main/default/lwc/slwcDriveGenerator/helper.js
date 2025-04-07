import { get, cloneDeep, orderBy, isEqual, sum, compact, uniqBy, isObject, isDate, max, uniqueId } from 'c/lodash';
import { LINK_DRIVE_TYPE, RESOURCE_TYPE, MANUALLY_CREATED_FROM, DRIVE_CHANGE_REQUEST_TYPE , ASSET_TYPE, PROCEDURE_TYPE, DRIVE_TYPE, OPERATION_TYPE, RESOURCE_ROLE_GROUP, PENDING_ACTION, DRIVE_STATUS, RESOURCE_ROLE, DRIVE_CHANGE_REQUEST_ITEM_TYPE, DRIVE_CONTENTION, DRIVE_CONTENTION_RESOLUTION, JOB_ALLOCATION_STATUS, DRIVE_APPROVAL_STATUS, OPERATION_DRIVE_LIMIT_TYPE, DRIVE_REQUEST_CHANGE_STATUS, SKIP_BEST_VEHICLE_CALCULATION} from 'c/slwcConstants';
import { DateTime } from 'c/luxon';
import { isNullOrEmpty, parseJSON, getTravelTimeIndexKey, generateUUID } from 'c/slwcUtils';
import { territoryCollectionOperationQueryModel, territoryCollectionOperationService } from 'c/dataService';
import * as autoMapper from 'c/autoMapper';
import * as slwcAvailator from 'c/slwcAvailator';

class DriveHelper {
  isMobileDrive(drive) {
    return drive && drive.typeOfDrive === DRIVE_TYPE.MOBILE;
  }
  isFixedSiteDrive(drive) {
    return drive && drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE && drive.operationType !== OPERATION_TYPE.NON_INTEGRATED_WB;
  }
  isWbFixedSiteDrive(drive) {
    return drive && drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE && drive.operationType === OPERATION_TYPE.NON_INTEGRATED_WB;
  }
  showPlateletField(drive) {
    return this.isFixedSiteDrive(drive);
  }
  showPlasmaField(drive) {
    return this.isFixedSiteDrive(drive);
  }
  showWBField(drive) {
    return !this.isFixedSiteDrive(drive) || drive.operationType === OPERATION_TYPE.INTEGRATED;
  }
  x2rbcEnabled(drive) {
    return drive && drive.account && drive.account.acceptsAutomation == "Yes";
  }
  show2RBCField(drive) {
    if (!this.x2rbcEnabled(drive)) return false;

    return !this.isFixedSiteDrive(drive) || drive.operationType === OPERATION_TYPE.INTEGRATED;
  }

  isAdminUser(loginUser) {
    return loginUser && loginUser.profileName &&
      (loginUser.profileName.startsWith('System Administrator') || loginUser.profileName.startsWith('Global Admin'));
  }

  isAPSUser(loginUser) {
    if(this.isAdminUser(loginUser)) return true;

    return loginUser && loginUser.profileName &&
      (loginUser.profileName.startsWith('APS'));
  }

  isOnlyAPSUser(loginUser) {
    return loginUser && loginUser.profileName && loginUser.profileName.startsWith('APS');
  }

  isAPSAdmin(loginUser) {
    return loginUser && loginUser.profileName && loginUser.profileName.startsWith('APS Admin');
  }

  isAPSManagement(loginUser) {
    return loginUser && loginUser.profileName && loginUser.profileName.startsWith('APS Management');
  }

  isCollectionManagentUser(loginUser) {
    return loginUser && loginUser.profileName && loginUser.profileName.startsWith('Collection Management');
  }

  isDRDUser(loginUser) {
    return loginUser && loginUser.profileName &&
      (loginUser.profileName.toLowerCase().startsWith('drd'));
  }

  isManufacturingUser(loginUser) {
    return loginUser && loginUser.profileName &&
      (loginUser.profileName.toLowerCase().startsWith('manufacturing'));
  }

  isTelerecuiterUser(loginUser) {
    return loginUser && loginUser.profileName &&
      (loginUser.profileName.toLowerCase().startsWith('telerecruiter'));
  }

  isDriveSkipLastAppointment(drive) {
    if(!drive || !drive.collectionOperation) return false;
    return drive.collectionOperation.skipLastAppointmentFor && drive.collectionOperation.skipLastAppointmentFor.includes(drive.typeOfDrive);
  }

  initiateNewDriveFromOpty(opp) {
    let drive = autoMapper.autoMapperInstance.initiateModel('sked_Drive__c');
    for (let prop in opp) {
      if (prop == "id") {
        continue;
      }
      if (prop == "name") {
        drive.name = this.truncateDriveName(opp.name);
      } else if (prop == "anticipatedRegisteredDonors") {
        drive.projectedRegisteredDonors = opp.anticipatedRegisteredDonors;
      } else if (prop === 'accountManagerId') {
        drive.driveOwnerId = opp.accountManagerId;
        drive.driveOwner = opp.accountManager;
      } else if (prop === 'aptRequired') {
        drive.aptRequired = opp.aptRequired;
      } else if (prop === 'aptQuantity') {
        drive.aptQuantity = opp.aptQuantity;
      } else if (prop === 'anticipatedRegisteredDonorsTemplate') {
        drive.historicalRegisteredDonors = opp.anticipatedRegisteredDonorsTemplate;
      } else {
        drive[prop] = opp[prop];
      }
    }
    if (opp.opportunityContactRoles && opp.opportunityContactRoles.length) {
      let primaryContactRole = opp.opportunityContactRoles.find(x => x.role === 'Primary Contact');
      if (primaryContactRole) {
        drive.primaryContactId = primaryContactRole.contactId;
      }
    }

    drive.opportunity = opp;
    drive.opportunityId = opp.id;
    drive.status = DRIVE_STATUS.DRAFT;
    drive.preferSystemGeneratedVehicles = true;
    if(this.isFixedSiteDrive(drive)) {
      drive.status = DRIVE_STATUS.TENTATIVE;
    }
    return drive;
  }

  populateSiteCollectionOperation(drive) {
    if (!drive) return;
    if (!drive.siteCollectionOperationId) return;
    let siteCollectionOperation = (drive.driveSite.siteCollectionOperations || []).find(item => {
      return item.id === drive.siteCollectionOperationId;
    })

    if(siteCollectionOperation) {
      drive.siteCollectionOperationId = siteCollectionOperation.id;
      drive.siteCollectionOperation = siteCollectionOperation;
      drive.collectionOperation = siteCollectionOperation.collectionOperation;
      drive.collectionOperationId = siteCollectionOperation.collectionOperationId;
    } else {
      drive.siteCollectionOperationId = null;
      drive.siteCollectionOperation = null;
      drive.collectionOperation = null;
      drive.collectionOperationId = null;
    }
  }

  populateDriveCollectionOperation(drive) {
    if (!drive) return;
    if (!drive.driveSite) return;
    let siteCollectionOperation = (drive.driveSite.siteCollectionOperations || []).find(item => {
      return item.startDate <= drive.driveDate && drive.driveDate <= item.endDate;
    })

    if(siteCollectionOperation) {
      drive.siteCollectionOperationId = siteCollectionOperation.id;
      drive.siteCollectionOperation = siteCollectionOperation;
      drive.collectionOperation = siteCollectionOperation.collectionOperation;
      drive.collectionOperationId = siteCollectionOperation.collectionOperationId;
    } else {
      drive.siteCollectionOperationId = null;
      drive.siteCollectionOperation = null;
      drive.collectionOperation = null;
      drive.collectionOperationId = null;
    }
  }

  getDriveTerritories(drives) {
    if (!drives) return;
    
    let orderedDrives = drives.sort((drive, prevDrive) => { return Date.parse(drive.driveDate) > Date.parse(prevDrive.driveDate); });
    let earliestDate = orderedDrives[0].driveDate;
    let latestDate = orderedDrives[orderedDrives.length-1].driveDate;

    let service = new territoryCollectionOperationService();
    let queryModel = new territoryCollectionOperationQueryModel();
    queryModel.collectionOperationIds = [drives[0].collectionOperationId],
    queryModel.startDate = earliestDate;
    queryModel.endDate = latestDate;

    return Promise.resolve()
    .then(() => {
      return service.query(queryModel)
    })
    .then((result) => {
        if (!result || !result.returnedData) return [];
        return autoMapper.autoMapperInstance.mapToArray('sked_Territory_Collection_Operation__c', result.returnedData.territoryCollectionOperations);
    });
  }

  getDriveTerritory(drive, territoryCollectionOperations = []) {
      let tco = territoryCollectionOperations.find(item => {
        return (item.startDate == null || drive.driveDate >= item.startDate) && (item.endDate == null || drive.driveDate <= item.endDate) &&
          (drive.collectionOperationId == item.collectionOperationId);  
      });

      return tco;
  }

  isDriveInPathOfLinkedDrive(drive) {
    if(!drive) return null;
    return drive.linkedDriveId;
  }

  isDriveAPartOfMultiDaysLinkedDrive(drive) {
    if(!this.isDriveInPathOfLinkedDrive(drive)) return;
    return drive.linkedDriveType === LINK_DRIVE_TYPE.MULTI_DAY
  }

  cancelDrive(drive, {
    timezoneSidId,
    cancellationReason,
    initiatedBy,
    replacementDriveId
  }) {
    if(!drive) return null;

    let driveDate = drive.driveDate;
    let driveStatus = drive.status;
    let needToCheckForApproval = !drive.isSurrogate && [DRIVE_STATUS.CONFIRMED].includes(driveStatus);
    let today =  DateTime.fromObject({
      zone: timezoneSidId
    }).toISODate();
    let diff = DateTime.fromISO(driveDate).diff(DateTime.fromISO(today), 'days').days;
    const isPartOfLinkedDrive = this.isDriveInPathOfLinkedDrive(drive);

    if(isPartOfLinkedDrive) {
      return {
        id: drive.id,
        approvalStatus: DRIVE_APPROVAL_STATUS.SUBMITTED,
        pendingAction: PENDING_ACTION.CANCEL_IN_PROCESS,
        pendingActionReasonCode: DRIVE_CONTENTION.PART_OF_LINKED_DRIVE,
        cancellationReason: cancellationReason,
        initiatedBy: initiatedBy,
        replacementDriveId: replacementDriveId
      }
    } else {
      if(needToCheckForApproval && diff <= 42) {
        return {
          id: drive.id,
          approvalStatus: DRIVE_APPROVAL_STATUS.SUBMITTED,
          pendingAction: PENDING_ACTION.CANCEL_IN_PROCESS,
          pendingActionReasonCode: '',
          cancellationReason: cancellationReason,
          initiatedBy: initiatedBy,
          replacementDriveId: replacementDriveId
        }
      } else {
        return {
          id: drive.id,
          status: DRIVE_STATUS.CANCEL,
          cancellationReason: cancellationReason,
          initiatedBy: initiatedBy,
          pendingActionReasonCode: '',
          replacementDriveId: replacementDriveId
        }
      }
    }
  }

  splitScheduledDonors(drive, driveShifts, timezoneSidId) {
    if(this.isFixedSiteDrive(drive)) return;

    let totalDriveShiftDuration = 0;
    let driveShiftDurationMap = {};
    driveShifts.forEach((driveShift) => {
      let driveShiftStart = this.newDateTime(drive.driveDate, driveShift.startTime, timezoneSidId);
      let driveShiftEnd = this.newDateTime(drive.driveDate, driveShift.endTime, timezoneSidId);
      if (driveShiftStart.getTime() > driveShiftEnd.getTime()) {
        driveShiftStart = driveShiftEnd;
      }
      let driveShiftDuration = (driveShiftEnd.getTime() - driveShiftStart.getTime()) / 60000; //minutes

      driveShiftDurationMap[driveShift.key] = driveShiftDuration;
      totalDriveShiftDuration += driveShiftDuration;
    })
    let totalDonors = drive.projectedRegisteredDonors || 0;
    let remainingDonors = totalDonors;
    driveShifts.forEach(driveShift => {
      let driveShiftDuration = driveShiftDurationMap[driveShift.key];
      let percentage = driveShiftDuration / totalDriveShiftDuration;
      driveShift.donorsScheduled = Math.ceil(totalDonors * percentage);

      if (driveShift.donorsScheduled > remainingDonors) {
        driveShift.donorsScheduled = remainingDonors;
      }

      remainingDonors -= driveShift.donorsScheduled;
    });
  }

  splitProjectedProcedures(drive, driveShifts, driveShiftsMetadata, procedureType, timezoneSidId) {   
    if(procedureType === PROCEDURE_TYPE._2RBC && !this.show2RBCField(drive)) return;
    if(procedureType === PROCEDURE_TYPE.WB && !this.showWBField(drive)) return;
    if(procedureType === PROCEDURE_TYPE.PLATELET && !this.showPlateletField(drive)) return;
    if(procedureType === PROCEDURE_TYPE.PLASMA && !this.showPlasmaField(drive)) return;

    const excludeOverlappedTime = [PROCEDURE_TYPE._2RBC, PROCEDURE_TYPE.PLATELET, PROCEDURE_TYPE.PLASMA].includes(procedureType);
    const useRoundTimes = [PROCEDURE_TYPE.PLATELET, PROCEDURE_TYPE.PLASMA].includes(procedureType);
    const mapFieldProcedureType = {
      [PROCEDURE_TYPE._2RBC]: 'x2rbcProjectedProcedures',
      [PROCEDURE_TYPE.WB]: 'wbProjectedProcedures',
      [PROCEDURE_TYPE.PLATELET]: 'plateletProjectedProcedures',
      [PROCEDURE_TYPE.PLASMA]: 'plasmaProjectedProcedures'
    };
    let fieldProcedureType = mapFieldProcedureType[procedureType];
    let totalDriveShiftDuration = 0;
    let totalDriveShiftRounds = 0;
    let driveShiftDurationMap = {};
    let driveShiftRoundsMap = {};

    driveShifts.forEach((driveShift, driveShiftIndex) => {
      if(useRoundTimes) {
        driveShiftRoundsMap[driveShift.key] = driveShift.numberOfRounds;
        totalDriveShiftRounds += driveShift.numberOfRounds;
      } else {
        let driveShiftStart = this.newDateTime(drive.driveDate, driveShift.startTime, timezoneSidId);
        let driveShiftEnd = this.newDateTime(drive.driveDate, driveShift.endTime, timezoneSidId);

        if (excludeOverlappedTime) {
          let previousDriveShift = null;  
          if (driveShiftIndex > 0) {
            previousDriveShift = driveShifts[driveShiftIndex - 1];
          }

          if (previousDriveShift && previousDriveShift.endTime > driveShift.startTime) {
            driveShiftStart = this.newDateTime(drive.driveDate, previousDriveShift.endTime, timezoneSidId);
          }
        }

        if (driveShiftStart.getTime() > driveShiftEnd.getTime()) {
          driveShiftStart = driveShiftEnd;
        }
        let driveShiftDuration = (driveShiftEnd.getTime() - driveShiftStart.getTime()) / 60000; //minutes

        driveShiftDurationMap[driveShift.key] = driveShiftDuration;
        totalDriveShiftDuration += driveShiftDuration;
      }
    })

    let totalProjectedProcedures = driveShiftsMetadata[fieldProcedureType];
    let remaningProjectedProcedures = totalProjectedProcedures;
    driveShifts.forEach(driveShift => {
      let percentage;
      if(useRoundTimes) {
        let driveShiftRounds = driveShiftRoundsMap[driveShift.key];
        percentage = driveShiftRounds / totalDriveShiftRounds;
      } else {
        let driveShiftDuration = driveShiftDurationMap[driveShift.key];
        percentage = driveShiftDuration / totalDriveShiftDuration;
      }
     
      driveShift[fieldProcedureType] = Math.ceil(totalProjectedProcedures * percentage);

      if (driveShift[fieldProcedureType] > remaningProjectedProcedures) {
        driveShift[fieldProcedureType] = remaningProjectedProcedures;
      }

      remaningProjectedProcedures -= driveShift[fieldProcedureType];
    });
  }
  
  splitProcedureCapacity(drive, driveShifts, driveProcedureCapacityMap, procedureType, timezoneSidId) {   
    if(procedureType === PROCEDURE_TYPE._2RBC && !this.show2RBCField(drive)) return;
    if(procedureType === PROCEDURE_TYPE.WB && !this.showWBField(drive)) return;
    if(procedureType === PROCEDURE_TYPE.PLATELET && !this.showPlateletField(drive)) return;
    if(procedureType === PROCEDURE_TYPE.PLASMA && !this.showPlasmaField(drive)) return;

    const excludeOverlappedTime = [PROCEDURE_TYPE._2RBC, PROCEDURE_TYPE.PLATELET, PROCEDURE_TYPE.PLASMA].includes(procedureType);
    const useRoundTimes = [PROCEDURE_TYPE.PLATELET, PROCEDURE_TYPE.PLASMA].includes(procedureType);
    let fieldProcedureType = procedureType;
    let totalDriveShiftDuration = 0;
    let totalDriveShiftRounds = 0;
    let driveShiftDurationMap = {};
    let driveShiftRoundsMap = {};

    driveShifts.forEach((driveShift, driveShiftIndex) => {
      if(useRoundTimes) {
        driveShiftRoundsMap[driveShift.key] = driveShift.numberOfRounds;
        totalDriveShiftRounds += driveShift.numberOfRounds;
      } else {
        let driveShiftStart = this.newDateTime(drive.driveDate, driveShift.startTime, timezoneSidId);
        let driveShiftEnd = this.newDateTime(drive.driveDate, driveShift.endTime, timezoneSidId);

        if (excludeOverlappedTime) {
          let previousDriveShift = null;  
          if (driveShiftIndex > 0) {
            previousDriveShift = driveShifts[driveShiftIndex - 1];
          }

          if (previousDriveShift && previousDriveShift.endTime > driveShift.startTime) {
            driveShiftStart = this.newDateTime(drive.driveDate, previousDriveShift.endTime, timezoneSidId);
          }
        }

        if (driveShiftStart.getTime() > driveShiftEnd.getTime()) {
          driveShiftStart = driveShiftEnd;
        }
        let driveShiftDuration = (driveShiftEnd.getTime() - driveShiftStart.getTime()) / 60000; //minutes

        driveShiftDurationMap[driveShift.key] = driveShiftDuration;
        totalDriveShiftDuration += driveShiftDuration;
      }
    })

    let totalProcedureCapacity = driveProcedureCapacityMap[fieldProcedureType];
    let remaningProcedureCapacity = totalProcedureCapacity;
    driveShifts.forEach(driveShift => {
      let percentage;
      if(useRoundTimes) {
        let driveShiftRounds = driveShiftRoundsMap[driveShift.key];
        percentage = driveShiftRounds / totalDriveShiftRounds;
      } else {
        let driveShiftDuration = driveShiftDurationMap[driveShift.key];
        percentage = driveShiftDuration / totalDriveShiftDuration;
      }

      driveShift[fieldProcedureType] = totalProcedureCapacity * percentage;

      if (driveShift[fieldProcedureType] > remaningProcedureCapacity) {
        driveShift[fieldProcedureType] = remaningProcedureCapacity;
      }

      remaningProcedureCapacity -= driveShift[fieldProcedureType];
    });
  }

  truncateDriveName(rawName) {
    if(!rawName) return rawName;
    let trim = String(rawName).trim();
    let truncated = trim;
    if(truncated.length > 80) {
      truncated = truncated.substring(0, 75) + ' ...'
    }
    return truncated;
  }

  getJobQuantity(job) {
    if (!job) return null;

    if (job.resourceRole === 'VP/HH') {
      return job.vphhQuantity;
    } else {
      return job.quantity;
    }
  }
  
  getResourceRoleGroup(resourceRole, {
    resourceRoleGroups
  }) {
    return Object.keys(resourceRoleGroups).find(resourceRoleGroup => {
      return !!resourceRoleGroups[resourceRoleGroup].find(item => item === resourceRole);
    })
  }

  getDriveShiftResourceQuantity(driveShift) {
    let resourceQuantity = new Map();
    const jobs = this.getDriveShiftJobs(driveShift, {
      excludeManuallyCreatedFromStaffingModal: true
    })
    jobs.forEach(job => {
      if(job.resourceRole) {
        let key = job.resourceRole;
        if(job.dualRole) {
          key = `${job.resourceRole}-${job.dualRole}`
        }
        
        resourceQuantity.set(key, {
          quantity: this.getJobQuantity(job) || 0,
          dualRole: job.dualRole
        });
      }
    })
    return resourceQuantity;
  }

  getAvailableAssets(vehicles = [], drive, ignoreExistingAllocations = false) {
    let availator = slwcAvailator.getInstance({
      drive: drive,
      mapApis: window.google ? window.google.maps : null
    })

    return Promise.all([
      availator.fetchAssetsData()
    ])
      .then(() => {
        return availator.buildScheduledAllocations({
          ignoreExistingAllocations
        });
      })
      .then((result) => {
        let availableVehicleIds = (result.possibleAllocations || []).filter(posAl => {
          if(posAl.resource.assetType !== ASSET_TYPE.VEHICLE) return false;

          const noException = (posAl.exceptionLog || []).length === 0;
          if(!noException) return false;

          if(ignoreExistingAllocations) {
            const currentAssignedVehicleIds = (posAl.job.jobAllocations || [])
              .filter(ja => ja.status !== JOB_ALLOCATION_STATUS.DELETED)
              .map(ja => ja.resourceId);

            return !currentAssignedVehicleIds.includes(posAl.resourceId);
          } else {
            return true;
          }
        }).map(posAl => posAl.resourceId);

        let availableEquipments = (result.possibleAllocations || []).filter(posAl => {
          if(posAl.resource.assetType !== ASSET_TYPE.EQUIPMENT) return false;

          const noException = (posAl.exceptionLog || []).length === 0;
          if(!noException) return false;

          if(ignoreExistingAllocations) {
            const currentAssignedVehicleIds = (posAl.job.jobAllocations || [])
              .filter(ja => ja.status !== JOB_ALLOCATION_STATUS.DELETED)
              .map(ja => ja.resourceId);

            return !currentAssignedVehicleIds.includes(posAl.resourceId);
          } else {
            return true;
          }
        }).map(posAl => posAl.resource);

        let availableButNotSharedAssetIds = (result.possibleAllocations || []).filter(posAl => {
          return (posAl.exceptionLog || []).length === 1 && posAl.exceptionLog[0].exceptionCode === 'RESOURCE_NOT_AVAILABLE_FOR_CO'
        }).map(posAl => posAl.resourceId);

        return {
          availableVehicles: vehicles.filter(vehicle => availableVehicleIds.includes(vehicle.id)),
          availableEquipments: availableEquipments,
          availableButNotSharedAssetIds
        }
      })
  }

  getCurrentAssignedAssets(drive) {
    let { assignedVehicles } = this.getCurrentAssignedVehicles(drive);
    let { assignedEquipments } = this.getCurrentAssignedEquipments(drive);
    return [...assignedVehicles, ...assignedEquipments];
  }

  getCurrentAssignedVehicles(drive) {
    let vehicleJob = drive.driveShifts.length ? (drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE) : null;
    let assignedVehicles = [];
    let lockedVehicles = [];
    let totalCurrentAssignedVehiclesCapacity = 0;
    if (vehicleJob) {
      (vehicleJob.jobAllocations || []).forEach(jobAllocation => {
        if(jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
          assignedVehicles.push(jobAllocation.resource);
          if(jobAllocation.isLocked) {
            lockedVehicles.push(jobAllocation.resource);
          }
          totalCurrentAssignedVehiclesCapacity += (jobAllocation.resource.presDonorCapacity || 0)
        }
      });
    }
    return {
      assignedVehicles,
      lockedVehicles,
      totalCurrentAssignedVehiclesCapacity
    }
  }

  getCurrentAssignedEquipments(drive) {
    let equipmentJobs = drive.driveShifts.length ? (drive.driveShifts[0].jobs || []).filter(job => job.assetType === ASSET_TYPE.EQUIPMENT) : [];
    let totalRequired = 0;
    let assignedEquipments = [];
    let lockedEquipments = [];
    if (equipmentJobs.length) {
      equipmentJobs.forEach((currentJob) => {
        let jobQuantity = this.getJobQuantity(currentJob);
        totalRequired = totalRequired + (jobQuantity || 0);
        (currentJob.jobAllocations || [])
          .filter((jobAllocation) =>  jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED)
          .forEach(jobAllocation => {
            assignedEquipments.push(jobAllocation.resource);
            if(jobAllocation.isLocked) {
              lockedEquipments.push(jobAllocation.resource);
            }
          })
      });
    }

    return {
      totalRequired: totalRequired,
      assignedEquipments: assignedEquipments,
      lockedEquipments: lockedEquipments
    }
  }

  getVehicleTags(driveTags) {
    if (!driveTags) return [];

    let vehicleTags = [];
    if (driveTags.accountTags && driveTags.accountTags.length) {
      driveTags.accountTags.forEach((at) => {
        if (at.required) {
          let resourceTypes = at.tag.resourceType;
          if (resourceTypes.length === 0 || resourceTypes.includes(ASSET_TYPE.VEHICLE)) {
            vehicleTags.push(at.tag);
          }
        }
      });
    }
    if (driveTags.locationTags && driveTags.locationTags.length) {
      driveTags.locationTags.forEach((lt) => {
        if (lt.required) {
          let resourceTypes = lt.tag.resourceType;
          if (resourceTypes.length === 0 || resourceTypes.includes(ASSET_TYPE.VEHICLE)) {
            vehicleTags.push(lt.tag);
          }
        }
      });
    }

    return uniqBy(vehicleTags, 'id');
  }
  
  buildRoleTimeDetailMap(drive, {
    roleTimeData, 
    allResourceRoleGroups = {}
  }) {
    let roleTimeDetailMap = {};
    let roleTimeVarianceMap = {};
    let roleGroupTimeDetailMap = {};
    let roleGroupTimeVarianceMap = {};

    if (roleTimeData) {
      if (roleTimeData.roleTimeDetails && roleTimeData.roleTimeDetails.length) {
        roleTimeData.roleTimeDetails.forEach((item) => {
          if((this.isFixedSiteDrive(drive) || this.isWbFixedSiteDrive(drive)) && 
            item.fixedSiteOperationType && 
            item.fixedSiteOperationType !== drive.operationType) return;
          
          if (item.roleTimeDetailType == 'Global') {
            let resourceRoleGroups = item.resourceRoleGroup;
            resourceRoleGroups.forEach((resourceRoleGroup) => {
              let resourceRoles = allResourceRoleGroups[resourceRoleGroup] || [];
              resourceRoles.forEach((resourceRole) => {
                roleTimeDetailMap[resourceRole] = item;
              });
              roleGroupTimeDetailMap[resourceRoleGroup] = item;
            });
          }
        });
        roleTimeData.roleTimeDetails.forEach((item) => {
          if((this.isFixedSiteDrive(drive) || this.isWbFixedSiteDrive(drive))&& 
            item.fixedSiteOperationType && 
            item.fixedSiteOperationType !== drive.operationType) return;
            
          if (item.roleTimeDetailType == 'Collection Operation') {
            let resourceRoleGroups = item.resourceRoleGroup;
            resourceRoleGroups.forEach((resourceRoleGroup) => {
              let resourceRoles = allResourceRoleGroups[resourceRoleGroup] || [];
              resourceRoles.forEach((resourceRole) => {
                roleTimeDetailMap[resourceRole] = item;
              });
              roleGroupTimeDetailMap[resourceRoleGroup] = item;
            });
          }
        });
      }

      if (roleTimeData.roleTimeVariances && roleTimeData.roleTimeVariances.length) {
        roleTimeData.roleTimeVariances.forEach((item) => {
          let resourceRoleGroups = item.resourceRoleGroup || [];
          resourceRoleGroups.forEach((resourceRoleGroup) => {
            if (!roleGroupTimeVarianceMap[resourceRoleGroup]) {
              roleGroupTimeVarianceMap[resourceRoleGroup] = [];
            }

            let resourceRoles = allResourceRoleGroups[resourceRoleGroup] || [];
            resourceRoles.forEach((resourceRole) => {
              if (!roleTimeVarianceMap[resourceRole]) {
                roleTimeVarianceMap[resourceRole] = [];
              }
              roleTimeVarianceMap[resourceRole].push(item);
            });
            roleGroupTimeVarianceMap[resourceRoleGroup].push(item);
          });
        });
      }
    }

    return {
      roleTimeDetailMap,
      roleTimeVarianceMap,
      roleGroupTimeDetailMap,
      roleGroupTimeVarianceMap
    }
  }

  compareAndGetDriveChanges(oldDrive, newDrive) {
    if(!newDrive || !oldDrive) return [];

    const fieldsToTrack = [
        'totalStaffRequested',
        'totalVehicleRequested',
        'totalEquipmentRequested',
        'projectedRegisteredDonors',
        'driveDate',
        'startTime',
        'endTime',
        'driveSiteId',
        'totalProceduresProjected',
        'totalProductsProjected',
        'driveProductivityPlanned',
        'totalSlots',
        'aptQuantity'
    ]
    
    let driveChanges = [];
    let config = autoMapper.mappingConfigContainerInstance.getMappingConfig('sked_Drive__c');
    config.fieldConfigs.forEach(element => {
        if(element.domainFieldName === 'id') return;
        if(element.sObjectFieldPath.indexOf(".") > -1) return;
        if([autoMapper.MAPPING_TYPE.relatedList, autoMapper.MAPPING_TYPE.related].includes(element.mappingType)) return;
        if(!fieldsToTrack.includes(element.domainFieldName)) return;
        
        let oldValue = get(oldDrive, element.domainFieldName);
        let newValue = get(newDrive, element.domainFieldName);
            
        if(!isEqual(oldValue, newValue)) {
            driveChanges.push({
                fieldApiName: element.sObjectFieldPath,
                objectApiName: 'sked_Drive__c',
                oldValue,
                newValue
            })
        }
    });
    
    return driveChanges;
  }

  buildFieldPermissionsMap(drive, {
    waitingDriveChangeRequest,
    pendingDriveChangeRequest,
    adminSetting,
    loginUser, 
    timezoneSidId,
    travelTimeIndexItemMap
  }) {
    const isAdminUser = this.isAdminUser(loginUser);
    const isAPSUser = this.isAPSUser(loginUser);
    const isOnlyAPSUser = this.isOnlyAPSUser(loginUser);
    const isDRDUser = this.isDRDUser(loginUser);
    const isManufacturingUser = this.isManufacturingUser(loginUser);
    const isTelerecuiterUser = this.isTelerecuiterUser(loginUser);
    const isAPSAdmin = this.isAPSAdmin(loginUser);

    const isDriveSubmittedForDriveChangeRequest = !!waitingDriveChangeRequest;
    const isDriveSubmittedForSubmissionApproval = this.isDriveSubmittedForSubmissionApproval(drive);
    const isDriveSubmittedForCancelApproval = this.isDriveSubmittedForCancelApproval(drive);
    
    const readonlyRule1 = isDriveSubmittedForCancelApproval
                        || drive.status === DRIVE_STATUS.HOLD 
                        || (!isAdminUser && !isAPSUser && (
                            (isDriveSubmittedForDriveChangeRequest) ||
                            isDriveSubmittedForSubmissionApproval
                          ));
    
    const matchedSiteCO = this.getMatchedSiteCOForDrive(drive);
    const { travelTimeBreakdownsCoToSite, travelTimeBreakdownsSiteToCo} = this.getTravelTimeBreakdownData({
      driveDate: drive.driveDate,
      driveSite: drive.driveSite,
      collectionOperation: matchedSiteCO ? matchedSiteCO.collectionOperation : drive.collectionOperation
    }, { travelTimeIndexItemMap });
    const readonlyRule2 = !isAdminUser && !isAPSAdmin && drive && drive.typeOfDrive === DRIVE_TYPE.MOBILE && (!travelTimeBreakdownsCoToSite?.length || !travelTimeBreakdownsSiteToCo?.length);
    const readonlyRule3 = pendingDriveChangeRequest;
    if (readonlyRule1 || readonlyRule2 || readonlyRule3) {
      return {
        isReadonly: true,
        fieldReadonlyMap: {
          driveDate: true,
          startTime: true,
          endTime: true,
          driveSite: true,
          projectedRegisteredDonors: true,
          driveShiftsMetadata: true,
          driveShiftsConfiguration: true,
          driveShifts: true,
          driveShiftSlots: true,
          driveDeliveryJobs: true,
          volunteerJobs: true,
          operationNotes: true,
          linkedDrives: true,
          mobileDriveVehicesInput: true
        },
        fieldChangeRestrictionMap: {
          driveSite: true
        }
      }
    }

    if ([DRIVE_STATUS.DRAFT].includes(drive.status)) {
      //even drive is draft, DRD can only update volunteer jobs, slots, operation notes.
      if(isDRDUser) {
        return {
          isReadonly: true,
          fieldReadonlyMap: {
            driveDate: true,
            startTime: true,
            endTime: true,
            driveSite: true,
            projectedRegisteredDonors: true,
            driveShiftsMetadata: true,
            driveShiftsConfiguration: true, 
            driveShifts: true,
            driveShiftSlots: false,
            driveDeliveryJobs: true,
            volunteerJobs: false,
            operationNotes: false,
            linkedDrives: true,
            aptQuantity: true,
            mobileDriveVehicesInput: true
          },
          fieldChangeRestrictionMap: {
            driveSite: true
          }
        }
      } else {
        let fieldPermissionMap = {
          isReadonly: false,
          fieldReadonlyMap: {
            driveDate: false,
            startTime: false,
            endTime: false,
            driveSite: true,
            projectedRegisteredDonors: false,
            driveShiftsMetadata: false,
            driveShiftsConfiguration: false, 
            driveShifts: false,
            driveShiftSlots: false,
            driveDeliveryJobs: false,
            volunteerJobs: false,
            operationNotes: false,
            linkedDrives: false,
            aptQuantity: isOnlyAPSUser ? false : true,
            mobileDriveVehicesInput: false,
          },
          fieldChangeRestrictionMap: {
            driveSite: true
          }
        }

        if (isManufacturingUser) {
          fieldPermissionMap.fieldReadonlyMap.driveDeliveryJobs = true;
        }

        return fieldPermissionMap;
      }
    }

    let isReadonly = true;
    let fieldReadonlyMap = {
      driveDate: isReadonly,
      startTime: isReadonly,
      endTime: isReadonly,
      driveSite: isReadonly,
      projectedRegisteredDonors: isReadonly,
      driveShiftsMetadata: isReadonly,
      driveShiftsConfiguration: isReadonly,
      mobileDriveVehicesInput: isReadonly,
      driveShifts: isReadonly,
      driveShiftSlots: isReadonly,
      driveDeliveryJobs: isReadonly,
      volunteerJobs: isReadonly,
      operationNotes: isReadonly,
      linkedDrives: isReadonly,
      aptQuantity: isReadonly
    }
    let fieldChangeRestrictionMap = {
      driveSite: true
    }

    const today = DateTime.fromObject({
      zone: timezoneSidId
    }).toISODate();

    if ([DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED].includes(drive.status)) {
      if (drive.driveDate >= today) {
        if(isAdminUser && ![DRIVE_STATUS.CONFIRMED].includes(drive.status)) {
          fieldReadonlyMap.driveDate = false;
        }
        
        if(isAPSUser) {
          fieldReadonlyMap.startTime = false;
          fieldReadonlyMap.endTime = false;
          fieldReadonlyMap.projectedRegisteredDonors = false;
          fieldReadonlyMap.driveShiftsMetadata = false;
          fieldReadonlyMap.driveShiftsConfiguration = false;
          fieldReadonlyMap.driveShifts = false;
        }
        
        if(isAPSUser || isManufacturingUser) {
          if ([DRIVE_STATUS.CONFIRMED].includes(drive.status)) {
            fieldReadonlyMap.driveDeliveryJobs = false;
          }
        }

        if(isAPSUser || isDRDUser || isTelerecuiterUser) {
          fieldReadonlyMap.volunteerJobs = false;
          fieldReadonlyMap.driveShiftSlots = false;
        }

        if(isAPSUser) {
          fieldReadonlyMap.linkedDrives = false;
        }
      }     
    }
      
    if (drive.driveDate >= today) {
      if(isAPSUser) {
        fieldReadonlyMap.mobileDriveVehicesInput = false;
      }
    }

    if(isAPSUser || isDRDUser) {
      fieldReadonlyMap.operationNotes = false;
    }

    fieldReadonlyMap.aptQuantity = isOnlyAPSUser ? false : true;

    return {
      isReadonly,
      fieldReadonlyMap,
      fieldChangeRestrictionMap
    }
  }   

  generateDriveChangesFromDCR(drive, driveChangeRequest) {
    let opportunity = drive.opportunity;
    let isFixedSiteDrive = this.isFixedSiteDrive(drive);
    let driveFields = [];
    if(isFixedSiteDrive) {
      driveFields = [
        'status',
        'driveDate',
        'startTime',
        'endTime',
        'driveSiteId',
        'siteCollectionOperationId',
        'collectionOperationId',
        'numberOf2rbcAssets',
        'numberOfPlateletAssets',
        'numberOfPlasmaAssets',
        'wbProjectedProcedures',
        'x2rbcProjectedProcedures',
        'plateletProjectedProcedures',
        'plasmaProjectedProcedures',
        'slotGenerator'
      ]
    } else {
      driveFields = [
        'status',
        'driveDate',
        'startTime',
        'endTime',
        'driveSiteId',
        'siteCollectionOperationId',
        'collectionOperationId',
        'projectedRegisteredDonors',
        'wbProjectedProcedures',
        'x2rbcProjectedProcedures',
        'aptRequired',
        'aptQuantity',
        'slotGenerator'
      ];
    }

    let fieldsToCheckChanges = [];
    driveChangeRequest.driveChangeRequestItems.find(dcrItem => {
      if(dcrItem.type !== DRIVE_CHANGE_REQUEST_ITEM_TYPE.CHANGE) return;

      const mapping = autoMapper.mappingConfigContainerInstance.getMappingConfig(dcrItem.objectApiName);
      if(!mapping) return;  

      const fieldConfig = mapping.fieldConfigs.find(element => element.sObjectFieldPath === dcrItem.fieldApiName);
      if(!fieldConfig) return;
      if(fieldConfig.domainFieldName === 'id') return;
      if([autoMapper.MAPPING_TYPE.relatedList, autoMapper.MAPPING_TYPE.related].includes(fieldConfig.mappingType)) return;

      const driveFieldValid = driveFields.includes(fieldConfig.domainFieldName === 'anticipatedRegisteredDonors' ? 'projectedRegisteredDonors' : fieldConfig.domainFieldName);
      if(!driveFieldValid) return;
    
      const notUserChanges = ['status', 'siteCollectionOperationId', 'collectionOperationId'].includes(fieldConfig.domainFieldName);
      fieldsToCheckChanges.push({
        targetName: fieldConfig.domainFieldName,
        targetValue: notUserChanges ? dcrItem.newValue : undefined
      });
    })

    let results = fieldsToCheckChanges.map(({targetName, targetValue}) => {
      const notUserChanges = ['status', 'siteCollectionOperationId', 'collectionOperationId'].includes(targetName);
      if (targetName == 'anticipatedRegisteredDonors') {
        return {
          targetName: 'projectedRegisteredDonors',
          targetValue: opportunity[targetName]
        }
      }
      if (targetName == 'aptRequired') {
        return {
          targetName: 'aptRequired',
          targetValue: opportunity[targetName]
        }
      }
      return {
        targetName: targetName,
        targetValue: notUserChanges ? targetValue : opportunity[targetName]
      }
    });

    if (driveChangeRequest.type && driveChangeRequest.type.includes(DRIVE_CHANGE_REQUEST_TYPE.ROLE_TIME_VARIANCE_CHANGE)) {
      results.push({
        targetName: 'roleTimeVarianceChanged',
        targetValue: null
      });
    }

    if (driveChangeRequest.type && driveChangeRequest.type.includes(DRIVE_CHANGE_REQUEST_TYPE.ROLE_TIME_DETAIL_CHANGE)) {
      results.push({
        targetName: 'roleTimeDetailChanged',
        targetValue: null
      });
    }

    if (driveChangeRequest.type && driveChangeRequest.type.includes(DRIVE_CHANGE_REQUEST_TYPE.SITE_ADDRESS_CHANGE)) {
      results.push({
        targetName: 'siteAddressChanged',
        targetValue: null
      });
    }

    if (driveChangeRequest.type && driveChangeRequest.type.includes(DRIVE_CHANGE_REQUEST_TYPE.TRAVEL_TIME_CHANGE)) {
      results.push({
        targetName: 'travelTimeChanged',
        targetValue: null
      });
    }

    if (driveChangeRequest.type && driveChangeRequest.type.includes(DRIVE_CHANGE_REQUEST_TYPE.REGENERATE_DRIVE)) {
      results.push({
        targetName: 'regenerateDrive',
        targetValue: null
      });
    }
    return results;
  }
  
  preProcessSuggestVehicles(maxRegisteredDonors, availableVehicles = [], lockedVehicles = [], {
    maxDOT = Number.MAX_SAFE_INTEGER,
    maxCDL = Number.MAX_SAFE_INTEGER
  }) {
    const lockedVehiclesIds = lockedVehicles.map(item => item.id);
    let maxRegisteredDonorsToAllocate = maxRegisteredDonors;
    let availableVehiclesCanBeUsed = availableVehicles.filter(item => !lockedVehiclesIds.includes(item.id));
    if(!maxRegisteredDonorsToAllocate || !availableVehicles.length) return {
      maxRegisteredDonorsToAllocate,
      availableVehiclesCanBeUsed
    }

    const lockedVehiclesPresDonorCapacity = lockedVehicles.reduce((result, item) => {
      return result + (item.presDonorCapacity || 0);
    }, 0);
    const lockedDOTVehicles = lockedVehicles.filter((item) => {
      return item.DOT;
    });
    const lockedCDLVehicles = lockedVehicles.filter((item) => {
      return item.CDL;
    });

    let remainingMaxCDL = maxCDL;
    let remainingMaxDOT = maxDOT;
    if(remainingMaxCDL !== Number.MAX_SAFE_INTEGER) {
      remainingMaxCDL = Math.max(remainingMaxCDL - lockedCDLVehicles.length, 0);
    }
    if(remainingMaxDOT !== Number.MAX_SAFE_INTEGER) {
      remainingMaxDOT = Math.max(remainingMaxDOT - lockedDOTVehicles.length, 0);
    }

    if(lockedVehiclesPresDonorCapacity >= maxRegisteredDonorsToAllocate) {
      maxRegisteredDonorsToAllocate = 0;
    } else {
      maxRegisteredDonorsToAllocate = maxRegisteredDonorsToAllocate - lockedVehiclesPresDonorCapacity;
    }

    return {
      maxRegisteredDonorsToAllocate,
      availableVehiclesCanBeUsed,
      remainingMaxCDL,
      remainingMaxDOT
    }
  }

  preProcessSuggestEquipments(totalRequired, availableEquipments = [], lockedEquipments = []) {
    const lockedEquipmentIds = lockedEquipments.map(item => item.id);
    let slotsToAllocate = totalRequired;
    let availableEquipmentsCanBeUsed = availableEquipments.filter(item => !lockedEquipmentIds.includes(item.id));
    if(!totalRequired || !availableEquipments.length) return {
      slotsToAllocate,
      availableEquipmentsCanBeUsed
    }

    if(lockedEquipments.length >= totalRequired) {
      slotsToAllocate = 0;
    } else {
      slotsToAllocate = totalRequired - lockedEquipments.length;
    }

    return {
      slotsToAllocate,
      availableEquipmentsCanBeUsed
    }
  }

  suggestEquipments(drives, equipments, quantityToAllocate) {
    let map_drive_equipmentSets = {};
    drives.forEach(drive => {
      if (!drive.driveShifts || !drive.driveShifts.length) return;

      //init maps
      map_drive_equipmentSets[drive.key] = {
        driveKey: drive.key,
        drive: drive,
        equipmentJobsMap: {}
      };

      let equipmentJobs = (drive.driveShifts[0].jobs || []).filter(job => job.assetType === ASSET_TYPE.EQUIPMENT);
      equipmentJobs.forEach(equipmentJob => {
        map_drive_equipmentSets[drive.key].equipmentJobsMap[equipmentJob.equipmentSubtype] = {
          quantity: quantityToAllocate ?? equipmentJob.quantity ?? 0,
          equipments: []
        }
      });

      //simple allocations
      //dedicatedToSite equipments will be preferred
      const orderedEquipments = orderBy(equipments, [(equipment) => {
        if(equipment.dedicatedToSiteId && equipment.dedicatedToSiteId === drive.driveSiteId) {
          return 0;
        } else {
          return 1;
        }

      }], ['asc']);
      orderedEquipments.forEach(equipment => {
        let equipmentInMap = map_drive_equipmentSets[drive.key].equipmentJobsMap[equipment.equipmentSubtype];
        if (!equipmentInMap) return;

        if (equipmentInMap.equipments.length < equipmentInMap.quantity) {
          equipmentInMap.equipments.push(equipment)
        }
      })
    })

    return Object.values(map_drive_equipmentSets);
  }

  suggestVehicles(drives, vehicles) {
    let map_drive_vehicleSets = {};
    drives.forEach(drive => {
      //init maps
      map_drive_vehicleSets[drive.key] = {
        driveKey: drive.key,
        drive: drive,
        vehicles: []
      };

      let maxRegisteredDonors = this.getMaxDonorsScheduledOfDriveShifts(drive);

      //simple allocations
      vehicles.forEach(vehicle => {
        let totalCap = map_drive_vehicleSets[drive.key].vehicles.reduce((result, vehicle) => {
          return result + vehicle.presDonorCapacity;
        }, 0);

        if (totalCap < maxRegisteredDonors) {
          map_drive_vehicleSets[drive.key].vehicles.push(vehicle)
        }
      })
    })

    return Object.values(map_drive_vehicleSets);
  }

  getMaxDonorsScheduledOfDriveShifts(drive) {
    let maxRegisteredDonors = 0;
    (drive.driveShifts || []).forEach(driveShift => {
      const registeredDonors = driveShift.donorsScheduled;
      if(registeredDonors && registeredDonors > maxRegisteredDonors) {
        maxRegisteredDonors = registeredDonors;
      }
    });
    if(!maxRegisteredDonors) {
      maxRegisteredDonors = drive.anticipatedRegisteredDonors || drive.projectedRegisteredDonors;
    }
    return maxRegisteredDonors;
  }

  calculateNumberOfVehiclesForDrive(drive, vehicles = [], {
    maxDOT = Number.MAX_SAFE_INTEGER,
    maxCDL = Number.MAX_SAFE_INTEGER,
    maxRegisteredDonorsToAllocate
  } = {}) {
    const validVehicles = vehicles.filter(vehicle => !isNullOrEmpty(vehicle.presDonorCapacity));

    let vehicleSets = [];
    let maxRegisteredDonors = maxRegisteredDonorsToAllocate ?? this.getMaxDonorsScheduledOfDriveShifts(drive);
    this.getVehicleSet(vehicleSets, maxRegisteredDonors, validVehicles);
    vehicleSets.forEach((vehicleSet) => {
      vehicleSet.noOfVehicles = vehicleSet.vehicleIndexes.length;
      vehicleSet.vehicles = vehicleSet.vehicleIndexes.map(vehicleIndex => {
        return validVehicles[vehicleIndex];
      });
    });
    
    let orderedVehicleSets = orderBy(vehicleSets, ['noOfVehicles', 'totalCap'], ['asc', 'asc']);

    let bestResult = null;
    orderedVehicleSets.forEach(vehicleSet => {
      if(bestResult?.rank === 1) return; //found a best vehicle set

      const numberOfDOT = vehicleSet.vehicles.filter(vehicle => vehicle.DOT).length;
      const numberOfCDL = vehicleSet.vehicles.filter(vehicle => vehicle.CDL).length;

      const isDOTValid = numberOfDOT === 0 || (maxDOT > 0 && numberOfDOT <= maxDOT);
      const isCDLValid = numberOfCDL === 0 || (maxCDL > 0 && numberOfCDL <= maxCDL);

      if(isDOTValid && isCDLValid && (
        !bestResult || bestResult.rank > 1)) {
        bestResult = {
          driveKey: drive.key,
          drive: drive,
          vehicles: vehicleSet.vehicles || [],
          rank: 1
        };
        return;
      }

      if((isDOTValid || isCDLValid) && (
        !bestResult || bestResult.rank > 2)) {
        bestResult = {
          driveKey: drive.key,
          drive: drive,
          vehicles: vehicleSet.vehicles || [],
          rank: 2
        };
        return;
      }
      
      if((!isDOTValid && !isCDLValid) && (
        !bestResult || bestResult.rank > 3)) {
        bestResult = {
          driveKey: drive.key,
          drive: drive,
          vehicles: vehicleSet.vehicles || [],
          rank: 3
        };
        return;
      }
    });

    return bestResult ? [bestResult] : [];
  }

  calculateNumberOfVehicles(drives, vehicles = []) {
    let map_drive_vehicleSets = [];
    const validVehicles = vehicles.filter(vehicle => !isNullOrEmpty(vehicle.presDonorCapacity));

    for (let i = 0; i < drives.length; i++) {
      let vehicleSets = [];
      let maxRegisteredDonors = this.getMaxDonorsScheduledOfDriveShifts(drives[i]);
      this.getVehicleSet(vehicleSets, maxRegisteredDonors, validVehicles);
      vehicleSets.forEach((vehicleSet) => {
        vehicleSet.noOfVehicles = vehicleSet.vehicleIndexes.length;
      });
      map_drive_vehicleSets[i] = orderBy(vehicleSets, ['noOfVehicles', 'totalCap'], ['asc', 'asc']);
    }

    let result = {
      totalCap: 0,
      vehicleIndexes: [],
      vehicleSets: [],
    }

    this.bestResult = null;
    this.findBestResult(result, map_drive_vehicleSets, 0);
    if (this.bestResult) {
      let output = [];
      for (let i = 0; i < this.bestResult.vehicleSets.length; i++) {
        let item = {
          driveKey: drives[i].key,
          drive: drives[i],
          vehicles: []
        }
        let vehicleSet = this.bestResult.vehicleSets[i];
        for (let j = 0; j < vehicleSet.vehicleIndexes.length; j++) {
          let vehicleIndex = vehicleSet.vehicleIndexes[j];
          item.vehicles.push(validVehicles[vehicleIndex]);
        }
        output.push(item);
      }
      return output;
    }
    return null;
  }

  findBestResult(result, map_drive_vehicleSets, driveIndex) {
    if (driveIndex < map_drive_vehicleSets.length) {
      let vehicleSets = map_drive_vehicleSets[driveIndex];
      for (let i = 0; i < vehicleSets.length; i++) {
        let vehicleSet = vehicleSets[i];
        let conflictedVehicle = false;
        for (let j = 0; j < vehicleSet.vehicleIndexes.length; j++) {
          if (result.vehicleIndexes.indexOf(vehicleSet.vehicleIndexes[j]) > -1) {
            conflictedVehicle = true;
            break;
          }
        }

        if (!conflictedVehicle) {
          let newResult = cloneDeep(result);
          newResult.totalCap += vehicleSet.totalCap;
          newResult.vehicleIndexes = newResult.vehicleIndexes.concat(vehicleSet.vehicleIndexes);
          newResult.vehicleSets.push(vehicleSet);

          if (driveIndex == map_drive_vehicleSets.length - 1) {
            if (!this.bestResult) {
              this.bestResult = newResult;
            }
            else {
              if (this.bestResult.vehicleIndexes.length > newResult.vehicleIndexes.length) {
                this.bestResult = newResult;
              }
              else if (this.bestResult.vehicleIndexes.length == newResult.vehicleIndexes.length) {
                if (this.bestResult.totalCap > newResult.totalCap) {
                  this.bestResult = newResult;
                }
              }
            }
            break;
          }
          else {
            this.findBestResult(newResult, map_drive_vehicleSets, driveIndex + 1);
          }
        }
      }
    }
  }

  getVehicleSet(results, requiredCap, vehicles) {
    let nextArray = [];
    for (let j = 0; j < vehicles.length; j++) {
      let vehicleSet = {
        totalCap: vehicles[j].presDonorCapacity,
        vehicleIndexes: [j]
      }
      if (vehicleSet.totalCap >= requiredCap) {
        results.push(vehicleSet);
      }
      else {
        nextArray.push(vehicleSet);
      }
    }
    if(requiredCap > SKIP_BEST_VEHICLE_CALCULATION.ANTICIPATED_REGISTERED_DONOR_GREATER_THEN){
      this.findVehicleForAllocation(requiredCap, vehicles, results);
    } else{
      this.processNextArray(requiredCap, vehicles, results, nextArray);
    }
  }

  processNextArray(requiredCap, vehicles, results, nextArray) {
    let newNextArray = [];

    for (let i = 0; i < nextArray.length; i++) {
      let vehicleSet = nextArray[i];

      for (let j = vehicleSet.vehicleIndexes[vehicleSet.vehicleIndexes.length - 1] + 1; j < vehicles.length; j++) {
        let newVehicleSet = cloneDeep(vehicleSet);
        newVehicleSet.totalCap += vehicles[j].presDonorCapacity;
        newVehicleSet.vehicleIndexes.push(j);

        if (newVehicleSet.totalCap >= requiredCap) {
          results.push(newVehicleSet);
        }
        else if (j < vehicles.length - 1) {
          newNextArray.push(newVehicleSet);
        }
      }
    }
    if (newNextArray.length > 0) {
      this.processNextArray(requiredCap, vehicles, results, newNextArray);
    }
  }

  findVehicleForAllocation(requiredCap, vehicles, results) {
    vehicles.sort((a, b) => b.presDonorCapacity - a.presDonorCapacity);
    
    let totalCap = 0;
    let selectedVehicles = [];

    for (let i = 0; i < vehicles.length; i++) {
        totalCap += vehicles[i].presDonorCapacity;
        selectedVehicles.push(i);

        if (totalCap >= requiredCap) {
            results.push({
                totalCap,
                vehicleIndexes: selectedVehicles
            });
            break;
        }
    }
  }

  calculateDriveTravelTime({
    driveSite,
    driveDate,
    startTime,
    endTime,
    collectionOperation,
  }, {
    timezoneSidId,
    travelTimeIndexItemMap = {}
  }, 
  roleTimeData = {}
  ) {

    let travelTimeToStagingLocation = driveSite.travelTimeToStagingLocation ? driveSite.travelTimeToStagingLocation : 45;
    let travelTimeCoToStie = travelTimeToStagingLocation;
    let travelTimeSiteToCo = travelTimeToStagingLocation;

    let driveDateObj = DateTime.fromISO(driveDate, { zone: timezoneSidId });
    let driveDateWeekday = driveDateObj.toFormat('EEEE');

    let dateTimeObj = {
      start: this.newDateTime(driveDate, startTime, timezoneSidId),
      end: this.newDateTime(driveDate, endTime, timezoneSidId)
    };
  
    const durationObj = {
      minDurationBefore: roleTimeData.setupTime + roleTimeData.siteLogisticsTo,
      maxDurationAfter: roleTimeData.breakdownTime + roleTimeData.siteLogisticsBack
    };

    dateTimeObj.start = new Date(dateTimeObj.start.getTime() - durationObj.minDurationBefore * 60000); 
    dateTimeObj.end = new Date(dateTimeObj.end.getTime() + durationObj.maxDurationAfter * 60000); 

    startTime = this.dateJSToTimeIso(dateTimeObj.start, timezoneSidId);
    endTime = this.dateJSToTimeIso(dateTimeObj.end, timezoneSidId);
    
    const driveStartTimeString = startTime + 'Z';
    const { travelTimeBreakdownsCoToSite, travelTimeBreakdownsSiteToCo} = this.getTravelTimeBreakdownData({
      driveSite,
      driveDate,
      collectionOperation
    }, {
      travelTimeIndexItemMap
    });
    
    if (travelTimeBreakdownsCoToSite && travelTimeBreakdownsCoToSite.length) {
      let travelTimeBreakdown = travelTimeBreakdownsCoToSite.find((item) => item.weekday == driveDateWeekday && item.startOfWindow <= driveStartTimeString && driveStartTimeString <= item.endOfWindow);
      
      if (travelTimeBreakdown && !isNaN(travelTimeBreakdown.travelTime)) {
        travelTimeCoToStie = Math.ceil(travelTimeBreakdown.travelTime);
      }
    }

    const driveEndTimeString = endTime + 'Z';
    if (travelTimeBreakdownsSiteToCo && travelTimeBreakdownsSiteToCo.length) {
      let travelTimeBreakdown = travelTimeBreakdownsSiteToCo.find((item) => item.weekday == driveDateWeekday && item.startOfWindow <= driveEndTimeString && driveEndTimeString <= item.endOfWindow);
      if (travelTimeBreakdown && !isNaN(travelTimeBreakdown.travelTime)) {
        travelTimeSiteToCo = Math.ceil(travelTimeBreakdown.travelTime);
      }
    }

    return {
      travelTime: travelTimeCoToStie,
      travelTime2: travelTimeSiteToCo
    }
  }

  getTravelTimeIndexData({
    driveDate,
    driveSite,
    collectionOperation
  }, {
    travelTimeIndexItemMap = {}
  }) {
    let travelTimeCoToSiteIndex = null;
    let travelTimeSiteToCoIndex = null;
    const collectionOperationStagingLocation = (collectionOperation.collectionOpStagingLocations || []).find(item => (!item.startDate || item.startDate <= driveDate) && (!item.endDate || driveDate <= item.endDate));
    if(collectionOperationStagingLocation) {
      const { geoLocationLatitude: driveSiteGeoLocationLatitude, geoLocationLongitude: driveSiteGeoLocationLongitude } = driveSite;
      const { geoLocationLatitude: stagingLocationGeoLocationLatitude, geoLocationLongitude: stagingLocationGeoLocationLongitude } = collectionOperationStagingLocation.stagingLocation;
      const siteToCOKey = getTravelTimeIndexKey(driveSiteGeoLocationLatitude, driveSiteGeoLocationLongitude, stagingLocationGeoLocationLatitude, stagingLocationGeoLocationLongitude);
      const coToSiteKey = getTravelTimeIndexKey(stagingLocationGeoLocationLatitude, stagingLocationGeoLocationLongitude, driveSiteGeoLocationLatitude, driveSiteGeoLocationLongitude);

      const siteToCOTravelTimeIndex = travelTimeIndexItemMap[siteToCOKey];
      const coToSiteTravelTimeIndex = travelTimeIndexItemMap[coToSiteKey];

      if(siteToCOTravelTimeIndex) {
        travelTimeSiteToCoIndex = siteToCOTravelTimeIndex;
      }

      if(coToSiteTravelTimeIndex) {
        travelTimeCoToSiteIndex = coToSiteTravelTimeIndex;
      }
    }

    return {
      travelTimeSiteToCoIndex,
      travelTimeCoToSiteIndex
    }
  }

  getTravelTimeBreakdownData({
    driveDate,
    driveSite,
    collectionOperation
  }, {
    travelTimeIndexItemMap = {}
  }) {
    const { travelTimeSiteToCoIndex, travelTimeCoToSiteIndex } = this.getTravelTimeIndexData({
      driveDate,
      driveSite,
      collectionOperation
    }, {
      travelTimeIndexItemMap
    })
    let travelTimeBreakdownsCoToSite = [];
    let travelTimeBreakdownsSiteToCo = [];

    if(travelTimeSiteToCoIndex) {
      travelTimeBreakdownsSiteToCo = parseJSON(travelTimeSiteToCoIndex.travelTimeBreakdownJson, []);
    }

    if(travelTimeCoToSiteIndex) {
      travelTimeBreakdownsCoToSite = parseJSON(travelTimeCoToSiteIndex.travelTimeBreakdownJson, []);
    }

    return {
      travelTimeBreakdownsCoToSite,
      travelTimeBreakdownsSiteToCo
    }
  }

  calculateDriveRoleTimeData(drive, masterData) {
    const { roleGroupTimeDetailMap, roleGroupTimeVarianceMap, resourceRoleGroups: resourceRoleGroupsMap} = masterData;
    const resourceRoleGroups = Object.keys(resourceRoleGroupsMap);
    let resourceRoleGroupRoleTimeDataMap = {};
    if(resourceRoleGroups && resourceRoleGroups.length) {
      resourceRoleGroups.forEach(resourceRoleGroup => {
        let roleTimeData = {
          leadTime: 0,
          travelTime: 0,
          siteLogisticsTo: 0,
          setupTime: 0,
          breakdownTime: 0,
          travelTime2: 0,
          siteLogisticsBack: 0,
          wrapUpTime: 0,
          travelTimeCoToSiteVariance: 0,
          travelTimeSiteToCoVariance: 0
        }

        const roleGroupTimeDetail = roleGroupTimeDetailMap[resourceRoleGroup];
        if (roleGroupTimeDetail) {
          roleTimeData.leadTime += roleGroupTimeDetail.leadTime;
          roleTimeData.breakdownTime += roleGroupTimeDetail.breakdownTime;
          roleTimeData.setupTime += roleGroupTimeDetail.setupTime;
          roleTimeData.wrapUpTime += roleGroupTimeDetail.wrapUpTime;
        }

        let roleGroupTimeVariances = roleGroupTimeVarianceMap[resourceRoleGroup];
        if (roleGroupTimeVariances && roleGroupTimeVariances.length) {
          roleGroupTimeVariances.forEach((roleGroupTimeVariance) => {
            let amount = roleGroupTimeVariance.varianceAmount;
            let appliesTo = roleGroupTimeVariance.varianceAppliesTo;
            if (roleGroupTimeVariance.bufferType == 'Subtract') {
              amount = -1 * amount;
            }
            if (appliesTo.includes('Lead Time')) {
              roleTimeData.leadTime += amount;
            }
            if (appliesTo.includes('Setup Time')) {
              roleTimeData.setupTime += amount;
            }
            if (appliesTo.includes('Breakdown Time')) {
              roleTimeData.breakdownTime += amount;
            }
            if (appliesTo.includes('Wrap-up Time')) {
              roleTimeData.wrapUpTime += amount;
            }
            if (appliesTo.includes('Travel Time To') && (!drive.collectionOperation?.noTravelTime || resourceRoleGroup === RESOURCE_ROLE_GROUP.DRIVING_ROLES)) {
              roleTimeData.travelTimeCoToSiteVariance += amount;
            }
            if (appliesTo.includes('Travel Time From') && (!drive.collectionOperation?.noTravelTime || resourceRoleGroup === RESOURCE_ROLE_GROUP.DRIVING_ROLES)) {
              roleTimeData.travelTimeSiteToCoVariance += amount;
            }
            if (appliesTo.includes('Site Logistics To')) {
              roleTimeData.siteLogisticsTo += amount;
            }
            if (appliesTo.includes('Site Logistics Back')) {
              roleTimeData.siteLogisticsBack += amount;
            }
          });
        }
        const { travelTime, travelTime2 } = this.calculateDriveTravelTime(drive, masterData, roleTimeData);
        roleTimeData.travelTime = travelTime + roleTimeData.travelTimeCoToSiteVariance;
        roleTimeData.travelTime2 = travelTime2 + roleTimeData.travelTimeSiteToCoVariance;

        if (
          resourceRoleGroup !== RESOURCE_ROLE_GROUP.DRIVING_ROLES && (
            drive.travelTimeIncluded === 'Drivers Only' ||
            drive.collectionOperation?.noTravelTime
          )
        ) {
          roleTimeData.travelTime = roleTimeData.travelTimeCoToSiteVariance;
          roleTimeData.travelTime2 = roleTimeData.travelTimeSiteToCoVariance;
        }

        roleTimeData = this.getAdjustedRoleTimeDetailData(roleTimeData);
        resourceRoleGroupRoleTimeDataMap[resourceRoleGroup] = roleTimeData;
      })
    }

    return resourceRoleGroupRoleTimeDataMap;
  }

  getAdjustedRoleTimeDetailData(roleTimeData) {
    return {
      ... roleTimeData,
      leadTime:  max([0, roleTimeData.leadTime]),
      setupTime: max([0, roleTimeData.setupTime]),
      breakdownTime: max([0, roleTimeData.breakdownTime]),
      wrapUpTime: max([0, roleTimeData.wrapUpTime]),
      travelTime: max([0, roleTimeData.travelTime]),
      travelTime2: max([0, roleTimeData.travelTime2]),
      siteLogisticsTo: max([0, roleTimeData.siteLogisticsTo]),
      siteLogisticsBack: max([0, roleTimeData.siteLogisticsBack])
    }
  }

  calculateDriveShiftRoleTimeData(masterData, drive, driveShiftMetadata) {
    const driveShiftsMetadata = drive.driveShiftsMetadata;
    const driveShiftIndex = driveShiftsMetadata.driveShifts.findIndex(item => item.key === driveShiftMetadata.key);
    const breakdownTimeThreshold = drive.collectionOperation.breakdownTimeThreshold;
    const setupTimeThreshold = drive.collectionOperation.setupTimeThreshold;
    
    let resourceRoleGroupRoleTimeDataMap = cloneDeep(driveShiftsMetadata.resourceRoleGroupRoleTimeDataMap);

    const resourceRoleGroups = Object.keys(resourceRoleGroupRoleTimeDataMap);
    if(resourceRoleGroups && resourceRoleGroups.length) {
      resourceRoleGroups.forEach(resourceRoleGroup => {
        let roleTimeData = resourceRoleGroupRoleTimeDataMap[resourceRoleGroup];
        if (driveShiftIndex > 0) {
          if (roleTimeData.setupTime > setupTimeThreshold) {
            roleTimeData.setupTime = setupTimeThreshold;
          }
        }
        if (driveShiftIndex < driveShiftsMetadata.driveShifts.length - 1) {
          if (roleTimeData.breakdownTime > breakdownTimeThreshold) {
            roleTimeData.breakdownTime = breakdownTimeThreshold;
          }
        }
        const { travelTime, travelTime2 } = this.calculateDriveTravelTime({
          ... drive, 
          startTime: driveShiftMetadata.startTime,
          endTime: driveShiftMetadata.endTime
          }, 
          masterData, 
          roleTimeData
        );
        roleTimeData.travelTime = travelTime + roleTimeData.travelTimeCoToSiteVariance;
        roleTimeData.travelTime2 = travelTime2 + roleTimeData.travelTimeSiteToCoVariance;
  
        if (
          resourceRoleGroup !== RESOURCE_ROLE_GROUP.DRIVING_ROLES && (
            drive.travelTimeIncluded === 'Drivers Only' ||
            drive.collectionOperation?.noTravelTime
          )
        ) {
          roleTimeData.travelTime = roleTimeData.travelTimeCoToSiteVariance;
          roleTimeData.travelTime2 = roleTimeData.travelTimeSiteToCoVariance;
        }
        roleTimeData = this.getAdjustedRoleTimeDetailData(roleTimeData);
        resourceRoleGroupRoleTimeDataMap[resourceRoleGroup] = roleTimeData
      })
    }

    return resourceRoleGroupRoleTimeDataMap;
  }

  calculateDriveShiftLunchBreakSettings(drive, driveShiftMetadata, {
    timezoneSidId
  }) {
    const lunchBreakBeforeDrawHours = drive.collectionOperation.lunchBreakBeforeDrawHours;
    let maximumLunchBreakDuration = 0;
    if(drive.typeOfDrive === DRIVE_TYPE.MOBILE) {
      maximumLunchBreakDuration = drive.collectionOperation.lunchBreakDurationMobile; 
    } else {
      maximumLunchBreakDuration = drive.collectionOperation.lunchBreakDurationFixedSite;
    }
    
    let lunchBreakSettings = {
      lunchBreak: false,
      lunchBreakBeforeDrawHours: lunchBreakBeforeDrawHours,
      maximumLunchBreakDuration: maximumLunchBreakDuration,
      unpaidLunchBreakDuration: drive.collectionOperation.unpaidLunchBreakDuration
    }

    //NOTE: If Fixed Site, exclude driving roles group
    let resourceRoleGroupsToProcess = drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE ? [RESOURCE_ROLE_GROUP.SUPERVISORY_ROLES, RESOURCE_ROLE_GROUP.STAFF_ROLES] : [];
    const { maxDurationBefore, maxDurationAfter } = this.calculateMinMaxRoleTimeDuration(drive, driveShiftMetadata.resourceRoleGroupRoleTimeDataMap, resourceRoleGroupsToProcess);
    const driveShiftDrawHoursInMinutes = this.calculateDrawHoursInMinutes(driveShiftMetadata, {
      timezoneSidId
    });

    const driveShiftLengthInMinutes = driveShiftDrawHoursInMinutes + maxDurationBefore + maxDurationAfter; 
    if(driveShiftLengthInMinutes >= 360 && drive.collectionOperation.lunchBreak) {
      lunchBreakSettings.lunchBreak = true;
    }

    return lunchBreakSettings;
  }

  calculateMinMaxRoleTimeDuration(drive, resourceRoleGroupRoleTimeDataMap, resourceRoleGroups = []) {
    let maxDurationBefore = 0;  
    let maxDurationAfter = 0;
    Object.keys(resourceRoleGroupRoleTimeDataMap).forEach(resourceRoleGroup => {
      if (resourceRoleGroups.length && !resourceRoleGroups.includes(resourceRoleGroup)) return;

      const roleTimeData = resourceRoleGroupRoleTimeDataMap[resourceRoleGroup];
      let durationBefore = sum(compact([roleTimeData.leadTime, roleTimeData.setupTime, roleTimeData.siteLogisticsTo]));
      let durationAfter = sum(compact([roleTimeData.breakdownTime, roleTimeData.wrapUpTime, roleTimeData.siteLogisticsBack]));

      if(this.isMobileDrive(drive)) {
        durationBefore += roleTimeData.travelTime;
        durationAfter += roleTimeData.travelTime2;
      }
      
      if(durationBefore > maxDurationBefore) {
        maxDurationBefore = durationBefore;
      }

      if(durationAfter > maxDurationAfter) {
        maxDurationAfter = durationAfter;
      }
    })

    return {
      maxDurationBefore: maxDurationBefore,
      maxDurationAfter: maxDurationAfter
    }
  }

  calculateDrawHours(driveOrDriveShift, {
    timezoneSidId
  }, lunchBreakSettings) {
   let drawHoursInMunutes = this.calculateDrawHoursInMinutes(driveOrDriveShift, {
      timezoneSidId
    }, lunchBreakSettings);
    return drawHoursInMunutes / 60;
  }
  
  calculateDrawHoursInMinutes(driveOrDriveShift, {
    timezoneSidId
  }, lunchBreakSettings) {
    if(!driveOrDriveShift || !driveOrDriveShift.driveDate || !driveOrDriveShift.startTime || !driveOrDriveShift.endTime) return 0;
    let start = this.newDateTime(driveOrDriveShift.driveDate, driveOrDriveShift.startTime, timezoneSidId);
    let end = this.newDateTime(driveOrDriveShift.driveDate, driveOrDriveShift.endTime, timezoneSidId);
    let durationInMinutes = (end.getTime() - start.getTime()) / 60000;

    let durationInMinutesWithoutLunchBreak = durationInMinutes;
    if(lunchBreakSettings) {
      if(lunchBreakSettings.lunchBreak && !lunchBreakSettings.lunchBreakBeforeDrawHours) {
        durationInMinutesWithoutLunchBreak = durationInMinutesWithoutLunchBreak - lunchBreakSettings.maximumLunchBreakDuration
      }
    }

    return durationInMinutesWithoutLunchBreak;
  }

  calculateStaffSetup(resourceRoles = [], driveShift) {
    const mapResourceQuantity = this.getDriveShiftResourceQuantity(driveShift);
    mapResourceQuantity.forEach((value, key) => {
      if (value.dualRole) {
        let variable1, variable2;
        if (key.includes('-')) {
          [variable1, variable2] = key.split('-');
        }
        if (variable1 && resourceRoles.length > 0 && resourceRoles.includes(variable1)) {
          resourceRoles.push(`${key}`);
        }
      }
    });
    let staffSetup = 0;
    resourceRoles.forEach(resourceRole => {
      let resourceQuantity = mapResourceQuantity.get(resourceRole);
      if(resourceQuantity) {
        staffSetup += (resourceQuantity.quantity || 0);
      }
    })
    return staffSetup;
  };

  calculateStaffCapacity(resourceRoles = [], drive, driveShiftMetadata, mapResourceQuantity, {
    staffingDecisionMatrix,
    timezoneSidId 
  }, ignoreLunchBreak = false) {
    const resourceRoleCapacityFieldMap = {
      'Driver': 'driverCapacity',
      'Driver Support': 'driverSupportCapacity',
      '2RBC': 'x2RbcStaffCapacity',
      'Charge': 'chargeCapacity',
      'VP/HH': 'vpHhCapacity'
    }

    const resourceQuantity = mapResourceQuantity.get(driveShiftMetadata.key);
    let drawHours = this.calculateDrawHours(driveShiftMetadata, {
      timezoneSidId
    }, driveShiftMetadata.lunchBreakSettings);

    const drawHoursWithoutLunchBreak = this.calculateDrawHours(driveShiftMetadata, {
      timezoneSidId
    });

    if(ignoreLunchBreak) {
      drawHours = drawHoursWithoutLunchBreak;
    }

    let staffCapacity = 0;
    Array.from(resourceQuantity.keys()).forEach(resourceRole => {
      const data = resourceQuantity.get(resourceRole);
      let noOfResources = data || 0;
      let dualRole = null;
      if(isObject(data)) {
        noOfResources = data.quantity || 0;
        dualRole = data.dualRole;
      }

      let role = resourceRole.split('-')[0];;
      let roleCapacity = staffingDecisionMatrix[resourceRoleCapacityFieldMap[role]] || 0;

      if(resourceRoles.includes(role)) {
        if(role === RESOURCE_ROLE.x2RBC) {
          const noOf2RBCAssets = drive.numberOf2rbcAssets || 0;
          const noOfResourcesHaveEnough2RBCAssets = Math.min(noOfResources, Math.floor(noOf2RBCAssets / 2));
          const noOfResourcesNotHaveEnough2RBCAssets = Math.max(noOfResources - noOfResourcesHaveEnough2RBCAssets, 0);
          const x2RBCRoleCapacity = staffingDecisionMatrix[resourceRoleCapacityFieldMap[RESOURCE_ROLE.x2RBC]] || 0;
          
          const capacity1 = noOfResourcesHaveEnough2RBCAssets * 2 * drawHoursWithoutLunchBreak;
          const capacity2 = noOfResourcesNotHaveEnough2RBCAssets * x2RBCRoleCapacity * drawHoursWithoutLunchBreak;
          staffCapacity += capacity1 + capacity2;
        } else {
          staffCapacity += noOfResources * roleCapacity * drawHours;
        }
      }
    });

    return staffCapacity;
  }
  calculateMaximumStaffCapacityWithDrawHours(resourceRoles = [], drive, driveShiftMetadata, mapResourceQuantity, {
    staffingDecisionMatrix,
    timezoneSidId 
  }, ignoreLunchBreak = false) {
    const resourceRoleCapacityFieldMap = {
      'Driver': 'driverCapacity',
      'Driver Support': 'driverSupportCapacity',
      '2RBC': 'x2RbcStaffCapacity',
      'Charge': 'chargeCapacity',
      'VP/HH': 'vpHhCapacity'
    }

    const resourceQuantity = mapResourceQuantity.get(driveShiftMetadata.key);
    let drawHours = this.calculateDrawHours(driveShiftMetadata, {
      timezoneSidId
    }, driveShiftMetadata.lunchBreakSettings);

    const drawHoursWithoutLunchBreak = this.calculateDrawHours(driveShiftMetadata, {
      timezoneSidId
    });

    if(ignoreLunchBreak) {
      drawHours = drawHoursWithoutLunchBreak;
    }
    let maxStaffCapacity = 0;
    Array.from(resourceQuantity.keys()).forEach(resourceRole => {
      const data = resourceQuantity.get(resourceRole);
      let noOfResources = data || 0;
      let dualRole = null;
      if(isObject(data)) {
        noOfResources = data.quantity || 0;
        dualRole = data.dualRole;
      }

      let role = resourceRole.split('-')[0];;
      let roleCapacity = staffingDecisionMatrix[resourceRoleCapacityFieldMap[role]] || 0;
      if(resourceRoles.includes(role)) {
        let roleCapacitywithDrawHours = roleCapacity * drawHours;
        if(roleCapacitywithDrawHours > maxStaffCapacity){
          maxStaffCapacity = roleCapacitywithDrawHours;
        }
      }
    });
    return maxStaffCapacity;
  }

  calculateMaximumStaffCapacity(resourceRoles = [], drive, driveShiftMetadata, mapResourceQuantity, {
    staffingDecisionMatrix,
    timezoneSidId 
  }, ignoreLunchBreak = false) {
    const resourceRoleCapacityFieldMap = {
      'Driver': 'driverCapacity',
      'Driver Support': 'driverSupportCapacity',
      '2RBC': 'x2RbcStaffCapacity',
      'Charge': 'chargeCapacity',
      'VP/HH': 'vpHhCapacity'
    }

    const resourceQuantity = mapResourceQuantity.get(driveShiftMetadata.key);

    let maxStaffCapacity = 0;
    Array.from(resourceQuantity.keys()).forEach(resourceRole => {
      const data = resourceQuantity.get(resourceRole);
      let noOfResources = data || 0;
      let dualRole = null;
      if(isObject(data)) {
        noOfResources = data.quantity || 0;
        dualRole = data.dualRole;
      }

      let role = resourceRole.split('-')[0];;
      let roleCapacity = staffingDecisionMatrix[resourceRoleCapacityFieldMap[role]] || 0;
      if(resourceRoles.includes(role)) {
        if(roleCapacity > maxStaffCapacity){
          maxStaffCapacity = roleCapacity;
        }
      }
    });
    return maxStaffCapacity;
  }

  countDriveStaffs(resourceRoles = [], drive, driveShiftMetadata, mapResourceQuantity, {
    staffingDecisionMatrix,
    timezoneSidId 
  }, ignoreLunchBreak = false) {
    const resourceQuantity = mapResourceQuantity.get(driveShiftMetadata.key);
    let staffCount = 0;
    Array.from(resourceQuantity.keys()).forEach(resourceRole => {
      const data = resourceQuantity.get(resourceRole);
      let noOfResources = data || 0;
      if(isObject(data)) {
        noOfResources = data.quantity || 0;
      }

      let role = resourceRole.split('-')[0];

      if(resourceRoles.includes(role)) {
        staffCount += noOfResources;
      }
    });

    return staffCount;
  }

  calculateDriveShiftTags({
    driveTags
  }) {
    let driveShiftTagsMap = {};
    if (driveTags) {
      const requiredAccountTagNames = (driveTags.accountTags || []).filter(at => {
        return at.required;
      }).map(at => at.tag.name);
      const requiredLocationTagNames = (driveTags.locationTags || []).filter(lt => {
        return lt.required;
      }).map(lt => lt.tag.name);
      const allRequiredTagNames = requiredAccountTagNames.concat(requiredLocationTagNames);

      if (driveTags.accountTags && driveTags.accountTags.length) {
        driveTags.accountTags.forEach((at) => {
          if (at.required) return;
          if (allRequiredTagNames.includes(at.tag.name)) return;

          const existed = driveShiftTagsMap[at.tag.name];
          let minimumQuantity = at.minimumQuantity;
          if(existed && existed.minimumQuantity > minimumQuantity) {
            minimumQuantity = existed.minimumQuantity;
          }

          driveShiftTagsMap[at.tag.name] = {
            tagId: at.tagId,
            tagName: at.tag.name,
            tag: at.tag,
            minimumQuantity: minimumQuantity
          }
        });
      }

      if (driveTags.locationTags && driveTags.locationTags.length) {
        driveTags.locationTags.forEach((lt) => {
          if (lt.required) return;
          if (allRequiredTagNames.includes(lt.tag.name)) return;

          const existed = driveShiftTagsMap[lt.tag.name];
          let minimumQuantity = lt.minimumQuantity;
          if(existed && existed.minimumQuantity > minimumQuantity) {
            minimumQuantity = existed.minimumQuantity;
          }

          driveShiftTagsMap[lt.tag.name] = {
            tagId: lt.tagId,
            tagName: lt.tag.name,
            tag: lt.tag,
            minimumQuantity: minimumQuantity
          }
        });
      }
    }
    return Object.values(driveShiftTagsMap);
  }

  calculateJobTagsMap({
    driveTags
  }) {
    let jobTagsMap = {
      [ASSET_TYPE.VEHICLE]: [],
      [ASSET_TYPE.EQUIPMENT]: [],
      [RESOURCE_TYPE.PERSON]: []
    }

    const _setTags = (locationTag) => {
      let tag = locationTag.tag;
      let resourceTypes = tag.resourceType || [];
      let systemCreated = !!locationTag.systemCreated;
      if(!resourceTypes.length) {
        resourceTypes = [ASSET_TYPE.VEHICLE, ASSET_TYPE.EQUIPMENT, RESOURCE_TYPE.PERSON]; //add to all resource type
      }

      resourceTypes.forEach(resourceType => {
        let tags = jobTagsMap[resourceType];
        if (tags) {
          let found = tags.find(item => item.tag.name === tag.name);
          if (!found) {
            tags.push({
              tagId: tag.id,
              tag: tag,
              systemCreated: systemCreated
            })
          }
        }
      })
    }

    if (driveTags) {
      if (driveTags.accountTags && driveTags.accountTags.length) {
        driveTags.accountTags.forEach((at) => {
          if(!at.required) return;
          _setTags(at);
        });
      }
      if (driveTags.locationTags && driveTags.locationTags.length) {
        driveTags.locationTags.forEach((lt) => {
          if(!lt.required) return;
          _setTags(lt);
        });
      }
    }

    return jobTagsMap;
  }

  getDrawHoursInMinutesByProcedureType({
    driveDate,
    startTime,
    endTime,
    typeOfDrive,
    collectionOperation
  }, procedureType, {
    timezoneSidId
  }) {
    let driveStart = this.newDateTime(driveDate, startTime, timezoneSidId);
    let driveEnd = this.newDateTime(driveDate, endTime, timezoneSidId);
    if (procedureType === PROCEDURE_TYPE.PLATELET) {
      driveStart = driveStart;
      driveEnd = driveEnd;
    }
    else if (procedureType === PROCEDURE_TYPE.PLASMA) {
      driveStart = new Date(driveStart.getTime() + 60 * 60000);
      driveEnd = new Date(driveEnd.getTime() - 50 * 60000);
    }
    else if (procedureType === PROCEDURE_TYPE.WB) {
      driveStart = new Date(driveStart.getTime() + 60 * 60000);
      if (this.isDriveSkipLastAppointment({
        typeOfDrive,
        collectionOperation
      })) {
        driveEnd = new Date(driveEnd.getTime() - 15 * 60000);
      } else {
        driveEnd = driveEnd;
      }
    }
    else if (procedureType === PROCEDURE_TYPE._2RBC) {
      driveStart = new Date(driveStart.getTime() + 60 * 60000);
      driveEnd = new Date(driveEnd.getTime() - 30 * 60000);
    }

    let driveDuration = (driveEnd.getTime() - driveStart.getTime()) / 60000;
    if (driveDuration < 0) driveDuration = 0;
    return driveDuration;
  }

  getDriveShiftJobByProcedureType(driveShift, procedureType) {
    return (driveShift.jobs || []).find(driveShiftJob => {
      return driveShiftJob.procedureType === procedureType;
    });
  }

  getFixedSiteProcedureTypeCapacity(procedureType, masterData) {
    if (!masterData || !masterData.staffingDecisionMatrix) return 0;

    if (procedureType === PROCEDURE_TYPE.PLATELET) {
      return masterData.staffingDecisionMatrix.plateletRoundCapacity || 0;
    }
    else if (procedureType === PROCEDURE_TYPE.PLASMA) {
      return masterData.staffingDecisionMatrix.plasmaHourlyCapacity || 0;
    }
    else if (procedureType === PROCEDURE_TYPE.WB) {
      return masterData.staffingDecisionMatrix.wbHourlyCapacity || 0;
    }
    else if (procedureType === PROCEDURE_TYPE._2RBC) {
      return masterData.staffingDecisionMatrix.x2rbcHourlyCapacity || 0;
    }

    return 0;
  }

  getProjectedProceduresByProcedureType(drive, procedureType) {
    if (procedureType === PROCEDURE_TYPE.PLATELET) {
        return drive.plateletProjectedProcedures;
    }
    else if (procedureType === PROCEDURE_TYPE.PLASMA) {
        return drive.plasmaProjectedProcedures;
    }
    else if (procedureType === PROCEDURE_TYPE.WB) {
        return drive.wbProjectedProcedures;
    }
    else if (procedureType=== PROCEDURE_TYPE._2RBC) {
        return drive.x2rbcProjectedProcedures;
    }

    return 0;
  }

  splitMergedJobType(mergedString) {
    if (!mergedString) return {
      jobType: null,
      jobSubtype: null
    };

    let parts = mergedString.split(' - ');
    return {
      jobType: parts[0],
      jobSubtype: parts.length > 1 ? parts[1] : null
    }
  }

  applyRoleTimeDataToJob(job, {
    leadTime = 0,
    setupTime = 0,
    breakdownTime = 0,
    wrapUpTime = 0,
    travelTime = 0,
    travelTime2 = 0,
    siteLogisticsBack = 0,
    siteLogisticsTo = 0
  }, {
    lunchBreak = false,
    lunchBreakBeforeDrawHours = false,
    lunchBreakDuration
  }) {
    if (!job || !job.start || !job.finish || !job.resourceRole) return job;

    const drawHoursStart = job.start;
    const drawHoursEnd = job.finish;

    let durationBeforeDrawHours = leadTime + setupTime + travelTime + siteLogisticsTo;
    if (lunchBreak && lunchBreakBeforeDrawHours) {
      durationBeforeDrawHours += lunchBreakDuration;
    }
          
    job.start = new Date(drawHoursStart.getTime() - durationBeforeDrawHours * 60000);
    job.finish = new Date(drawHoursEnd.getTime() + (breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack) * 60000);
    job.duration = (job.finish.getTime() - job.start.getTime()) / 60000;

    return job;
  }

  checkForChangesToDrive(drive, backupDrive) { 
    let requiresAssetValidation = false;

    const triggeringFields = ['status', 'driveDate', 'startTime', 'endTime', 'driveSiteId', 'projectedRegisteredDonors'];
    triggeringFields.every(field => {
      if (drive[field] !== backupDrive[field]) {
          requiresAssetValidation = true;
      }
      return !requiresAssetValidation;
    });

    return requiresAssetValidation;
  }

  isJobsSameRoles(job1, job2) {
    if(job1.resourceRole) {
      const job1Role = `${job1.resourceRole}-${job1.dualRole || ''}`;
      const job2Role = `${job2.resourceRole}-${job2.dualRole || ''}`;
      return job1Role === job2Role;
    } else if(job1.assetType) return job1.assetType == job2.assetType;

    const sameVolunteerType = job1.volunteerRole == job2.volunteerRole;
    return sameVolunteerType;
  }

  generateJobKey(job) {
    if(job.volunteerRole) return job.volunteerRole;
    if(job.assetType) return job.assetType;
    if(job.dualRole) return `${job.resourceRole}-${job.dualRole}`;
    return job.resourceRole;
  }
  
  parseJobKey(jobKey) {
    const [resourceRole, dualRole = ''] = jobKey.split('-');
    return {
      resourceRole,
      dualRole
    }
  }

  checkForChangesToDriveJobs(drive, backupDrive) {
    if (drive.driveShifts.length !== backupDrive.driveShifts.length) {
      return true;
    }

    for (let i = 0; i < drive.driveShifts.length; i++) {
      let driveShift = drive.driveShifts[i];
      let backupDriveShift = backupDrive.driveShifts[i];
      
      let validJobs = driveShift.jobs.filter(job => !job.volunteerRole);
      let validBackupJobs = backupDriveShift.jobs.filter(job => !job.volunteerRole);

      if (validJobs.length !== validBackupJobs.length) return true;
      for (let j = 0; j < validJobs.length; j++) {
        let job = validJobs[j];
        let backupJob = validBackupJobs.find((item) => {
          if (this.isJobsSameRoles(item, job) && item.quantity == job.quantity) {
            return true;
          }
        });

        if (backupJob == null) {
          return true;
        }
      }
    }
    
    return false;
  }

  findDriveLimitByDay = (dateIso, driveLimits = [], type = null) => {
    if (!dateIso) return null;

    const dayOfWeek = DateTime.fromFormat(dateIso, 'yyyy-MM-dd').toFormat('cccc');
    let driveLimit = null;
    (driveLimits || []).filter((limit) => {
      if (!type) {
        return !limit.type || limit.type === OPERATION_DRIVE_LIMIT_TYPE.DRIVE_LIMIT;
      }

      return limit.type === type;
    }).forEach(item => {
      const daysOfWeek = item.daysOfWeek || [];
      const isDateRangeValid = (!item.effectiveStartDate || item.effectiveStartDate <= dateIso) && (!item.effectiveEndDate || dateIso <= item.effectiveEndDate);
      const isDayOfWeekValid = daysOfWeek.includes(dayOfWeek);
      const isOverrided = (item.operationDriveLimitOverrides || []).find(item => item.date == dateIso);

      if (isDateRangeValid && isDayOfWeekValid) {
        driveLimit = item.quantity;
      }

      if (isOverrided) {
        driveLimit = isOverrided.quantity;
      }
    })

    return driveLimit;
  }
  
  validateDrive = (drive, masterData, contentionsToValidate = [], originalContentions = []) => {
    const isContentionOverrided = (drive, contention) => {
      const contentionResolutionMap = {
        [DRIVE_CONTENTION.DRIVE_LIMIT]: [DRIVE_CONTENTION_RESOLUTION.ELECT_DRIVE_LIMIT],
        [DRIVE_CONTENTION.x2RBC_LIMIT]: [DRIVE_CONTENTION_RESOLUTION.ELECT_2RBC_LIMIT],
        [DRIVE_CONTENTION.DOT_LIMIT]: [DRIVE_CONTENTION_RESOLUTION.ELECT_DOT_LIMIT],
        [DRIVE_CONTENTION.CDL_LIMIT]: [DRIVE_CONTENTION_RESOLUTION.ELECT_CDL_LIMIT],
        [DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS]: [DRIVE_CONTENTION_RESOLUTION.ELECT_OUT_OF_OPERATIONAL_HOURS],
        [DRIVE_CONTENTION.LACKING_EQUIPMENT]: ['none'],
        [DRIVE_CONTENTION.LACKING_VEHICLE]: [DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY, DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_USE_RENTAL],
        [DRIVE_CONTENTION.WITHIN_42_DAYS]: [DRIVE_CONTENTION_RESOLUTION.ELECT_WITHIN_42_DAYS],
        [DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS]: [DRIVE_CONTENTION_RESOLUTION.ELECT_CONFIRM_WITHIN_42_DAYS],
        [DRIVE_CONTENTION.PART_OF_LINKED_DRIVE]: [DRIVE_CONTENTION_RESOLUTION.ELECT_PART_OF_LINKED_DRIVE],
        [DRIVE_CONTENTION.INSUFFICIENT_RESOURCES]: [DRIVE_CONTENTION_RESOLUTION.ELECT_INSUFFICIENT_RESOURCES],
        [DRIVE_CONTENTION.MULTI_SHIFT_DRIVE]: [DRIVE_CONTENTION_RESOLUTION.ELECT_MULTI_SHIFT_DRIVE],
        [DRIVE_CONTENTION.DUAL_ROLE_REMOVAL]: [DRIVE_CONTENTION_RESOLUTION.ELECT_DUAL_ROLE_REMOVAL],     
        [DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS]: [DRIVE_CONTENTION_RESOLUTION.ELECT_CO_CHANGED_CROSS_REGIONS_REMOVE_FROM_LINKED_DRIVE],
        [DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO]: [DRIVE_CONTENTION_RESOLUTION.ELECT_ASSETS_NOT_SHARED_WITH_NEW_CO],
        [DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY]: [DRIVE_CONTENTION_RESOLUTION.ELECT_EXCESS_STAFF_CAPACITY]
      };

      const driveContentionResolutions = drive.contentionResolution || [];
      const contentionOverrided = contentionResolutionMap[contention].find(contentionResolution => driveContentionResolutions.includes(contentionResolution));
      return !!contentionOverrided;
    }

    const validateDriveLimit = (drive, {
      driveLimits = [],
      sameDateDrives = []
    }) => {
      // Operation Drive Limit
      let result = {
        contention: DRIVE_CONTENTION.DRIVE_LIMIT,
        violated: false,
        passed: true,
        data: null
      }

      if(this.isFixedSiteDrive(drive)) {
        return result;
      }

      let driveLimit = this.findDriveLimitByDay(drive.driveDate, driveLimits);
      let noOfConfirmedDrives = 0;
      sameDateDrives.forEach((sameDateDrive) => {
        if ([DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(sameDateDrive.status)) {
          if(!this.isFixedSiteDrive(sameDateDrive)) {
            noOfConfirmedDrives++;
          }
        }
      });

      result.data = {
        driveLimit: isNullOrEmpty(driveLimit) ? '∞' : driveLimit,
        noOfCurrentDrives: noOfConfirmedDrives
      }
      result.violated = !isNullOrEmpty(driveLimit) && driveLimit <= noOfConfirmedDrives;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.DRIVE_LIMIT);
      return result;
    }

    const validate2RBCLimit = (drive, {
      driveLimits = [],
      sameDateDrives = []
    }) => {
      let result = {
        contention: DRIVE_CONTENTION.x2RBC_LIMIT,
        violated: false,
        passed: true,
        data: null
      }

      if (this.isFixedSiteDrive(drive)) {
        return result;
      }

      const operationalLimit = this.findDriveLimitByDay(drive.driveDate, driveLimits, OPERATION_DRIVE_LIMIT_TYPE.x2RBC_LIMIT);
      let sameDateMobileDrives2RBCRequested = 0;
      sameDateDrives.forEach((sameDateDrive) => {
        if (([DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(sameDateDrive.status))) {
          if (!this.isFixedSiteDrive(sameDateDrive)) {
            sameDateMobileDrives2RBCRequested += sameDateDrive.totalEquipmentRequested || 0;
          }
        }
      });
      const noOf2RBCRequested = drive.totalEquipmentRequested || 0;

      result.data = {
        operationalLimit: isNullOrEmpty(operationalLimit) ? '∞' : operationalLimit,
        noOf2RBCRequested,
      }
      result.violated = noOf2RBCRequested > 0 && !isNullOrEmpty(operationalLimit) && sameDateMobileDrives2RBCRequested + noOf2RBCRequested > operationalLimit;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.x2RBC_LIMIT);
      return result;
    }

    const validateDOTLimit = (drive, {
      driveLimits = [],
      sameDateDrives = []
    }) => {
      let result = {
        contention: DRIVE_CONTENTION.DOT_LIMIT,
        violated: false,
        passed: true,
        data: null
      }

      if (this.isFixedSiteDrive(drive)) {
        return result;
      }

      const operationalLimit = this.findDriveLimitByDay(drive.driveDate, driveLimits, OPERATION_DRIVE_LIMIT_TYPE.DOT_LIMIT);
      let sameDateMobileDrivesDOTAllocated = 0;
      sameDateDrives.forEach((sameDateDrive) => {
        if (([DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(sameDateDrive.status))) {
          if (!this.isFixedSiteDrive(sameDateDrive)) {
          sameDateMobileDrivesDOTAllocated += sameDateDrive.noOfAllocatedDOTVehicles || 0;
          }
        }
      });
      
      const { assignedVehicles } = this.getCurrentAssignedVehicles(drive);
      const noOfDOTRequested = assignedVehicles?.filter((vehicle) => vehicle.DOT)?.length || 0;

      result.data = {
        operationalLimit: isNullOrEmpty(operationalLimit) ? '∞' : operationalLimit,
        noOfDOTRequested,
      }

      result.violated = noOfDOTRequested > 0 && !isNullOrEmpty(operationalLimit) && sameDateMobileDrivesDOTAllocated + noOfDOTRequested > operationalLimit;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.DOT_LIMIT);
      return result;
    }

    const validateCDLLimit = (drive, {
      driveLimits = [],
      sameDateDrives = []
    }) => {
      let result = {
        contention: DRIVE_CONTENTION.CDL_LIMIT,
        violated: false,
        passed: true,
        data: null
      }

      if (this.isFixedSiteDrive(drive)) {
        return result;
      }

      const operationalLimit = this.findDriveLimitByDay(drive.driveDate, driveLimits, OPERATION_DRIVE_LIMIT_TYPE.CDL_LIMIT);
      let sameDateMobileDrivesCDLAllocated = 0;
      sameDateDrives.forEach((sameDateDrive) => {
        if (([DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(sameDateDrive.status))) {
          if (!this.isFixedSiteDrive(sameDateDrive)) {
          sameDateMobileDrivesCDLAllocated += sameDateDrive.noOfAllocatedCDLVehicles || 0;
          }
        }
      });

      const { assignedVehicles } = this.getCurrentAssignedVehicles(drive);
      const noOfCDLRequested = assignedVehicles?.filter((vehicle) => vehicle.CDL)?.length || 0;

      result.data = {
        operationalLimit: isNullOrEmpty(operationalLimit) ? '∞' : operationalLimit,
        noOfCDLRequested,
      }
      result.violated = noOfCDLRequested > 0 && !isNullOrEmpty(operationalLimit) && sameDateMobileDrivesCDLAllocated + noOfCDLRequested > operationalLimit;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.CDL_LIMIT);
      return result;
    }

    const validateOperationalHours = (drive, {
      timezoneSidId
    }) => {
      // Operational Drive Hours
      let result = {
        contention: DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS,
        violated: false,
        passed: true,
        data: null
      }

      const minimumDriveStartTime = drive.collectionOperation.minimumDriveStartTime;
      const maximumDriveEndTime = drive.collectionOperation.maximumDriveEndTime;
      const minimumDriveStartDateTime = minimumDriveStartTime ? this.newDateTime(drive.driveDate, minimumDriveStartTime, timezoneSidId) : null;
      const maximumDriveEndDateTime = maximumDriveEndTime ? this.newDateTime(drive.driveDate, maximumDriveEndTime, timezoneSidId) : null;
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

      result.data = {
        minShiftStart: drive.minShiftStart,
        maxShiftEnd: drive.maxShiftEnd,
        operationalHoursStart: minimumDriveStartTime,
        operationalHoursEnd: maximumDriveEndTime
      }
      result.violated = isOutOfOperationalHours;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS);
      return result;
    }

    const validateLackingEquipments = (drive) => {
      // Lacking of Equipments
      let result = {
        contention: DRIVE_CONTENTION.LACKING_EQUIPMENT,
        violated: false,
        passed: true,
        data: null
      }

      let equipmentJob = null;
      if (drive.driveShifts && drive.driveShifts.length) {
        equipmentJob = (drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
      }

      let quantityAssigned = 0;
      let quantiyNeeded = 0;
      if(equipmentJob) {
        quantityAssigned = (equipmentJob.jobAllocations || []).filter(jobAllocation => {
          return jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED;
        }).length;
        quantiyNeeded = this.getJobQuantity(equipmentJob);
      }
      
      result.data = {
        quantityNeeded: quantiyNeeded,
        quantityAssigned: quantityAssigned
      }
      result.violated = quantityAssigned < quantiyNeeded;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.LACKING_EQUIPMENT);
      return result;
    }

    const validateWithin42Days = (drive, {
      backupDrive,
      timezoneSidId
    }) => {
      //Within 42 days
      let result = {
        contention: DRIVE_CONTENTION.WITHIN_42_DAYS,
        violated: false,
        passed: true,
        data: null
      }

      const isDriveStatusMovedToConfirmed = backupDrive && backupDrive.status !== DRIVE_STATUS.CONFIRMED && drive.status === DRIVE_STATUS.CONFIRMED;

      let submissionDate = DateTime.fromObject({
        zone: timezoneSidId
      }).toISODate();
      let driveDate = drive.driveDate;
      let diff = DateTime.fromISO(driveDate).diff(DateTime.fromISO(submissionDate), 'days').days;
      let within42Days = diff <= 42;
      
      result.data = {
        diff: diff
      }
      result.violated = !isDriveStatusMovedToConfirmed && within42Days;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.WITHIN_42_DAYS);
      return result;
    }
    
    const validateConfirmWithin42Days = (drive, {
      backupDrive,
      timezoneSidId
    }) => {
      //Within 42 days
      let result = {
        contention: DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS,
        violated: false,
        passed: true,
        data: null
      }

      const isDriveStatusMovedToConfirmed = backupDrive && backupDrive.status !== DRIVE_STATUS.CONFIRMED && drive.status === DRIVE_STATUS.CONFIRMED;

      let submissionDate = DateTime.fromObject({
        zone: timezoneSidId
      }).toISODate();
      let driveDate = drive.driveDate;
      let diff = DateTime.fromISO(driveDate).diff(DateTime.fromISO(submissionDate), 'days').days;
      let within42Days = diff <= 42;
      
      result.data = {
        diff: diff
      }
      result.violated = isDriveStatusMovedToConfirmed && within42Days;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS);
      return result;
    }

    const validateIsPathOfLinkedDrive = (drive, {
      backupDrive
    }) => {
      //Part of Linked Drive
      let result = {
        contention: DRIVE_CONTENTION.PART_OF_LINKED_DRIVE,
        violated: false,
        passed: true,
        data: null
      }

      const isDriveDateChanged = !backupDrive || backupDrive.driveDate !== drive.driveDate;
      const totalStaffRequestedChanged = !backupDrive || backupDrive.totalStaffRequested !== drive.totalStaffRequested;
      const totalVehicleRequestedChanged = !backupDrive || backupDrive.totalVehicleRequested !== drive.totalVehicleRequested;
      const totalEquipmentRequestedChanged = !backupDrive || backupDrive.totalEquipmentRequested !== drive.totalEquipmentRequested;
      const isPartOfLinkedDrive = this.isDriveInPathOfLinkedDrive(backupDrive);
      result.data = {}
      result.violated = (
        isDriveDateChanged || 
        totalStaffRequestedChanged || 
        totalVehicleRequestedChanged || 
        totalEquipmentRequestedChanged
      ) && isPartOfLinkedDrive;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.PART_OF_LINKED_DRIVE);
      return result;
    }

    const validateIsMultiShiftDrive = (drive) => {
      let result = {
        contention: DRIVE_CONTENTION.MULTI_SHIFT_DRIVE,
        violated: false,
        passed: true,
        data: null
      }

      const isMultiShiftDrive = drive.driveShifts.length > 1;
      result.data = {
        numberOfDriveShifts: drive.driveShifts.length
      };
      result.violated = isMultiShiftDrive;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.MULTI_SHIFT_DRIVE);
      return result;
    }

    const validateInsufficientResources = (drive, {
      staffingConstraints = [], 
      sameDateDrives = [], 
      sameDateActivities = []
    }) => {
      // Insufficient Resources
      let result = {
        contention: DRIVE_CONTENTION.INSUFFICIENT_RESOURCES,
        violated: false,
        passed: true,
        data: null
      }

      let sameDateDrivesStaffRequested = 0;
      let sameDateNceStaffRequested = 0;

      let totalStaffRequested = 0;
      drive.driveShifts.forEach((driveShift) => {
        const jobs = this.getDriveShiftJobs(driveShift, {
          excludeManuallyCreatedFromStaffingModal: true
        })
        jobs.forEach((job) => {
          if (job.resourceRole) {
            totalStaffRequested += (job.quantity || 0);
          }
        });
      });

      sameDateDrives.forEach((sameDateDrive) => {
        if (([DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(sameDateDrive.status))) {
          if (this.isFixedSiteDrive(drive) === this.isFixedSiteDrive(sameDateDrive)) {
            sameDateDrivesStaffRequested += sameDateDrive.totalStaffRequested || 0;
          }
        }
      });
      sameDateActivities.forEach((sameDateActivity) => {
        if(this.isFixedSiteDrive(drive)) {
          sameDateNceStaffRequested += sameDateActivity.fixedSiteStaffQuantity || 0;
        } else {
          sameDateNceStaffRequested += sameDateActivity.mobileStaffQuantity || 0;
        }
      });

      let totalStaffConstraints = 0;
      if (staffingConstraints && staffingConstraints.length) {
        let staffingConstraint = staffingConstraints[0];
        totalStaffConstraints = staffingConstraint.totalStaffConstraints || 0;
      }

      result.data = {
        staffRequested: totalStaffRequested,
        staffAllocated: drive.staffAllocated || 0,
        staffAvailable: totalStaffConstraints - sameDateDrivesStaffRequested - sameDateNceStaffRequested 
      }
      result.violated = sameDateDrivesStaffRequested + sameDateNceStaffRequested + totalStaffRequested > totalStaffConstraints;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.INSUFFICIENT_RESOURCES);
      return result;
    }

    const validateExcessStaffCapacity = (drive,masterData) => {
      // Excess Staff Capacity
      let result = {
        contention: DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY,
        violated: false,
        passed: true,
        data: null
      }
      
      result.data = {
        plannedCapacity: drive.staffCapacity || 0,
        projRegisteredDonor: drive.projectedRegisteredDonors || 0,
        excessStaff: drive.excessStaffCapacity 
      }
      result.violated = drive.excessStaffCapacity >= masterData.adminSetting.excessStaffCapacityThreshold;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY);
      return result;
    }
   
    const validateLackingVehicles = (drive) => {
      //validate lacking of vehicles
      let result = {
        contention: DRIVE_CONTENTION.LACKING_VEHICLE,
        violated: false,
        passed: true,
        data: null
      }

      let { assignedVehicles, totalCurrentAssignedVehiclesCapacity } = this.getCurrentAssignedVehicles(drive);
      let maxRegisteredDonors = this.getMaxDonorsScheduledOfDriveShifts(drive);
      
      result.data = {
        capacityNeeded: maxRegisteredDonors,
        capacityAssigned: totalCurrentAssignedVehiclesCapacity,
        quantityAssigned: assignedVehicles.length
      }
      result.violated = !drive.doNotUseVehicle && totalCurrentAssignedVehiclesCapacity < maxRegisteredDonors;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.LACKING_VEHICLE);
      return result;
    }      

    const validateDualRoleRemoval = (drive, {
      backupDrive,
      timezoneSidId
    }) => {
      //Dual Role Removal
      let result = {
        contention: DRIVE_CONTENTION.DUAL_ROLE_REMOVAL,
        violated: false,
        passed: true,
        data: null
      }

      /*let mapDualRoleJobsRemovedByDriveShiftId = {}; 
      backupDrive.driveShifts.forEach((backupDriveShift, driveShiftIndex) => {
        const currentDriveShift = drive.driveShifts[driveShiftIndex];
        if(!currentDriveShift) return;

        const beforeDualRoleJobs = backupDriveShift.jobs.filter(job => {
          return job.dualRole;
        });
        const afterDualRoleJobs = currentDriveShift.jobs.filter(job => {
          return job.dualRole;
        });;

        const dualRoleJobsRemoved = beforeDualRoleJobs.filter(beforeJob => {
          const stillExisted = !!afterDualRoleJobs.find(afterJob => {
            return this.isJobsSameRoles(afterJob, beforeJob);
          });
          return !stillExisted;
        });

        if(dualRoleJobsRemoved.length > 0) {
          mapDualRoleJobsRemovedByDriveShiftId[driveShiftIndex] = {
            driveShift: currentDriveShift,
            dualRoleJobsRemoved,
            newJobs: currentDriveShift.jobs.filter(job => {
              return dualRoleJobsRemoved.find(removedJob => {
                return removedJob.resourceRole === job.resourceRole || removedJob.dualRole === job.resourceRole;
              });
            })
          }
        }
      });

      const hasDualRoleJobsRemoved = !!Object.keys(mapDualRoleJobsRemovedByDriveShiftId).find(driveShiftId => {
        const dualRoleJobsRemovedData = mapDualRoleJobsRemovedByDriveShiftId[driveShiftId];
        return dualRoleJobsRemovedData.dualRoleJobsRemoved?.length > 0;
      });

      result.data = {
        mapDualRoleJobsRemovedByDriveShiftId,
      }
      result.violated = hasDualRoleJobsRemoved;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.DUAL_ROLE_REMOVAL);*/
      return result;
    }

    const validateStaffingComplementChanged = (drive, {
      backupDrive,
    }) => {
      let result = {
        contention: DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED,
        violated: false,
        passed: true,
        data: null
      }

      const { newJobs, changedJobs, deletedJobs } = this.getDriveSystemGeneratedStaffingComplementChanges(drive, backupDrive);
      const staffingComplementChanged = newJobs.length || deletedJobs.length || changedJobs.length;

      let mapSystemGeneratedRoleJobsRemovedByDriveShiftId = {}; 
      backupDrive.driveShifts.forEach((backupDriveShift, driveShiftIndex) => {
        mapSystemGeneratedRoleJobsRemovedByDriveShiftId[driveShiftIndex] = {
          ...mapSystemGeneratedRoleJobsRemovedByDriveShiftId[driveShiftIndex],
          backupDriveShift: backupDriveShift,
          backupDrive: backupDrive,
          backupJobs: backupDriveShift.jobs?.filter(job => {
            return this.isSystemRole(job, backupDrive) && job.resourceRole;
          })
        }
      });

      drive.driveShifts.forEach((driveShift, driveShiftIndex) => {
        mapSystemGeneratedRoleJobsRemovedByDriveShiftId[driveShiftIndex] = {
          ...mapSystemGeneratedRoleJobsRemovedByDriveShiftId[driveShiftIndex],
          driveShift: driveShift,
 		      drive: drive,
          newJobs: driveShift.jobs?.filter(job => {
            return this.isSystemRole(job, drive) && job.resourceRole;
          })
        }
      });

      result.data = {
        newJobs,
        changedJobs,
        deletedJobs,
        mapSystemGeneratedRoleJobsRemovedByDriveShiftId
      }

      result.violated = staffingComplementChanged;
      result.passed = !result.violated;
      return result;
    }

    const validateCOChangeCrossRegions = (drive, {
      backupDrive,
      territoryCollectionOperations
    }) => {
      //Collection Operation Change cross regions
      let result = {
        contention: DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS,
        violated: false,
        passed: true,
        data: {}
      }

      const backupDriveRegionId = backupDrive.arcRegionId;
      const driveRegionId = this.getDriveTerritory(drive, territoryCollectionOperations)?.regionId;
      const isCOChangedCrossRegions = !!this.isDriveInPathOfLinkedDrive(drive) && backupDrive && backupDrive.collectionOperationId !== drive.collectionOperationId && backupDriveRegionId !== driveRegionId;
      result.violated = isCOChangedCrossRegions;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS);
      return result;
    }

    const validateAssetsNotSharedWithNewCO = (drive, {
      backupDrive,
      territoryCollectionOperations,
      availableAssetsInfo
    }) => {
      //Assets are not shared with new Collection Operation
      let result = {
        contention: DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO,
        violated: false,
        passed: true,
        data: {}
      }

      let availableButNotSharedAssetIds = availableAssetsInfo?.availableButNotSharedAssetIds || [];
      let currentAssignedAssets = this.getCurrentAssignedAssets(drive);
      const backupDriveRegionId = backupDrive.arcRegionId;
      const driveRegionId = this.getDriveTerritory(drive, territoryCollectionOperations)?.regionId;
      const hasAssignedAssetNotSharedWithNewCO = currentAssignedAssets.some(assignedAsset => availableButNotSharedAssetIds.includes(assignedAsset.id));
      result.violated = !!this.isDriveInPathOfLinkedDrive(drive) 
                        && backupDrive && backupDrive.collectionOperationId !== drive.collectionOperationId && backupDriveRegionId === driveRegionId
                        && hasAssignedAssetNotSharedWithNewCO;;
      result.passed = !result.violated || isContentionOverrided(drive, DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO);
      return result;
    }

    let contentions = [];
    let pendingActionReasonCodes = [];
    let allPassed = true;

    const contentionValidateFnMap = {
      [DRIVE_CONTENTION.INSUFFICIENT_RESOURCES]: validateInsufficientResources,
      [DRIVE_CONTENTION.LACKING_VEHICLE]: validateLackingVehicles,
      [DRIVE_CONTENTION.LACKING_EQUIPMENT]: validateLackingEquipments,
      [DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS]: validateOperationalHours,
      [DRIVE_CONTENTION.DRIVE_LIMIT]: validateDriveLimit,
      [DRIVE_CONTENTION.x2RBC_LIMIT]: validate2RBCLimit,
      [DRIVE_CONTENTION.DOT_LIMIT]: validateDOTLimit,
      [DRIVE_CONTENTION.CDL_LIMIT]: validateCDLLimit,
      [DRIVE_CONTENTION.WITHIN_42_DAYS]: validateWithin42Days,
      [DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS]: validateConfirmWithin42Days,
      [DRIVE_CONTENTION.PART_OF_LINKED_DRIVE]: validateIsPathOfLinkedDrive,
      [DRIVE_CONTENTION.MULTI_SHIFT_DRIVE]: validateIsMultiShiftDrive,
      [DRIVE_CONTENTION.DUAL_ROLE_REMOVAL]: validateDualRoleRemoval,
      [DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED]: validateStaffingComplementChanged,
      [DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS]: validateCOChangeCrossRegions,
      [DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO]: validateAssetsNotSharedWithNewCO,
      [DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY]: validateExcessStaffCapacity
    }
    let validateFns = orderBy(contentionsToValidate,(contention) => {
      return Object.keys(contentionValidateFnMap).indexOf(contention);
    }, 'asc').map(contention => {
      return contentionValidateFnMap[contention];
    });

    validateFns.forEach(validateFn => {
      const {
        contention,
        violated,
        passed,
        data
      } = validateFn(drive, masterData);
      
      if(!passed) {
        pendingActionReasonCodes.push(contention);
      }
      
      if(violated || 
        contention === DRIVE_CONTENTION.LACKING_EQUIPMENT || 
        (this.isMobileDrive(drive) && contention === DRIVE_CONTENTION.LACKING_VEHICLE) || 
        originalContentions.includes(contention)
      ) {
        contentions.push({
          contention,
          violated,
          passed,
          data
        });
      }

      if(!passed) {
        allPassed = false;
      }
    })

    return {
      passed: allPassed,
      pendingActionReasonCodes: pendingActionReasonCodes,
      contentions: contentions
    }
  }

  updateJobAllocations = (job, newJobAllocations = []) => {
    if(!job) return null;

    if (!job.jobAllocations) {
      job.jobAllocations = [];
    }

    job.jobAllocations.forEach((jobAllocation) => {
      let newAllocation = newJobAllocations.find(ja => ja.resourceId === jobAllocation.resourceId);
      if (!newAllocation) {
        jobAllocation.status = JOB_ALLOCATION_STATUS.DELETED;
      }
    });

    newJobAllocations.forEach((ja) => {
      let existingJobAllocation = job.jobAllocations.find(jobAllocation => jobAllocation.resourceId === ja.resourceId);
      if (!existingJobAllocation) {
        job.jobAllocations.push(ja)
      }
    });

    return job;
  }

  isDriveSubmittedForCancelApproval(drive) {
    if(!drive) return false;

    const validApprovalStatuses = [
      DRIVE_APPROVAL_STATUS.SUBMITTED,
      DRIVE_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL,
      DRIVE_APPROVAL_STATUS.WAITING_FOR_APS_APPROVAL,
      DRIVE_APPROVAL_STATUS.APS_WAITING_FOR_DRD_FEEDBACK,
      DRIVE_APPROVAL_STATUS.DM_WAITING_FOR_DRD_FEEDBACK
    ];

    if (!drive.pendingAction || !validApprovalStatuses.includes(drive.approvalStatus)) return false;

    return drive.pendingAction === PENDING_ACTION.CANCEL_IN_PROCESS;
  }

  isDriveSubmittedForSubmissionApproval(drive) {
    if(!drive) return false;

    const validApprovalStatuses = [
      DRIVE_APPROVAL_STATUS.SUBMITTED,
      DRIVE_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL,
      DRIVE_APPROVAL_STATUS.WAITING_FOR_APS_APPROVAL,
      DRIVE_APPROVAL_STATUS.APS_WAITING_FOR_DRD_FEEDBACK,
      DRIVE_APPROVAL_STATUS.DM_WAITING_FOR_DRD_FEEDBACK
    ];

    if (!drive.pendingAction || !validApprovalStatuses.includes(drive.approvalStatus)) return false;

    return drive.pendingAction === PENDING_ACTION.DRIVE_SUBMISSION;
  }
  
  isDriverJob(job) {
    if(!job) return false;
    const isNotCdlDriverJob = job.id && !job.id.startsWith('drivercdl');
    const isNotDotDriverJob = job.id && !job.id.startsWith('driverdot');
    return isNotCdlDriverJob && isNotDotDriverJob && (job.resourceRole === 'Driver' || job.dualRole === 'Driver')
  }

  isDriverSupport(job) {
    if(!job) return false;
    return job.resourceRole === 'Driver Support';
  }

  /*
    HRP-10428
    Any drive up to 3 hours would default to 1 round,
    Any drive over 3 up to 6 hours would default to 2 rounds
    Any drive over 6 hours up to 9 would default to 3 rounds
    Any drive over 9 up to 12 default to 4 rounds
    Any drive over 12 hours default to 5 rounds
  */
  calculatePlateletRounds(drive, masterData) {
    if (!drive.driveDate || !drive.startTime || !drive.endTime) return 0;
    const driveDrawHoursInMinutes = this.calculateDrawHoursInMinutes(drive, masterData);
    
    let totalRounds = 0;
    if(driveDrawHoursInMinutes <= 3 * 60) {
      totalRounds = 1;
    } else if(driveDrawHoursInMinutes > 3 * 60 && driveDrawHoursInMinutes <= 6 * 60) {
      totalRounds = 2;
    } else if (driveDrawHoursInMinutes > 6 * 60 && driveDrawHoursInMinutes <= 9 * 60) {
      totalRounds = 3;
    } else if (driveDrawHoursInMinutes > 9 * 60 && driveDrawHoursInMinutes <= 12 * 60) {
      totalRounds = 4;
    } else {
      totalRounds = 5;
    }

    return totalRounds;
  }

  isSystemRole(job, drive) {
    if(!job) return false;
    // if(job.isManuallyCreated) return false;

    if (job.resourceRole) {
      if(this.isMobileDrive(drive)) {
        return ['Driver', 'Driver Support', '2RBC', 'Drive Lead', 'Team Supervisor', 'Charge', 'VP/HH'].includes(job.resourceRole);
      } else if(this.isFixedSiteDrive(drive)) {
        return ['Apheresis Charge', 'Apheresis'].includes(job.resourceRole);
      } else if(this.isWbFixedSiteDrive(drive)) {
        return ['2RBC', 'Drive Lead', 'Team Supervisor', 'Charge', 'VP/HH'].includes(job.resourceRole);
      }
    } else if (job.assetType) {
      return true;
    } else if (job.volunteerRole) { 
      if(this.isMobileDrive(drive)) {
        return false;
      } else {
        return ['Donor Ambassador'].includes(job.volunteerRole);
      }
    }

    return false;
  }

  isManuallyCreatedJob(job, drive) {
    //cannot use isManuallyCreated because data migration doesn't track this field. 
    //workaround: roles that didn't generated by system is manually created
    if(!job) return false;
    
    if(job.isManuallyCreated) return true;
    return !this.isSystemRole(job, drive);
  }

  getDriveSystemGeneratedStaffingComplementChanges(currentDrive, backupDrive, {
    isDriveGettingRegenerated = false
  } = {}) {
    const mapResult = (job, backupJob, driveShift, driveShiftIndex, result) => {
      result.push({
        id: job.id,
        driveShiftKey: driveShift.key,
        driveShiftIndex: driveShiftIndex,
        driveShift: driveShift,
        resourceRole: job.resourceRole,
        dualRole: job.dualRole,
        quantity: job.quantity,
        systemQuantity: job.systemQuantity,
        backupJob: backupJob
      })
    };

    const result = {
      newJobs: [],
      changedJobs: [],
      deletedJobs: []
    };

    if(!currentDrive || !backupDrive) return result;

    currentDrive.driveShifts?.forEach((driveShift, driveShiftIndex) => {
      driveShift.jobs?.forEach(job => {
        const isSystemGenerated = this.isSystemRole(job, currentDrive);
        if(!isSystemGenerated || !job.resourceRole) return;

        const backupDriveShift = backupDrive.driveShifts?.[driveShiftIndex];
        if(!backupDriveShift) {
          mapResult(job, null, driveShift, driveShiftIndex, result.newJobs);
          return;
        }

        const backupJob = backupDriveShift.jobs?.find(_job => {
          const sameRole = this.isJobsSameRoles(_job, job);
          return sameRole;
        })

        if(!backupJob) {
          if(job.quantity > 0 || job.vphhQuantity > 0 || job.aptQuantity > 0) {
            mapResult(job, null, driveShift, driveShiftIndex, result.newJobs);
          }
        } else {
          if(job.resourceRole === 'VP/HH') {
            if((!job.aptQuantity && !!backupJob.aptQuantity) ||
              (!!job.aptQuantity && !backupJob.aptQuantity) ||
              (!!job.aptQuantity && !!backupJob.aptQuantity && job.aptQuantity !== backupJob.aptQuantity)) {
              mapResult(job, backupJob, driveShift, driveShiftIndex, result.changedJobs);
              return;
            }

            const currentJobVphhSystemQuantity = Math.max(job.systemQuantity - (currentDrive.aptQuantity || 0), 0);
            const backupJobVphhSystemQuantity = Math.max(backupJob.systemQuantity - (backupDrive.aptQuantity || 0), 0);
            if(currentJobVphhSystemQuantity !== backupJobVphhSystemQuantity || isDriveGettingRegenerated) {
              mapResult(job, backupJob, driveShift, driveShiftIndex, result.changedJobs);
            }
          } else {
            if(job.systemQuantity !== backupJob.systemQuantity || isDriveGettingRegenerated) {
              mapResult(job, backupJob, driveShift, driveShiftIndex, result.changedJobs);
            }
          }
        }
      }); 
    })

    backupDrive.driveShifts?.forEach((backupDriveShift, backupDriveShiftIndex) => {
      backupDriveShift.jobs?.forEach(backupJob => {
        const isSystemGenerated = this.isSystemRole(backupJob, backupDrive);
        if(!isSystemGenerated || !backupJob.resourceRole) return;

        const driveShift = currentDrive.driveShifts?.[backupDriveShiftIndex];
        if(!driveShift) {
          mapResult(backupJob, null, backupDriveShift, backupDriveShiftIndex, result.deletedJobs);
          return;
        }

        const job = driveShift.jobs?.find(_job => {
          const sameRole = this.isJobsSameRoles(_job, backupJob);
          return sameRole;
        })

        if(!job) {
          mapResult(backupJob, null, backupDriveShift, backupDriveShiftIndex, result.deletedJobs);
        }
      }); 
    })

    return result; 
  }

  getJobAllocations(job) {
    if(!job || !job.jobAllocations) return [];
    return job.jobAllocations.filter(jobAllocation => jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED);
  }

  isJobBelongToDrivingRolesGroup(job, {
    resourceRoleGroups
  }) {
    return slwcAvailator.isJobBelongToDrivingRolesGroup(job, {
      resourceRoleGroups
    })
  }

  isJobRequireTravelTimes(isTemporaryCO, job, drive, {
    resourceRoleGroups
  }) {
    return slwcAvailator.isJobRequireTravelTimes(isTemporaryCO, job, drive, {
      resourceRoleGroups
    });
  }

  calculateJATimesWithTravel(jobAllocation, drive, {
    timezoneSidId,
    resourceRoleGroups
  }) {
    const { isRelocatedResource, job } = jobAllocation;
    let jaStartWithTravelTime = isDate(job.start) ? job.start.toISOString() : job.start;
    let jaEndWithTravelTime = isDate(job.finish) ? job.finish.toISOString() : job.finish;

    if(!job.resourceRole) {
      return {
        start: jaStartWithTravelTime,
        end: jaEndWithTravelTime
      }
    }
    
    const requiresTravelTime = this.isJobRequireTravelTimes( isRelocatedResource, job, drive, {
      resourceRoleGroups
    })
    const travelTimeTo = isNullOrEmpty(jobAllocation.travelTimeTo) ? job.travelTime : jobAllocation.travelTimeTo;
    jaStartWithTravelTime = DateTime.fromISO(jaStartWithTravelTime, { zone: timezoneSidId }).minus({
      minute: requiresTravelTime ? (travelTimeTo - (job.travelTime || 0)) : travelTimeTo
    }).toUTC().toISO();

    const travelTimeBack = isNullOrEmpty(jobAllocation.travelTimeBack) ? job.travelTime2 : jobAllocation.travelTimeBack;
    jaEndWithTravelTime = DateTime.fromISO(jaEndWithTravelTime, { zone: timezoneSidId }).plus({
      minute: requiresTravelTime ? (travelTimeBack - (job.travelTime2 || 0)) : travelTimeBack
    }).toUTC().toISO();

    return {
      start: jaStartWithTravelTime,
      end: jaEndWithTravelTime
    }
  }

  calculateRequestedStaff(mappedDriveData, mappedActivityData, collectionOperationId, driveTypes, dateIso) {
    const KEY_SEPERATOR = "__";

    const matchedDrives = driveTypes.reduce(
      (accumulate, driveType) => [
        ...accumulate,
        ...(mappedDriveData?.[
          `${collectionOperationId}${KEY_SEPERATOR}${driveType}${KEY_SEPERATOR}${dateIso}`
        ] ?? [])
      ],
      []
    );

    const matchedActivities = mappedActivityData?.[
      `${collectionOperationId}${KEY_SEPERATOR}${dateIso}`
    ] ?? [];

    let totalFixedSiteStaffRequested = 0;
    let totalMobileStaffRequested = 0;
    let totalFixedSiteStaffNCERequested = 0;
    let totalMobileStaffNCERequested = 0;

    if (matchedDrives.length) {
      matchedDrives.forEach((drive) => {
        if (this.isFixedSiteDrive(drive)) {
          totalFixedSiteStaffRequested += drive.totalStaffRequested;
        } else {
          totalMobileStaffRequested += drive.totalStaffRequested;
        }
      });
    }

    if(matchedActivities?.length) {
      matchedActivities.forEach((activity) => {
        if (driveTypes.includes(DRIVE_TYPE.FIXED_SITE)) {
          totalFixedSiteStaffNCERequested += activity.fixedSiteStaffQuantity || 0;
        }
        if (driveTypes.includes(DRIVE_TYPE.MOBILE)) {
          totalMobileStaffNCERequested += activity.mobileStaffQuantity || 0;
        }
      });
    }
   
    return {
      totalStaffRequested:
        totalFixedSiteStaffRequested +
        totalMobileStaffRequested +
        totalFixedSiteStaffNCERequested +
        totalMobileStaffNCERequested,
      totalFixedSiteStaffRequested:
        totalFixedSiteStaffRequested + totalFixedSiteStaffNCERequested,
      totalMobileStaffRequested:
        totalMobileStaffRequested + totalMobileStaffNCERequested
    };
  }

  getSlotDurationByType = (slotType) => {
    if(slotType === 'Platelet') return 3 * 60;
    if(slotType === 'Plasma') return 90;
    if(slotType === 'Whole Blood') return 15;
    if(slotType === '2RBC') return 60;
    return 15;
  }

  findJob = (job, allJobs = []) => {
    if(!job || !allJobs.length) return null;

    let jobFound = null;
    if (job.resourceRole) {
      if (job.procedureType) {
        jobFound = allJobs.find(item => this.isJobsSameRoles(item, job) && item.procedureType === job.procedureType);
      }
      else {
        jobFound = allJobs.find(item => this.isJobsSameRoles(item, job));
      }
    } else if (job.assetType) {
      if (job.assetType === ASSET_TYPE.EQUIPMENT) {
        jobFound = allJobs.find(item => item.assetType === job.assetType && item.equipmentSubtype === job.equipmentSubtype);
      } else {
        jobFound = allJobs.find(item => item.assetType === job.assetType);
      }
    } else if (job.volunteerRole) { 
      jobFound = allJobs.find(item => item.volunteerRole === job.volunteerRole);
    }

    return jobFound;
  }

  getMaxDOTAndCDLForDrive = (drive, {
    driveLimits = [],
    sameDateDrives = []
  }) => {
    let maxDOT = Number.MAX_SAFE_INTEGER;
    let maxCDL = Number.MAX_SAFE_INTEGER;
    if(!drive || !driveLimits.length) {
      return {
        maxDOT,
        maxCDL
      }
    }

    const { driveDate } = drive;  
    const operationalDOTLimit = this.findDriveLimitByDay(driveDate, driveLimits, OPERATION_DRIVE_LIMIT_TYPE.DOT_LIMIT);
    const operationalCDLLimit = this.findDriveLimitByDay(driveDate, driveLimits, OPERATION_DRIVE_LIMIT_TYPE.CDL_LIMIT);

    let sameDateMobileDrivesDOTAllocated = 0;
    let sameDateMobileDrivesCDLAllocated = 0;
    sameDateDrives.forEach((sameDateDrive) => {
      if (([DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(sameDateDrive.status))) {
        if (!this.isFixedSiteDrive(sameDateDrive)) {
          sameDateMobileDrivesDOTAllocated += sameDateDrive.noOfAllocatedDOTVehicles || 0;
          sameDateMobileDrivesCDLAllocated += sameDateDrive.noOfAllocatedCDLVehicles || 0;
        }
      }
    });

    if(!isNullOrEmpty(operationalDOTLimit)) {
      maxDOT = Math.max(operationalDOTLimit - sameDateMobileDrivesDOTAllocated, 0);
    }

    if(!isNullOrEmpty(operationalCDLLimit)) {
      maxCDL = Math.max(operationalCDLLimit - sameDateMobileDrivesCDLAllocated, 0);
    }

    return {
      maxDOT,
      maxCDL
    }
  }
  
  getDriveShiftJobs(driveShift, {
    excludeManuallyCreatedFromStaffingModal = false
  } = {}) {
    if(!driveShift || !driveShift.jobs) return [];

    return driveShift.jobs.filter(job => {
      if(excludeManuallyCreatedFromStaffingModal) {
        return !job.isManuallyCreated || job.manuallyCreatedFrom !== MANUALLY_CREATED_FROM.STAFFING_MODAL;
      }

      return true;
    });
  }

  getDrivePlateletRounds(drive) {
    if(!drive || !drive.driveShiftsMetadata) return null;

    return (drive.driveShiftsMetadata.driveShifts || []).reduce((result, item) => {
      return result + (item.numberOfRounds || 0)
    }, 0);
  }

  getMatchedSiteCOForDrive(drive) {
    if (!drive || !drive.siteCollectionOperation || !drive.driveSite) return null;

    return drive.driveSite.siteCollectionOperations.find(item => item.id === drive.siteCollectionOperation.id);
  }

  /** Date Time Utils **/
  dateJSToTimeIso(
    dateJS,
    timezoneSidId
  ) {
    if (!dateJS || !timezoneSidId) return null;
    return DateTime.fromJSDate(dateJS, {
      zone: timezoneSidId
    }).toFormat('HH:mm:ss.000');
  }

  newDateTime(dateIso, timeIso, timezoneSidId) {
    if (!dateIso || !timeIso || !timezoneSidId) return null;

    let dateTimeIso = dateIso + 'T' + timeIso;
    let dateTimeObj = DateTime.fromISO(dateTimeIso, {
      zone: timezoneSidId
    });

    return dateTimeObj.toJSDate();
  }

  countDriveShiftStaffs(drive, driveShift, masterData, ignoreLunchBreak = false) {
    const driveShiftStaffs = Math.floor(this.countDriveStaffs([
      'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'
    ], drive, driveShift.driveShiftMetadata, 
      new Map()
        .set(driveShift.driveShiftMetadata.key, this.getDriveShiftResourceQuantity(driveShift))
    , masterData, ignoreLunchBreak));

    return driveShiftStaffs;
  }

  calculateDriveAverageStaffCapacity(drive, masterData) {
    let driveStaffCount = 0;
    if (masterData && masterData.staffingDecisionMatrix) {
      drive.driveShifts.forEach((driveShift) => {
        const driveShiftStaffCount = this.countDriveShiftStaffs(drive, driveShift, masterData);
        driveStaffCount += driveShiftStaffCount;
      });
    }
    if(drive.staffCapacity && drive.staffCapacity > 0 && driveStaffCount > 0) {
      let averageStaffCapacity = drive.staffCapacity / driveStaffCount;
      averageStaffCapacity = +drive.averageStaffCapacity.toFixed(1);
      return averageStaffCapacity;
    } else {
      return 0;
    }
  }

  calculateExcessStaffCapacity(drive) {
    if(drive.staffCapacity && drive.staffCapacity > 0 && drive.maxRoleCapacityWithDrawHours && drive.maxRoleCapacityWithDrawHours > 0) {
      if(drive.projectedRegisteredDonors) {
        return +((drive.staffCapacity - drive.projectedRegisteredDonors) / drive.maxRoleCapacityWithDrawHours).toFixed(1);
      } else {
        return +(drive.staffCapacity / drive.maxRoleCapacityWithDrawHours).toFixed(1);;
      }
    } else {
      return 0;
    }
  } 
  
  calculateDriveShiftMaxStaffCapacity (drive, driveShift, masterData, ignoreLunchBreak = false) {
    const driveShiftStaffCapacity = this.calculateMaximumStaffCapacity([
      'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'
    ], drive, driveShift.driveShiftMetadata, 
      new Map()
        .set(driveShift.driveShiftMetadata.key, this.getDriveShiftResourceQuantity(driveShift))
    , masterData, ignoreLunchBreak);

    return driveShiftStaffCapacity;
  }

  calculateDriveShiftDrawHours(driveShift, masterData, ignoreLunchBreak = false) {
    const drawHours = this.calculateDrawHours(driveShift.driveShiftMetadata, masterData, driveShift.driveShiftMetadata.lunchBreakSettings);
    return drawHours;
  }

  calculateDriveMaxRoleCapacity(drive, masterData) {
    let driveMaxStaffCapacity = 0;
    let driveMaxStaffCapacityWithDrawHours = 0;
    let totalDrawHours = 0;
    if (masterData && masterData.staffingDecisionMatrix) {
      drive.driveShifts.forEach((driveShift) => {
        const driveShiftMaxStaffCapacity = this.calculateDriveShiftMaxStaffCapacity(drive, driveShift, masterData);
        if(driveShiftMaxStaffCapacity && driveShiftMaxStaffCapacity > driveMaxStaffCapacity){
          driveMaxStaffCapacity = driveShiftMaxStaffCapacity;
        }
        const shiftDrawHours = this.calculateDriveShiftDrawHours(driveShift, masterData);
        if(shiftDrawHours){
          totalDrawHours = totalDrawHours + shiftDrawHours;
        }
      });
      if(totalDrawHours > 0){
        driveMaxStaffCapacityWithDrawHours = driveMaxStaffCapacity * totalDrawHours;
      }
    }

    return {
      maxRoleCapacity: +driveMaxStaffCapacity.toFixed(2),
      maxRoleCapacityWithDrawHours: +driveMaxStaffCapacityWithDrawHours.toFixed(2)
    }
  }

  checkResourceQuantityMapContainsRoles(resourceQuantityMap, roles = []) {
    if(!resourceQuantityMap) return false;
    if(!roles.length) return true;

    const validRoles = this.getValidRolesInResourceQuantityMap(resourceQuantityMap);
    const allRolesValid = roles.every(role => validRoles.includes(role));
    return allRolesValid;
  }

  checkResourceQuantityMapContainsAnyManuallyChangedDualRole(resourceQuantityMap) {
    if (!resourceQuantityMap) return false;

    let found = false;
    resourceQuantityMap.forEach((item, resourceRole) => {
        if (found) return; // Exit early if already found

        const quantityValid = resourceRole === 'VP/HH' ? item.vphhQuantity > 0 : item.quantity > 0;
        if (!quantityValid) return;

        if (item.isCreatedOrUpdatedViaDualRoleChange) {
            found = true;
        }
    });

    return found;
  }

  getValidRolesInResourceQuantityMap(resourceQuantityMap) {
    if(!resourceQuantityMap) return false;

    let validRoles = [];
    resourceQuantityMap.forEach((item, resourceRole) => {
      const quantityValid = resourceRole === 'VP/HH' ? item.vphhQuantity > 0 : item.quantity > 0;
      if(!quantityValid) return;

      validRoles.push(resourceRole);
    });

    return validRoles;
  }

  generateDualRoleJob = (job1, job2) => {
    const { quantity: quantity1 } = job1;
    const { quantity: quantity2 } = job2;
    
    const jobsToCreate = [];
    const jobsToUpdate = [];
    const jobsToDelete = [];

    if(quantity1 === quantity2) {
      jobsToUpdate.push({
        previousJob: job1,
        newJob: {
          ...job1,
          dualRole: job2.resourceRole,
          quantity: job1.quantity,
          backupJob: job1
        }
      })
      jobsToDelete.push({
        previousJob: job2
      });
      return {
        jobsToCreate,
        jobsToUpdate,
        jobsToDelete
      }
    }

    if(quantity1 < quantity2) {
      jobsToUpdate.push({
        previousJob: job1,
        newJob: {
          ...job1,
          dualRole: job2.resourceRole,
          quantity: job1.quantity
        }
      })
      jobsToUpdate.push({
        previousJob: job2,
        newJob: {
          ...job2,
          dualRole: '',
          quantity: job2.quantity - job1.quantity
        }
      })
    }

    if(quantity1 > quantity2) {
      jobsToUpdate.push({
        previousJob: job1,
        newJob: {
          ...job1,
          dualRole: job2.resourceRole,
          quantity: job2.quantity
        }
      })
      jobsToDelete.push({
        previousJob: job2
      })
      jobsToCreate.push({
        newJob: {
          ...job1,
          id: uniqueId('temp_job_'),
          key: generateUUID(),
          quantity: job1.quantity - job2.quantity,
          jobTags: []
        }
      })
    }

    return {
      jobsToCreate,
      jobsToUpdate,
      jobsToDelete
    }
  }
}

export {
  DriveHelper
}