import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OperationDriveLimitMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Operation_Drive_Limit__c';
      mappingConfig.objectType = 'operationDriveLimit';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Days_of_Week__c', 'daysOfWeek', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_End_Date__c', 'effectiveEndDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_Start_Date__c', 'effectiveStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Quantity__c', 'quantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Type__c', 'type', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Time_Block__c', 'timeBlockId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfigWithRelatedList('sked_Operation_Drive_Limit_Overrides__r', 'operationDriveLimitOverrides', 'sked_Operation_Drive_Limit_Override__c', 'sked_Operation_Drive_Limit__c');

      return mappingConfig;
  }
}