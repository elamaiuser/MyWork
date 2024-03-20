import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class StaffSetupExcludedRoleMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Staff_Setup_Excluded_Role__c';
      mappingConfig.objectType = 'staffSetupExcludedRole';

      mappingConfig.addFieldConfig('sked_Resource_Role__c', 'resourceRole', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Excluded_For_Staff_Allocated__c', 'excludedForStaffAllocated', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Excluded_for_Assigned_Staff_Count__c', 'excludedForAssignedStaffCount', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}