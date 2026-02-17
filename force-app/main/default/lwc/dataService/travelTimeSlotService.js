import { dataService, queryModelBase } from './base';

class travelTimeSlotService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Travel_Time_Slot__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({ template: 'sked_Collection_Operation__c IN {0}', value: query.collectionOperationIds, type: "array_string" });
    }
  }
}

class travelTimeSlotQueryModel extends queryModelBase  {
  collectionOperationIds;
}

export {
  travelTimeSlotService,
  travelTimeSlotQueryModel
}
