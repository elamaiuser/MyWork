import { DRIVE_SHIFT_TRADE_STATUS, FIELD_TYPE } from 'c/slwcConstants';
import { LightningElement, api, track } from 'lwc';

export default class SlwcDriveShiftTradeApproval extends LightningElement {
  // @api recordId = 'a1x3F000000tJW9QAM';
  @api recordId;
  @api record;
  
  get isReadonly() {
    return [DRIVE_SHIFT_TRADE_STATUS.WAITING_FOR_REQUESTING_STAFF_ACKNOWLEDGE, DRIVE_SHIFT_TRADE_STATUS.WAITING_FOR_TRADING_STAFF_ACKNOWLEDGE, 
      DRIVE_SHIFT_TRADE_STATUS.EXPIRED, DRIVE_SHIFT_TRADE_STATUS.CANCELLED].includes(this.record?.status);
  }
  @track rejectAdditionalFields = [
    {
      label: 'Denied Reason',
      type: FIELD_TYPE.PICKLIST,
      field: 'deniedReason',
      required: true,
      objectApiName: 'sked_Drive_Shift_Trade__c',
      picklistFieldApiName: 'sked_Denied_Reason__c'
    },
    {
      label: 'APS Notes',
      type: FIELD_TYPE.TEXT,
      field: 'apsNotes',
      required: (driveShiftTradeApprovalModel) => driveShiftTradeApprovalModel.deniedReason === 'Other',
      objectApiName: 'sked_Drive_Shift_Trade__c'
    }
  ];
}