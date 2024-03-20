import { dataService, queryModelBase } from './base';

class productGoalService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Product_Goal__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds) {
          queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.driveTypes && query.driveTypes.length) {
          queryBuilder.addCondition({template: "sked_Drive_Type__c IN {0}", value: query.driveTypes, type: "array_string"});
      }
      if (query.procedureTypes && query.procedureTypes.length) {
          queryBuilder.addCondition({template: "sked_Procedure_Type__c IN {0}", value: query.procedureTypes, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Date_of_Goal__c >= {0}", value: query.startDate});
          queryBuilder.addCondition({template: "sked_Date_of_Goal__c <= {0}", value: query.endDate});
      }
  }
}

class productGoalQueryModel extends queryModelBase { 
  collectionOperationIds;
  driveTypes;
  procedureTypes;
  endDate;
  startDate;
}

export {
  productGoalService,
  productGoalQueryModel
}