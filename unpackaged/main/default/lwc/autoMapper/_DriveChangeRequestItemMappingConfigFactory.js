import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveChangeRequestItemMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Drive_Change_Request_Item__c';
      mappingConfig.objectType = 'driveChangeRequestItem';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedBy', 'createdBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('LastModifiedBy.Name', 'lastModifiedByName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('LastModifiedDate', 'lastModifiedDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Change_Reason__c', 'changeReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Change_Request__c', 'driveChangeRequestId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Field_API_Name__c', 'fieldApiName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Field_Label__c', 'fieldLabel', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Field_Type__c', 'fieldType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_New_Value_Display__c', 'newValueDisplay', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_New_Value__c', 'newValue', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Object_API_Name__c', 'objectApiName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Old_Value_Display__c', 'oldValueDisplay', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Old_Value__c', 'oldValue', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Type__c', 'type', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_Hidden__c', 'isHidden', MAPPING_TYPE.direct);
      
      mappingConfig.masterFields.push('sked_Drive_Change_Request__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}