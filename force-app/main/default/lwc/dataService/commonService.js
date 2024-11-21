import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';
import { siteFeedbackService, siteFeedbackQueryModel } from './siteFeedbackService';
import { driveShiftTradeService, driveShiftTradeQueryModel } from './driveShiftTradeService';
import { driveChangeRequestService, driveChangeRequestQueryModel } from './driveChangeRequestService';
import { driveService, driveQueryModel } from './driveService';

class commonService extends dataService {
  constructor() {
    super();
  }

  getServiceBySObjectName = (sObjectName) => {
    switch(sObjectName) {
      case 'sked_Site_Feedback__c': {
        return {
          service: new siteFeedbackService(),
          queryModel: new siteFeedbackQueryModel()
        }
      };
      case 'sked_Drive_Shift_Trade__c': {
        return {
          service: new driveShiftTradeService(),
          queryModel: new driveShiftTradeQueryModel()
        }
      };
      case 'sked_Drive__c': {
        return {
          service: new driveService(),
          queryModel: new driveQueryModel()
        }
      }
      case 'sked_Drive_Change_Request__c': {
        return {
          service: new driveChangeRequestService(),
          queryModel: new driveChangeRequestQueryModel()
        }
      }
      default: {
        return null
      }
    }
  }
}

export {
  commonService
}