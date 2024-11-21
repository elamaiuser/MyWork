import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ResourceOverrideMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Resource_Override__c';
      mappingConfig.objectType = 'resourceOverride';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__r.Name', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Description__c', 'description', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__End__c', 'end', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Latitude__s', 'geoLocationLatitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Longitude__s', 'geoLocationLongitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Home_Address__c', 'address', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_To_Start__c', 'travelToStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_To_End__c', 'travelToEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Back_Start__c', 'travelBackStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Back_End__c', 'travelBackEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_Travel_Required__c', 'isTravelRequired', MAPPING_TYPE.direct);
      
      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}