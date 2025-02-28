import { dataService, queryModelBase } from './base';

class driveBridgeApiService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'DriveBridgeAPI__x';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.driveIds && query.driveIds.length) {
      queryBuilder.addCondition({ template: 'guid__c IN {0}', value: query.driveIds, type: "array_string" });
    }
  }
}

class driveBridgeApiQueryModel extends queryModelBase  {
  driveIds;
}

export {
  driveBridgeApiService,
  driveBridgeApiQueryModel
}