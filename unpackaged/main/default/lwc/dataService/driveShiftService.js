import { dataService, queryModelBase, sObjectType } from './base';

class driveShiftService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Drive_Shift__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.driveIds && query.driveIds.length) {
          queryBuilder.addCondition({template: "sked_Drive__c IN {0}", value: query.driveIds, type: "array_string"});
      }
      if (query.includes(sObjectType.SLOT)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Slot__c");
      }
      if (query.includes(sObjectType.DRIVE_SHIFT_TAG)) {
          let subQueryBuilder = query.getQueryBuilder("sked_Drive_Shift_Tag__c");
      }
      queryBuilder.orderClause = 'ORDER BY sked_Start__c ASC';
  }
}

class driveShiftQueryModel extends queryModelBase  {
  driveIds;
}

export {
  driveShiftService,
  driveShiftQueryModel
}