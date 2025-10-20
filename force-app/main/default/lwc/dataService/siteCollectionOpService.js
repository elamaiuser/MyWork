import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';

class siteCollectionOpService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Site_Collection_Operation__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
    
    if (query.collectionOperationIds && query.collectionOperationIds.length) {
      queryBuilder.addCondition({ template: "sked_Collection_Operation__c IN {0} AND sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY", value: query.collectionOperationIds, type: "array_string" });
    }
  }

  manualRefreshTravelTimeIndexes = (params) => auraProxy.getInstance().manualRefreshTravelTimeIndexes(params);
  isManualRefreshInProgress = (params) => auraProxy.getInstance().isManualRefreshInProgress(params);
  hasInvalidTravelTimeData = (params) => auraProxy.getInstance().hasInvalidTravelTimeData(params);
  getRelatedSiteInfo = (params) => auraProxy.getInstance().getRelatedSiteInfo(params);
  isSCOUserOverrideEnabled = (params) => auraProxy.getInstance().isSCOUserOverrideEnabled(params);
}

class siteCollectionOpQueryModel extends queryModelBase {
  collectionOperationIds;
}

export {
  siteCollectionOpQueryModel,
  siteCollectionOpService
}