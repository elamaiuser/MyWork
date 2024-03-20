import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class SiteFeedbackMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Site_Feedback__c';
      mappingConfig.objectType = 'siteFeedback';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Amount__c', 'amount', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Buffer_Type__c', 'bufferType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Designated_Approver__c', 'designatedApproverId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Designated_Approver__r.Name', 'designatedApproverName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DM_Approver__c', 'dmApproverId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.Name', 'driveName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_End_Date__c', 'effectiveEndDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Effective_Start_Date__c', 'effectiveStartDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Job__c', 'jobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Job__r.Name', 'jobName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Reason__c', 'reason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Resource_Role_Group__c', 'resourceRoleGroup', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Route_Approval_Request_To__c', 'routeApprovalRequestTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site__c', 'siteId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site__r.Name', 'siteName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Variance_Applies_To__c', 'varianceAppliesTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Variance_Type__c', 'varianceType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedBy', 'createdBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('CreatedBy.Name', 'createdByName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('LastModifiedDate', 'lastModifiedDate', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}