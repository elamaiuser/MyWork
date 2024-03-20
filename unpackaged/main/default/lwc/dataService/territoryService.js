import { dataService, queryModelBase } from './base';

class territoryService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Territory__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.orderClause = 'ORDER BY Name ASC';

      if (query.startDate && query.endDate) {
        queryBuilder.addCondition({template: "(Start_Date__c = NULL OR Start_Date__c <= {0})", value: query.endDate});
        queryBuilder.addCondition({template: "(End_Date__c = NULL OR End_Date__c >= {0})", value: query.startDate});
      }
  }
}

class territoryQueryModel extends queryModelBase {}

export {
  territoryService,
  territoryQueryModel
}