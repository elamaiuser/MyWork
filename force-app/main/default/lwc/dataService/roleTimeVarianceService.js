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
      if (query.daysOfWeek && query.daysOfWeek.length) {
          queryBuilder.addCondition({template: "sked_Days_Of_Week__c INCLUDES{0}", value: query.daysOfWeek, type: "array_string"});
      }
      if (query.excludeExpiry) {
          queryBuilder.addCondition({template: "(sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= TODAY)"});
      }
  }
}

class roleTimeVarianceQueryModel extends queryModelBase {
  driveSiteIds;
  endDate;
  startDate;
  excludeExpiry;
  daysOfWeek;
}

export {
  roleTimeVarianceService,
  roleTimeVarianceQueryModel
}