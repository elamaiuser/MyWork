import { dataService, queryModelBase, sObjectType } from './base';

class activityCollectionOperationService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Activity_Collection_Operation__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({ template: 'sked_Biomed_Collection_Operation__c IN {0}', value: query.collectionOperationIds, type: "array_string" });
    }

    if (query.startDate && query.endDate) {
      queryBuilder.addCondition({ template: "sked_Activity__r.sked_Start_Date__c >= {0}", value: query.startDate });
      queryBuilder.addCondition({ template: "sked_Activity__r.sked_Start_Date__c <= {0}", value: query.endDate });
    }

    if (query.activityTypes && query.activityTypes.length) {
      queryBuilder.addCondition({ template: 'sked_Activity__r.sked__Type__c IN {0}', value: query.activityTypes, type: "array_string" });
    }
  }
}

class activityCollectionOperationQueryModel extends queryModelBase {
  collectionOperationIds;
  endDate;
  startDate;
  activityTypes;
}

export {
  activityCollectionOperationQueryModel,
  activityCollectionOperationService
}