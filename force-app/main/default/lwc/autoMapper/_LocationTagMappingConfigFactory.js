import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class LocationTagMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Location_Tag__c';
      mappingConfig.objectType = 'locationTag';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Minimum_Quantity__c', 'minimumQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Location__c', 'locationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Required__c', 'required', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Tag__c', 'tagId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_SystemCreated__c', 'systemCreated', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Tag__r', 'tag', MAPPING_TYPE.related, 'sked__Tag__c');

      return mappingConfig;
  }
};