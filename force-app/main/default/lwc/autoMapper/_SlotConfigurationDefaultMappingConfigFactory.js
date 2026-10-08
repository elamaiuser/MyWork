import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class SlotConfigurationDefaultMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Slot_Configuration_Default__mdt';
      mappingConfig.objectType = 'slotConfigurationDefault';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Fixed_Site_Operation_Type__c', 'fixedSiteOperationType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Procedure_Type__c', 'procedureType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Configuration_Json__c', 'configurationJson', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}
