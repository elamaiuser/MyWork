import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveDeliveryJobMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Drive_Delivery_Job__c';
      mappingConfig.objectType = 'driveDeliveryJob';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Arrive__c', 'arrive', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Comments__c', 'comments', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Delivery_ID__c', 'deliveryId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End__c', 'end', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Pick_Up__c', 'pickUp', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Type__c', 'type', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Vehicle__c', 'vehicle', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_Drive_Bags__r', 'driveBags', 'sked_Drive_Bag__c', 'sked_Drive_Delivery_Job__c');

      return mappingConfig;
  }
}