import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class AvailabilityPatternRoleMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Availability_Pattern_Role__c';
      mappingConfig.objectType = 'AvailabilityPatternRole';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Role__c', 'role', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Actual_Count_of_Role__c', 'actualCountOfRoles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Min_Nbr_of_Role__c', 'minNumberOfRoles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Collection_Operation_Availability__c', 'colOpAvailabilityId', MAPPING_TYPE.direct);
      
      return mappingConfig;
  }
}