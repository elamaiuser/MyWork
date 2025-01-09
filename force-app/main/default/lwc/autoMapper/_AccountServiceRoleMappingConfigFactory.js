import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AccountServiceRoleMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Account_Service_Role__c';
      mappingConfig.objectType = 'accountServiceRole';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Account_Service_Role__c', 'accountServiceRole', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Account__c', 'account', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Is_Active__c', 'isActive', MAPPING_TYPE.direct);

      mappingConfig.masterFields.push('Account__c');
      console.log('mappingConfig account service role :: ',mappingConfig);
      return mappingConfig;
  }
};