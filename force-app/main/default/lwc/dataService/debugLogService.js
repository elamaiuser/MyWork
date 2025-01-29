import { dataService, queryModelBase } from './base';
import USER_ID from "@salesforce/user/Id";
import { jsonFriendlyErrorReplacer } from 'c/slwcUtils';

class debugLogService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Debug_Log__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
  }

  captureDebugLog = (error, driveId) => {
    try {
      console.log(error);
      const debugLog = {
        userId: USER_ID,
        type: 'Error Log',
        summary: JSON.stringify(error, jsonFriendlyErrorReplacer),
        message: driveId ? `LWC Error: ${driveId}` : (error && error.message) ? error.message : ''
      };
      return this.save(debugLog);
    } catch(e) {
        console.log(e);
    }
  }
}

class debugLogQueryModel extends queryModelBase { }

export {
  debugLogQueryModel,
  debugLogService
};