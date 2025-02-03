import { dataService, queryModelBase } from './base';

class recurringScheduleService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Recurring_Schedule__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
  }
}

class recurringScheduleQueryModel extends queryModelBase { }

export {
  recurringScheduleService,
  recurringScheduleQueryModel
}