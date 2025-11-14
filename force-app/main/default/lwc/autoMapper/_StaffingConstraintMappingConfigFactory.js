import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class StaffingConstraintMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Staffing_Constraint__c';
      mappingConfig.objectType = 'staffingConstraint';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Decrease_Indicator__c', 'decreaseIndicator', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Date_of_Constraint__c', 'dateOfConstraint', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Time_Block__c', 'timeBlockId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Total_Staff_Constraints__c', 'totalStaffConstraints', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Collection_Operation__r', 'collectionOperation', MAPPING_TYPE.related, 'Biomed_Collection_Op_Center__c');
      mappingConfig.addFieldConfig('sked_Time_Block__r', 'timeBlock', MAPPING_TYPE.related, 'Time_Block__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}