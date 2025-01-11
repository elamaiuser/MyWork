import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class SlotMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Slot__c';
      mappingConfig.objectType = 'slot';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__c', 'driveShiftId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__r.sked_Order__c', 'driveShiftIndex', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End__c', 'endTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Fixed_Site_Lock_Reason__c', 'fixedSiteLockReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Fixed_Site_Lock_Comment__c', 'fixedSiteLockComment', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__c', 'jobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Label__c', 'label', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Locked__c', 'locked', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Type__c', 'slotType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start__c', 'startTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      
      return mappingConfig;
  }
}