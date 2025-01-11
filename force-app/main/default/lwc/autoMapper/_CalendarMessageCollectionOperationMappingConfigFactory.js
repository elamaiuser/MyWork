import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class CalendarMessageCollectionOperationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_CalendarMessage_CollectionOperation__c';
      mappingConfig.objectType = 'calendarMessageCollectionOperation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId');
      mappingConfig.addFieldConfig('sked_Calendar_Message__c', 'calendarMessageId');

      mappingConfig.addFieldConfig('sked_Calendar_Message__r', 'calendarMessage', MAPPING_TYPE.related, 'sked_Calendar_Message__c');

      mappingConfig.masterFields.push('sked_Collection_Operation__c');
      mappingConfig.masterFields.push('sked_Calendar_Message__c');

      return mappingConfig;
  }
}