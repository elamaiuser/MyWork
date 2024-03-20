import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class RoleTimeVarianceMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Role_Time_Variance__c';
      mappingConfig.objectType = 'roleTimeVariance';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Buffer_Type__c', 'bufferType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_End_Date__c', 'effectiveEndDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_Start_Date__c', 'effectiveStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Location__c', 'locationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Role_Group__c', 'resourceRoleGroup', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Variance_Applies_to__c', 'varianceAppliesTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Variation_Amount__c', 'varianceAmount', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Variation_Type__c', 'varianceType', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}