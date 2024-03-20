import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OperationRecordMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Operation_Record__c';
      mappingConfig.objectType = 'operationRecord';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity_No_of_Issue_Devices__c', 'connectivityNoOfIssueDevices', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_No_of_Issue_Devices__c', 'eBdrNoOfIssueDevices', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Account__c', 'accountId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Account__r.Name', 'accountName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Account_External_ID__c', 'accountExternalID', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Drive_End__c', 'actualDriveEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Actual_Drive_Start__c', 'actualDriveStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Barcode__c', 'barcode', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Changed_Drive_Location__c', 'changedDriveLocation', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Changed_Drive_Location_Reason__c', 'changedDriveLocationReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Checked_In_No_HH__c', 'checkedInNoHH', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__r.Name', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity__c', 'connectivity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity_Client__c', 'connectivityClient', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity_Detail__c', 'connectivityDetail', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity_Handheld__c', 'connectivityHandheld', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity_Reason__c', 'connectivityReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity_Total_Devices__c', 'connectivityTotalDevices', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Connectivity_Zebra__c', 'connectivityZebra', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Donor_Ambassadors_Actual__c', 'donorAmbassadorsActual', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Donor_Ambassadors_Requested__c', 'donorAmbassadorsRequested', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DRD_Rep__c', 'drdRep', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_DRD_Rep_Contact__c', 'drdRepContact', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.Name', 'driveName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_UFID__c', 'driveUfid', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Min_Shift_Start__c', 'driveMinShiftStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__r.sked_Max_Shift_End__c', 'driveMaxShiftEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Date__c', 'driveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Delayed__c', 'driveDelayed', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Delayed_Reason__c', 'driveDelayedReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_End_Time__c', 'driveEndTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive_External_ID__c', 'driveExternalID', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Issues__c', 'driveIssues', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__c', 'driveShiftId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift__r.Name', 'driveShiftName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Shift_End_Time__c', 'driveShiftEndTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive_Shift_Start_Time__c', 'driveShiftStartTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive_Site__c', 'driveSiteId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Site__r.Name', 'driveSiteName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Start_Time__c', 'driveStartTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Drive_Type__c', 'driveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_Client__c', 'eBdrClient', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_Equipment_Problem_Failure__c', 'eBdrEquipmentProblemFailure', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_Handheld__c', 'eBdrHandheld', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_Master__c', 'eBdrMaster', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_Total_Devices__c', 'eBdrTotalDevices', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_eBDR_Zebra__c', 'eBdrZebra', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Floor_Description__c', 'floorDescription', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Improper_Room_Conditions__c', 'improperRoomConditions', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Improper_Room_Conditions_Reason__c', 'improperRoomConditionsReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Last_Modified_User__c', 'lastModifiedUser', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Late_End_Drive__c', 'lateEndDrive', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Late_End_Drive_Approved_By__c', 'lateEndDriveApprovedBy', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Late_End_Reason__c', 'lateEndReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Limited_Access_to_Unload__c', 'limitedAccessToUnload', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Limited_Access_to_Unload_Reason__c', 'limitedAccessToUnloadReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Master_Server_Issue__c', 'masterServerIssue', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Master_Server_Issue_Reason__c', 'masterServerIssueReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Missing_Equipment_Supply__c', 'missingEquipmentSupply', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Missing_Equipment_Supply_Reason__c', 'missingEquipmentSupplyReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_National_Account_Name__c', 'nationalAccountName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_National_Site_Name__c', 'nationalSiteName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Notes_Comments__c', 'notesComments', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Power_Red_Machines_Sent__c', 'powerRedMachinesSent', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Power_Red_Machines_Used__c', 'powerRedMachinesUsed', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Primary_Contact__c', 'primaryContactId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Primary_Contact__r.Name', 'primaryContactName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Primary_Contact_Phone__c', 'primaryContactPhone', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Projected_Procedures__c', 'projectedProcedures', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Projected_Products__c', 'projectedProducts', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Purple_Top__c', 'purpleTop', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_QC_Issue__c', 'qcIssue', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_QC_Issue_Reason__c', 'qcIssueReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Room_Name__c', 'roomName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Room_Not_Accessible_Locked__c', 'roomNotAccessibleLocked', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Room_Not_Accessible_Locked_Reason__c', 'roomNotAccessibleLockedReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Security_Protocol_Issue__c', 'securityProtocolIssue', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Security_Protocol_Issue_Reason__c', 'securityProtocolIssueReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Setup__c', 'setup', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Setup_Reason__c', 'setupReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Address__c', 'siteAddress', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Contact__c', 'siteContactId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Contact__r.Name', 'siteContactName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_Contact_Phone__c', 'siteContactPhone', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Site_External_ID__c', 'siteExternalID', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Staff__c', 'staff', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Staff_Reason__c', 'staffReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Supervisor_Charge_Signature__c', 'supervisorChargeSignature', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Vehicle_Malfunction__c', 'vehicleMalfunction', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Vehicle_Malfunction_Reason__c', 'vehicleMalfunctionReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Wireless_Policy__c', 'wirelessPolicy', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_Operation_Record_Staff__r', 'operationRecordStaff', 'sked_Operation_Record_Staff__c', 'sked_Operation_Record__c');

      mappingConfig.readonlyFields.push('Name');
      mappingConfig.readonlyFields.push('sked_Timezone__c');

      return mappingConfig;
  }
}