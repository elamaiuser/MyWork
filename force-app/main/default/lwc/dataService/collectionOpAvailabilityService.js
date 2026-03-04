import { dataService, queryModelBase } from './base';

class collectionOpAvailabilityService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'Collection_Operation_Availability__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds) {
        queryBuilder.addCondition({template: "Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      let subQueryBuilder = query.getQueryBuilder("Availability_Pattern_Role__c");
  }
}

class collectionOpAvailabilityQueryModel extends queryModelBase  {
  collectionOperationId;
}

export {
  collectionOpAvailabilityService,
  collectionOpAvailabilityQueryModel
}