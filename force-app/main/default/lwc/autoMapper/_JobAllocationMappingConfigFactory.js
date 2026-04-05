import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class JobAllocationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Job_Allocation__c';
      mappingConfig.objectType = 'jobAllocation';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_CDL__c', 'CDL', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DOT__c', 'DOT', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Duration__c', 'duration', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Set_End__c', 'end', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Set_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__c', 'jobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__r.sked_Asset_Type__c', 'assetType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive__c', 'driveId', MAPPING_TYPE.direct);        
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive__r.Name', 'driveName', MAPPING_TYPE.direct);        
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive__r.sked_Drive_Date__c', 'driveDate', MAPPING_TYPE.direct);        
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive__r.sked_Start_Time__c', 'driveStartTime', MAPPING_TYPE.time);        
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive__r.sked_End_Time__c', 'driveEndTime', MAPPING_TYPE.time);        
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive__r.sked_UFID__c', 'driveUfid', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive__r.sked_Collection_Operation__r.Name', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__r.sked_Drive_Shift__r.Name', 'driveShiftName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__r.sked__Region__r.sked_Biomed_Collection_Op_Center__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job__r.sked_Resource_Role__c', 'resourceRole', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource__r.Name', 'resourceName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_With_Travel_Time__c', 'startWithTravelTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time_Back__c', 'travelTimeBack', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time_To__c', 'travelTimeTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Geoservice_Travel_Time_Back__c', 'geoServiceTravelTimeBack', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Geoservice_Travel_Time_To__c', 'geoServiceTravelTimeTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Geoservice_Travel_Distance_Back__c', 'geoServiceTravelDistanceBack', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Geoservice_Travel_Distance_To__c', 'geoServiceTravelDistanceTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_Relocated_Resource__c', 'isRelocatedResource', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Additional_Roles__c', 'additionalRoles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift_Trade__c', 'driveShiftTradeId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Locked__c', 'locked', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Call_Out_Reported__c', 'callOutReported', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Call_Out_Reason_Code__c', 'callOutReasonCode', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Call_Out_Notes__c', 'callOutNotes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Call_Out_Type__c', 'callOutType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Optimization_Run__c', 'optimizationRunId', MAPPING_TYPE.direct);      
      mappingConfig.addFieldConfig('sked__Job__r', 'job', MAPPING_TYPE.related, 'sked__Job__c');
      mappingConfig.addFieldConfig('sked__Resource__r', 'resource', MAPPING_TYPE.related, 'sked__Resource__c');
      mappingConfig.addFieldConfig('sked_Drive_Shift_Trade__r', 'driveShiftTrade', MAPPING_TYPE.related, 'sked_Drive_Shift_Trade__c');
      mappingConfig.addFieldConfig('sked_Optimization_Run__r', 'optimizationRun', MAPPING_TYPE.related, 'sked_Optimization_Run__c');
      mappingConfig.addFieldConfig('sked_Guarded__c', 'guarded', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_Locked__c', 'isLocked', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Staffing_Reason__c', 'staffingReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Replacement_For__c', 'replacementFor', MAPPING_TYPE.direct);
      
      mappingConfig.addFieldConfigWithRelatedList('skedHC__Exception_Log__r', 'exceptionLog', 'skedHC__Exception__c', 'skedHC__Job_Allocation__c');

      mappingConfig.readonlyFields.push('Name');
      mappingConfig.readonlyFields.push('sked_Start_Date__c');
      mappingConfig.readonlyFields.push('sked_Set_End_Date__c');

      mappingConfig.masterFields.push('sked__Job__c');
      mappingConfig.masterFields.push('sked__Resource__c');

      return mappingConfig;
  }
}