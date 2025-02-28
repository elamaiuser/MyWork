import { dataService, queryModelBase } from './base';

class collectionOperationStagingLocationService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Collection_Op_Staging_Location__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({ template: 'sked_Collection_Operation__c IN {0}', value: query.collectionOperationIds, type: "array_string" });
    }
    queryBuilder.orderClause = 'ORDER BY sked_Start_Date__c ASC';
  }
}

class collectionOperationStagingLocationQueryModel extends queryModelBase  {
  collectionOperationIds;
}

export {
  collectionOperationStagingLocationService,
  collectionOperationStagingLocationQueryModel
}