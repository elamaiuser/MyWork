import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ExceptionMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'skedHC__Exception__c';
      mappingConfig.objectType = 'exception';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate');
      mappingConfig.addFieldConfig('Name', 'name');
      mappingConfig.addFieldConfig('skedHC__Activity__c', 'activityId');
      mappingConfig.addFieldConfig('skedHC__Availability__c', 'availabilityId');
      mappingConfig.addFieldConfig('skedHC__Exception__c', 'exception');
      mappingConfig.addFieldConfig('skedHC__Job__c', 'jobId');
      mappingConfig.addFieldConfig('skedHC__Job__r.Name', 'jobName');
      mappingConfig.addFieldConfig('skedHC__Job__r.sked__Type__c', 'jobType');
      mappingConfig.addFieldConfig('skedHC__Job_Allocation__c', 'jobAllocationId');
      mappingConfig.addFieldConfig('skedHC__Resource__c', 'resourceId');
      mappingConfig.addFieldConfig('skedHC__Resource__r.Name', 'resourceName');
      mappingConfig.addFieldConfig('skedHC__Status__c', 'status');
      mappingConfig.addFieldConfig('sked_Conflicted_Job__c', 'conflictedJobId');
      mappingConfig.addFieldConfig('sked_Conflicted_Job_Allocation__c', 'conflictedJobAllocationId');
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId');
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Drive_Date__c', 'driveDate');
      mappingConfig.addFieldConfig('sked_Drive__r.sked_UFID__c', 'ufid');
      mappingConfig.addFieldConfig('sked_Drive__r.Name', 'driveName');
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Start_Time__c', 'driveStartTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_End_Time__c', 'driveEndTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive_Shift__r.Name', 'driveShiftName');
      mappingConfig.addFieldConfig('sked_Drive_Shift__r.sked_Time_Block__r.Name', 'driveShiftTimeBlockName');
      mappingConfig.addFieldConfig('sked_Drive_Shift__r.sked_Start_Time__c', 'driveShiftStartTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive_Shift__r.sked_End_Time__c', 'driveShiftEndTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Exception_Code__c', 'exceptionCode');
      mappingConfig.addFieldConfig('sked_Priority__c', 'priority');
      mappingConfig.addFieldConfig('sked_Conflicted_Drive__c', 'conflictedDrive');
      mappingConfig.addFieldConfig('sked_Conflicted_Drive__r.Name', 'conflictedDriveName');
      mappingConfig.addFieldConfig('skedHC__Activity__r.sked_Activity_Title__c', 'activityTitle');
      mappingConfig.addFieldConfig('skedHC__Activity__r.sked__Start__c', 'activityStart');
      mappingConfig.addFieldConfig('skedHC__Activity__r.sked__End__c', 'activityEnd');
      mappingConfig.addFieldConfig('skedHC__Activity__r.sked__Type__c', 'activityType');
      mappingConfig.addFieldConfig('skedHC__Activity__r.sked_Subtype__c', 'activitySubType');

      mappingConfig.addFieldConfig('sked_Linked_Drive__c', 'linkedDriveId');
      mappingConfig.addFieldConfig('sked_Linked_Drive__r.Name', 'linkedDriveName');
      mappingConfig.addFieldConfig('sked_Linked_Drive__r.sked_Earliest_Drive_Date__c', 'linkedDriveEarliestDriveDate');
      mappingConfig.addFieldConfig('sked_Linked_Drive__r.sked_Latest_Drive_Date__c', 'linkedDriveLatestDriveDate');

      mappingConfig.addFieldConfig('skedHC__Job__r', 'job', MAPPING_TYPE.related, 'sked__Job__c');

      return mappingConfig;
  }
}