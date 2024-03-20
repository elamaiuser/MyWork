import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';

class optimizationRunService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Optimization_Run__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds && query.collectionOperationIds.length) {
          queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.territoryKeys && query.territoryKeys.length) {
        queryBuilder.addCondition({template: "sked_Territory_Key__c IN {0}", value: query.territoryKeys, type: "array_string"});
      }
      if (query.statuses && query.statuses.length) {
          queryBuilder.addCondition({template: "sked_Status__c IN {0}", value: query.statuses, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Start_Date__c <= {0}", value: query.endDate});
          queryBuilder.addCondition({template: "sked_End_Date__c >= {0}", value: query.startDate});
      }
      queryBuilder.orderClause = "ORDER BY CreatedDate DESC";
  }
  
  initiateOptimizationRun = (params) => auraProxy.getInstance().initiateOptimizationRun(params);
  getOptimizationRuns = (params) => auraProxy.getInstance().getOptimizationRuns(params);
}

class optimizationRunQueryModel extends queryModelBase { 
  collectionOperationIds;
  territoryKeys;
  endDate;
  startDate;
  statuses;
}

export {
  optimizationRunService,
  optimizationRunQueryModel
}