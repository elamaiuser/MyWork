import { MobileGenerator } from './mobileGenerator.js';
import { FixedSiteGenerator } from './fixedSiteGenerator.js';
import { WbFixedSiteGenerator } from './wbFixedSiteGenerator.js';

import {
  dataService, driveService, driveQueryModel, roleTimeDetailService, collectionOperationSdmService,
  locationService, locationQueryModel, activityService, activityQueryModel,
  fixedSiteProcedureProjectionService, fixedSiteProcedureProjectionQueryModel, 
  userService, jobAllocationService,
  collectionOperationStagingLocationService, collectionOperationStagingLocationQueryModel,
  collectionOperationTimeBlockService, collectionOperationTimeBlockQueryModel,
  travelTimeIndexItemService, travelTimeIndexItemQueryModel,
  resourceService, resourceQueryModel, sObjectType, territoryCollectionOperationService, territoryCollectionOperationQueryModel
} from 'c/dataService';
import * as autoMapper from 'c/autoMapper';
import { DRIVE_TYPE, OPERATION_TYPE, ASSET_TYPE } from 'c/slwcConstants';
import { groupBy, keyBy, orderBy, isString, cloneDeep, uniq } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { DriveHelper } from './helper';
import { getTravelTimeIndexKey } from 'c/slwcUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';

class SlwcDrivesGenerator {
  drives = [];
  driveGeneratorInstanceMap = {};
  masterData = {
    adminSetting: {},
    resourceRoleGroups: null,
    lunchBreakSettings: [],
    driveSites: [],
    drives: [],
    vehicles: [],
    activities: [],
    roleTimeData: {},
    fixedSiteProcedureProjections: [],
    collectionOperationSDM: [],
    staffingDecisionMatrix: [],
    accountTags: [],
    locationTags: [],
    territoryCollectionOperations: [],
    travelTimeIndexItemMap: {}
  };

  get collectionOperationIds() {
    let collectionOperationIds = [];
    this.drives.forEach(drive => {
      if (drive.collectionOperationId && !collectionOperationIds.includes(drive.collectionOperationId)) {
        collectionOperationIds.push(drive.collectionOperationId);
      }
    });
    return collectionOperationIds;
  }

  get driveSiteIds() {
    let driveSiteIds = [];
    this.drives.forEach((drive) => {
      if (drive.driveSiteId && !driveSiteIds.includes(drive.driveSiteId)) {
        driveSiteIds.push(drive.driveSiteId);
      }
    });
    return driveSiteIds;
  }

  get accountIds() {
    let accountIds = [];
    this.drives.forEach((drive) => {
      if (drive.accountId && !accountIds.includes(drive.accountId)) {
        accountIds.push(drive.accountId);
      }
    });
    return accountIds;
  }

  get drivesDateRange() {
    let minStartDate = null;
    let maxEndDate = null;

    this.drives.forEach(drive => {
      if (!minStartDate || drive.driveDate < minStartDate) {
        minStartDate = drive.driveDate
      }

      if (!maxEndDate || drive.driveDate > maxEndDate) {
        maxEndDate = drive.driveDate
      }
    })

    return {
      minStartDate,
      maxEndDate
    }
  }

  initialize(recordIds = [], excludeExceptions = false) {
    if (!recordIds.length) return;

    const inputIdsMode = isString(recordIds[0]);
    return Promise.all([
      Promise.resolve()
      .then(() => {
        if(inputIdsMode) {
          return this.getDrivesData(recordIds, excludeExceptions);
        } else {
          return this.initDrivesData(recordIds);
        }
      }),
      this.retrieveCustomSettings()
    ]).then(() => {
        return Promise.all([
          this.retrieveLoginUser(),
          this.retrieveDriveSites(),
          this.retrieveRoleTimeData(),
          this.retrieveFixedSiteProcedureProjections(),
          this.retrieveDrives(),
          this.retrieveActivities(),
          this.retrieveCollectionOperationSDM(),
          this.retrieveDefaultTags(),
          this.retrieveVehicles(),
          this.retrieveTerritoryCollectionOps(),
          this.retrieveCollectionOperationTimeBlocksData()
        ])
      })
      .then(() => {
        return this.retrieveTravelTimeIndexItemMap();
      })
      .then(() => {
        this.initDriveGeneratorInstances();
      })
  }
  
  getDrivesData(recordIds = [], excludeExceptions = false) {
    let service = new driveService();
    return service.getDrivesByIds(recordIds, excludeExceptions)
    .then((drives) => {
      this.drives = drives || [];
    })
  }

  initDrivesData(drives = []) {
    this.drives = drives;
  }

  retrieveCustomSettings() {
    let settingKeys = ["resourceRoleGroups", "adminSetting", "lunchBreakSettings", "staffSetupExcludedRoles", "staffCountThresholds"];
    return Promise.resolve()
      .then(() => {
        let service = new dataService();
        return service.getCustomSettings({ settingKeys: settingKeys })
          .then((result) => {
            this.masterData.resourceRoleGroups = result.returnedData.resourceRoleGroups;
            this.masterData.adminSetting = result.returnedData.adminSetting;
            this.masterData.lunchBreakSettings = autoMapper.autoMapperInstance.mapToArray('sked_Lunch_Break_Setting__c', result.returnedData.lunchBreakSettings);
            this.masterData.staffSetupExcludedRoles = autoMapper.autoMapperInstance.mapToArray('sked_Staff_Setup_Excluded_Role__c', result.returnedData.staffSetupExcludedRoles);
            this.masterData.staffCountThresholds = autoMapper.autoMapperInstance.mapToArray('sked_Staff_Count_Threshold__c', result.returnedData.staffCountThresholds ?? []);
          })
      });
  }


  retrieveVehicles() {
    return Promise.resolve()
      .then(() => {
        if (!this.collectionOperationIds.length || !this.drivesDateRange.minStartDate || !this.drivesDateRange.maxEndDate) return;

        let request = {
          accountIds: [],
          collectionOperationIds: this.collectionOperationIds,
          locationIds: [],
          inputDates: [this.drivesDateRange.minStartDate, this.drivesDateRange.maxEndDate],
          jobIds: [],
          pageSize: 1000,
          pageNo: 1,
          getAssetsOnly: true,
          timezoneSidId: TIME_ZONE
        } 

        let service = new jobAllocationService();
        return service.getResourceData({
          request: request
        })
        .then(result => {
          if(!result || !result.returnedData) {
              throw result;
          }

          this.masterData.vehicles = autoMapper.autoMapperInstance.mapToArray('sked__Resource__c', result.returnedData.resources).filter(resource => {
            return resource.assetType === ASSET_TYPE.VEHICLE;
          });
        })
      });
  }

  retrieveLoginUser() {
    return Promise.resolve()
    .then(() => {
        let service = new userService();
        return service.getLoginUser()
        .then((result) => {
            this.masterData.loginUser = result.returnedData;
        })
    });  
  }

  retrieveDriveSites() {
    return Promise.resolve()
      .then(() => {
        if (!this.driveSiteIds.length) return;

        let locationSvc = new locationService();
        let locationQuery = new locationQueryModel();
        locationQuery.recordIds = this.driveSiteIds;

        return locationSvc.query(locationQuery)
          .then((result) => {
            this.masterData.driveSites = (result || []).map(driveSite => {
              return driveSite;
            });

            const possibleCollectionOperationIds = [];
            this.masterData.driveSites.forEach(driveSite => {
              possibleCollectionOperationIds.push(...driveSite.siteCollectionOperations?.map(item => item.collectionOperationId) || []);
            })
            if(!possibleCollectionOperationIds.length) {
              return;
            }

            let coStagingLocationService = new collectionOperationStagingLocationService();
            let coStagingLocationQueryModel = new collectionOperationStagingLocationQueryModel();
            coStagingLocationQueryModel.collectionOperationIds = uniq(possibleCollectionOperationIds);

            return coStagingLocationService.query(coStagingLocationQueryModel)
              .then(coStagingLocations => {
                const mapcoStagingLocationsByCOId = groupBy(coStagingLocations, 'collectionOperationId');

                this.masterData.driveSites.forEach(driveSite => {
                  driveSite.siteCollectionOperations.forEach(siteCO => {
                    siteCO.collectionOperation.collectionOpStagingLocations = mapcoStagingLocationsByCOId[siteCO.collectionOperationId] || [];
                  });
                })
              });
          })
      });
  }
  
  retrieveTravelTimeIndexItemMap() {
    this.masterData.travelTimeIndexItemMap = {};

    const possibleCollectionOperationIds = [];
    this.masterData.driveSites.forEach(driveSite => {
      possibleCollectionOperationIds.push(...driveSite.siteCollectionOperations?.map(item => item.collectionOperationId) || []);
    })
    if(!possibleCollectionOperationIds.length) {
      return;
    }

    let coStagingLocationService = new collectionOperationStagingLocationService();
    let coStagingLocationQueryModel = new collectionOperationStagingLocationQueryModel();
    coStagingLocationQueryModel.collectionOperationIds = uniq(possibleCollectionOperationIds);
    return coStagingLocationService.query(coStagingLocationQueryModel)
      .then(coStagingLocations => {
        const mapCOStagingLocationsByCOId = groupBy(coStagingLocations, 'collectionOperationId');
        const travelTimeIndexItemKeys = [];

        this.masterData.driveSites.forEach(driveSite => {
          const { geoLocationLatitude: driveSiteGeoLocationLatitude, geoLocationLongitude: driveSiteGeoLocationLongitude } = driveSite;
          
          driveSite.siteCollectionOperations?.forEach(siteCO => {
            const _coStagingLocations = mapCOStagingLocationsByCOId[siteCO.collectionOperationId];
            _coStagingLocations?.forEach(coStagingLocation => {
              const { geoLocationLatitude: stagingLocationGeoLocationLatitude, geoLocationLongitude: stagingLocationGeoLocationLongitude } = coStagingLocation.stagingLocation;
              const siteToCOKey = getTravelTimeIndexKey(driveSiteGeoLocationLatitude, driveSiteGeoLocationLongitude, stagingLocationGeoLocationLatitude, stagingLocationGeoLocationLongitude);
              const coToSiteKey = getTravelTimeIndexKey(stagingLocationGeoLocationLatitude, stagingLocationGeoLocationLongitude, driveSiteGeoLocationLatitude, driveSiteGeoLocationLongitude);
            
              travelTimeIndexItemKeys.push(...[siteToCOKey, coToSiteKey]); 
            })
          })
        });

        if(!travelTimeIndexItemKeys.length) return;

        let service = new travelTimeIndexItemService();
        let queryModel = new travelTimeIndexItemQueryModel();
        queryModel.keys = uniq(travelTimeIndexItemKeys);

        return service.query(queryModel);
      })
      .then(travelTimeIndexItems => {
        this.masterData.travelTimeIndexItemMap = keyBy(travelTimeIndexItems, 'key');
      });
  }

  retrieveTerritoryCollectionOps() {
    return Promise.resolve()
    .then(() => {
      if (!this.collectionOperationIds.length || !this.drives.length) return;

      let orderedDrives = this.drives.sort((drive, prevDrive) => { return Date.parse(drive.driveDate) > Date.parse(prevDrive.driveDate); });
      let earliestDate = orderedDrives[0].driveDate;
      let latestDate = orderedDrives[orderedDrives.length-1].driveDate;

      let territoryCollectionOperationSvc = new territoryCollectionOperationService();
      let queryModel = new territoryCollectionOperationQueryModel();
      queryModel.collectionOperationIds = this.collectionOperationIds;
      queryModel.startDate = earliestDate;
      queryModel.endDate = latestDate;

      territoryCollectionOperationSvc.query(queryModel)
        .then((result) => {
          this.masterData.territoryCollectionOperations = result || [];
        });
    });
  }

  retrieveDrives() {
    return Promise.resolve()
      .then(() => {
        if (!this.collectionOperationIds.length || !this.drivesDateRange.minStartDate || !this.drivesDateRange.maxEndDate) return;

        let query = new driveQueryModel();
        query.startDate = this.drivesDateRange.minStartDate;
        query.endDate = this.drivesDateRange.maxEndDate;
        query.collectionOpIds = this.collectionOperationIds;
        query.subQueryIndicator = sObjectType.DRIVE_SHIFT;

        let service = new driveService();
        return service.query(query)
          .then((result) => {
            this.masterData.drives = result || [];
          })
      });
  }

  retrieveActivities() {
    return Promise.resolve()
      .then(() => {
        if (!this.collectionOperationIds.length || !this.drivesDateRange.minStartDate || !this.drivesDateRange.maxEndDate) return;

        let query = new activityQueryModel();
        query.startDate = this.drivesDateRange.minStartDate;
        query.endDate = this.drivesDateRange.maxEndDate;
        query.collectionOperationIds = this.collectionOperationIds;
        query.isGroupActivity = true;
        query.reduceFromStaffingConstraint = true;

        let service = new activityService();
        return service.query(query)
          .then((result) => {
            this.masterData.activities = result || [];
          })
      });
  }

  retrieveRoleTimeData() {
    return Promise.resolve()
      .then(() => {
        if (!this.collectionOperationIds.length || !this.driveSiteIds.length || !this.drivesDateRange.minStartDate || !this.drivesDateRange.maxEndDate) return;

        let service = new roleTimeDetailService();

        return service.getRoleTimeData(this.drivesDateRange.minStartDate, this.drivesDateRange.maxEndDate, this.collectionOperationIds, this.driveSiteIds)
          .then(result => {
            this.masterData.roleTimeData = result || {};
          })
      });
  }

  retrieveCollectionOperationTimeBlocksData() {
    return Promise.resolve()
      .then(() => {
        if (!this.collectionOperationIds.length || !this.drivesDateRange.minStartDate || !this.drivesDateRange.maxEndDate) return;

        let service = new collectionOperationTimeBlockService();
        let model = new collectionOperationTimeBlockQueryModel();
        model.collectionOperationIds = this.collectionOperationIds;
        model.startDate = this.drivesDateRange.minStartDate;
        model.endDate = this.drivesDateRange.maxEndDate;
        return service.query(model)
          .then(result => {
            this.masterData.collectionOperationTimeBlocks = result;
          })
      });
  }

  retrieveFixedSiteProcedureProjections() {
    return Promise.resolve()
      .then(() => {
        if (!this.accountIds.length || !this.drivesDateRange.minStartDate || !this.drivesDateRange.maxEndDate) return;

        let fixedSiteProcedureProjectionSvc = new fixedSiteProcedureProjectionService();
        let query = new fixedSiteProcedureProjectionQueryModel();
        query.accountIds = this.accountIds;
        query.startDate = this.drivesDateRange.minStartDate;
        query.endDate = this.drivesDateRange.maxEndDate;

        return fixedSiteProcedureProjectionSvc.query(query)
          .then((result) => {
            this.masterData.fixedSiteProcedureProjections = result || [];
          });
      });
  }

  retrieveCollectionOperationSDM() {
    return Promise.resolve()
      .then(() => {
        if (!this.collectionOperationIds.length || !this.drivesDateRange.minStartDate || !this.drivesDateRange.maxEndDate ) return;

        let service = new collectionOperationSdmService();
        return service.getStaffingDecisionMatrices(this.collectionOperationIds, [DRIVE_TYPE.MOBILE, DRIVE_TYPE.FIXED_SITE], this.drivesDateRange.minStartDate, this.drivesDateRange.maxEndDate)
          .then(result => {
            this.masterData.staffingDecisionMatrix = result.staffingDecisionMatrix || [];
            this.masterData.collectionOperationSDM = result.collectionOperationSDM || [];
          })
      });
  }

  retrieveDefaultTags() {
    return Promise.resolve()
      .then(() => {
        let service = new driveService();
        return service.getDefaultTags(this.accountIds, this.driveSiteIds)
          .then((result) => {
            this.masterData.accountTags = result.accountTags || [];
            this.masterData.locationTags = result.locationTags || [];
          })
      });
  }

  initDriveGeneratorInstances() {
    if(!this.drives.length) return [];

    const filterItemsByDateRange = (items = [], {startField, startValue}, {endField, endValue}) => {
      return items.filter(item => {
        if(['start'].includes(startField) && ['finish', 'end'].includes(endField)) {
          const startIso  = item[startField] ? DateTime.fromISO(item[startField], {
            zone: item.timezoneSidId
          }).toISODate() : null;
          const endIso  = item[endField] ? DateTime.fromISO(item[endField], {
            zone: item.timezoneSidId
          }).toISODate() : null;

          return (!startIso || startIso <= endValue) && (!endIso || endIso >= startValue)
        } else {
          return (!item[startField] || item[startField] <= endValue) && (!item[endField] || item[endField] >= startValue)
        }
      })
    }

    const filterRoleTimeDetails = (items = [], {driveDate, driveType, mobileType}) => {
      let dayOfWeek = DateTime.fromFormat(driveDate, 'yyyy-MM-dd').toFormat('cccc');
      return items.filter(item => {
        return (item.daysOfWeek?.includes(dayOfWeek) 
                && !item.effectiveStartDate || item.effectiveStartDate <= driveDate) 
                && (!item.effectiveEndDate || driveDate <= item.effectiveEndDate)
                && item.driveType === driveType
                && item.mobileType === mobileType;
        });
    }

    this.driveGeneratorInstanceMap = {};
    let accountTagsMap = groupBy(this.masterData.accountTags, 'accountId');
    let locationTagsMap = groupBy(this.masterData.locationTags, 'locationId');
    let roleTimeDetailsMap = groupBy(this.masterData.roleTimeData.roleTimeDetails, 'collectionOperationId');
    let globalRoleTimeDetails = this.masterData.roleTimeData.roleTimeDetails.filter(item => item.roleTimeDetailType === 'Global');
    let roleTimeVariancesMap = groupBy(this.masterData.roleTimeData.roleTimeVariances, 'locationId');
    let vehiclesMap = groupBy(this.masterData.vehicles, 'collectionOperationId');
    let driveSiteMap = keyBy(this.masterData.driveSites, 'id');
    let retrieveFixedSiteProcedureProjectionsMap = groupBy(this.masterData.fixedSiteProcedureProjections, 'accountId');
    let collectionOperationSDMMap = groupBy(this.masterData.collectionOperationSDM, 'collectionOpId');
    let staffingDecisionMatrixMap = keyBy(this.masterData.staffingDecisionMatrix, 'id');
    let collectionOperationTimeBlocksMap = groupBy(this.masterData.collectionOperationTimeBlocks, 'collectionOperationId');
    let loginUser = this.masterData.loginUser;

    this.drives = this.drives.map(drive => {
      let driveGeneratorInstance = null;
      if (drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE) {
        if (drive.operationType === OPERATION_TYPE.NON_INTEGRATED_WB) {
          driveGeneratorInstance = new WbFixedSiteGenerator();
        } else {
          driveGeneratorInstance = new FixedSiteGenerator();
        }
      } else {
        driveGeneratorInstance = new MobileGenerator();
      }

      let validCollectionOperationSDM = filterItemsByDateRange(collectionOperationSDMMap[drive.collectionOperationId] || [], {
        startField: 'effectiveStartDate',
        startValue: drive.driveDate
      }, {
        endField: 'effectiveEndDate',
        endValue: drive.driveDate
      }).filter(item => {
        return item.staffingDecisionMatrix.recordTypeName === drive.typeOfDrive;
      });

      drive = driveGeneratorInstance.initData({
        drive: {
          ...drive,
          driveSite: driveSiteMap[drive.driveSiteId]
        },
        masterData: {
          loginUser: loginUser,
          driveTags: {
            accountTags: accountTagsMap[drive.accountId] || [],
            locationTags: locationTagsMap[drive.driveSiteId] || []
          },
          lunchBreakSettings: this.masterData.lunchBreakSettings,
          resourceRoleGroups: this.masterData.resourceRoleGroups,
          adminSetting: cloneDeep(this.masterData.adminSetting),
          staffSetupExcludedRoles: this.masterData.staffSetupExcludedRoles,
          territoryCollectionOperations: filterItemsByDateRange(this.masterData.territoryCollectionOperations, {
            startField: 'startDate',
            startValue: drive.driveDate
          }, {
            endField: 'endDate',
            endValue: drive.driveDate
          }),
          roleTimeData: {
            roleTimeDetails: filterRoleTimeDetails(globalRoleTimeDetails.concat(roleTimeDetailsMap[drive.collectionOperationId] || []), {
              driveDate: drive.driveDate,
              driveType: drive.typeOfDrive,
              mobileType: driveSiteMap[drive.driveSiteId].physicalLocationType
            }, {
              endField: 'effectiveEndDate',
              endValue: drive.driveDate
            }),
            roleTimeVariances: filterItemsByDateRange(roleTimeVariancesMap[drive.driveSiteId] || [], {
              startField: 'effectiveStartDate',
              startValue: drive.driveDate
            }, {
              endField: 'effectiveEndDate',
              endValue: drive.driveDate
            })
          },
          sameDateActivities: filterItemsByDateRange(this.masterData.activities, {
            startField: 'start',
            startValue: drive.driveDate
          }, {
            endField: 'finish',
            endValue: drive.driveDate
          }),
          sameDateDrives: filterItemsByDateRange(this.masterData.drives, {
            startField: 'driveDate',
            startValue: drive.driveDate
          }, {
            endField: 'driveDate',
            endValue: drive.driveDate
          }),
          staffingDecisionMatrix: validCollectionOperationSDM.length > 0 ? staffingDecisionMatrixMap[validCollectionOperationSDM[0].staffingDecisionMatrixId] : {},
          fixedSiteProcedureProjections: filterItemsByDateRange(retrieveFixedSiteProcedureProjectionsMap[drive.accountId], {
            startField: 'effectiveStartDate',
            startValue: drive.driveDate
          }, {
            endField: 'effectiveEndDate',
            endValue: drive.driveDate
          }),
          vehicles: vehiclesMap[drive.collectionOperationId] || [],
          travelTimeIndexItemMap: this.masterData.travelTimeIndexItemMap,
          collectionOperationTimeBlocks: filterItemsByDateRange(collectionOperationTimeBlocksMap[drive.collectionOperationId] || [], {
            startField: 'effectiveStartDate',
            startValue: drive.driveDate
          }, {
            endField: 'effectiveEndDate',
            endValue: drive.driveDate
          }),
          staffCountThresholds: this.masterData.staffCountThresholds
        }
      })

      this.driveGeneratorInstanceMap[drive.id] = driveGeneratorInstance;

      return drive;
    })
  }

  proposeDriveShifts() {
    this.drives.forEach(drive => {
      let driveGeneratorInstance = this.driveGeneratorInstanceMap[drive.id];
      driveGeneratorInstance.proposeDriveShifts();
      drive = driveGeneratorInstance.drive;
    });
    return this.drives;
  }

  generateDrives({
    skipGenerateSlots = false
  }) {
    this.drives.forEach(drive => {
      let driveGeneratorInstance = this.driveGeneratorInstanceMap[drive.id];

      driveGeneratorInstance.calculateTotalProceduresProjected();
      driveGeneratorInstance.calculateDriveShiftsMetadata();
      driveGeneratorInstance.calculateNumberOf2rbcAssets();
      driveGeneratorInstance.calculatePreferredNumberOf2rbcAssets();
      
      driveGeneratorInstance.proposeDriveShifts({
        skipGenerateSlots
      });
      driveGeneratorInstance.calculateDriveProductivityPlanned();

      drive = driveGeneratorInstance.drive;
    });
    return this.drives;
  }

  proposeVehicles() {
    let sortedDrives = orderBy(this.drives, ['projectedRegisteredDonors', 'id'], ['asc', 'asc']);
    let groupedDrivesByDriveDate = groupBy(sortedDrives, 'driveDate');

    let isAnyGroupNotEnoughVehicles = false;
    Object.keys(groupedDrivesByDriveDate).forEach(driveDate => {
      if(isAnyGroupNotEnoughVehicles) return;

      //TODO: future ticket
      let drives = groupedDrivesByDriveDate[driveDate];
      let helper = new DriveHelper();
      let drivesWithVehicles = helper.calculateNumberOfVehicles(drives, this.masterData.vehicles);

      if (!drivesWithVehicles || !drivesWithVehicles.length) {
        isAnyGroupNotEnoughVehicles = true;
        return;
      } 
      
      //only have data if can assign vehicles to all input drives
      drives.forEach(drive => {
        let currentDrive = drivesWithVehicles.find(drivesWithVehicle => drivesWithVehicle.driveKey == drive.key);
        let noOfVehicles = currentDrive.vehicles.length;
        let currentNoOfVehicles = drive.totalVehicleRequested;

        if(noOfVehicles > 0 && noOfVehicles !== currentNoOfVehicles) {
          let driveGeneratorInstance = this.driveGeneratorInstanceMap[drive.id];

          driveGeneratorInstance.onDriveDataChanged([{
            targetName: 'totalVehicleRequestedChanged',
            targetValue: {
              totalVehicleRequested: noOfVehicles,
              vehicles: currentDrive.vehicles
            }
          }])
          .then(() => {
            drive = driveGeneratorInstance.drive
          })
        }
      })
    })

    return !isAnyGroupNotEnoughVehicles;
  }
}

export default SlwcDrivesGenerator;