import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DcrFieldMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_DCR_Field__c';
      mappingConfig.objectType = 'dcrField';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DP_Updated__c', 'dpUpdated', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Editable__c', 'editable', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Field_API_Name__c', 'fieldApiName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Field_Label__c', 'fieldLabel', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_DCR_Role_Fields__r', 'dcrRoleFields', 'sked_DCR_Role_Field__c', 'sked_DCR_Field__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}