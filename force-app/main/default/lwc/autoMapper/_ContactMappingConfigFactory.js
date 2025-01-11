import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class ContactMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Contact';
      mappingConfig.objectType = 'contact';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Email', 'email', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Phone', 'phone', MAPPING_TYPE.direct);

      return mappingConfig;
  }
};