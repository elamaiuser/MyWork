import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class RoleTimeDetailMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Role_Time_Detail__c';
      mappingConfig.objectType = 'roleTimeDetail';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Breakdown_Time__c', 'breakdownTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Days_of_Week__c', 'daysOfWeek', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_End_Date__c', 'effectiveEndDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_Start_Date__c', 'effectiveStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Fixed_Site_Operation_Type__c', 'fixedSiteOperationType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lead_Time__c', 'leadTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Mobile_Type__c', 'mobileType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Role_Group__c', 'resourceRoleGroup', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('sked_Setup_Time__c', 'setupTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Type__c', 'roleTimeDetailType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Wrap_up_Time__c', 'wrapUpTime', MAPPING_TYPE.direct);

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}