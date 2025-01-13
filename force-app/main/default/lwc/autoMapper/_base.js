export const MAPPING_TYPE = {
  direct: 'direct',
  related: 'related',
  relatedList: 'relatedList',
  multiPicklist: 'multiPicklist',
  time: 'time'
}

export class fieldConfigModel {
  sObjectFieldPath;
  sObjectFieldPaths;
  domainFieldName;
  mappingType;
  relatedObjectDomainType;
  relatedSObjectName;
  relatedListSObjectName;
  parentFieldName;
}

export class mappingConfigModel {
  sObjectName;
  objectType;
  fieldConfigs;
  readonlyFields;
  masterFields;

  constructor(sObjectName, objectType) {
      this.sObjectName = sObjectName;
      this.objectType = objectType;
      this.fieldConfigs = [];
      this.readonlyFields = [];
      this.masterFields = [];
  }

  addFieldConfig(sObjectFieldPath, domainFieldName, mappingType, relatedSObjectName) {
      let fieldConfig = new fieldConfigModel();
      fieldConfig.sObjectFieldPath = sObjectFieldPath;
      fieldConfig.domainFieldName = domainFieldName;
      fieldConfig.mappingType = mappingType ? mappingType : MAPPING_TYPE.direct;
      fieldConfig.relatedSObjectName = relatedSObjectName;

      this.fieldConfigs.push(fieldConfig);
      return fieldConfig;
  }

  addFieldConfigWithRelatedList(sObjectFieldPath, domainFieldName, relatedListSObjectName, parentFieldName) {
      let fieldConfig = new fieldConfigModel();
      fieldConfig.sObjectFieldPath = sObjectFieldPath;
      fieldConfig.domainFieldName = domainFieldName;
      fieldConfig.mappingType = MAPPING_TYPE.relatedList;
      fieldConfig.relatedListSObjectName = relatedListSObjectName;
      fieldConfig.parentFieldName = parentFieldName;

      this.fieldConfigs.push(fieldConfig);
      return fieldConfig;
  }
}