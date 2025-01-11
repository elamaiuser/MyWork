import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ResourceRoleGroupMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Resource_Role_Group__c';
      mappingConfig.objectType = 'resourceRoleGroup';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Roles__c', 'resourceRoles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Role_Group__c', 'resourceRoleGroup', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}