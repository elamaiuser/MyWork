import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class LunchBreakSettingMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Lunch_Break_Setting__c';
      mappingConfig.objectType = 'lunchBreakSetting';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Maximum_Lunch_Break_Duration__c', 'maximumLunchBreakDuration', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_Lunch_Break_Definitions__r', 'lunchBreakDefinitions', 'sked_Lunch_Break_Definition__c', 'sked_Lunch_Break_Setting__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}