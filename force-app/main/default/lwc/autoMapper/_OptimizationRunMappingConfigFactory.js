import { MAPPING_TYPE, fieldConfigModel, mappingConfigModel }  from './_base.js';

export class OptimizationRunMappingConfigFactory {
  constructor() {}

  process() {
      let mappingConfig = new mappingConfigModel();
      mappingConfig.sObjectName = 'sked_Optimization_Run__c';
      mappingConfig.objectType = 'optimizationRun';

      mappingConfig.addFieldConfig('Id', 'id', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('Name', 'name', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('CreatedBy', 'createdBy', MAPPING_TYPE.related, 'User');
      mappingConfig.addFieldConfig('CreatedDate', 'createdDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Collection_Operation__r.Name', 'collectionOperationName', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', MAPPING_TYPE.direct);            
      mappingConfig.addFieldConfig('sked_Status__c', 'status', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Territory_Key__c', 'territoryKey', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Planned_Allocations__c', 'totalPlannedAllocations', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Sched_Allocations__c', 'totalSchedAllocations', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Unsched_Allocations__c', 'totalUnSchedAllocations', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Resource_Sched__c', 'totalResourceSched', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Resource_Unsched__c', 'totalResourceUnSched', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Sched_Time__c', 'totalSchedTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Travel_Time__c', 'totalTravelTime', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Total_Travel_Distances__c', 'totalTravelDistances', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Max_Travel_Time_Alloc__c', 'maxTravelTimeAllocations', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Avg_Num_Alloc_Resource__c', 'avgNumAllocationsPerResource', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Hard_Constraints_Score__c', 'hardConstraintScore', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Stat_Soft_Constraints_Score__c', 'softConstraintScore', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Parm_Accnt_Prefer__c', 'accountPreferences', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Parm_Site_Prefer__c', 'sitePreferences', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Parm_Geo_Prefer__c', 'geoPreferences', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Parm_Hire_Date_Skills__c', 'hireDateSkills', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Parm_Role_Priority_Skills__c', 'rolePrioritySkills', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Timezone__c', 'timeZone', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Run_Diff__c', 'runDiff', MAPPING_TYPE.direct);
      mappingConfig.addFieldConfig('sked_Opt_Run_Meta__c', 'runMeta', MAPPING_TYPE.direct);

      return mappingConfig;
  }
}