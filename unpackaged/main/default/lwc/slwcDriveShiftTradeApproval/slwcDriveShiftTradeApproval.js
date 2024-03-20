import { LightningElement, api, track } from 'lwc';

export default class SlwcDriveShiftTradeApproval extends LightningElement {
  // @api recordId = 'a1x3F000000tJW9QAM';
  @api recordId;
  
  @track rejectAdditionalFields = [
    {
      label: 'Denied Reason',
      type: 'picklist',
      field: 'deniedReason',
      required: true,
      objectApiName: 'sked_Drive_Shift_Trade__c',
      picklistFieldApiName: 'sked_Denied_Reason__c'
    }
  ];
}