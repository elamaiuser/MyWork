import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class SiteBridgeApiMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'SiteBridgeAPI__x';
      mappingConfig.objectType = 'siteBridgeApi';

      mappingConfig.addFieldConfig('external_id__c', 'externalId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('guid__c', 'guid', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}