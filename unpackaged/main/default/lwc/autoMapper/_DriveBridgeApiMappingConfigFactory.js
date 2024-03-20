import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveBridgeApiMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'DriveBridgeAPI__x';
      mappingConfig.objectType = 'driveBridgeApi';

      mappingConfig.addFieldConfig('external_id__c', 'externalId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('guid__c', 'guid', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}