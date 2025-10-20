import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OpportunityMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'Opportunity';
      mappingConfig.objectType = 'opportunity';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('AccountId', 'accountId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Account.APT_Required__c', 'accountAptRequired', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Account_Type__c', 'accountType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Account_Manager__c', 'accountManagerId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Anticipated_Registered_Donors__c', 'anticipatedRegisteredDonors', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Anticipated_Registered_Donors_Template__c', 'anticipatedRegisteredDonorsTemplate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('APT_Required__c', 'aptRequired', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('APT_Quantity__c', 'aptQuantity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Call_List_Recipient_Exist__c', 'callListRecipientExist', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Drive_Date__c', 'driveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Drive_Date_Change_Reason__c', 'driveDateChangeReason', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Drive_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Drive_Site__c', 'driveSiteId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Drive_Site__r.Operation_Type__c', 'operationType', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('End_Time__c', 'endTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('Industry_Code__c', 'industryCode', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Linked_Opportunity_Drives__c', 'linkedOpportunityDrivesId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Number_of_2RBC_Assets__c', 'numberOf2rbcAssets', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Number_of_Plasma_Assets__c', 'numberOfPlasmaAssets', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Number_of_Platelet_Assets__c', 'numberOfPlateletAssets', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Processing_Status__c', 'processingStatus', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Plasma_Pheresis_Projected_Procedures__c', 'plasmaProjectedProcedures', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Platelet_Projected_Procedures__c', 'plateletProjectedProcedures', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Recruited_By__c', 'recruitedBy', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Slot_Generator__c', 'slotGenerator', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Start_Time__c', 'startTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('StageName', 'stage', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Type', 'type', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Type_of_Drive__c', 'typeOfDrive', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('WB_Projected_Procedures__c', 'wbProjectedProcedures', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('X2RBC_Projected_Procedures__c', 'x2rbcProjectedProcedures', MAPPING_TYPE.direct);
      
      mappingConfig.addFieldConfig('Account', 'account', MAPPING_TYPE.related, 'Account');
      mappingConfig.addFieldConfig('Account.Owner', 'driveOwner', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('Account_Manager__r', 'accountManager', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('Drive_Site__r', 'driveSite', MAPPING_TYPE.related, 'sked__Location__c');

      mappingConfig.addFieldConfigWithRelatedList('OpportunityContactRoles', 'opportunityContactRoles', 'OpportunityContactRole', 'OpportunityId');
      mappingConfig.addFieldConfigWithRelatedList('sked_Drives__r', 'drives', 'sked_Drive__c', 'sked_Opportunity__c');

      mappingConfig.readonlyFields.push('Account_Type__c');
      mappingConfig.readonlyFields.push('Industry_Code__c');

      return mappingConfig;
  }
}