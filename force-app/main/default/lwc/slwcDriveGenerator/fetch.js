import {
  collectionOperationSdmService, dataService,
  activityService, activityQueryModel,
  driveService, driveQueryModel,
  locationService, locationQueryModel,
  userService, jobAllocationService,
  opportunityService, opportunityQueryModel,
  fixedSiteProcedureProjectionService, fixedSiteProcedureProjectionQueryModel,
  driveChangeRequestService, driveChangeRequestQueryModel,
  operationDriveLimitQueryModel, operationDriveLimitService,
  collectionOperationStagingLocationService, collectionOperationStagingLocationQueryModel,
  roleTimeDetailService, sObjectType, territoryCollectionOperationService, territoryCollectionOperationQueryModel, operationRecordQueryModel, travelTimeIndexItemService, travelTimeIndexItemQueryModel
} from 'c/dataService';
import * as autoMapper from 'c/autoMapper';
import { DRIVE_TYPE, ASSET_TYPE, PENDING_ACTION, DRIVE_REQUEST_CHANGE_STATUS, DRIVE_CHANGE_REQUEST_TYPE } from 'c/slwcConstants';
import { keyBy, groupBy, uniq } from 'c/lodash';
import { getTravelTimeIndexKey } from 'c/slwcUtils';
class Fetch {
  driveType = DRIVE_TYPE.MOBILE;

  constructor({
    driveType
  }) {
    this.driveType = driveType;
  }

  get settingKeys() {
    if(this.driveType === DRIVE_TYPE.MOBILE) {
      return ['adminSetting', 'resourceRoleGroups', 'lunchBreakSettings', 'staffSetupExcludedRoles', 'redcrossVolunteerMatrix'];
    } else {
      return ['adminSetting', 'resourceRoleGroups', 'lunchBreakSettings', 'staffSetupExcludedRoles'];
    }
  }

  retrieveOpportunity(oppId) {
    let queryModel = new opportunityQueryModel();
    queryModel.recordIds = [oppId];
    queryModel.subQueryIndicator = sObjectType.DRIVE | sObjectType.OPPORTUNITY_CONTACT_ROLE;
    let service = new opportunityService();

    return service.query(queryModel)
    .then(result => {
      return result[0];
    })
  }

  retrieveCustomSettings() {
    return Promise.resolve()
      .then(() => {
        let service = new dataService();
        return service.getCustomSettings({ settingKeys: this.settingKeys })
          .then((result) => {
            return {
              adminSetting: result.returnedData.adminSetting,
              resourceRoleGroups: result.returnedData.resourceRoleGroups,
              lunchBreakSettings: autoMapper.autoMapperInstance.mapToArray('sked_Lunch_Break_Setting__c', result.returnedData.lunchBreakSettings),
              staffSetupExcludedRoles: autoMapper.autoMapperInstance.mapToArray('sked_Staff_Setup_Excluded_Role__c', result.returnedData.staffSetupExcludedRoles),
              redcrossVolunteerMatrix: result.returnedData.redcrossVolunteerMatrix
            }
          })
      });
  }

  retrieveLoginUser() {
    let service = new userService();
    return service.getLoginUser()
      .then((result) => {
        return result.returnedData;
      })
  }

  retrieveCollectionOperationSDM({
    driveDate,
    collectionOperationId
  }) {
    return Promise.resolve()
      .then(() => {
        if (driveDate && collectionOperationId) {
          let collectionOpId = collectionOperationId;
          let service = new collectionOperationSdmService();

          return service.getStaffingDecisionMatrices([collectionOpId], [this.driveType], driveDate, driveDate)
            .then((result) => {
              return result.staffingDecisionMatrix[0];
            })
        }
      });
  }

  retrieveRoleTimeData({
    driveDate,
    collectionOperationId,
    driveSiteId,
    typeOfDrive,
    driveSite
  }) {
    return Promise.resolve()
      .then(() => {
        if (driveDate && collectionOperationId) {
          let service = new roleTimeDetailService();

          return service.getRoleTimeData(driveDate, driveDate, [collectionOperationId], [driveSiteId], [typeOfDrive], [driveSite.physicalLocationType])
            .then(roleTimeData => {
              return roleTimeData;
            })
        }
      });
  }

  retrieveOperationDriveLimit({
    driveDate,
    collectionOperationId
  }) {
    return Promise.resolve()
    .then(() => {
      if (driveDate && collectionOperationId) {
        let service = new operationDriveLimitService();
        let queryModel = new operationDriveLimitQueryModel();
        queryModel.effectiveStartDate = driveDate;
        queryModel.effectiveEndDate = driveDate;
        queryModel.collectionOperationIds = [collectionOperationId];

        return service.query(queryModel)
          .then((result) => {
            return result;
          })
      }
    });
  }

  retrieveDefaultTags({
    accountId,
    driveSiteId
  }) {
    return Promise.resolve()
    .then(() => {
      if (accountId && driveSiteId) {
        let service = new driveService();
        return service.getDefaultTags([accountId], [driveSiteId])
          .then((result) => {
            return result;
          })
      }
    });
  }

  retrieveTravelTimeIndexItemMap({
    driveSite,
  }) {
    const siteCollectionOperations = driveSite.siteCollectionOperations || [];
    const possibleCollectionOperations = siteCollectionOperations.map(item => item.collectionOperation);

    if(!driveSite || !possibleCollectionOperations.length) { 
      return Promise.resolve({}); 
    };

    const { geoLocationLatitude: driveSiteGeoLocationLatitude, geoLocationLongitude: driveSiteGeoLocationLongitude } = driveSite;
    let coStagingLocationService = new collectionOperationStagingLocationService();
    let coStagingLocationQueryModel = new collectionOperationStagingLocationQueryModel();
    coStagingLocationQueryModel.collectionOperationIds = uniq(possibleCollectionOperations.map(item => item.id));

    return coStagingLocationService.query(coStagingLocationQueryModel)
      .then(coStagingLocations => {
        const travelTimeIndexItemKeys = [];
        coStagingLocations?.forEach(coStagingLocation => {
          const { geoLocationLatitude: stagingLocationGeoLocationLatitude, geoLocationLongitude: stagingLocationGeoLocationLongitude } = coStagingLocation.stagingLocation;
          const siteToCOKey = getTravelTimeIndexKey(driveSiteGeoLocationLatitude, driveSiteGeoLocationLongitude, stagingLocationGeoLocationLatitude, stagingLocationGeoLocationLongitude);
          const coToSiteKey = getTravelTimeIndexKey(stagingLocationGeoLocationLatitude, stagingLocationGeoLocationLongitude, driveSiteGeoLocationLatitude, driveSiteGeoLocationLongitude);

          travelTimeIndexItemKeys.push(...[siteToCOKey, coToSiteKey]); 
        });

        if(!travelTimeIndexItemKeys.length) return {};

        let service = new travelTimeIndexItemService();
        let queryModel = new travelTimeIndexItemQueryModel();
        queryModel.keys = travelTimeIndexItemKeys;

        return service.query(queryModel);
      })
      .then(travelTimeIndexItems => {
        return keyBy(travelTimeIndexItems, 'key');
      });
  }

  retrieveDriveSite({
    driveSiteId
  }) {
    return Promise.resolve()
      .then(() => {
        if (driveSiteId) {
          let locationSvc = new locationService();
          let locationQuery = new locationQueryModel();
          locationQuery.recordIds = [driveSiteId];

          return locationSvc.query(locationQuery)
            .then(([driveSite]) => {
              const possibleCollectionOperationIds = driveSite.siteCollectionOperations?.map(item => item.collectionOperationId) || [];
              if(!possibleCollectionOperationIds.length) {
                return driveSite;
              }

              let coStagingLocationService = new collectionOperationStagingLocationService();
              let coStagingLocationQueryModel = new collectionOperationStagingLocationQueryModel();
              coStagingLocationQueryModel.collectionOperationIds = possibleCollectionOperationIds;

              return coStagingLocationService.query(coStagingLocationQueryModel)
                .then(coStagingLocations => {
                  const mapcoStagingLocationsByCOId = groupBy(coStagingLocations, 'collectionOperationId');

                  driveSite.siteCollectionOperations.forEach(siteCO => {
                    siteCO.collectionOperation.collectionOpStagingLocations = mapcoStagingLocationsByCOId[siteCO.collectionOperationId] || [];
                  });

                  return driveSite;
                });
            })
        }
      });
  }

  retrieveVehicles({
    collectionOperationId,
    driveDate,
    driveSite
  }) {
    return Promise.resolve()
      .then(() => {
        if (collectionOperationId && driveDate) {
          let request = {
            accountIds: [],
            collectionOperationIds: [collectionOperationId],
            locationIds: [],
            inputDates: [driveDate],
            jobIds: [],
            pageSize: 1000,
            pageNo: 1,
            getAssetsOnly: true,
            timezoneSidId: driveSite.timezoneSidId
          }

          let service = new jobAllocationService();
          return service.getResourceData({
            request: request
          })
            .then(result => {
              if (!result || !result.returnedData) {
                throw result;
              }

              return autoMapper.autoMapperInstance.mapToArray('sked__Resource__c', result.returnedData.resources).filter(resource => {
                return resource.assetType === ASSET_TYPE.VEHICLE;
              });;
            })
        }
      });
  }

  retrieveSameDateDrives({
    id,
    collectionOperationId,
    driveDate
  }) {
    return Promise.resolve()
      .then(() => {
        if (driveDate && collectionOperationId) {
          let query = new driveQueryModel();
          query.startDate = driveDate;
          query.endDate = driveDate;
          query.collectionOpId = collectionOperationId;

          let service = new driveService();
          return service.query(query)
            .then((result) => {
              let sameDateDrives = [];
              result.forEach((sameDateDrive) => {
                if (id != sameDateDrive.id) {
                  sameDateDrives.push(sameDateDrive);
                }
              });
              return sameDateDrives;
            })
        }
      });
  }

  retrieveSameDateActivities({
    collectionOperationId,
    driveDate,
  }) {
    return Promise.resolve()
      .then(() => {
        if (driveDate && collectionOperationId) {
          let query = new activityQueryModel();
          query.startDate = driveDate;
          query.endDate = driveDate;
          query.collectionOperationIds = [collectionOperationId];
          query.isGroupActivity = true;
          query.reduceFromStaffingConstraint = true;

          let service = new activityService();
          return service.query(query)
            .then((result) => {
              return result;
            })
        }
      });
  }

  retrieveFixedSiteProcedureProjections({
    accountId,
    driveDate
  }) {
    return Promise.resolve()
      .then(() => {
        if (accountId, driveDate) {
          let fixedSiteProcedureProjectionSvc = new fixedSiteProcedureProjectionService();
          let query = new fixedSiteProcedureProjectionQueryModel();
          query.accountIds = [accountId];
          query.startDate = driveDate;
          query.endDate = driveDate;

          return fixedSiteProcedureProjectionSvc.query(query)
            .then((result) => {
              return result || [];
            });
        }
      });
  }

  retrieveActiveDriveChangeRequest({
    id,
    pendingAction
  }) {
    return Promise.resolve()
      .then(() => {
        if (!id) return null;
        if (pendingAction !== PENDING_ACTION.DRIVE_CHANGE_REQUEST && pendingAction !== null) return null;

        let dcrService = new driveChangeRequestService();
        let dcrQueryModel = new driveChangeRequestQueryModel();
        dcrQueryModel.driveIds = [id];
        dcrQueryModel.statuses = [
          DRIVE_REQUEST_CHANGE_STATUS.PENDING,
          DRIVE_REQUEST_CHANGE_STATUS.SUBMITTED,
          DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL,
          DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL,
          DRIVE_REQUEST_CHANGE_STATUS.APS_WAITING_FOR_DRD_FEEDBACK,
          DRIVE_REQUEST_CHANGE_STATUS.DM_WAITING_FOR_DRD_FEEDBACK
        ];
        dcrQueryModel.subQueryIndicator = sObjectType.DRIVE_CHANGE_REQUEST_ITEM;

        return dcrService.query(dcrQueryModel)
          .then(([driveChangeRequest]) => {
            return driveChangeRequest;
          });
      })
  }
  
  getDriveDetails(driveId) {
    let service = new driveService();
    return service.getDriveById(driveId)
    .then((result) => {
      return result;
    })
  }

  retrieveTerritoryCollectionOperations({
    driveDate,
    collectionOperationId
  }) {

    let service = new territoryCollectionOperationService();
    let queryModel = new territoryCollectionOperationQueryModel();
    queryModel.collectionOperationIds = [collectionOperationId];
    queryModel.startDate = driveDate;
    queryModel.endDate = driveDate;

    return Promise.resolve()
    .then(() => {
      return service.query(queryModel)
    })
    .then((result) => {
        return result || [];
    });
  }
}


export {
  Fetch
}