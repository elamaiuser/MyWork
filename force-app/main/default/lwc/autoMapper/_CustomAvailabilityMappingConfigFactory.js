import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class CustomAvailabilityMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Custom_Availability__c';
      mappingConfig.objectType = 'customAvailability';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Finish__c', 'finish', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Finish_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_Available__c', 'isAvailable', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Type__c', 'type', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('sked_Start_Date__c');
      mappingConfig.readonlyFields.push('sked_Finish_Date__c');

      return mappingConfig;
  }
};