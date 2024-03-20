import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class CalendarMessageMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Calendar_Message__c';
      mappingConfig.objectType = 'calendarMessage';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Message__c', 'message', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Global__c', 'global', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}