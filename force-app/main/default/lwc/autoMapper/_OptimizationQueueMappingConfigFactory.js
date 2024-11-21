import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OptimizationQueueMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Optimization_Queue__c';
      mappingConfig.objectType = 'optimizationQueue';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedBy', 'createdBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_Optimization_Queue_Items__r', 'optimizationQueueItems', 'sked_Optimization_Queue_Item__c', 'sked_Optimization_Queue__c');

      return mappingConfig;
  }
}