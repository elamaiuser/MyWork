import { dataService, queryModelBase, sObjectType } from './base';

class activityResourceService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked__Activity_Resource__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({ template: 'sked__Activity__r.sked_Region__r.sked_Biomed_Collection_Op_Center__c IN {0}', value: query.collectionOperationIds, type: "array_string" });
    }
    if (query.startDate && query.endDate) {
      queryBuilder.addCondition({ template: "sked_Start_Date__c >= {0}", value: query.startDate });
      queryBuilder.addCondition({ template: "sked_Start_Date__c <= {0}", value: query.endDate });
    }
    if (query.resourceIds && query.resourceIds.length) {
      queryBuilder.addCondition({ template: "sked__Resource__c IN {0}", value: query.resourceIds, type: "array_string" });
    }
    if (query.activityIds && query.activityIds.length) {
      queryBuilder.addCondition({ template: "sked__Activity__c IN {0}", value: query.activityIds, type: "array_string" });
    }
    if (query.isGroupActivity != undefined && query.isGroupActivity != null) {
      queryBuilder.addCondition({ template: "sked__Activity__r.sked_Is_Group_Activity__c = {0}", value: query.isGroupActivity });
    }
  }
}

class activityResourceQueryModel extends queryModelBase {
  collectionOperationIds
  endDate;
  startDate;
  resourceIds;
  activityIds;
  isGroupActivity;
}

export {
  activityResourceQueryModel,
  activityResourceService
}