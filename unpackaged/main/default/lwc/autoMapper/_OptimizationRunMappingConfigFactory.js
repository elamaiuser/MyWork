import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OptimizationRunMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Optimization_Run__c';
      mappingConfig.objectType = 'optimizationRun';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedBy', 'createdBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__r.Name', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory_Key__c', 'territoryKey', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}