import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AccountMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Account';
      mappingConfig.objectType = 'account';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Accepts_Automation2__c', 'acceptsAutomation', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('APT_Required__c', 'aptRequired', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Days_of_Week_Declined__c', 'daysOfWeekDeclined', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('Days_of_Week_Preferred__c', 'daysOfWeekPreferred', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('Industry_Code__c', 'industryCode', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('National_Name__c', 'nationalName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Type', 'type', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('Owner', 'owner', MAPPING_TYPE.related, 'User');

      mappingConfig.addFieldConfigWithRelatedList('sked_Client_Availabilities__r', 'clientAvailabilities', 'sked__Client_Availability__c', 'sked__Account__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Account_Availability_Preferences__r', 'accountAvailabilityPreferences', 'sked_Account_Availability_Preference__c', 'sked_Account__c');

      return mappingConfig;
  }
};