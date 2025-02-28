import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';
import { COLLECTION_OPERATION } from 'c/slwcConstants';

class territoryCollectionOperationService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Territory_Collection_Operation__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.territoryIds && query.territoryIds.length) {
      queryBuilder.addCondition({template: "sked_Territory__c IN {0}", value: query.territoryIds, type: "array_string"});
    }

    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
    }

    if (query.startDate && query.endDate) {
      queryBuilder.addCondition({template: "(sked_Start_Date__c = NULL OR sked_Start_Date__c <= {0})", value: query.endDate});
      queryBuilder.addCondition({template: "(sked_End_Date__c = NULL OR sked_End_Date__c >= {0})", value: query.startDate});
    }
    queryBuilder.addCondition({template: "sked_Collection_Operation__r.sked_Is_Deactivated__c = FALSE"});
    
    let exludedCONames = [COLLECTION_OPERATION.NON_COLLECTION_AREA];
    queryBuilder.addCondition({template: "sked_Collection_Operation__r.Name NOT IN {0}", value: exludedCONames, type: "array_string"});

    queryBuilder.orderClause = 'ORDER BY sked_Start_Date__c ASC';
  }
}

class territoryCollectionOperationQueryModel extends queryModelBase {
  territoryIds = [];
  collectionOperationIds = [];
  startDate = null;
  endDate = null;
}

export {
  territoryCollectionOperationService,
  territoryCollectionOperationQueryModel
}