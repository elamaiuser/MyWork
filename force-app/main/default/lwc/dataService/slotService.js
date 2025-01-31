import { dataService, queryModelBase } from './base';

class slotService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Slot__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.driveIds && query.driveIds.length) {
          queryBuilder.addCondition({template: "sked_Drive__c IN {0}", value: query.driveIds, type: "array_string"});
      }
  }
}

class slotQueryModel extends queryModelBase { 
  driveIds;
}

export {
  slotService,
  slotQueryModel
}