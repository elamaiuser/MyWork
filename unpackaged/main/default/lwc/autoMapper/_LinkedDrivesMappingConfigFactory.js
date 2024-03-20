import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class LinkedDrivesMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Linked_Drives__c';
      mappingConfig.objectType = 'linkedDrives';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Linked_Drive_Type__c', 'linkedDriveType', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_Activities__r', 'activities', 'sked__Activity__c', 'sked_Linked_Drives__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Drives__r', 'drives', 'sked_Drive__c', 'sked_Linked_Drives__c');

      return mappingConfig;
  }
};