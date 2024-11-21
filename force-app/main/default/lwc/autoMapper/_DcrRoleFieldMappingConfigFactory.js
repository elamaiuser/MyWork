import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DcrRoleFieldMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_DCR_Role_Field__c';
      mappingConfig.objectType = 'dcrRoleField';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Action__c', 'action', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DCR_Field__c', 'dcrFieldId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DCR_Role__c', 'dcrRoleId', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}