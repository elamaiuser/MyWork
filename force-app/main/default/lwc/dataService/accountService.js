import { dataService, queryModelBase, sObjectType } from './base';
import auraProxy from 'c/auraProxy';

class accountService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'Account';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.includes(sObjectType.ACCOUNT_AVAILABILITY_PREFERENCE)) {
          let subQueryBuilder = query.getQueryBuilder("sked_Account_Availability_Preference__c");
      }
  }

  searchMarket = (params) => auraProxy.getInstance().searchMarket(params);
}

class accountQueryModel extends queryModelBase { }

export {
  accountQueryModel,
  accountService
}