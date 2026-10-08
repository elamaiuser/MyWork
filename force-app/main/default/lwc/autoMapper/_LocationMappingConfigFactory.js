import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class LocationMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Location__c';
      mappingConfig.objectType = 'location';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Operation_Type__c', 'operationType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Address__c', 'address', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Address_1__c', 'address1', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Address_2__c', 'address2', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_City__c', 'city', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation_Id__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation_Name__c', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_County__c', 'county', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Days_of_Week_Declined__c', 'daysOfWeekDeclined', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Days_of_Week_Preferred__c', 'daysOfWeekPreferred', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Do_Not_Use_Vehicle__c', 'doNotUseVehicle', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Date_Site_Inspection_Completed__c', 'dateSiteInspectionCompleted', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Fixed_Site_Appointment_Pattern__c', 'fixedSiteAppointmentPattern', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Latitude__s', 'geoLocationLatitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__GeoLocation__Longitude__s', 'geoLocationLongitude', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Max_Auto_Machines__c', 'maxAutoMachines', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_National_Name__c', 'nationalName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Physical_Location_Type__c', 'physicalLocationType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Building_Name__c', 'siteBuildingName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Inspection_Completed_By__c', 'siteInspectionCompletedById', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Inspection_Completed_By__r.Id', 'siteInspectionCompletedBy.id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Inspection_Completed_By__r.Name', 'siteInspectionCompletedBy.name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_State__c', 'state', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Room_Name__c', 'roomName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Travel_Time_to_Staging_Location__c', 'travelTimeToStagingLocation', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Zip_Code__c', 'zipCode', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Site_Inspection_Completed_By__r', 'siteInspectionCompletedBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('sked_Collection_Operation__r', 'collectionOperation', MAPPING_TYPE.related, 'Biomed_Collection_Op_Center__c');

      mappingConfig.addFieldConfigWithRelatedList('sked_Site_Collection_Operations__r', 'siteCollectionOperations', 'sked_Site_Collection_Operation__c', 'sked_Site__c');

      return mappingConfig;
  }
}