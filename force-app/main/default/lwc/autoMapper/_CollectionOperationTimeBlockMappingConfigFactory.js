import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';
export class CollectionOperationTimeBlockMappingConfigFactory {
  constructor() {}
  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Collection_Operation_Time_Block__c';
      mappingConfig.objectType = 'collectionOperationTimeBlock';
      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Effective_Start_Date__c', 'effectiveStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Effective_End_Date__c', 'effectiveEndDate', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('Collection_Operation__r', 'collectionOperation', MAPPING_TYPE.related, 'Biomed_Collection_Op_Center__c');
      mappingConfig.addFieldConfig('Time_Block__r', 'timeBlock', MAPPING_TYPE.related, 'Time_Block__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
};