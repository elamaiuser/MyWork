import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DcrPeriodMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_DCR_Period__c';
      mappingConfig.objectType = 'dcrPeriod';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Background_Color__c', 'backgroundColor', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Sort_Order__c', 'sortOrder', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_DCR_Roles__r', 'dcrRoles', 'sked_DCR_Role__c', 'sked_DCR_Period__c');

      return mappingConfig;
  }
}