import { dataService, queryModelBase } from './base';

class collectionOperationOptimizerSettingService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_CollectionOperationOptimizerSetting__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds) {
        queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      queryBuilder.orderClause = 'ORDER BY sked_Display_Order__c ASC';
  }
}

class collectionOperationOptimizerSettingQueryModel extends queryModelBase  {
  collectionOperationIds;
}

export {
  collectionOperationOptimizerSettingService,
  collectionOperationOptimizerSettingQueryModel
}