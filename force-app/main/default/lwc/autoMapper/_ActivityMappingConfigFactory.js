import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ActivityMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Activity__c';
      mappingConfig.objectType = 'activity';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Activity_Title__c', 'activityTitle', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Address__c', 'address', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.Name', 'driveName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_District__c', 'districtId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__End__c', 'finish', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Time__c', 'endTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked__GeoLocation__Latitude__s', 'geoLocationLatitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Longitude__s', 'geoLocationLongitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Fixed_Site_Staff_Quantity__c', 'fixedSiteStaffQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_Group_Activity__c', 'isGroupActivity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Linked_Drives__c', 'linkedDrivesId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Linked_Drives__r.Name', 'linkedDrivesName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Mobile_Staff_Quantity__c', 'mobileStaffQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Notes__c', 'notes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Quantity__c', 'quantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Reduce_From_Staffing_Constraint__c', 'reduceFromStaffingConstraint', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Region__c', 'regionId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Show_On_Calendar__c', 'showOnCalendar', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Time__c', 'startTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Subtype__c', 'subtype', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory_Key__c', 'territoryKey', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Time_Block__c', 'timeBlockId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Timezone__c', 'timezoneSidId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Type__c', 'eventType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Vehicles_Allocated__c', 'vehiclesAllocated', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked__Activity_Resources__r', 'activityResources', 'sked__Activity_Resource__c', 'sked__Activity__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Activity_Collection_Operations__r', 'activityCollectionOperations', 'sked_Activity_Collection_Operation__c', 'sked_Activity__c');

      mappingConfig.readonlyFields.push('Name');
      mappingConfig.readonlyFields.push('sked_Start_Date__c');
      mappingConfig.readonlyFields.push('sked_End_Date__c');

      return mappingConfig;
  }
}