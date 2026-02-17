import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class TravelTimeSlotConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Travel_Time_Slot__c';
      mappingConfig.objectType = 'travelTimeSlot';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Time__c', 'endTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Time__c', 'startTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Weekday__c', 'weekday', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}
