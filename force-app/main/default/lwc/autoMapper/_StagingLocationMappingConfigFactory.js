import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class StagingLocationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Staging_Location__c';
      mappingConfig.objectType = 'stagingLocation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Address__c', 'address', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_GeoLocation__Latitude__s', 'geoLocationLatitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_GeoLocation__Longitude__s', 'geoLocationLongitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Zip_Code__c', 'zipCode', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}