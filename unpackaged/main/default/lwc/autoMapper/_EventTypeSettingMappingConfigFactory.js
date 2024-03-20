import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class EventTypeSettingMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Event_Type_Setting__c';
      mappingConfig.objectType = 'eventTypeSetting';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name');
      mappingConfig.addFieldConfig('sked_Available_End__c', 'availableEnd');
      mappingConfig.addFieldConfig('sked_Available_Start__c', 'availableStart');
      mappingConfig.addFieldConfig('sked_Background_Color__c', 'backgroundColor');
      mappingConfig.addFieldConfig('sked_Can_Be_Pre_dated__c', 'canBePreDated');
      mappingConfig.addFieldConfig('sked_Category__c', 'category');
      mappingConfig.addFieldConfig('sked_Color__c', 'color');
      mappingConfig.addFieldConfig('sked_Is_Active__c', 'isActive');
      mappingConfig.addFieldConfig('sked_Is_Available__c', 'isAvailable');
      mappingConfig.addFieldConfig('sked_Item__c', 'item');
      mappingConfig.addFieldConfig('sked_Short_Name__c', 'shortName');
      mappingConfig.addFieldConfig('sked_Show_Legend__c', 'showLegend');
      mappingConfig.addFieldConfig('sked_Step__c', 'step');

      return mappingConfig;
  }
}