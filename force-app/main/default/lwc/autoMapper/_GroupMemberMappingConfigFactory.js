import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class GroupMemberMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'GroupMember';
      mappingConfig.objectType = 'GroupMember';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Group.Name', 'groupName');

      return mappingConfig;
  }
}