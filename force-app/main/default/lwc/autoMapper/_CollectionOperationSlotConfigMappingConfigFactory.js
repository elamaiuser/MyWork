import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class CollectionOperationSlotConfigMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Collection_Operation_Slot_Config__c';
      mappingConfig.objectType = 'collectionOperationSlotConfig';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Fixed_Site_Operation_Type__c', 'fixedSiteOperationType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Procedure_Type__c', 'procedureType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Slot_Configuration__c', 'slotConfigurationJson', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}
