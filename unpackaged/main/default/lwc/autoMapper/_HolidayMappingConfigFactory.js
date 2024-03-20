import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class HolidayMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Holiday__c';
      mappingConfig.objectType = 'holiday';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name');
      mappingConfig.addFieldConfig('sked__End_Date__c', 'endDate');
      mappingConfig.addFieldConfig('sked__Global__c', 'global');
      mappingConfig.addFieldConfig('sked__Start_Date__c', 'startDate');

      return mappingConfig;
  }
}