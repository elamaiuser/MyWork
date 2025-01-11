import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class HolidayCollectionOperationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Holiday_Collection_Operation__c';
      mappingConfig.objectType = 'holidayCollectionOperation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId');
      mappingConfig.addFieldConfig('sked_Holiday__c', 'holidayId');

      mappingConfig.addFieldConfig('sked_Holiday__r', 'holiday', MAPPING_TYPE.related, 'sked__Holiday__c');

      mappingConfig.masterFields.push('sked_Collection_Operation__c');
      mappingConfig.masterFields.push('sked_Holiday__c');

      return mappingConfig;
  }
}