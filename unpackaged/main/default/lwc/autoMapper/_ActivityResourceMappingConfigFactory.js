import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ActivityResourceMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Activity_Resource__c';
      mappingConfig.objectType = 'activityResource';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Activity__c', 'activityId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start1__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End__c', 'finish', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked__Activity__r', 'activity', MAPPING_TYPE.related, 'sked__Activity__c');
      mappingConfig.addFieldConfig('sked__Resource__r', 'resource', MAPPING_TYPE.related, 'sked__Resource__c');

      mappingConfig.readonlyFields.push('Name');
      mappingConfig.readonlyFields.push('sked_Start_Date__c');
      mappingConfig.readonlyFields.push('sked_End_Date__c');

      return mappingConfig;
  }
}