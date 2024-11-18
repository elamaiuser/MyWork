import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class StaffMealAndRestBreakMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Staff_Meal_Rest_Break_Setting__c';
      mappingConfig.objectType = 'staffMealAndRestBreakSetting';
    
      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Operation_Record_Staff__c', 'opRecordStaff', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Break_Type__c', 'breakType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Start_Time__c', 'actualStartTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_End_Time__c', 'actualEndTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Start_Time__c', 'actualStartTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_End_Time__c', 'actualEndTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Start_Date__c', 'actualStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_End_Date__c', 'actualEndDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Start__c', 'actualStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_End__c', 'actualEnd', MAPPING_TYPE.direct);
      return mappingConfig;
  }
}