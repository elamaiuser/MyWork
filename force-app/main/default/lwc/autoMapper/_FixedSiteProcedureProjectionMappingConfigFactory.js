import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class FixedSiteProcedureProjectionMappingConfigFactory {
    constructor() {}

    process() {
        let mappingConfig = new mappingConfigModel();
        mappingConfig.sObjectName = 'sked_Fixed_Site_Procedure_Projection__c';
        mappingConfig.objectType = 'fixedSiteProcedureProjection';

        mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('Name', 'name');
        mappingConfig.addFieldConfig('sked_Account__c', 'accountId');
        mappingConfig.addFieldConfig('sked_Deferral__c', 'deferral');
        mappingConfig.addFieldConfig('sked_Effective_End_Date__c', 'effectiveEndDate');
        mappingConfig.addFieldConfig('sked_Effective_Start_Date__c', 'effectiveStartDate');
        mappingConfig.addFieldConfig('sked_Impact_Drives__c', 'impactDrives');
        mappingConfig.addFieldConfig('sked_Procedure_Type__c', 'procedureType');
        mappingConfig.addFieldConfig('sked_QNS__c', 'qns');

        mappingConfig.masterFields.push('sked_Account__c');

        return mappingConfig;
    }
}