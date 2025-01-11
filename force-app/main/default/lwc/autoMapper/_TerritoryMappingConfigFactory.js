import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class TerritoryMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Territory__c';
      mappingConfig.objectType = 'territory';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('RecordType.Name', 'recordTypeName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Parent__c', 'parentId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('End_Date__c', 'endDate', MAPPING_TYPE.direct);
      return mappingConfig;
  }
}