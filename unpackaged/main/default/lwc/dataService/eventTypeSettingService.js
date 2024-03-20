import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';

class eventTypeSettingService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Event_Type_Setting__c';
  }

  getEventTypeSettings = (params) => auraProxy.getInstance().getEventTypeSettings(params);
}

class eventTypeSettingQueryModel extends queryModelBase { }

export {
  eventTypeSettingService,
  eventTypeSettingQueryModel
}