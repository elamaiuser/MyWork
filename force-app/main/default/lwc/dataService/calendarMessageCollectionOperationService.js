import { dataService, queryModelBase } from './base';

class calendarMessageCollectionOperationService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_CalendarMessage_CollectionOperation__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds && query.collectionOperationIds.length) {
          queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Calendar_Message__r.sked_Start_Date__c <= {0}", value: query.endDate});
          queryBuilder.addCondition({template: "sked_Calendar_Message__r.sked_End_Date__c >= {0}", value: query.startDate});
      }
  }
}
class calendarMessageCollectionOperationQueryModel extends queryModelBase {
  collectionOperationIds;
  endDate;
  startDate;
}

export {
  calendarMessageCollectionOperationService,
  calendarMessageCollectionOperationQueryModel
}