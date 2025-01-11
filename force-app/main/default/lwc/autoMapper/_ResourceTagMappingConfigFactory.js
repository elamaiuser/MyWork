import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ResourceTagMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Resource_Tag__c';
      mappingConfig.objectType = 'resourceTag';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Expiry_Date__c', 'expiryDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Tag__c', 'tagId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Restriction_Start_Date__c', 'restrictionStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Restriction_End_Date__c', 'restrictionEndDate', MAPPING_TYPE.direct);
      
      mappingConfig.addFieldConfig('sked__Tag__r', 'tag', MAPPING_TYPE.related, 'sked__Tag__c');

      return mappingConfig;
  }
}