import { dataService, queryModelBase } from './base';

class resourceSecondaryCollectionOperationService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Resource_Biomed_Collection_Op__c';
  }
  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({ template: "sked_Biomed_Collection_Op_Center__c IN {0}", value: query.collectionOperationIds, type: "array_string" });
    }

    if (query.excludedResourceIds && query.excludedResourceIds.length) {
      queryBuilder.addCondition({ template: "sked_Resource__c NOT IN {0}", value: query.excludedResourceIds, type: "array_string" });
    }

    if (query.resourceIds && query.resourceIds.length) {
      queryBuilder.addCondition({ template: "sked_Resource__c IN {0}", value: query.resourceIds, type: "array_string" });
    }

    if (query.resourceTypes && query.resourceTypes.length) {
      queryBuilder.addCondition({ template: "sked_Resource__r.sked__Resource_Type__c IN {0}", value: query.resourceTypes, type: "array_string" });
    }

    if (query.startDate && query.endDate) {
      queryBuilder.addCondition({template: "(sked_Start_Date__c = NULL OR sked_Start_Date__c <= {0})", value: query.endDate});
      queryBuilder.addCondition({template: "(sked_End_Date__c = NULL OR sked_End_Date__c >= {0})", value: query.startDate});
    }
  }
}
class resourceSecondaryCollectionOperationQueryModel extends queryModelBase {
  collectionOperationIds;
  endDate;
  excludedResourceIds;
  resourceIds;
  resourceTypes;
  startDate;
}

export {
  resourceSecondaryCollectionOperationService,
  resourceSecondaryCollectionOperationQueryModel
}