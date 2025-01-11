import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveShiftTagMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Drive_Shift_Tag__c';
      mappingConfig.objectType = 'driveShiftTag';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__c', 'driveShiftId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__r', 'driveShift', MAPPING_TYPE.related, 'sked_Drive_Shift__c');
      mappingConfig.addFieldConfig('sked_Minimum_Quantity__c', 'minimumQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_SystemCreated__c', 'systemCreated', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Tag__c', 'tagId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Tag__r', 'tag', MAPPING_TYPE.related, 'sked__Tag__c');
      mappingConfig.addFieldConfig('sked_Tag__r.Name', 'tagName', MAPPING_TYPE.direct);

      mappingConfig.masterFields.push('sked_Tag__c');
      mappingConfig.masterFields.push('sked_Drive_Shift__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
};