import { dataService, queryModelBase } from './base';

class travelTimeIndexItemService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Travel_Time_Index_Item__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.keys && query.keys.length) {
      queryBuilder.addCondition({ template: 'sked_Key__c IN {0}', value: query.keys, type: "array_string" });
    }
  }
}

class travelTimeIndexItemQueryModel extends queryModelBase  {
  keys;
}

export {
  travelTimeIndexItemService,
  travelTimeIndexItemQueryModel
}