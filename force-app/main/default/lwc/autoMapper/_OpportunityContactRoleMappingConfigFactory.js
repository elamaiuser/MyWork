import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OpportunityContactRoleMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'OpportunityContactRole';
      mappingConfig.objectType = 'opportunityContactRole';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('ContactId', 'contactId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('OpportunityId', 'opportunityId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Role', 'role', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}