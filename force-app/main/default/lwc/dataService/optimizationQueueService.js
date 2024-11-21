import { dataService, queryModelBase, sObjectType } from './base';

class optimizationQueueService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Optimization_Queue__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds && query.collectionOperationIds.length) {
          queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.optimizationRunIds && query.optimizationRunIds.length) {
          queryBuilder.addCondition({template: "sked_Optimization_Run__c IN {0}", value: query.optimizationRunIds, type: "array_string"});
      }
      if (query.driveTypes && query.driveTypes.length) {
          queryBuilder.addCondition({template: "sked_Drive_Type__c IN {0}", value: query.driveTypes, type: "array_string"});
      }
      if (query.statuses && query.statuses.length) {
          queryBuilder.addCondition({template: "sked_Status__c IN {0}", value: query.statuses, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Start_Date__c <= {0}", value: query.endDate});
          queryBuilder.addCondition({template: "sked_End_Date__c >= {0}", value: query.startDate});
      }
      queryBuilder.orderClause = "ORDER BY sked_Start_Date__c ASC";

      if (query.includes(sObjectType.OPTIMIZATION_QUEUE_ITEM)) {
          let subQueryBuilder = query.getQueryBuilder("sked_Optimization_Queue_Item__c");
      }
  }
}

class optimizationQueueQueryModel extends queryModelBase { 
  collectionOperationIds;
  endDate;
  driveTypes;
  optimizationRunIds;
  startDate;
  statuses;
}

export {
  optimizationQueueService,
  optimizationQueueQueryModel
}