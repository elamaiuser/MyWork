import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class CollectionOperationOptimizerSettingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_CollectionOperationOptimizerSetting__c';
      mappingConfig.objectType = 'collectionOperationOptimizerSetting';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Constraint__c', 'constraint', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Constraint_Type__c', 'constraintType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Default_Weight__c', 'defaultWeight', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Enabled__c', 'enabled', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Optimizer_Mapped_Weight__c', 'optimizerMappedWeight', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Display_Order__c', 'displayOrder', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Display_Type__c', 'displayType', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Collection_Operation__r', 'collectionOperation', MAPPING_TYPE.related, 'Biomed_Collection_Op_Center__c');

      return mappingConfig;
  }
}