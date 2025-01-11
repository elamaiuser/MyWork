import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AccountResourceScoreMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Account_Resource_Score__c';
      mappingConfig.objectType = 'accountResourceScore';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Account__c', 'accountId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Blacklisted__c', 'blacklisted', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Whitelisted__c', 'whitelisted', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}