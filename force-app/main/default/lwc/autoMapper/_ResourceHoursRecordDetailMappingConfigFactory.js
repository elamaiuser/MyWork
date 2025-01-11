import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class ResourceHoursRecordDetailMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Resource_Hours_Record_Detail__c';
      mappingConfig.objectType = 'resourceHoursRecordDetail';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Hours_Record__c', 'resourceHoursRecordId', MAPPING_TYPE.direct);
      return mappingConfig;
  }
}