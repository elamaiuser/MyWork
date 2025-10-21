import { dataService, queryModelBase } from './base';

class holidayCollectionOperationService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Holiday_Collection_Operation__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds && query.collectionOperationIds.length) {
          queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Holiday__r.sked__Start_Date__c <= {0}", value: query.endDate});
          queryBuilder.addCondition({template: "sked_Holiday__r.sked__End_Date__c >= {0}", value: query.startDate});
      }
  }
}
class holidayCollectionOperationQueryModel extends queryModelBase {
  collectionOperationIds;
  endDate;
  startDate;
}

export {
  holidayCollectionOperationService,
  holidayCollectionOperationQueryModel
}