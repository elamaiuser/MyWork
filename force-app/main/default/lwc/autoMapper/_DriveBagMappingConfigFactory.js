import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveBagMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Drive_Bag__c';
      mappingConfig.objectType = 'driveBag';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Bag_Type__c', 'bagType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Delivery_Job__c', 'driveDeliveryJobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Quantity__c', 'quantity', MAPPING_TYPE.direct);

      mappingConfig.masterFields.push('sked_Drive_Delivery_Job__c');

      return mappingConfig;
  }
}