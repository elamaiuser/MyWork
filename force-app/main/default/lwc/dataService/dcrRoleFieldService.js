import { dataService, queryModelBase } from './base';

class dcrRoleFieldService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_DCR_Role_Field__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
  }
}

class dcrRoleFieldQueryModel extends queryModelBase  {}

export {
  dcrRoleFieldService,
  dcrRoleFieldQueryModel
}