import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class RecurringScheduleMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Recurring_Schedule__c';
      mappingConfig.objectType = 'recurringSchedule';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked__Client_Availabilities__r', 'clientAvailabilities', 'sked__Client_Availability__c', 'sked__Recurring_Schedule__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}