import { dataService, queryModelBase } from './base';

class staffMealAndRestBreakService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Staff_Meal_Rest_Break_Setting__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.opRecordStaffIds && query.opRecordStaffIds.length) {
          queryBuilder.addCondition({template: 'sked_Operation_Record_Staff__c IN {0}', value: query.opRecordStaffIds, type: "array_string"});
      }
  }
}

class staffMealAndRestBreakQueryModel extends queryModelBase { 
  opRecordStaffIds;
}

export {
    staffMealAndRestBreakService,
    staffMealAndRestBreakQueryModel
}