import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AccountTagMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Account_Tag__c';
      mappingConfig.objectType = 'accountTag';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Minimum_Quantity__c', 'minimumQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Account__c', 'accountId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Required__c', 'required', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Tag__c', 'tagId', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked__Tag__r', 'tag', MAPPING_TYPE.related, 'sked__Tag__c');

      return mappingConfig;
  }
}