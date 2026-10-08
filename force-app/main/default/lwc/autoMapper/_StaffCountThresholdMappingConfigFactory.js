import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class StaffCountThresholdMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Staff_Count_Threshold__c';
      mappingConfig.objectType = 'staffCountThreshold';

      mappingConfig.addFieldConfig('sked_Staff_Count_Threshold__c', 'staffCountThreshold', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}