import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class TravelTimeIndexItemMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Travel_Time_Index_Item__c';
      mappingConfig.objectType = 'travelTimeIndexItem';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Key__c', 'key', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Distance__c', 'travelDistance', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time_Breakdown_JSON__c', 'travelTimeBreakdownJson', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}