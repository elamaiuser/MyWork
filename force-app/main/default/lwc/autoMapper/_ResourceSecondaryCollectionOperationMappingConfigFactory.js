import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel } from './_base.js';

export class ResourceSecondaryCollectionOperationMappingConfigFactory {
  constructor() { }

  process() {
    let mappingConfig = new mappingConfigModel();
    mappingConfig.sObjectName = 'sked_Resource_Biomed_Collection_Op__c';
    mappingConfig.objectType = 'resourceBiomedCollectionOp';

    mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
    mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
    mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__c', 'collectionOperationId', MAPPING_TYPE.direct);
    mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
    mappingConfig.addFieldConfig('sked_Resource__c', 'resourceId', MAPPING_TYPE.direct);
    mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);

    mappingConfig.readonlyFields.push('Name');

    return mappingConfig;
  }
}