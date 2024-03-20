import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class CollectionOpStagingLocationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Collection_Op_Staging_Location__c';
      mappingConfig.objectType = 'collectionOpStagingLocation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Staging_Location__c', 'stagingLocationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Staging_Location__r', 'stagingLocation', MAPPING_TYPE.related, 'sked_Staging_Location__c');

      return mappingConfig;
  }
}