import { dataService, queryModelBase } from './base';

class tagService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Tag__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.resourceTypes && query.resourceTypes.length) {
          queryBuilder.addCondition({template: "sked_Resource_Type__c INCLUDES {0}", value: query.resourceTypes, type: "array_string"});
      }

      if (query.nonSystem == true) {
          let systemTagTypes = ["Role", "Asset Type", "Physical Location Type", "Drive Type"];
          queryBuilder.addCondition({template: "sked__Type__c NOT IN {0}", value: systemTagTypes, type: "array_string"});
      }
  }
}

class tagQueryModel extends queryModelBase {
  nonSystem;
}

export { 
  tagService,
  tagQueryModel
}