import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';
import { isNullOrEmpty } from 'c/slwcUtils';

class locationService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Location__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.addCondition({template: "sked_Active__c = TRUE"});

      if(!isNullOrEmpty(query.name)) {
        queryBuilder.addCondition({template: "Name LIKE '%{0}%'", value: query.name.trim() });
      }
      
      //Related List
      let siteCollectionOperationSubQueryBuilder = query.getQueryBuilder("sked_Site_Collection_Operation__c");

      queryBuilder.orderClause = 'ORDER BY Name ASC';
  }

  getStandardAddress = (params) => auraProxy.getInstance().getStandardAddress(params);
  getTimezone = (params) => auraProxy.getInstance().getTimezone(params);
}

class locationQueryModel extends queryModelBase { 
  name;
}

export {
  locationService,
  locationQueryModel
}