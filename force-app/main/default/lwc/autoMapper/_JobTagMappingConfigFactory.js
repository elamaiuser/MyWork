import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class JobTagMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Job_Tag__c';
      mappingConfig.objectType = 'jobTag';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__c', 'jobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_SystemCreated__c', 'systemCreated', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Tag__c', 'tagId', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked__Tag__r', 'tag', MAPPING_TYPE.related, 'sked__Tag__c');

      return mappingConfig;

  }
}