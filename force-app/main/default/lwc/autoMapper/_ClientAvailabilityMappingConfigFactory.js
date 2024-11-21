import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ClientAvailabilityMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Client_Availability__c';
      mappingConfig.objectType = 'clientAvailability';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Account__c', 'accountId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__End__c', 'finish', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Is_Available__c', 'isAvailable', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Preferred_Start__c', 'preferredStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Preferred_End__c', 'preferredEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Recurring_Schedule__c', 'scheduleId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_All_Time_Preferred__c', 'isAllTimePreferred', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Notes__c', 'notes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Service_Location__c', 'serviceLocationId', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}