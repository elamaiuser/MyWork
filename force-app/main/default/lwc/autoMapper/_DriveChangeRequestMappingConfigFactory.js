import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveChangeRequestMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Drive_Change_Request__c';
      mappingConfig.objectType = 'driveChangeRequest';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedBy', 'createdBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('CreatedBy.Name', 'createdByName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('LastModifiedDate', 'lastModifiedDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Auto_Process__c', 'autoProcess', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Comments__c', 'comments', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Designated_Approver__c', 'designatedApproverId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Designated_Approver__r.Name', 'designatedApproverName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Contention__c', 'driveContention', MAPPING_TYPE.multiPicklist);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Drive_Date__c', 'driveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_End_Time__c', 'driveEndTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive__r.Name', 'driveName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Drive_Productivity_Planned__c', 'driveProductivityPlanned', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Drive_Site__r.sked__Address__c', 'driveSiteAddress', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Drive_Site__r.sked_Physical_Location_Type__c', 'driveSiteType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Drive_Shift_Count__c', 'driveShiftCount', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Start_Time__c', 'driveStartTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Status__c', 'driveStatus', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Total_Equipment_Requested__c', 'driveTotalEquipmentRequested', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Total_Staff_Requested__c', 'driveTotalStaffRequested', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Type_of_Drive__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Vehicle_Types__c', 'driveVehicleTypes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Notes__c', 'notes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Opportunity__c', 'opportunityId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Reason__c', 'reason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Route_Approval_Request_To__c', 'routeApprovalRequestTo', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Sub_reason__c', 'subReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Type__c', 'type', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_Drive_Change_Request_Items__r', 'driveChangeRequestItems', 'sked_Drive_Change_Request_Item__c', 'sked_Drive_Change_Request__c');

      mappingConfig.masterFields.push('sked_Drive__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
};