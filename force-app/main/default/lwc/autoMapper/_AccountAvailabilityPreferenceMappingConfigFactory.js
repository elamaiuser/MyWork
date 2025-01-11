import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AccountAvailabilityPreferenceMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Account_Availability_Preference__c';
      mappingConfig.objectType = 'accountAvailabilityPreference';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Account__c', 'accountId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Month_Name__c', 'monthName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Preferred_Weekdays__c', 'preferredWeekdays', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('sked_Preferred_Weeks__c', 'preferredWeeks', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('sked_Restricted_Weekdays__c', 'restrictedWeekdays', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('sked_Restricted_Weeks__c', 'restrictedWeeks', MAPPING_TYPE.multiPicklist);

      return mappingConfig;
  }
}