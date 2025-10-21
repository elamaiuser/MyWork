import { dataService, queryModelBase } from './base';

class accountTagService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Account_Tag__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.accountIds && query.accountIds.length) {
          queryBuilder.addCondition({template: 'sked__Account__c IN {0}', value: query.accountIds, type: "array_string"});
      }
  }
}

class accountTagQueryModel extends queryModelBase { 
  accountIds;
}

export {
  accountTagService,
  accountTagQueryModel
}