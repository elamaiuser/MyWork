import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class AvailabilityMappingConfigFactory {
    constructor() {}

    process() {
        let mappingConfig = new mappingConfigModel();
        mappingConfig.sObjectName = 'sked__Availability__c';
        mappingConfig.objectType = 'availability';

        mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);        
        mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Custom_Status__c', 'status', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Workday_Sync_Message__c', 'workdaySyncMessage', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked__Finish__c', 'finish', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Finish_Date__c', 'endDate', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked__Is_Available__c', 'isAvailable', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked__Resource__r.Name', 'resourceName', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked__Start__c', 'start', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked__Type__c', 'eventType', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Activity__c', 'callOutForActivityId', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Activity__r.sked_Activity_Title__c', 'callOutForActivityTitle', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Activity__r.sked__Type__c', 'callOutForActivityEventType', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Activity__r.sked_Subtype__c', 'callOutForActivitySubtype', MAPPING_TYPE.direct);

        mappingConfig.addFieldConfig('sked_Call_Out_for_Job_Allocation__c', 'callOutForJobAllocationId', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__r.Name', 'callOutForJobAllocationDriveName', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__r.sked_Drive_Date__c', 'callOutForJobAllocationDriveDate', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__r.sked_Start_Time__c', 'callOutForJobAllocationDriveStartTime', MAPPING_TYPE.time);
        mappingConfig.addFieldConfig('sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__r.sked_End_Time__c', 'callOutForJobAllocationDriveEndTime', MAPPING_TYPE.time);

        mappingConfig.addFieldConfig('sked_Call_Out_for_Drive__c', 'callOutForDriveId', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_Type__c', 'callOutType', MAPPING_TYPE.direct);
        mappingConfig.addFieldConfig('sked_Call_Out_Reason_Code__c', 'callOutReasonCode', MAPPING_TYPE.direct);

        mappingConfig.addFieldConfig('sked_Call_Out_for_Activity__r', 'callOutForActivity', MAPPING_TYPE.related, 'sked__Activity__c');
        mappingConfig.addFieldConfig('sked_Call_Out_for_Job_Allocation__r', 'callOutForJobAllocation', MAPPING_TYPE.related, 'sked__Job_Allocation__c');

        mappingConfig.readonlyFields.push('Name');
        mappingConfig.readonlyFields.push('sked_Start_Date__c');
        mappingConfig.readonlyFields.push('sked_Finish_Date__c');

        mappingConfig.masterFields.push('sked__Resource__c');

        return mappingConfig;
    }
}