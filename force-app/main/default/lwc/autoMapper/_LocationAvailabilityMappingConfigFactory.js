import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class LocationAvailabilityMappingConfigFactory {
    constructor() {}

    process() {
        let mappingConfig = new mappingConfigModel();
        mappingConfig.sObjectName = 'sked_Location_Availability__c';
        mappingConfig.objectType = 'locationAvailability';

        mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Finish__c', 'finish', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Is_Available__c', 'isAvailable', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Location__c', 'locationId', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Notes__c', 'notes', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Start__c', 'start', MAPPING_TYPE.direct);

        mappingConfig.readonlyFields.push('Name');

        mappingConfig.masterFields.push('sked_Location__c');

        return mappingConfig;
    }
}