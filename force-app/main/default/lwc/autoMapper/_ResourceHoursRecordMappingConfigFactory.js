import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ResourceHoursRecordMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Resource_Hours_Record__c';
      mappingConfig.objectType = 'resourceHoursRecord';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Total_Working_Time__c', 'totalWorkingTime', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Resource__r', 'resource', MAPPING_TYPE.related, 'sked__Resource__c');

      return mappingConfig;
  }
}