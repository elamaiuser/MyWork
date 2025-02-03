import { dataService, queryModelBase } from './base';

class exceptionSettingService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Exception_Setting__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.orderClause = 'ORDER BY sked_Exception_Code__c ASC';
  }
}

class exceptionSettingQueryModel extends queryModelBase { }

export {
  exceptionSettingService,
  exceptionSettingQueryModel
}