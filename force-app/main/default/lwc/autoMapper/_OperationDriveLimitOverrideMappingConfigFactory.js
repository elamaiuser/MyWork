import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OperationDriveLimitOverrideMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Operation_Drive_Limit_Override__c';
      mappingConfig.objectType = 'operationDriveLimitOverride';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Date__c', 'date', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Operation_Drive_Limit__c', 'operationDriveLimitId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Quantity__c', 'quantity', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}