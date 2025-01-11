import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OptimizationQueueItemMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Optimization_Queue_Item__c';
      mappingConfig.objectType = 'optimizationQueueItem';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Optimization_Queue__c', 'optimizationQueueId', MAPPING_TYPE.direct);

      return mappingConfig;
  }
};