import { dataService, queryModelBase } from './base';

class accountBridgeApiService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'AccountBridgeAPI__x';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.accountIds && query.accountIds.length) {
      queryBuilder.addCondition({ template: 'guid__c IN {0}', value: query.accountIds, type: "array_string" });
    }
  }
}

class accountBridgeApiQueryModel extends queryModelBase  {
  accountIds;
}

export {
  accountBridgeApiService,
  accountBridgeApiQueryModel
}