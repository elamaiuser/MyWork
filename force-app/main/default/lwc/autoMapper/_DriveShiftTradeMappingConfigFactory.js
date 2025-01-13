import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveShiftTradeMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Drive_Shift_Trade__c';
      mappingConfig.objectType = 'driveShiftTrade';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_APS_Notes__c', 'apsNotes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__r.Name', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Contact_Method__c', 'contactMethod', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Contention_Acknowledge__c', 'contentionAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Date_Trade_Approved__c', 'dateTradeApproved', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Denied_Reason__c', 'deniedReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Designated_Approver__c', 'designatedApproverId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Designated_Approver__r.Name', 'designatedApproverName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Reason_Approval_Required__c', 'reasonApprovalRequired', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requester_Not_Available_For_CO__c', 'requestingStaffUnavailableForCO', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requester_Relocated_Acknowledge__c', 'requesterRelocatedAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requester_Unavailable_For_CO_Ack__c', 'requesterUnavailableForCOAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff__c', 'requestingStaffId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Trade_Reason__c', 'requestingStaffTradeReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Notes__c', 'requestingStaffNotes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff__r.Name', 'requestingStaffName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Name', 'requestingStaffPrimaryCOName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff__r.sked_Hire_Date__c', 'requestingStaffHireDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Drive__c', 'requestingStaffDriveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Drive_Date__c', 'requestingStaffDriveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Drive_ID__c', 'requestingStaffDriveUfid', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Drive_Name__c', 'requestingStaffDriveName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Drive_Type__c', 'requestingStaffDriveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Drive_Shift__c', 'requestingStaffDriveShiftId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Drive_Shift__r.Name', 'requestingStaffDriveShiftName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_GMH_Acknowledge__c', 'requestingStaffGMHAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Trading_Avail_Date__c', 'requestingStaffTradingAvailableDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Trading_Event_Name__c', 'requestingStaffTradingEventName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Trading_Event_Date__c', 'requestingStaffTradingEventDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Job__c', 'requestingStaffJobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Job__r.sked__Start__c', 'requestingStaffJobStart', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Job__r.sked__Finish__c', 'requestingStaffJobEnd', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Job_Allocation__c', 'requestingStaffJobAllocationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Job_Allocation__r.sked_Roles_Assignment_Str__c', 'requestingStaffAssignedRoles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_NCE__c', 'requestingStaffNCEId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Overnight__c', 'requestingStaffOvernight', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_TAT_Acknowledge__c', 'requestingStaffTATAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Trading_Type__c', 'requestingStaffTradingType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Relocated__c', 'requestingStaffRelocated', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_Role_on_Drive__c', 'requestingStaffRoleOnDrive', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_RequestingStaffScheduledHoursAfter__c', 'requestingStaffScheduledHoursAfter', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_RequestingStaffScheduledHoursBefore__c', 'requestingStaffScheduledHoursBefore', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_TT_To_Before_Trade__c', 'requestingStaffTravelTimeToBeforeTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_TT_To_After_Trade__c', 'requestingStaffTravelTimeToAfterTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_TTBack_BeforeTrade__c', 'requestingStaffTravelTimeBackBeforeTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Requesting_Staff_TTBack_AfterTrade__c', 'requestingStaffTravelTimeBackAfterTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_GuaranteedMinHrsForfeited_Requester__c', 'requestingStaffGuaranteedMinHrsForfeited', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_TAT_Time_Traded_Into_Requester__c', 'requestingStaffTurnaroundViolation', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trader_Not_Available_For_CO__c', 'tradingStaffUnavailableForCO', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trader_Relocated_Acknowledge__c', 'traderRelocatedAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trader_Unavailable_For_CO_Ack__c', 'traderUnavailableForCOAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Notes__c', 'tradingStaffNotes', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Trade_Reason__c', 'tradingStaffTradeReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff__c', 'tradingStaffId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff__r.Name', 'tradingStaffName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Name', 'tradingStaffPrimaryCOName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff__r.sked_Hire_Date__c', 'tradingStaffHireDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Drive__c', 'tradingStaffDriveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Drive_Date__c', 'tradingStaffDriveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Drive_ID__c', 'tradingStaffDriveUfid', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Drive_Name__c', 'tradingStaffDriveName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Drive_Type__c', 'tradingStaffDriveType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Drive_Shift__c', 'tradingStaffDriveShiftId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Drive_Shift__r.Name', 'tradingStaffDriveShiftName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_GMH_Acknowledge__c', 'tradingStaffGMHAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Trading_Avail_Date__c', 'tradingStaffTradingAvailableDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Trading_Event_Name__c', 'tradingStaffTradingEventName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Trading_Event_Date__c', 'tradingStaffTradingEventDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Job__c', 'tradingStaffJobId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Job_Allocation__c', 'tradingStaffJobAllocationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Job_Allocation__r.sked_Roles_Assignment_Str__c', 'tradingStaffAssignedRoles', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Overnight__c', 'tradingStaffOvernight', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_NCE__c', 'tradingStaffNCEId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_TAT_Acknowledge__c', 'tradingStaffTATAcknowledge', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Trading_Type__c', 'tradingStaffTradingType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Relocated__c', 'tradingStaffRelocated', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Role_on_Drive__c', 'tradingStaffRoleOnDrive', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_Scheduled_Hours_After__c', 'tradingStaffScheduledHoursAfter', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_TradingStaff_Scheduled_Hours_Before__c', 'tradingStaffScheduledHoursBefore', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_TT_To_Before_Trade__c', 'tradingStaffTravelTimeToBeforeTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_TT_To_After_Trade__c', 'tradingStaffTravelTimeToAfterTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_TT_Back_Before_Trade__c', 'tradingStaffTravelTimeBackBeforeTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Trading_Staff_TT_Back_After_Trade__c', 'tradingStaffTravelTimeBackAfterTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_GuaranteedMinHrsForfeited_Trading__c', 'tradingStaffGuaranteedMinHrsForfeited', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_TAT_Time_Traded_Into_Trading__c', 'tradingStaffTurnaroundViolation', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory_Key__c', 'territoryKey', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Is_One_Side_Trade__c', 'isOneSideTrade', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedBy', 'createdBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('CreatedBy.Name', 'createdByName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('LastModifiedDate', 'lastModifiedDate', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfig('sked_Requesting_Staff_Job_Allocation__r', 'requestingStaffJobAllocation', MAPPING_TYPE.related, 'sked__Job_Allocation__c');
      mappingConfig.addFieldConfig('sked_Requesting_Staff_NCE__r', 'requestingStaffNCE', MAPPING_TYPE.related, 'sked__Activity__c');
      mappingConfig.addFieldConfig('sked_Trading_Staff_NCE__r', 'tradingStaffNCE', MAPPING_TYPE.related, 'sked__Activity__c');
      
      return mappingConfig;

  }
}