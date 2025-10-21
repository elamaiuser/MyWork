import { dataService, queryModelBase } from './base';

class siteBridgeApiService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'SiteBridgeAPI__x';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.siteIds && query.siteIds.length) {
      queryBuilder.addCondition({ template: 'guid__c IN {0}', value: query.siteIds, type: "array_string" });
    }
  }
}

class siteBridgeApiQueryModel extends queryModelBase  {
  siteIds;
}

export {
  siteBridgeApiService,
  siteBridgeApiQueryModel
}