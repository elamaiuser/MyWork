import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class TerritoryCollectionOperationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Territory_Collection_Operation__c';
      mappingConfig.objectType = 'territoryCollectionOperation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory__c', 'territoryId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory__r.sked_High_Drive_Productivity_Threshold__c', 'highDriveProductivityThreshold', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory__r.sked_Mid_Drive_Productivity_Threshold__c', 'midDriveProductivityThreshold', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}