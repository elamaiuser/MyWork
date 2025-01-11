import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class UserMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'User';
      mappingConfig.objectType = 'user';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Profile.Name', 'profileName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('SmallPhotoUrl', 'photoUrl', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Redcross_Skedulo_Usertype__c', 'redcrossSkeduloUsertype', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}