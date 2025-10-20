import { dataService, queryModelBase } from './base';

class dcrRoleService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_DCR_Role__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.orderClause = 'ORDER BY sked_Sort_Order__c ASC';
  }
}

class dcrRoleQueryModel extends queryModelBase  {}

export {
  dcrRoleService,
  dcrRoleQueryModel
}