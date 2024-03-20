import { dataService, queryModelBase } from './base';

class linkedDrivesService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Linked_Drives__c';
  }
  
  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

      //Related List
      let driveQueryBuilder = query.getQueryBuilder('sked_Drive__c');
      let activityQueryBuilder = query.getQueryBuilder('sked__Activity__c');
  }
}

class linkedDrivesQueryModel extends queryModelBase { }

export {
  linkedDrivesService,
  linkedDrivesQueryModel
}