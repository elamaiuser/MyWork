import { dataService, queryModelBase } from './base';

class collectionOperationTimeBlockService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'Collection_Operation_Time_Block__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({ template: 'Collection_Operation__c IN {0}', value: query.collectionOperationIds, type: "array_string" });
    }
    if (query.effectiveStartDate && query.effectiveEndDate) {
      queryBuilder.addCondition({ template: "Effective_Start_Date__c <= {0}", value: query.effectiveEndDate });
      queryBuilder.addCondition({ template: "Effective_End_Date__c >= {0}", value: query.effectiveStartDate });
    }
  }
}

class collectionOperationTimeBlockQueryModel extends queryModelBase  {
  collectionOperationIds;
  effectiveEndDate;
  effectiveStartDate;
}

export {
  collectionOperationTimeBlockService,
  collectionOperationTimeBlockQueryModel
}