import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OperationRecordStaffMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Operation_Record_Staff__c';
      mappingConfig.objectType = 'operationRecordStaff';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Absent__c', 'absent', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Roles__c', 'actualRoles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Shift_End__c', 'actualShiftEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Shift_End_Date__c', 'actualShiftEndDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Shift_End_Time__c', 'actualShiftEndTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Actual_Shift_Start__c', 'actualShiftStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Shift_Start_Date__c', 'actualShiftStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Shift_Start_Time__c', 'actualShiftStartTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Added_Staff__c', 'addedStaff', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_EarlyDeparture_LateArrival_Reasons__c', 'earlyDepartureLateArrivalReasons', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_ID__c', 'eBdrId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Job__c', 'jobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Job__r.Name', 'jobName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Job_Allocation__c', 'jobAllocationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_No_Meal__c', 'noMeal', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Notes_Comments__c', 'notesComments', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Operation_Record__c', 'operationRecordId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Operation_Record__r.Name', 'operationRecordName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Pool__c', 'pool', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Premiums_Op_Pay__c', 'premiumsOpPay', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource__r.Name', 'resourceName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Role__c', 'role', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Scheduled_Shift_End__c', 'scheduledShiftEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Scheduled_Shift_Start__c', 'scheduledShiftStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');
      mappingConfig.readonlyFields.push('sked_Timezone__c');

      mappingConfig.masterFields.push('sked_Operation_Record__c');

      return mappingConfig;
  }
}