import { LightningElement, api, track } from 'lwc';

export default class SlwcSiteFeedbackApproval extends LightningElement {
  // @api recordId = 'a3G2i000000NNJuEAO';
  @api recordId;

  @track rejectAdditionalFields = [
    {
      label: 'Reason',
      type: 'text',
      field: 'reason',
      required: true
    }
  ];

  @track approveAdditionalFields = [
    {
      label: 'Effective Start Date',
      type: 'date',
      field: 'effectiveStartDate',
      required: true,
      hideIf: (record) => {
        return record.status !== 'Waiting for CO Supervisor Approval';
      }
    },
    {
      label: 'Effective End Date',
      type: 'date',
      field: 'effectiveEndDate',
      required: true,
      hideIf: (record) => {
        return record.status !== 'Waiting for CO Supervisor Approval';
      }
    },
    {
      label: 'Reason',
      type: 'text',
      field: 'reason',
      required: true,
      hideIf: (record) => {
        return record.status !== 'Waiting for CO Supervisor Approval';
      }
    }
  ];
}