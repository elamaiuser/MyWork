import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class TimeBlockMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Time_Block__c';
      mappingConfig.objectType = 'timeBlock';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Days_of_Week__c', 'daysOfWeek', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Start_Time__c', 'startTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('End_Time__c', 'endTime', MAPPING_TYPE.time);

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
};