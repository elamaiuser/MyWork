import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class JobMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Job__c';
      mappingConfig.objectType = 'job';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Account__c', 'accountId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Asset_Type__c', 'assetType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_APT_Quantity__c', 'aptQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Breakdown_Time__c', 'breakdownTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collections_Manager__c', 'collectionsManagerId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collections_Manager__r.Name', 'collectionsManagerName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collections_Manager__r.MobilePhone', 'collectionsManagerMobilePhone', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Dual_Role__c', 'dualRole', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.Id', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Drive_Date__c', 'driveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.Name', 'driveName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__c', 'driveShiftId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__r.Name', 'driveShiftName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Equipment_Subtype__c', 'equipmentSubtype', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Exclude_from_Optimizer__c', 'excludeFromOptimizer', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Finish__c', 'finish', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Finish_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Latitude__s', 'latitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Address__c', 'address', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Longitude__s', 'longitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_Manually_Created__c', 'isManuallyCreated', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Manually_Created_From__c', 'manuallyCreatedFrom', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job_Allocation_Count__c', 'jobAllocationCount', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job_Allocation_Time_Source__c', 'jobAllocationTimeSource', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Job_Status__c', 'jobStatus', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lead_Time__c', 'leadTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Location__c', 'driveSiteId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Location__r.Name', 'driveSiteName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Locked__c', 'isLocked', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Quantity__c', 'quantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_System_Quantity__c', 'systemQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Other_Volunteer_Adjustment_Reason__c', 'otherVolunteerAdjustmentReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Primary_Scheduler__c', 'primarySchedulerId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Primary_Scheduler__r.Name', 'primarySchedulerName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Primary_Scheduler__r.MobilePhone', 'primarySchedulerMobilePhone', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Redcross_Volunteer_Quantity__c', 'redcrossVolunteerQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Role__c', 'resourceRole', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Setup_Time__c', 'setupTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Sponsor_Volunteer_Quantity__c', 'sponsorVolunteerQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Logistics_Back__c', 'siteLogisticsBack', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Logistics_To__c', 'siteLogisticsTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time__c', 'travelTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time2__c', 'travelTime2', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Wrap_up_Time__c', 'wrapUpTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Longitude__s', 'longitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Latitude__s', 'latitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Type__c', 'eventType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Volunteer_Adjustment_Reason__c', 'volunteerAdjustmentReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Volunteer_Role__c', 'volunteerRole', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_VPHH_Quantity__c', 'vphhQuantity', MAPPING_TYPE.direct);
      
      mappingConfig.addFieldConfigWithRelatedList('sked__Job_Allocations__r', 'jobAllocations', 'sked__Job_Allocation__c', 'sked__Job__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__JobTags__r', 'jobTags', 'sked__Job_Tag__c', 'sked__Job__c');

      mappingConfig.readonlyFields.push('Name');
      mappingConfig.readonlyFields.push('sked_Start_Date__c');
      mappingConfig.readonlyFields.push('sked_Finish_Date__c');
      mappingConfig.readonlyFields.push('sked__Job_Allocation_Count__c');

      return mappingConfig;
  }
};