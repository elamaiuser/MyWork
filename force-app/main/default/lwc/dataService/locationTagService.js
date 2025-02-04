import { dataService, queryModelBase } from './base';

class locationTagService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Location_Tag__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.locationIds && query.locationIds.length) {
          queryBuilder.addCondition({template: 'sked_Location__c IN {0}', value: query.locationIds, type: "array_string"});
      }
  }
}

class locationTagQueryModel extends queryModelBase { 
  locationIds;
}

export {
  locationTagService,
  locationTagQueryModel
}