import { dataService, queryModelBase, sObjectType } from './base';

class stagingLocationService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Staging_Location__c';
  }
}

class stagingLocationQueryModel extends queryModelBase {}

export {
  stagingLocationService,
  stagingLocationQueryModel
}