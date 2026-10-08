import { dataService, queryModelBase } from './base';

class slotConfigurationDefaultService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Slot_Configuration_Default__mdt';
  }
}

class slotConfigurationDefaultQueryModel extends queryModelBase {}

export {
  slotConfigurationDefaultService,
  slotConfigurationDefaultQueryModel
}
