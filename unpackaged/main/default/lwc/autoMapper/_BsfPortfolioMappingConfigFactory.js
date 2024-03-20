import { MAPPING_TYPE, mappingConfigModel }  from './_base.js';

export class BsfPortfolioMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'BSF_Portfolio__c';
      mappingConfig.objectType = 'bsfPortfolio';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Account_Based_Portfolio__c', 'accountBasedPortfolio', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Territory_Portfolio__c', 'territoryPortfolio', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Start_Date__c', 'startDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('End_Date__c', 'endDate', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}