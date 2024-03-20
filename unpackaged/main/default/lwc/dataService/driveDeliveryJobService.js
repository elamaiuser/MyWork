import { dataService, queryModelBase, sObjectType } from './base';

class driveDeliveryJobService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Drive_Delivery_Job__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.driveIds && query.driveIds.length) {
          queryBuilder.addCondition({template: "sked_Drive__c IN {0}", value: query.driveIds, type: "array_string"});
      }
      if (query.includes(sObjectType.DRIVE_BAG)) {
          let subQueryBuilder = query.getQueryBuilder("sked_Drive_Bag__c");
      }
      queryBuilder.orderClause = 'ORDER BY sked_Start_Time__c ASC';
  }
}

class driveDeliveryJobQueryModel extends queryModelBase  {
  driveIds;
}

export {
  driveDeliveryJobService,
  driveDeliveryJobQueryModel
}