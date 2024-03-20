import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AccountBridgeApiMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'AccountBridgeAPI__x';
      mappingConfig.objectType = 'accountBridgeApi';

      mappingConfig.addFieldConfig('external_id__c', 'externalId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('guid__c', 'guid', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}