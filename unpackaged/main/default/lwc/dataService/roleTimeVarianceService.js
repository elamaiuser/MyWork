import { dataService, queryModelBase } from './base';

class roleTimeVarianceService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Role_Time_Variance__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.driveSiteIds) {
          queryBuilder.addCondition({template: "sked_Location__c IN {0}", value: query.driveSiteIds, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Effective_Start_Date__c <= {0}", value: query.startDate});
          queryBuilder.addCondition({template: "sked_Effective_End_date__c >= {0}", value: query.endDate});
      }
  }
}

class roleTimeVarianceQueryModel extends queryModelBase {
  driveSiteIds;
  endDate;
  startDate;
}

export {
  roleTimeVarianceService,
  roleTimeVarianceQueryModel
}