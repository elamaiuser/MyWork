import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ResourceMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Resource__c';
      mappingConfig.objectType = 'resource';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Address_Referenced_for_Scheduling__c', 'addressReferencedForScheduling', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Anticipated_Leave_Return_Date__c', 'anticipatedLeaveReturnDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Asset_Type__c', 'assetType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Category__c', 'category', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_CDL__c', 'CDL', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DOT__c', 'DOT', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Daily_Time_Off_Hours__c', 'dailyTimeOffHours', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Dedicated_to_Site__c', 'dedicatedToSiteId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center_Name__c', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Staging_Location_Geolocation__Latitude__s', 'collectionOperationStagingLocationGeolocationLatitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Staging_Location_Geolocation__Longitude__s', 'collectionOperationStagingLocationGeolocationLongitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Primary_Phone__c', 'primaryPhone', MAPPING_TYPE.direct);       
      mappingConfig.addFieldConfig('sked_Effective_Date__c', 'effectiveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Email__c', 'email', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Employment_Type__c', 'employmentType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Equipment_Subtype__c', 'equipmentSubtype', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Employment_Status__c', 'employmentStatus', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Latitude__s', 'latitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Longitude__s', 'longitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Is_Active__c', 'isActive', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Mobile_Phone__c', 'mobilePhone', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Max_Hours_Per_Week__c', 'maxHoursPerWeek', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Max_Travel_Time__c', 'maxTravelTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Maximum_Travel_Radius__c', 'maximumTravelRadius', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Mobile_Type__c', 'mobileType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Planned_Termination_Date__c', 'plannedTerminationDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Pres_Donor_Capacity__c', 'presDonorCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Quantity__c', 'quantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Resource_Type__c', 'resourceType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Roles__c', 'roles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_Address__c', 'satelliteAddress', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_Address_1__c', 'satelliteAddress1', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_City__c', 'satelliteCity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_Country__c', 'satelliteCountry', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_State__c', 'satelliteState', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_Zip_Code__c', 'satelliteZipCode', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_Address_Geolocation__Latitude__s', 'satelliteAddressGeoLocationLatitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Satellite_Address_Geolocation__Longitude__s', 'satelliteAddressGeoLocationLongitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Seniority_Date__c', 'seniorityDate', 'date');
      mappingConfig.addFieldConfig('sked_Seniority_Rank__c', 'seniorityRank', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Termination_Date__c', 'terminationDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Turnaround_Time__c', 'turnaroundTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Use_CO_Address_for_Scheduling__c', 'useCOAddressForScheduling', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Max_Working_Days_Per_Week__c', 'maxWorkingDaysPerWeek', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__User__c', 'userId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__User__r.SmallPhotoUrl', 'photoUrl', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked__Primary_Region__r', 'primaryRegion', MAPPING_TYPE.related, 'sked__Region__c');

      mappingConfig.addFieldConfigWithRelatedList('sked__Activities__r', 'activities', 'sked__Activity__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__Activity_Resources__r', 'activityResources', 'sked__Activity_Resource__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__Account_Resource_Scores__r', 'accountResourceScores', 'sked__Account_Resource_Score__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__Availabilities1__r', 'availabilities', 'sked__Availability__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__Availability_Pattern_Resources__r', 'availabilityPatternResources', 'sked__Availability_Pattern_Resource__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Resource_Biomed_Collection_Ops__r', 'secondaryCollectionOperations', 'sked_Resource_Biomed_Collection_Op__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Custom_Availabilities__r', 'customAvailabilities', 'sked_Custom_Availability__c', 'sked_Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__Job_Allocations__r', 'jobAllocations', 'sked__Job_Allocation__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__Location_Resource_Scores__r', 'locationResourceScores', 'sked__Location_Resource_Score__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__Resource_Overrides__r', 'resourceOverrides', 'sked__Resource_Override__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Resource_Hours_Records__r', 'resourceHoursRecords', 'sked_Resource_Hours_Record__c', 'sked__Resource__c');
      mappingConfig.addFieldConfigWithRelatedList('sked__ResourceTags__r', 'resourceTags', 'sked__Resource_Tag__c', 'sked__Resource__c');

      return mappingConfig;
  }
};