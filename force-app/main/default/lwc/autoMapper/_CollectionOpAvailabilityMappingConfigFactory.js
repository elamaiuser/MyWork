import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class CollectionOpAvailabilityMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Collection_Operation_Availability__c';
      mappingConfig.objectType = 'collectionOpAvailability';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Availability_Pattern__c', 'availabilityPatternId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Effective_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Effective_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Availability_Pattern__r.Name', 'availabilityPatternName', MAPPING_TYPE.direct);
       mappingConfig.addFieldConfig('Total_Actual_Resources__c', 'totalActualResources', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Total_Target__c', 'totalTargetResources', MAPPING_TYPE.direct);
      
      mappingConfig.addFieldConfigWithRelatedList('Availability_Pattern_Roles__r', 'availabilityPatternRoles', 'Availability_Pattern_Role__c', 'Collection_Operation_Availability__c');
      return mappingConfig;
  }
}