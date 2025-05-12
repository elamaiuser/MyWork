import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class DriveShiftMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Drive_Shift__c';
      mappingConfig.objectType = 'driveShift';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_APT_Setup__c', 'APTSetup', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_2RBC_Projected_Procedures__c', 'x2rbcProjectedProcedures', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Donors_Scheduled__c', 'donorsScheduled', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Drive_Date__c', 'driveDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Default_2RBC_Slots__c', 'default2rbcSlots', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Default_WB_Slots__c', 'defaultWbSlots', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Default_Platelet_Slots__c', 'defaultPlateletSlots', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Default_Plasma_Slots__c', 'defaultPlasmaSlots', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Time__c', 'endTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Equipment__c', 'equipment', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Finish__c', 'finish', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lunch_Break__c', 'lunchBreak', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lunch_Break_Before_Draw_Hours__c', 'lunchBreakBeforeDrawHours', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lunch_Break_Duration__c', 'lunchBreakDuration', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Lunch_Break_End_Time__c', 'lunchBreakEndTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Lunch_Break_Start_Time__c', 'lunchBreakStartTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Max_Donor_Capacity__c', 'maxDonorCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Plasma_Projected_Procedures__c', 'plasmaProjectedProcedures', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Platelet_Projected_Procedures__c', 'plateletProjectedProcedures', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Platelet_Rounds__c', 'plateletRounds', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Procedure_Capacity__c', 'procedureCapacity', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Sign_Up_Reduction__c', 'signUpReduction', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Staff_Setup__c', 'staffSetup', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Time__c', 'startTime', MAPPING_TYPE.time);
      mappingConfig.addFieldConfig('sked_Start__c', 'start', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Time_Block__c', 'timeBlockId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Total_Procedures_Projected__c', 'totalProceduresProjected', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Total_Products_Projected__c', 'totalProductsProjected', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Vehicles_Needed__c', 'vehiclesNeeded', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Volunteer_Setup__c', 'volunteerSetup', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_WB_Projected_Procedures__c', 'wbProjectedProcedures', MAPPING_TYPE.direct);

      mappingConfig.addFieldConfigWithRelatedList('sked_Drive_Shift_Tags__r', 'driveShiftTags', 'sked_Drive_Shift_Tag__c', 'sked_Drive_Shift__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Jobs__r', 'jobs', 'sked__Job__c', 'sked_Drive_Shift__c');
      mappingConfig.addFieldConfigWithRelatedList('sked_Slots__r', 'slots', 'sked__Slot__c', 'sked_Drive_Shift__c');

      mappingConfig.masterFields.push('sked_Drive__c');

      mappingConfig.readonlyFields.push('Name');

      return mappingConfig;
  }
}