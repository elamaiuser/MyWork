import { dataService, queryModelBase } from './base';
import { isEmpty } from 'c/lodash';

class availabilityPatternRoleService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'Availability_Pattern_Role__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.colOpAvailabilityIds && !isEmpty(query.colOpAvailabilityIds)) {
        queryBuilder.addCondition({template: "Collection_Operation_Availability__c IN {0}", value: query.colOpAvailabilityIds, type: "array_string"});
      }
  }
}

class availabilityPatternRoleQueryModel extends queryModelBase  {
  roles;
  colOpAvailabilityIds;
}

export {
  availabilityPatternRoleService,
  availabilityPatternRoleQueryModel
}