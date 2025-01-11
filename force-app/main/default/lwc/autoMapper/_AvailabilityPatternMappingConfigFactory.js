import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AvailabilityPatternMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Availability_Pattern__c';
      mappingConfig.objectType = 'availabilityPattern';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Description__c', 'description', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Hash__c', 'hash', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Pattern__c', 'pattern', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}