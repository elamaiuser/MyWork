import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class RegionMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked__Region__c';
      mappingConfig.objectType = 'region';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked__Timezone__c', 'timezoneSidId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c', 'collectionOperationWorkWeekFirstDay', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__r.sked_Available_Day_Trade_Window__c', 'collectionOperationAvailableDayTradeWindow', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}