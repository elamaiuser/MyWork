import { MobileGenerator, DRIVE_FIELD_CHANGE_MAPPING as mobileDriveFieldMapping } from './mobileGenerator.js';
import { WbFixedSiteGenerator, DRIVE_FIELD_CHANGE_MAPPING as wbFixedSiteDriveFieldMapping } from './wbFixedSiteGenerator.js';
import { FixedSiteGenerator, DRIVE_FIELD_CHANGE_MAPPING as fixedSiteDriveFieldMapping } from './fixedSiteGenerator.js';
import SlwcDrivesGenerator from './drivesGenerator.js';
import {
  opportunityService, opportunityQueryModel, driveService, driveQueryModel, sObjectType
} from 'c/dataService';
import { OPERATION_TYPE, DRIVE_TYPE } from 'c/slwcConstants';
import { DriveHelper } from './helper';
import { Fetch } from './fetch';

class SlwcDriveGeneratorHelper {
  initialize(recordId) {
    let driveGeneratorInstance;
    return Promise.resolve()
      .then(() => {
        if (recordId.startsWith('006')) {
          return this.getOpportunityData(recordId);
        } else {
          return this.getDriveData(recordId);
        }
      })
      .then((driveOrOpp) => {
        if (driveOrOpp.typeOfDrive === DRIVE_TYPE.FIXED_SITE) {
          if (driveOrOpp.operationType === OPERATION_TYPE.NON_INTEGRATED_WB) {
            driveGeneratorInstance = new WbFixedSiteGenerator();
          }
          else {
            driveGeneratorInstance = new FixedSiteGenerator();
          }
        } else {
          driveGeneratorInstance = new MobileGenerator();
        }
      })
      .then(() => {
        if (recordId.startsWith('006')) {
          return driveGeneratorInstance.initializeFromOptyId(recordId);
        } else {
          return driveGeneratorInstance.editDrive(recordId);
        }
      })
      .then((drive) => {
        return {
          driveGeneratorInstance: driveGeneratorInstance,
          drive: drive
        }
      })
  }

  getOpportunityData(oppId) {
    let queryModel = new opportunityQueryModel();
    queryModel.recordIds = [oppId];
    queryModel.subQueryIndicator = sObjectType.OPPORTUNITY_CONTACT_ROLE;
    let service = new opportunityService();
    return service.query(queryModel)
      .then(([opportunity]) => {
        return opportunity;
      })
  }

  getDriveData(driveId) {
    let queryModel = new driveQueryModel();
    queryModel.recordIds = [driveId];
    let service = new driveService();
    return service.query(queryModel)
      .then(([drive]) => {
        return drive;
      })
  }
}

let slwcDriveGeneratorHelper = new SlwcDriveGeneratorHelper();
let drivesGeneratorInstance = new SlwcDrivesGenerator();

export {
  slwcDriveGeneratorHelper,
  drivesGeneratorInstance,
  DriveHelper,
  SlwcDrivesGenerator,
  Fetch as DriveFetch
}