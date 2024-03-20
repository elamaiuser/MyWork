import { dataService, queryModelBase } from './base';

class fixedSiteProcedureProjectionService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Fixed_Site_Procedure_Projection__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.accountIds && query.accountIds.length) {
          queryBuilder.addCondition({template: "sked_Account__c IN {0}", value: query.accountIds, type: "array_string"});
      }
      if (query.impactDrives === true || query.impactDrives === false) {
          queryBuilder.addCondition({template: "sked_Impact_Drives__c = {0}", value: query.impactDrives});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "(sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= {0})", value: query.endDate});
          queryBuilder.addCondition({template: "(sked_Effective_End_date__c = NULL OR sked_Effective_End_date__c >= {0})", value: query.startDate});
      }
  }
}

class fixedSiteProcedureProjectionQueryModel extends queryModelBase { 
  accountIds;
  impactDrives;
  startDate;
  endDate
}

export {
  fixedSiteProcedureProjectionService,
  fixedSiteProcedureProjectionQueryModel
}