import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class LunchBreakDefinitionMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Lunch_Break_Definition__c';
      mappingConfig.objectType = 'lunchBreakDefinition';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lunch_Break_Duration__c', 'lunchBreakDuration', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lunch_Break_Setting__c', 'lunchBreakSettingId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Max_Number_of_Staff__c', 'maxNoOfStaff', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Min_Number_of_Staff__c', 'minNoOfStaff', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Slot_Reduction__c', 'slotReduction', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}