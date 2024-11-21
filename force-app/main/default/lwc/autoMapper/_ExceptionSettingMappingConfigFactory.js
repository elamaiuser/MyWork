import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ExceptionSettingMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Exception_Setting__c';
      mappingConfig.objectType = 'exceptionSetting';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name');
      mappingConfig.addFieldConfig('sked_Exception__c', 'exception');
      mappingConfig.addFieldConfig('sked_Exception_Code__c', 'exceptionCode');
      mappingConfig.addFieldConfig('sked_Priority__c', 'priority');

      return mappingConfig;
  }
}