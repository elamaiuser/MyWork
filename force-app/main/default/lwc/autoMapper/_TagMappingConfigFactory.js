import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class TagMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Tag__c';
      mappingConfig.objectType = 'tag';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Type__c', 'type', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Type__c', 'resourceType', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('sked_Priority__c', 'priority', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}