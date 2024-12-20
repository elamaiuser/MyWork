import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class ActivityCollectionOperationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Activity_Collection_Operation__c';
      mappingConfig.objectType = 'activityCollectionOperation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Activity__c', 'activityId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Biomed_Collection_Operation__c', 'biomedCollectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_District__c', 'districtId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory_Key__c', 'territoryKey', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Activity__r', 'activity', MAPPING_TYPE.related, 'sked__Activity__c');
      mappingConfig.addFieldConfig('sked_Biomed_Collection_Operation__r', 'biomedCollectionOperation', MAPPING_TYPE.related, 'Biomed_Collection_Op_Center__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}