import { FIELD_TYPE, RTV_APPROVAL_STATUS } from 'c/slwcConstants';
import { LightningElement, api, track } from 'lwc';

export default class SlwcSiteFeedbackApproval extends LightningElement {
  // @api recordId = 'a3G2i000000NNJuEAO';
  @api recordId;

  @track rejectAdditionalFields = [
    {
      label: 'Denial Notes',
      type: 'text',
      field: 'reason',
      required: true
    }
  ];

  @track approveAdditionalFields = [
    {
      label: 'Effective Start Date',
      type: FIELD_TYPE.DATE,
      field: 'effectiveStartDate',
      required: true,
    },
    {
      label: 'Effective End Date',
      type: FIELD_TYPE.DATE,
      field: 'effectiveEndDate',
      required: true,
    },
    {
      label: 'Days Of Week',
      type: FIELD_TYPE.MULTIPICKLIST,
      field: 'daysOfWeek',
      objectApiName: 'sked_Site_Feedback__c',
      multiPicklistFieldApiName: 'sked_Days_Of_Week__c',
      required: true
    },
    {
      label: 'Variance Type',
      type: FIELD_TYPE.PICKLIST,
      field: 'varianceType',
      objectApiName: 'sked_Site_Feedback__c',
      picklistFieldApiName: 'sked_Variance_Type__c',
      required: true,
      readonly: (record) => !!record.roleTimeVarianceId
    },
    {
      label: 'Variance Type Other',
      type: FIELD_TYPE.TEXT,
      field: 'varianceTypeOther',
      required: (record) => record.varianceType === 'Other',
      hideIf: (record) => record.varianceType !== 'Other',
      readonly: (record) => !!record.roleTimeVarianceId,
      depends: (record) => record.varianceType === 'Other'
    },
    {
      label: 'Buffer Type',
      type: FIELD_TYPE.PICKLIST,
      field: 'bufferType',
      objectApiName: 'sked_Site_Feedback__c',
      picklistFieldApiName: 'sked_Buffer_Type__c',
      required: true
    },
    {
      label: 'Variance Applies To',
      type: FIELD_TYPE.MULTIPICKLIST,
      field: 'varianceAppliesTo',
      objectApiName: 'sked_Site_Feedback__c',
      multiPicklistFieldApiName: 'sked_Variance_Applies_To__c',
      dependentFieldApiName: 'sked_Variance_Type__c',
      required: true
    },
    {
      label: 'Resource Role Group',
      type: FIELD_TYPE.MULTIPICKLIST,
      field: 'resourceRoleGroup',
      objectApiName: 'sked_Site_Feedback__c',
      multiPicklistFieldApiName: 'sked_Resource_Role_Group__c',
      required: true
    },
    {
      label: 'Amount (minutes)',
      type: FIELD_TYPE.NUMBER,
      field: 'varianceAmount',
      min: 5,
      step: 5,
      required: true
    },
    {
      label: 'Reason',
      type: FIELD_TYPE.TEXT,
      field: 'reason',
      required: (record) => record.status === 'Waiting for APS Approval',
      hideIf: (record) => {
        return record.status !== 'Waiting for APS Approval';
      }
    }
  ];

  @track canApproveReject = (record) => {
    return record.status !== RTV_APPROVAL_STATUS.EXPIRED;
  }
}