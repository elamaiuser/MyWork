import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class StaffingDecisionMatrixMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Staffing_Decision_Matrix__c';
      mappingConfig.objectType = 'staffingDecisionMatrix';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_2RBC_Staff_Capacity__c', 'x2RbcStaffCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Charge_Capacity__c', 'chargeCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Charge_Threshold__c', 'chargeThreshold', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Driver_Capacity__c', 'driverCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Driver_Support_Capacity__c', 'driverSupportCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_NR_Volunteer_Fixed_Site_Band_Lower__c', 'nrVolunteerFixedSiteBandLower', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_NR_Volunteer_Fixed_Site_Band_Upper__c', 'nrVolunteerFixedSiteBandUpper', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Team_Supervisor_Threshold__c', 'teamSupervisorThreshold', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_VP_HH_Capacity__c', 'vpHhCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Plasma_Hourly_Capacity__c', 'plasmaHourlyCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_WB_Hourly_Capacity__c', 'wbHourlyCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_2RBC_Hourly_Capacity__c', 'x2rbcHourlyCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('RecordType.Name', 'recordTypeName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Platelet_Round_Capacity__c', 'plateletRoundCapacity', MAPPING_TYPE.direct);
      
      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}