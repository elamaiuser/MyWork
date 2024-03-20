import { dataService, queryModelBase } from './base';

class dcrFieldService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_DCR_Field__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.orderClause = 'ORDER BY sked_Field_Label__c ASC';
  }
}

class dcrFieldQueryModel extends queryModelBase  {}

export {
  dcrFieldService,
  dcrFieldQueryModel
}