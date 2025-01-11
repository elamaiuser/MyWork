import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class SiteCollectionOperationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Site_Collection_Operation__c';
      mappingConfig.objectType = 'siteCollectionOperation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site__c', 'siteId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time_Breakdown_JSON__c', 'travelTimeBreakdownJson', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time_Breakdown_JSON_2__c', 'travelTimeBreakdownJson2', MAPPING_TYPE.direct);
            
      mappingConfig.addFieldConfig('sked_Collection_Operation__r', 'collectionOperation', MAPPING_TYPE.related, 'Biomed_Collection_Op_Center__c');

      return mappingConfig;
  }
};