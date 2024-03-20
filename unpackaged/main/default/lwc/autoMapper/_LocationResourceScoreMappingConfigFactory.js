import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class LocationResourceScoreMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Location_Resource_Score__c';
      mappingConfig.objectType = 'locationResourceScore';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Location__c', 'locationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Blacklisted__c', 'blacklisted', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Whitelisted__c', 'whitelisted', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}