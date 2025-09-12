import { dataService, queryModelBase } from './base';

class operationDriveLimitService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Operation_Drive_Limit__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds) {
          queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.effectiveEndDate && query.effectiveStartDate) {
        queryBuilder.addCondition({ template: `( 
          (sked_Effective_Start_Date__c = NULL AND sked_Effective_End_Date__c = NULL) OR 
          (sked_Effective_Start_Date__c != NULL AND sked_Effective_End_Date__c = NULL AND sked_Effective_Start_Date__c <= ${query.effectiveEndDate}) OR 
          (sked_Effective_Start_Date__c <= ${query.effectiveEndDate} AND sked_Effective_End_Date__c >= ${query.effectiveStartDate}) 
        )` });
      }
      //Related List
      let subQueryBuilder = query.getQueryBuilder("sked_Operation_Drive_Limit_Override__c");
      if (query.effectiveEndDate && query.effectiveStartDate) {
          subQueryBuilder.addCondition({template: "sked_Date__c >= {0}", value: query.effectiveStartDate});
          subQueryBuilder.addCondition({template: "sked_Date__c <= {0}", value: query.effectiveEndDate});
      }
      if (query.type) {
        queryBuilder.addCondition({template: "sked_Type__c = {0}", value: query.type});
      }
  }
}

class operationDriveLimitQueryModel extends queryModelBase { 
  collectionOperationIds;
  effectiveEndDate;
  effectiveStartDate;
}

export {
  operationDriveLimitService,
  operationDriveLimitQueryModel
}