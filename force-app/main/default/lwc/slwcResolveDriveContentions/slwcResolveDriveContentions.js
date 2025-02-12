import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { sObjectType, debugLogService, driveService, driveQueryModel, operationDriveLimitService, operationDriveLimitQueryModel, staffingConstraintService, staffingConstraintQueryModel, driveChangeRequestQueryModel, driveChangeRequestService, jobService, jobQueryModel } from 'c/dataService';
import { DRIVE_STATUS, DRIVE_CONTENTION, DRIVE_TYPE, DRIVE_CONTENTION_RESOLUTION, ASSET_TYPE, JOB_ALLOCATION_STATUS } from 'c/slwcConstants';
import { slwcDriveGeneratorHelper, DriveHelper, DriveFetch } from 'c/slwcDriveGenerator';
import { DateTime } from 'c/luxon';
import { getValueFromEvent } from 'c/slwcUtils';
import { remove, keyBy, cloneDeep, compact } from 'c/lodash';

const MODE = {
  DRIVE_SUBMISSION: 'driveSubmission',
  DRIVE_CHANGE_REQUEST: 'driveChangeRequest',
  UPDATE_DRIVE: 'updateDrive'
}

export default class SlwcResolveDriveContentions extends LightningElement {
  driveHelper = new DriveHelper();

  @api mode;
  @api recordId;
  @api isReadonly = false;
  @api driveGeneratorInstance = {
    drive: null,
    masterData: {
        driveTags: {
        accountTags: [],
        locationTags: []
        },
        isReadonly: false,
        lunchBreakSettings: [],
        resourceRoleGroups: null,
        roleTimeData: null,
        roleTimeDetailMap: null,
        roleTimeVarianceMap: {},
        sameDateActivities: [],
        sameDateDrives: [],
        staffingDecisionMatrix: null,
        timezoneSidId: null,
        vehicles: [],
        backupDriveShiftMap: {},
        adminSetting: {}
    },
    errorMessages: []
  };

  @track drive;
  @track driveChangeRequest;
  @track masterData = {};
  @track showSpinnerCount = 0;
  @track holdDrivesSummaryData = {};
  @track driveContentions = [];
  @track driveStaffingDetailsData = {};

  get driveContentionsGroup1() {
    return this.driveStaffingChangedContention ? [this.driveStaffingChangedContention] : [];
  }

  get driveContentionsGroup2() {
    return this.driveContentions.filter(item => item.contention !== DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED);
  }

  get showSpinner() {
    return this.showSpinnerCount > 0;
  }

  get allowToOpenDriveStaffing() {
    return true;
  }

  get showOpenDriveSchedulingBtn() {
    return this.mode !== MODE.UPDATE_DRIVE;
  }

  get vehicleAndDriverMismatchedWarning() {
    if(!this.drive || !this.drive.driveShifts || !this.drive.driveShifts.length) return null;

    const vehicleJob = this.drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.VEHICLE);
    const numberOfAllocatedVehicles = (vehicleJob.jobAllocations || []).filter(jobAllocation => jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED).length;

    const driveShiftsNotEnoughDrivers = this.drive.driveShifts.filter(driveShift => {
      const driverJob = driveShift.jobs.find(job => this.driveHelper.isDriverJob(job));
      const numberOfDrivers = driverJob.quantity || 0;

      return numberOfDrivers < numberOfAllocatedVehicles;
    });

    if(driveShiftsNotEnoughDrivers.length <= 0) return null;

    return `Number of drivers in ${driveShiftsNotEnoughDrivers.map(item => item.name).join(', ')} is less than number of allocated vehicles.`
  }
  
  @api getData() {
    let equipmentJob = null;
    let vehicleJob = null;
    return Promise.resolve()
    .then(() => {
      if (this.mode === MODE.UPDATE_DRIVE && this.drive.driveShifts && this.drive.driveShifts.length) {
        equipmentJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
        vehicleJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE);
      }

      return {
        drive: this.drive,
        contentionResolution: this.drive.contentionResolutions.join(';'),
        driveContentions: this.driveContentions,
        equipmentJob,
        vehicleJob
      }
    })
  }

  exceptionHandler = (error) => {
    new debugLogService().captureDebugLog(error, this.recordId);
    this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinnerCount++;
  }

  hideLoading = () => {
      this.showSpinnerCount--;
      if(this.showSpinnerCount < 0) {
          this.showSpinnerCount = 0;
      } 
  }
  
  connectedCallback() {
    this.mode = this.mode || MODE.DRIVE_SUBMISSION;

    // this.mode = MODE.DRIVE_CHANGE_REQUEST;
    // this.recordId = 'a2S2i000000ojgFEAQ';

    this.init();
  }

  init = () => {
    this.showLoading()
    Promise.resolve()
    .then(() => {
      if(this.mode === MODE.DRIVE_SUBMISSION) {
        return this.fetchDrive(this.recordId, false, true);
      } else if(this.mode === MODE.DRIVE_CHANGE_REQUEST) {
        return this.fetchDriveChangeRequestAndDrive(this.recordId, false, true);
      } else if (this.mode === MODE.UPDATE_DRIVE) {
        this.drive = cloneDeep(this.driveGeneratorInstance.drive);
        // this.driveChangeRequest = cloneDeep(this.driveGeneratorInstance.masterData.activeDriveChangeRequest);
        
        this.drive.contentionResolutions = [];
        if(this.drive.contentionResolution) {
          this.drive.contentionResolutions = this.drive.contentionResolution.split(';');
        }
      }
    })
    .then(() => {
      return Promise.all([
        this.fetchHoldDrivesSummary(),
        this.validateDriveStaffingChangedContention(),
        this.validateDriveContentions()
      ])
    })    
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  fetchDrive = (recordId, restoreContentionResolution = false, validateAssets = false) => {
    let fetch = new DriveFetch({
      driveType: null
    });

    const backupContentionResolution = this.drive ? (this.drive.contentionResolutions || []).join(';') : '';
    let equipmentJob = null;
    let vehicleJob = null;
    if (this.drive && this.drive.driveShifts && this.drive.driveShifts.length) {
      equipmentJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
      vehicleJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE);
    }
    
    const localEquipmentAllocations = (equipmentJob || {}).jobAllocations || [];
    const localVehicleAllocations = (vehicleJob || {}).jobAllocations || [];
    let localEquipments = [];
    let localVehicles = [];
    localEquipmentAllocations.forEach(allocation => {
      if(allocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
        localEquipments.push(allocation.resource);
      }
    });
    localVehicleAllocations.forEach(allocation => {
      if(allocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
        localVehicles.push(allocation.resource);
      }
    });
    
    return slwcDriveGeneratorHelper.initialize(recordId)
    .then((result) => {
      this.driveGeneratorInstance = result.driveGeneratorInstance;
      this.drive = this.driveGeneratorInstance.drive;

      if(!validateAssets) {
        //restore local asset allocations 
        return this.driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'totalEquipmentRequestedChanged',
          targetValue: {
            equipmentJobsMap: {
              '2RBC Asset': {
                quantity: localEquipments.length,
                equipments: localEquipments
              }
            }
          }
        }])
        .then(() => {
          return this.driveGeneratorInstance.onDriveDataChanged([{
            targetName: 'totalVehicleRequestedChanged',
            targetValue: {
              totalVehicleRequested: localVehicles.length,
              vehicles: localVehicles
            }
          }])
        });
      }

      return this.driveGeneratorInstance.validateCurrentAssignedAssets([], true)
        .then(({ allAssignedEquipmentsValid, newEquipmentJobsMap, lockedEquipments = [], allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
          //equipments
          return Promise.resolve()
            .then(() => {
              if (!allAssignedEquipmentsValid) {
                return this.driveGeneratorInstance.onDriveDataChanged([{
                  targetName: 'totalEquipmentRequestedChanged',
                  targetValue: {
                    equipmentJobsMap: newEquipmentJobsMap,
                    lockedEquipments: lockedEquipments
                  }
                }])
              }
            })
            .then(() => {
              return {
                allAssignedVehiclesValid,
                newVehicles,
                lockedVehicles, 
                canHandleDriveProjectedRegisteredDonors
              }
            })
        })
        .then(({ allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
          //vehicles
          if (!canHandleDriveProjectedRegisteredDonors) {
            return this.driveGeneratorInstance.onDriveDataChanged([{
              targetName: 'totalVehicleRequestedChanged',
              targetValue: {
                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                vehicles: newVehicles,
                lockedVehicles: lockedVehicles
              }
            }])
          }

          if (!allAssignedVehiclesValid && canHandleDriveProjectedRegisteredDonors) {
            return this.driveGeneratorInstance.onDriveDataChanged([{
              targetName: 'totalVehicleRequestedChanged',
              targetValue: {
                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                vehicles: newVehicles,
                lockedVehicles: lockedVehicles
              }
            }])
          }
        })
    })
    .then(() => {
      this.drive = this.driveGeneratorInstance.drive;

      if(restoreContentionResolution) {
        this.drive.contentionResolution = backupContentionResolution;
      }

      this.drive.contentionResolutions = [];
      if(this.drive.contentionResolution) {
        this.drive.contentionResolutions = this.drive.contentionResolution.split(';');
      }
    });
  }

  fetchDriveChangeRequestAndDrive = (recordId, restoreContentionResolution = false, validateAssets = false) => {
    const backupContentionResolution = this.drive ? (this.drive.contentionResolutions || []).join(';') : '';
    
    let equipmentJob = null;
    let vehicleJob = null;
    if (this.drive && this.drive.driveShifts && this.drive.driveShifts.length) {
      equipmentJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
      vehicleJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE);
    }
    
    const localEquipmentAllocations = (equipmentJob || {}).jobAllocations || [];
    const localVehicleAllocations = (vehicleJob || {}).jobAllocations || [];
    let localEquipments = [];
    let localVehicles = [];
    localEquipmentAllocations.forEach(allocation => {
      if(allocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
        localEquipments.push(allocation.resource);
      }
    });
    localVehicleAllocations.forEach(allocation => {
      if(allocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
        localVehicles.push(allocation.resource);
      }
    });
    
    return Promise.resolve()
    .then(() => {
      let service = new driveChangeRequestService();
      let queryModel = new driveChangeRequestQueryModel();
      queryModel.recordIds = [recordId];
      queryModel.subQueryIndicator = sObjectType.DRIVE_CHANGE_REQUEST_ITEM;

      return service.query(queryModel)
      .then(([driveChangeRequest]) => {
        this.driveChangeRequest = driveChangeRequest; 
      })
    })
    .then(() => {
      return slwcDriveGeneratorHelper.initialize(this.driveChangeRequest.driveId)
    })
    .then((result) => {
      this.driveGeneratorInstance = result.driveGeneratorInstance;
      this.drive = this.driveGeneratorInstance.drive;
    })
    .then(() => {
      let driveChanges = this.driveHelper.generateDriveChangesFromDCR(this.drive, this.driveChangeRequest);
      return this.driveGeneratorInstance.onDriveDataChanged(driveChanges)
    })
    .then(() => {
      if(!validateAssets) {
        //restore local asset allocations 
        return this.driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'totalEquipmentRequestedChanged',
          targetValue: {
            equipmentJobsMap: {
              '2RBC Asset': {
                quantity: localEquipments.length,
                equipments: localEquipments
              }
            }
          }
        }])
        .then(() => {
          return this.driveGeneratorInstance.onDriveDataChanged([{
            targetName: 'totalVehicleRequestedChanged',
            targetValue: {
              totalVehicleRequested: localVehicles.length,
              vehicles: localVehicles
            }
          }])
        });
      }

      if(this.drive.status === DRIVE_STATUS.DRAFT) {
        return;
      }

      return this.driveGeneratorInstance.validateCurrentAssignedAssets()
        .then(({ allAssignedEquipmentsValid, newEquipmentJobsMap, lockedEquipments, lockedVehicles, allAssignedVehiclesValid, newVehicles, canHandleDriveProjectedRegisteredDonors }) => {
          //equipments
          return Promise.resolve()
            .then(() => {
              if (!allAssignedEquipmentsValid) {
                return this.driveGeneratorInstance.onDriveDataChanged([{
                  targetName: 'totalEquipmentRequestedChanged',
                  targetValue: {
                    equipmentJobsMap: newEquipmentJobsMap,
                    lockedEquipments: lockedEquipments
                  }
                }])
              }
            })
            .then(() => {
              return {
                allAssignedVehiclesValid,
                newVehicles,
                lockedVehicles,
                canHandleDriveProjectedRegisteredDonors
              }
            })
        })
        .then(({ allAssignedVehiclesValid, newVehicles, lockedVehicles, canHandleDriveProjectedRegisteredDonors }) => {
          //vehicles
          if (!canHandleDriveProjectedRegisteredDonors) {
            return this.driveGeneratorInstance.onDriveDataChanged([{
              targetName: 'totalVehicleRequestedChanged',
              targetValue: {
                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                vehicles: newVehicles,
                lockedVehicles: lockedVehicles
              }
            }])
          }

          if (!allAssignedVehiclesValid && canHandleDriveProjectedRegisteredDonors) {
            return this.driveGeneratorInstance.onDriveDataChanged([{
              targetName: 'totalVehicleRequestedChanged',
              targetValue: {
                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                vehicles: newVehicles,
                lockedVehicles: lockedVehicles
              }
            }])
          }
        })
    })
    .then(() => {
      this.drive = this.driveGeneratorInstance.drive;

      if(restoreContentionResolution) {
        this.drive.contentionResolution = backupContentionResolution;
      }

      this.drive.contentionResolutions = [];
      if(this.drive.contentionResolution) {
        this.drive.contentionResolutions = this.drive.contentionResolution.split(';');
      }
    });
  }

  fetchDriveAssetAllocations = (driveId) => {
    let _jobService = new jobService();
    let _jobQueryModel = new jobQueryModel();
    _jobQueryModel.driveIds = [driveId];
    _jobQueryModel.subQueryIndicator = sObjectType.JOB_ALLOCATION;
    _jobQueryModel.assetTypes = [ASSET_TYPE.EQUIPMENT, ASSET_TYPE.VEHICLE];

    return _jobService.query(_jobQueryModel)
    .then((jobs = []) => {
      const jobMapByAssetType = keyBy(jobs, 'assetType');
      let equipmentJob = null;
      let vehicleJob = null;
      if (this.drive.driveShifts && this.drive.driveShifts.length) {
        equipmentJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
        vehicleJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE);
      }

      if(equipmentJob) {
        equipmentJob.jobAllocations = (jobMapByAssetType[ASSET_TYPE.EQUIPMENT] || {}).jobAllocations || [];
        equipmentJob.jobAllocationCount = equipmentJob.jobAllocations.length;
      }

      if(vehicleJob) {
        vehicleJob.jobAllocations = (jobMapByAssetType[ASSET_TYPE.VEHICLE] || {}).jobAllocations || [];
        vehicleJob.jobAllocationCount = vehicleJob.jobAllocations.length;
      }
    })
  }

  fetchMasterData = () => {
    const driveType = this.driveHelper.isFixedSiteDrive(this.drive) ? DRIVE_TYPE.FIXED_SITE : DRIVE_TYPE.MOBILE;
    
    let fetch = new DriveFetch({
      driveType: driveType
    });

    return Promise.resolve()
    .then(() => {
      let driveLimitQuery = new operationDriveLimitQueryModel();
      driveLimitQuery.effectiveStartDate = this.drive.driveDate;
      driveLimitQuery.effectiveEndDate = this.drive.driveDate;
      driveLimitQuery.collectionOperationIds = [this.drive.collectionOperationId];

      let staffingConstraintQuery = new staffingConstraintQueryModel();
      staffingConstraintQuery.startDate = this.drive.driveDate;
      staffingConstraintQuery.endDate = this.drive.driveDate;
      staffingConstraintQuery.driveTypes = [driveType];
      staffingConstraintQuery.collectionOpIds = [this.drive.collectionOperationId];

      let driveLimitSvc = new operationDriveLimitService();
      let staffingConstraintSvc = new staffingConstraintService();

      return Promise.all([
        driveLimitSvc.query(driveLimitQuery),
        staffingConstraintSvc.query(staffingConstraintQuery),
        fetch.retrieveDriveSite(this.drive),
        fetch.retrieveSameDateDrives(this.drive),
        fetch.retrieveSameDateActivities(this.drive),
        fetch.retrieveVehicles(this.drive),
        fetch.retrieveTerritoryCollectionOperations(this.drive),
        fetch.retrieveCustomSettings()
      ]);
    })
    .then(([driveLimits = [], staffingConstraints = [], driveSite, sameDateDrives = [], sameDateActivities = [], vehicles = [], territoryCollectionOperations = [], adminSetting]) => {
      this.masterData = {
        driveSite,
        sameDateActivities,
        sameDateDrives,
        driveLimits,
        staffingConstraints,
        vehicles,
        timezoneSidId: driveSite ? driveSite.timezoneSidId : null,
        territoryCollectionOperations,
        adminSetting : adminSetting.adminSetting
      }
    });
  }

  fetchHoldDrivesSummary = () => {
    return Promise.resolve()
    .then(() => {
      let driveDate = this.drive.driveDate;
      let service = new driveService();
      let queryModel = new driveQueryModel();
      queryModel.startDate = driveDate;
      queryModel.endDate = driveDate; 
      queryModel.statuses = [DRIVE_STATUS.HOLD];
      return service.query(queryModel)
      .then((holdDrives = []) => {
        const totalHoldDrives = holdDrives.length;
        let totalStaff = 0;
        let totalEquipment = 0;
        let totalVehiclesQuantity = 0;
        let totalVehiclesCapacity = 0;
        holdDrives.forEach(holdDrive => {
          totalStaff += (holdDrive.totalStaffRequested || 0);
          totalEquipment += (holdDrive.equipmentAllocated || 0);
          totalVehiclesQuantity += (holdDrive.vehiclesAllocated || 0);
          totalVehiclesCapacity += (holdDrive.vehicleCapacity || 0);
        })

        this.holdDrivesSummaryData = {
          totalHoldDrives: totalHoldDrives,
          totalStaff: totalStaff,
          totalEquipment: totalEquipment,
          totalVehicles: `Quantity: ${totalVehiclesQuantity}\nCapacity: ${totalVehiclesCapacity}`
        }
      })
    })
  }
  
  buildContentionText = (item, {
    availableEquipments = [],
    availableVehicles = []
  }) => {
    const contention = item.contention;
    const data = item.data;
    if(contention === DRIVE_CONTENTION.INSUFFICIENT_RESOURCES) {
      return {
        requested: `Staff Requested: ${data.staffRequested}`,
        current: `Current Staff Allocated: ${data.staffAllocated}`,
        calendarOverview: `Staff Available: ${data.staffAvailable}`
      }
    }

    if(contention === DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY) {
      return {
        requested: `Planned Capacity: ${data.plannedCapacity}`,
        current: `Proj Registered Donor: ${data.projRegisteredDonor}`,
        calendarOverview: `Excess Staff: ${data.excessStaff}`
      }
    }

    if(contention === DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS) {
      const minShiftStartString = DateTime.fromISO(data.minShiftStart, {
        zone: this.masterData.timezoneSidId
      }).toFormat('h:mm a'); 
      const maxShiftEndString = DateTime.fromISO(data.maxShiftEnd, {
        zone: this.masterData.timezoneSidId
      }).toFormat('h:mm a');
      const operationalHoursStartString = data.operationalHoursStart ? DateTime.fromFormat(data.operationalHoursStart, 'HH:mm:ss.000').toFormat('h:mm a') : 'Start of Day';
      const operationalHoursEndString = data.operationalHoursEnd ? DateTime.fromFormat(data.operationalHoursEnd, 'HH:mm:ss.000').toFormat('h:mm a') : 'End of Day'
      let currentText = '';
      if(minShiftStartString < operationalHoursStartString) currentText = 'Day before';
      if(maxShiftEndString > operationalHoursEndString) currentText = 'Day after';

      return {
        requested: `Min Shift Start: ${minShiftStartString}\nMax Shift End: ${maxShiftEndString}`,
        current: currentText,
        calendarOverview: `Operational Hours: ${operationalHoursStartString} - ${operationalHoursEndString}`,
      }
    }

    if(contention === DRIVE_CONTENTION.LACKING_VEHICLE) {
      let availableVehiclesCapacity = 0;
      availableVehicles.forEach(vehicle => {
        availableVehiclesCapacity += (vehicle.presDonorCapacity || 0)
      })

      return {
        requested: `Vehicle Capacity Needed: ${data.capacityNeeded}`,
        current: `Current Vehicle Capacity: ${data.capacityAssigned}`,
        calendarOverview: `Vehicles Available: ${availableVehicles.length}\nVehicle Capacity: ${availableVehiclesCapacity}`
      }
    }

    if(contention === DRIVE_CONTENTION.LACKING_EQUIPMENT) {
      return {
        requested: `Machines Requested: ${data.quantityNeeded}`,
        current: `Current Machines: ${data.quantityAssigned}`,
        calendarOverview: `Machines Available: ${availableEquipments.length}`,
      }
    }

    if(contention === DRIVE_CONTENTION.DRIVE_LIMIT) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `Operational Drive Limit: ${data.driveLimit}\nCurrent number of Drives: ${data.noOfCurrentDrives}`
      }
    }

    if(contention === DRIVE_CONTENTION.x2RBC_LIMIT) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `2RBC Operational Limit: ${data.operationalLimit}\nCurrent number of 2RBC: ${data.noOf2RBCRequested}`
      }
    }

    if(contention === DRIVE_CONTENTION.DOT_LIMIT) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `DOT Operational Limit: ${data.operationalLimit}\nCurrent number of DOT: ${data.noOfDOTRequested}`
      }
    }

    if(contention === DRIVE_CONTENTION.CDL_LIMIT) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `CDL Operational Limit: ${data.operationalLimit}\nCurrent number of CDL: ${data.noOfCDLRequested}`
      }
    }

    if(contention === DRIVE_CONTENTION.WITHIN_42_DAYS) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `Number of different days between Submitted Date and Drive Date: ${data.diff}`
      }
    }

    if(contention === DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `Drive confirmed within 42 days`
      }
    }

    if(contention === DRIVE_CONTENTION.PART_OF_LINKED_DRIVE) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `a Part of Linked Drive`
      }
    }

    if(contention === DRIVE_CONTENTION.MULTI_SHIFT_DRIVE) {
      return {
        requested: `Number of Shifts: ${data.numberOfDriveShifts}`,
        current: ``,
        calendarOverview: ``
      }
    }

    if(contention === DRIVE_CONTENTION.DUAL_ROLE_REMOVAL) {
      const { mapDualRoleJobsRemovedByDriveShiftId } = data;
      return {
        requested: ``,
        current: `
          Current Roles
          ${
            Object.keys(mapDualRoleJobsRemovedByDriveShiftId).map((driveShiftId, driveShiftIndex) => {
              const dualRoleJobsRemovedData = mapDualRoleJobsRemovedByDriveShiftId[driveShiftId];
              return `
                Drive Shift #${driveShiftIndex + 1} 
                ${dualRoleJobsRemovedData.newJobs.map(newJob => {
                  return `${compact([newJob.resourceRole, newJob.dualRole]).join('/')}: ${newJob.quantity}`
                }).join('\n')}
              `
            }).join('\n')
          }
        `,
        calendarOverview: `
          Dual Role Removal
          ${
            Object.keys(mapDualRoleJobsRemovedByDriveShiftId).map((driveShiftId, driveShiftIndex) => {
              const dualRoleJobsRemovedData = mapDualRoleJobsRemovedByDriveShiftId[driveShiftId];
              return `
                Drive Shift #${driveShiftIndex + 1}
                ${dualRoleJobsRemovedData.dualRoleJobsRemoved.map(removedJob => {
                  return `${compact([removeJob.resourceRole, removeJob.dualRole]).join('/')}: ${removedJob.quantity}`
                }).join('\n')}
              `
            }).join('\n')
          }
        `
      }
    }

    if(contention === DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED) {
      const { mapSystemGeneratedRoleJobsRemovedByDriveShiftId } = data;
      return {
        requested: ``,
        current: `
          Current Roles
          ${
            Object.keys(mapSystemGeneratedRoleJobsRemovedByDriveShiftId).map((driveShiftId, driveShiftIndex) => {
              const {backupJobs, backupDrive} = mapSystemGeneratedRoleJobsRemovedByDriveShiftId[driveShiftId];
              if(!backupJobs?.length) return null;

              const systemGeneratedJobs = backupJobs.filter(item => !this.driveHelper.isManuallyCreatedJob(item, backupDrive));
              const otherJobs = backupJobs.filter(item => this.driveHelper.isManuallyCreatedJob(item, backupDrive));

              return `
                Drive Shift #${driveShiftIndex + 1} 
                ${systemGeneratedJobs.map(job => {
                  return `${compact([job.resourceRole, job.dualRole]).join('/')}: ${job.quantity}`
                }).join('\n')}
                ${otherJobs.map(job => {
                  return `${compact([job.resourceRole, job.dualRole]).join('/')}: ${job.quantity} (Manual)`
                }).join('\n')}
              `
            }).filter(item => item).join('\n')
          }
        `,
        calendarOverview: `
          New Roles
          ${
            Object.keys(mapSystemGeneratedRoleJobsRemovedByDriveShiftId).map((driveShiftId, driveShiftIndex) => {
              const {newJobs, drive} = mapSystemGeneratedRoleJobsRemovedByDriveShiftId[driveShiftId];
              if(!newJobs?.length) return null;

              const systemGeneratedJobs = newJobs.filter(item => !this.driveHelper.isManuallyCreatedJob(item, drive));
              const otherJobs = newJobs.filter(item => this.driveHelper.isManuallyCreatedJob(item, drive));

              return `
                Drive Shift #${driveShiftIndex + 1}
                ${systemGeneratedJobs.map(job => {
                  return `${compact([job.resourceRole, job.dualRole]).join('/')}: ${job.quantity}`
                }).join('\n')}
                ${otherJobs.map(job => {
                  return `${compact([job.resourceRole, job.dualRole]).join('/')}: ${job.quantity} (Manual)`
                }).join('\n')}
              `
            }).filter(item => item).join('\n')
          }
        `
      }
    }

    if (contention === DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `Collection Operation changed cross regions`
      }
    }

    if (contention === DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO) {
      return {
        requested: ``,
        current: ``,
        calendarOverview: `Assets are not shared with new Collection Operation`
      }
    }
  }

  getContentionActions = (item) => {
    const isContentionOverride = (contentionResolution) => {
      return this.drive.contentionResolutions && this.drive.contentionResolutions.includes(contentionResolution);
    }

    const contention = item.contention;
    if (contention === DRIVE_CONTENTION.INSUFFICIENT_RESOURCES) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_INSUFFICIENT_RESOURCES,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_INSUFFICIENT_RESOURCES)
      }]
    }

    if (contention === DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_EXCESS_STAFF_CAPACITY,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_EXCESS_STAFF_CAPACITY)
      }]
    }

    if(contention === DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_OUT_OF_OPERATIONAL_HOURS,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_OUT_OF_OPERATIONAL_HOURS)
      }]
    }

    if (contention === DRIVE_CONTENTION.LACKING_VEHICLE) {
      let actions = [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_USE_RENTAL,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_USE_RENTAL)
      }, {
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY),
      }];
      
      if(this.allowToOpenDriveStaffing) {
        actions.push({
          isLink: true,
          label: 'Allocate Assets',
          onclick: () => {
            this.openDriveStaffingDetails(this.drive);
          }
        })
      }

      return actions;
    }

    if (contention === DRIVE_CONTENTION.LACKING_EQUIPMENT) {
      let actions = [];
      if(this.allowToOpenDriveStaffing) {
        actions.push({
          isLink: true,
          label: 'Allocate Assets',
          onclick: () => {
            this.openDriveStaffingDetails(this.drive);
          }
        });
      }

      return actions;
    }

    if (contention === DRIVE_CONTENTION.WITHIN_42_DAYS) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_WITHIN_42_DAYS,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_WITHIN_42_DAYS)
      }]
    }

    if (contention === DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_CONFIRM_WITHIN_42_DAYS,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_CONFIRM_WITHIN_42_DAYS)
      }]
    }

    if (contention === DRIVE_CONTENTION.DUAL_ROLE_REMOVAL) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_DUAL_ROLE_REMOVAL,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_DUAL_ROLE_REMOVAL)
      }]
    }

    if (contention === DRIVE_CONTENTION.PART_OF_LINKED_DRIVE) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_PART_OF_LINKED_DRIVE,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_PART_OF_LINKED_DRIVE)
      }]
    }

    if(contention === DRIVE_CONTENTION.MULTI_SHIFT_DRIVE) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_MULTI_SHIFT_DRIVE,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_MULTI_SHIFT_DRIVE)
      }]
    }

    if(contention === DRIVE_CONTENTION.DRIVE_LIMIT) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_DRIVE_LIMIT,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_DRIVE_LIMIT)
      }] 
    }

    if (contention === DRIVE_CONTENTION.x2RBC_LIMIT) {
      let actions = [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_2RBC_LIMIT,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_2RBC_LIMIT)
      }];
      
      if(this.allowToOpenDriveStaffing) {
        actions.push({
          isLink: true,
          label: 'Allocate Assets',
          onclick: () => {
            this.openDriveStaffingDetails(this.drive);
          }
        })
      }

      return actions;
    }

    if (contention === DRIVE_CONTENTION.DOT_LIMIT) {
      let actions = [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_DOT_LIMIT,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_DOT_LIMIT)
      }];
      
      if(this.allowToOpenDriveStaffing) {
        actions.push({
          isLink: true,
          label: 'Allocate Assets',
          onclick: () => {
            this.openDriveStaffingDetails(this.drive);
          }
        })
      }

      return actions;
    }

    if (contention === DRIVE_CONTENTION.CDL_LIMIT) {
      let actions = [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_CDL_LIMIT,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_CDL_LIMIT)
      }];
      
      if(this.allowToOpenDriveStaffing) {
        actions.push({
          isLink: true,
          label: 'Allocate Assets',
          onclick: () => {
            this.openDriveStaffingDetails(this.drive);
          }
        })
      }

      return actions;
    }

    if(contention === DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED) {
      const noOptionSelected = !isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE) && !isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT);
      const { mapSystemGeneratedRoleJobsRemovedByDriveShiftId } = item.data;
      let isNumOfDriveShiftChanged = false;
      Object.keys(mapSystemGeneratedRoleJobsRemovedByDriveShiftId).map((driveShiftId) => {
        const {backupDriveShift, driveShift} = mapSystemGeneratedRoleJobsRemovedByDriveShiftId[driveShiftId];
        if(!backupDriveShift || !driveShift) {
          isNumOfDriveShiftChanged = true;
        }
      });
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE,
        value: noOptionSelected ? true : isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE),
        disabled: isNumOfDriveShiftChanged
      }, !isNumOfDriveShiftChanged ? {
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT),
        disabled: isNumOfDriveShiftChanged
      } : null].filter(item => item) 
    }

    if (contention === DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_CO_CHANGED_CROSS_REGIONS_REMOVE_FROM_LINKED_DRIVE,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_CO_CHANGED_CROSS_REGIONS_REMOVE_FROM_LINKED_DRIVE)
      }];
    }

    if (contention === DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO) {
      return [{
        label: DRIVE_CONTENTION_RESOLUTION.ELECT_ASSETS_NOT_SHARED_WITH_NEW_CO,
        value: isContentionOverride(DRIVE_CONTENTION_RESOLUTION.ELECT_ASSETS_NOT_SHARED_WITH_NEW_CO)
      }]
    }
  }

  validateDriveStaffingChangedContention = () => {
    return this.fetchMasterData()
      .then(() => {
        let contentionsToValidate = [
          DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED
        ];
        
        let originalContentions = [];
        if(this.mode === MODE.DRIVE_SUBMISSION) {
          originalContentions = this.drive.pendingActionReasonCode ? this.drive.pendingActionReasonCode.split(';') : [];
        } else {
          originalContentions = this.driveChangeRequest ? this.driveChangeRequest.driveContention.split(';') : [];
        }
        
        let {
          passed,
          contentions,
        } = this.driveHelper.validateDrive({
          ...this.drive,
          contentionResolution: this.drive.contentionResolutions.join(';')
        }, {
          ...this.masterData,
          backupDrive: this.driveGeneratorInstance.masterData.backupDrive
        }, contentionsToValidate, originalContentions);

        this.driveStaffingChangedContention = null;
        if(contentions.length > 0) {
          let contention = {
            passed: true,
            violated: contentions[0].violated,
            contention: contentions[0].contention
          }
          this.driveStaffingChangedContention = {
            ...contention,
            ...this.buildContentionText(contentions[0], {}),
            actions: this.getContentionActions(contentions[0])
          }
        }
      });
  }

  validateDriveContentions = () => {
    return this.fetchMasterData()
      .then(() => {
        return this.driveHelper.getAvailableAssets(this.masterData.vehicles, this.drive, true);
      })
      .then(({ availableVehicles = [], availableEquipments = [], availableButNotSharedAssetIds = [] }) => {
        let contentionsToValidate = [
          DRIVE_CONTENTION.DRIVE_LIMIT,
          DRIVE_CONTENTION.x2RBC_LIMIT,
          DRIVE_CONTENTION.DOT_LIMIT,
          DRIVE_CONTENTION.CDL_LIMIT,
          DRIVE_CONTENTION.OUT_OF_OPERATIONAL_HOURS,
          DRIVE_CONTENTION.LACKING_EQUIPMENT,
          DRIVE_CONTENTION.INSUFFICIENT_RESOURCES,
          DRIVE_CONTENTION.EXCESS_STAFF_CAPACITY,
          DRIVE_CONTENTION.WITHIN_42_DAYS,
          DRIVE_CONTENTION.CONFIRM_WITHIN_42_DAYS,
          DRIVE_CONTENTION.PART_OF_LINKED_DRIVE,
          DRIVE_CONTENTION.MULTI_SHIFT_DRIVE
        ];
        if(this.drive.typeOfDrive === DRIVE_TYPE.MOBILE) {
          contentionsToValidate.push(DRIVE_CONTENTION.LACKING_VEHICLE);
          contentionsToValidate.push(DRIVE_CONTENTION.DUAL_ROLE_REMOVAL);
          contentionsToValidate.push(DRIVE_CONTENTION.CO_CHANGED_CROSS_REGIONS);
          contentionsToValidate.push(DRIVE_CONTENTION.ASSETS_NOT_SHARED_WITH_NEW_CO);
        }

        let originalContentions = [];
        if(this.mode === MODE.DRIVE_SUBMISSION) {
          originalContentions = this.drive.pendingActionReasonCode ? this.drive.pendingActionReasonCode.split(';') : [];
        } else {
          originalContentions = this.driveChangeRequest ? this.driveChangeRequest.driveContention.split(';') : [];
        }
        
        let {
          passed,
          contentions,
        } = this.driveHelper.validateDrive({
          ...this.drive,
          contentionResolution: this.drive.contentionResolutions.join(';')
        }, {
          ...this.masterData,
          backupDrive: this.driveGeneratorInstance.masterData.backupDrive,
          availableAssetsInfo: {
            availableButNotSharedAssetIds
          }
        }, contentionsToValidate, originalContentions);

        this.driveContentions = contentions.map(item => {
          let contention = {
            passed: item.contention === DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED ? true : item.passed,
            violated: item.violated,
            contention: item.contention
          }
          contention = {
            ...contention,
            ...this.buildContentionText(item, {
              availableVehicles,
              availableEquipments
            }),
            actions: this.getContentionActions(item)
          }
          return contention;
        });
      });
  }

  handleActionChanged = (event) => {
    const value = getValueFromEvent(event);
    const contention = event.target.dataset['contention'];
    const targetName = event.target.name;

    let driveContention = this.driveContentions.find(item => item.contention === contention);
    driveContention.actions.forEach(action => {
      remove(this.drive.contentionResolutions, item => item === action.label);
      if(action.label === targetName) {
        action.value = value;
        if(value) {
          this.drive.contentionResolutions.push(action.label);
        }
        if(driveContention.contention === DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED) {
          setTimeout(() => {
            action.value = true;
            this.drive.contentionResolutions.push(action.label);
          })
        }
      } else {
        action.value = false;
      }
    })
  }

  handleActionStaffingComplementChanged = (event) => {
    const value = getValueFromEvent(event);
    const targetName = event.target.name;

    let driveContention = this.driveStaffingChangedContention;
    driveContention.actions.forEach(action => {
      remove(this.drive.contentionResolutions, item => item === action.label);
      if(action.label === targetName) {
        action.value = value;
        if(value) {
          this.drive.contentionResolutions.push(action.label);
        }
        if(driveContention.contention === DRIVE_CONTENTION.STAFFING_COMPLEMENT_CHANGED) {
          setTimeout(() => {
            action.value = true;
            this.drive.contentionResolutions.push(action.label);
          })
        }
      } else {
        action.value = false;
      }
    })

    this.showLoading()
    Promise.resolve()
    .then(() => {
      if(targetName === DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE) {
        return this.driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'staffingComplementChanged',
          targetValue: this.drive.driveShifts.map(driveShift => {
            return driveShift.jobs.reduce((staffingComplement, job) => {
              if(job.resourceRole) {
                return {
                  ...staffingComplement,
                  [this.driveHelper.generateJobKey(job)]: job
                }
              }

              return staffingComplement;
            }, {});
          })
        }])
      } else if (targetName === DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT) {
        return this.driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'staffingComplementChanged',
          targetValue: this.driveGeneratorInstance?.masterData?.backupDrive?.driveShifts?.map(driveShift => {
            return driveShift.jobs.reduce((staffingComplement, job) => {
              if(job.resourceRole) {
                return {
                  ...staffingComplement,
                  [this.driveHelper.generateJobKey(job)]: job
                }
              }

              return staffingComplement;
            }, {});
          })
        }])
      }
    })
    .then(() => {
      this.drive = this.driveGeneratorInstance.drive;

      this.drive.contentionResolutions = [];
      if(this.drive.contentionResolution) {
        this.drive.contentionResolutions = this.drive.contentionResolution.split(';');
      }
      return this.validateDriveContentions();
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleRefreshHoldDrivesSummaryBtn = () => {
    this.showLoading()
    this.fetchHoldDrivesSummary()
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleOpenDriveSchedulingBtn = () => {
    window.open('/' + this.drive.id, '_blank');
  }

  handleValidateBtn = () => {
    const backupContentionResolution = this.drive ? (this.drive.contentionResolutions || []).join(';') : '';

    this.showLoading()
    return Promise.resolve()
    .then(() => {
      if(this.mode === MODE.DRIVE_SUBMISSION) {
        return this.fetchDrive(this.recordId, true, false);
      } else if(this.mode === MODE.DRIVE_CHANGE_REQUEST) {
        return this.fetchDriveChangeRequestAndDrive(this.recordId, true, false);
      } else if(this.mode === MODE.UPDATE_DRIVE) {
        let equipmentJob = null;
        let vehicleJob = null;
        if (this.drive && this.drive.driveShifts && this.drive.driveShifts.length) {
          equipmentJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
          vehicleJob = (this.drive.driveShifts[0].jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE);
        }
        
        const localEquipmentAllocations = (equipmentJob || {}).jobAllocations || [];
        const localVehicleAllocations = (vehicleJob || {}).jobAllocations || [];
        let localEquipments = [];
        let localVehicles = [];
        localEquipmentAllocations.forEach(allocation => {
          if(allocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
            localEquipments.push(allocation.resource);
          }
        });
        localVehicleAllocations.forEach(allocation => {
          if(allocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
            localVehicles.push(allocation.resource);
          }
        });

        return this.driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'totalEquipmentRequestedChanged',
          targetValue: {
            equipmentJobsMap: {
              '2RBC Asset': {
                quantity: localEquipments.length,
                equipments: localEquipments
              }
            }
          }
        }])
        .then(() => {
          return this.driveGeneratorInstance.onDriveDataChanged([{
            targetName: 'totalVehicleRequestedChanged',
            targetValue: {
              totalVehicleRequested: localVehicles.length,
              vehicles: localVehicles
            }
          }])
        });
      }
    })
    .then(() => {
      const hasStaffingComplementChangedContention = !!this.driveStaffingChangedContention;
      if(!hasStaffingComplementChangedContention) return;

      const currentAction = this.driveStaffingChangedContention.actions?.find(action => action.value);
      if(!currentAction) return;

      if(currentAction.label === DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE) {
        return this.driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'staffingComplementChanged',
          targetValue: this.drive.driveShifts.map(driveShift => {
            return driveShift.jobs.reduce((staffingComplement, job) => {
              if(job.resourceRole) {
                return {
                  ...staffingComplement,
                  [this.driveHelper.generateJobKey(job)]: job
                }
              }

              return staffingComplement;
            }, {});
          })
        }])
      } else if (currentAction.label === DRIVE_CONTENTION_RESOLUTION.ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT) {
        return this.driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'staffingComplementChanged',
          targetValue: this.driveGeneratorInstance?.masterData?.backupDrive?.driveShifts?.map(driveShift => {
            return driveShift.jobs.reduce((staffingComplement, job) => {
              if(job.resourceRole) {
                return {
                  ...staffingComplement,
                  [this.driveHelper.generateJobKey(job)]: job
                }
              }

              return staffingComplement;
            }, {});
          })
        }])
      }
    })
    .then(() => {
      this.drive = this.driveGeneratorInstance.drive;
      this.drive.contentionResolution = backupContentionResolution;

      this.drive.contentionResolutions = [];
      if(this.drive.contentionResolution) {
        this.drive.contentionResolutions = this.drive.contentionResolution.split(';');
      }
      return this.validateDriveContentions()
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  //staffing details
  openDriveStaffingDetails(drive) {
    this.driveStaffingDetailsData = {
      shown: true,
      mode: 'local',
      recordId: drive.id,
      drive: drive
    }
  }

  closeDriveStaffingDetails() {
    this.driveStaffingDetailsData = {
      shown: false,
      recordId: null
    } 
  }

  saveDriveStaffingDetails(event) {
    this.closeDriveStaffingDetails();

    this.showLoading();
    Promise.resolve()
    .then(() => {
      const { drives: newDrives, jobs: newJobs } = event.detail;
      const equipmentJob = this.drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
      const vehicleJob = this.drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.VEHICLE);
      const newEquipmentJob = newJobs.find(newJob => equipmentJob && newJob.key === equipmentJob.key);
      const newVehicleJob = newJobs.find(newJob => vehicleJob && newJob.key === vehicleJob.key);
      if(newEquipmentJob) {
        equipmentJob.jobAllocations = [...newEquipmentJob.jobAllocations];
      }
      if(newVehicleJob) {
        vehicleJob.jobAllocations = [...newVehicleJob.jobAllocations];
      }

      if(this.mode === MODE.DRIVE_CHANGE_REQUEST) {
        let service = new jobService();
        return service.saveList([
          {
            id: equipmentJob.id,
            jobAllocations: equipmentJob.jobAllocations
          },
          {
            id: vehicleJob.id,
            jobAllocations: vehicleJob.jobAllocations
          }
        ]) 
      }
    })
    .then(() => {
      return this.handleValidateBtn();
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }
}