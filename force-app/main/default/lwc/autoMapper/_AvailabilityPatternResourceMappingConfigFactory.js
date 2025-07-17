import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AvailabilityPatternResourceMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Availability_Pattern_Resource__c';
      mappingConfig.objectType = 'availabilityPatternResource';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Availability_Pattern__c', 'availabilityPatternId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__End__c', 'end', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Time__c', 'startTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Time__c', 'endTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Timezone__c', 'timeZone', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_MigrationID__c', 'migrationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Availability_Pattern__r.Name', 'patternName', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');

      mappingConfig.masterFields.push('sked__Availability_Pattern__c');
      mappingConfig.masterFields.push('sked__Resource__c');

      return mappingConfig;
  }
}