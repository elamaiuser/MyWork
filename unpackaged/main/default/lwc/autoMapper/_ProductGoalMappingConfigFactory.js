import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ProductGoalMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Product_Goal__c';
      mappingConfig.objectType = 'productGoal';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Date_of_Goal__c', 'dateOfGoal', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Total_Products__c', 'totalProducts', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Procedure_Type__c', 'procedureType', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}