import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DcrRoleMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_DCR_Role__c';
      mappingConfig.objectType = 'dcrRole';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DCR_Period__c', 'dcrPeriodId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Role__c', 'role', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Sort_Order__c', 'sortOrder', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_DCR_Role_Fields__r', 'dcrRoleFields', 'sked_DCR_Role_Field__c', 'sked_DCR_Role__c');

      return mappingConfig;
  }
};