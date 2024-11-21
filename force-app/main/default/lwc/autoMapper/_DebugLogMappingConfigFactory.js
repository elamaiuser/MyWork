import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DebugLogMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Debug_Log__c';
      mappingConfig.objectType = 'debugLog';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__User__c', 'userId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Type__c', 'type', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Summary__c', 'summary', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Message__c', 'message', MAPPING_TYPE.direct);

      return mappingConfig;
  }
};