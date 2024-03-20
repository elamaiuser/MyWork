import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class CollectionOperationSdmMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Collection_Operation_SDM__c';
      mappingConfig.objectType = 'collectionOperationSdm';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOpId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_End_Date__c', 'effectiveEndDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_Start_Date__c', 'effectiveStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Staffing_Decision_Matrix__c', 'staffingDecisionMatrixId', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Staffing_Decision_Matrix__r', 'staffingDecisionMatrix', MAPPING_TYPE.related, 'sked_Staffing_Decision_Matrix__c');

      return mappingConfig;
  }
}