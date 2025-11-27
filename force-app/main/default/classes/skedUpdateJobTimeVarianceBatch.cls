global class skedUpdateJobTimeVarianceBatch implements Database.Batchable<sObject>, Database.Stateful {
    private static final Map<String, String> JOB_FIELD_NAME_BY_VARIANCE_LABEL = new Map<String,String>{
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME => 'sked_Lead_Time__c',
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME => 'sked_Setup_Time__c',
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME => 'sked_Breakdown_Time__c',
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_WRAP_UP_TIME => 'sked_Wrap_Up_Time__c',
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_TO => 'sked_Travel_Time__c',
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_FROM => 'sked_Travel_Time2__c',
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SITE_LOSGISTICS_TO => 'sked_Site_Logistics_To__c',
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SITE_LOSGISTICS_BACK => 'sked_Site_Logistics_Back__c'
    };

    private static final Set<String> ROLE_TIME_VARIANCE_START_TIME_FIELDS = new Set<String>{
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_TO,
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SITE_LOSGISTICS_TO 
    };

    private static final Set<String> ROLE_TIME_VARIANCE_FINISH_TIME_FIELDS = new Set<String>{
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME,
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_WRAP_UP_TIME,
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_FROM,
        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SITE_LOSGISTICS_BACK
    };
    
    private Map<String, Set<String>> resourceRoleByGroup;
    private Map<Id, List<skedRoleTimeVarianceAdjustment>> map_siteId_rtvAdjustments;
    private skedModels.startEnd minMaxRTVEffectiveDate;

    global skedUpdateJobTimeVarianceBatch(List<skedRoleTimeVarianceAdjustment> rtvAdjustments) {
        this.map_siteId_rtvAdjustments = getMapSiteIdToRtvAdjustments(rtvAdjustments);
        this.resourceRoleByGroup = skedResourceUtils.getResourceRolesByGroup();
        this.minMaxRTVEffectiveDate = getMinMaxRTVEffectiveDate(rtvAdjustments);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT 
                Id, sked_Drive_Site__c,
                (
                    SELECT
                        Id, sked_Setup_Time__c, sked_Lead_Time__c, sked_Travel_Time__c, sked_Site_Logistics_To__c,
                        sked_Wrap_Up_Time__c, sked_Breakdown_Time__c, sked_Travel_Time2__c, sked_Site_Logistics_Back__c,
                        sked__Start__c, sked_Start_Time__c, sked__Finish__c, sked_Finish_Time__c, sked_Start_Date__c, sked_Finish_Date__c,
                        sked_Resource_Role__c, sked_Dual_Role__c, sked_Asset_Type__c, sked_Volunteer_Role__c, sked_Drive_Shift__c
                    FROM sked_Jobs__r
                ),
                (
                    SELECT 
                        Id, sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Start_Time__c, sked_Drive__r.sked_Timezone__c,
                        sked_Order__c, sked_Drive__r.sked_Drive_Shift_Count__c,
                        sked_Drive__r.sked_Collection_Operation__r.sked_Breakdown_Time_Threshold__c, sked_Drive__r.sked_Collection_Operation__r.sked_Setup_Time_Threshold__c
                    FROM sked_Drive_Shifts__r
                    ORDER BY sked_Order__c
                )
            FROM sked_Drive__c
            WHERE sked_Drive_Date__c <= :this.minMaxRTVEffectiveDate.endDate
            AND sked_Drive_Date__c >= :this.minMaxRTVEffectiveDate.startDate
            AND sked_Drive_Site__c IN :this.map_siteId_rtvAdjustments.keySet()
            AND sked_Drive_Date__c > TODAY
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
            AND sked_Drive_Shift_Count__c > 0
            ORDER BY Id
        ]);
    }

    global void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        Map<Id, sked__Job__c> map_id_jobToUpdate = new Map<Id, sked__Job__c>();
        List<sked_Drive_Shift__c> driveShiftsToUpdate = new List<sked_Drive_Shift__c>();
        List<String> assetOrVolunteerJobIds = new List<String>();

        for (sked_Drive__c drive : drives) {
            Map<Id, List<sked__Job__c>> map_shiftId_jobs = getShiftIdJobsMap(drive.sked_Jobs__r);
            for (sked_Drive_Shift__c driveShift : drive.sked_Drive_Shifts__r) {
                List<sked__Job__c> jobs = map_shiftId_jobs.get(driveShift.Id);
                if (jobs != NULL && !jobs.isEmpty()) {
                    Boolean needRecalculateDriveShiftStartEndTime = false;
                    List<skedRoleTimeVarianceAdjustment> rtvAdjustments = this.map_siteId_rtvAdjustments.get(drive.sked_Drive_Site__c);
                    for (skedRoleTimeVarianceAdjustment rtvAdjustment : rtvAdjustments) {
                        if (checkAdjustmentDaysOfWeekAffectsDriveShift(rtvAdjustment, driveShift)) {
                            Set<String> affectedResourceRoles = getAffectedResourceRolesByResourceRoleGroup(rtvAdjustment.resourceRoleGroup);
                            for (sked__Job__c job : jobs) {
                                if (job.sked_Asset_Type__c != null || job.sked_Volunteer_Role__c != null) {
                                    assetOrVolunteerJobIds.add(job.Id);
                                } else if ((affectedResourceRoles.contains(job.sked_Resource_Role__c) || affectedResourceRoles.contains(job.sked_Dual_Role__c))
                                    && (job.sked_Start_Date__c <= rtvAdjustment.endDate && job.sked_Finish_Date__c >= rtvAdjustment.startDate)
                                ) {
                                    if(hasDrivingRoleAsPrimaryOrSecondaryRole(job.sked_Resource_Role__c, job.sked_Dual_Role__c) 
                                        && !rtvAdjustment.resourceRoleGroup.split(';').contains(skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES)) continue;
                                        
                                    List<String> affectedFields = getAffectedFields(rtvAdjustment.varianceApplyTo);
                                    Integer numAffectedStartFields = getNumAffectedFields(rtvAdjustment.varianceApplyTo, false);
                                    Integer numAffectedFinishFields = getNumAffectedFields(rtvAdjustment.varianceApplyTo, true);
                                    
                                    for (String affectedField : affectedFields) {
                                        Object jobFieldValue = job.get(affectedField);
                                        Integer originalFieldValue = 0;
                                        if (jobFieldValue != NULL) {
                                            originalFieldValue = ((Decimal)jobFieldValue).intValue();
                                        }
            
                                        job.put(affectedField, adjustAmountByCollectionOpThreshold(affectedField, originalFieldValue + rtvAdjustment.adjustAmount, driveShift));
                                    }
            
                                    if (numAffectedStartFields > 0) {
                                        Integer totalStartTimeAdjustAmount = rtvAdjustment.adjustAmount * numAffectedStartFields;
                                        job.sked__Start__c = job.sked__Start__c.addMinutes(totalStartTimeAdjustAmount * -1);
                                    }
            
                                    if (numAffectedFinishFields > 0) { 
                                        Integer totalFinishTimeAdjustAmount = rtvAdjustment.adjustAmount * numAffectedFinishFields;
                                        job.sked__Finish__c = job.sked__Finish__c.addMinutes(totalFinishTimeAdjustAmount);
                                    }
            
                                    map_id_jobToUpdate.put(job.Id, job);
                                    needRecalculateDriveShiftStartEndTime = true;
                                }
                            }
                        }
                    }
        
                    if (needRecalculateDriveShiftStartEndTime) {
                        DateTime minStartTime = NULL;
                        DateTime maxFinishTime = NULL;
                        for (sked__Job__c job : jobs) {
                            if (job.sked_Resource_Role__c != null && job.sked_Asset_Type__c == null) {
                                if (minStartTime == NULL || job.sked__Start__c < minStartTime) {
                                    minStartTime = job.sked__Start__c;
                                }
            
                                if (maxFinishTime == NULL || job.sked__Finish__c > maxFinishTime) {
                                    maxFinishTime = job.sked__Finish__c;
                                }
                            }
                        }
        
                        driveShift.sked_Start__c = minStartTime;
                        driveShift.sked_Finish__c = maxFinishTime;
                        driveShiftsToUpdate.add(driveShift);
                    }
                }     
            } 
        }   
        
        update map_id_jobToUpdate.values();
        update driveShiftsToUpdate;

        if (!assetOrVolunteerJobIds.isEmpty()) {
            List<sked__Job__c> assetOrVolunteerJobsToUpdate = new List<sked__Job__c>();
            for (sked__Job__c job : [
                SELECT Id, sked_Asset_Type__c,
                sked_Drive__r.sked_Min_Shift_Start__c, sked_Drive__r.sked_Max_Shift_End__c,
                sked_Drive_Shift__r.sked_Start__c, sked_Drive_Shift__r.sked_Finish__c
                FROM sked__Job__c
                WHERE Id IN :assetOrVolunteerJobIds
            ]) {
                if(job.sked_Asset_Type__c != null) {
                    job.sked__Start__c = job.sked_Drive__r.sked_Min_Shift_Start__c;
                    job.sked__Finish__c = job.sked_Drive__r.sked_Max_Shift_End__c;
                } else {
                    job.sked__Start__c = job.sked_Drive_Shift__r.sked_Start__c;
                    job.sked__Finish__c = job.sked_Drive_Shift__r.sked_Finish__c;
                }
                assetOrVolunteerJobsToUpdate.add(job);
            }

            update assetOrVolunteerJobsToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {}

    private Boolean hasDrivingRoleAsPrimaryOrSecondaryRole(String primaryRole, String secondaryRole) {
        return this.resourceRoleByGroup.get(skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES).contains(primaryRole) 
          || this.resourceRoleByGroup.get(skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES).contains(secondaryRole);
    }

    private Map<Id, List<skedRoleTimeVarianceAdjustment>> getMapSiteIdToRtvAdjustments(List<skedRoleTimeVarianceAdjustment> rtvAdjustments) {
        Map<Id, List<skedRoleTimeVarianceAdjustment>> map_siteId_rtvAdjustments = new Map<Id, List<skedRoleTimeVarianceAdjustment>>();

        for (skedRoleTimeVarianceAdjustment rtvAdjustment : rtvAdjustments) {
            if (!map_siteId_rtvAdjustments.containsKey(rtvAdjustment.siteId)) {
                map_siteId_rtvAdjustments.put(rtvAdjustment.siteId, new List<skedRoleTimeVarianceAdjustment>());
            }

            map_siteId_rtvAdjustments.get(rtvAdjustment.siteId).add(rtvAdjustment);
        }

        return map_siteId_rtvAdjustments;
    }

    private skedModels.startEnd getMinMaxRTVEffectiveDate(List<skedRoleTimeVarianceAdjustment> rtvAdjustments) {
        skedModels.startEnd startEnd = new skedModels.startEnd();

        for (skedRoleTimeVarianceAdjustment rtvAdjustment : rtvAdjustments) {
            if (startEnd.startDate == null || rtvAdjustment.startDate < startEnd.startDate) {
                startEnd.startDate = rtvAdjustment.startDate;
            }

            if (startEnd.endDate == null || rtvAdjustment.endDate > startEnd.endDate) {
                startEnd.endDate = rtvAdjustment.endDate;
            }
        }

        return startEnd;
    }

    private Set<String> getAffectedResourceRolesByResourceRoleGroup(String resourceRoleGroup) {
        Set<String> affectedResourceRoles = new Set<String>();
        List<String> affectedResourceRoleGroups = resourceRoleGroup.split(';');
        for (String affectedResourceRoleGroup : affectedResourceRoleGroups) {
            affectedResourceRoles.addAll(this.resourceRoleByGroup.get(affectedResourceRoleGroup));
        }

        return affectedResourceRoles;
    }

    private List<String> getAffectedFields(String appliesTo) {
        List<String> appliesToLabels = appliesTo.split(';');
        List<String> appliesToFields = new List<String>();

        for (String appliesToLabel : appliesToLabels) {
            appliesToFields.add(JOB_FIELD_NAME_BY_VARIANCE_LABEL.get(appliesToLabel));
        }

        return appliesToFields;
    }

    private Integer getNumAffectedFields(String appliesTo, Boolean isFinishFields) {
        List<String> appliesToLabels = appliesTo.split(';');
        Integer numAffectedFields = 0;

        for (String appliesToLabel : appliesToLabels) {
            if (!isFinishFields && ROLE_TIME_VARIANCE_START_TIME_FIELDS.contains(appliesToLabel) ||
                    isFinishFields && ROLE_TIME_VARIANCE_FINISH_TIME_FIELDS.contains(appliesToLabel)) {
                numAffectedFields++;
            }
        }

        return numAffectedFields;
    }

    private boolean checkAdjustmentDaysOfWeekAffectsDriveShift(skedRoleTimeVarianceAdjustment rtvAdjustment, sked_Drive_Shift__c driveShift) {
        DateTime driveDate = DateTime.newInstance(driveShift.sked_Drive__r.sked_Drive_Date__c, driveShift.sked_Drive__r.sked_Start_Time__c);
        driveDate = skedDateTimeUtils.toTimezone(driveDate, driveShift.sked_Drive__r.sked_Timezone__c);
        string driveWeekday = driveDate.format('EEEE');
        return rtvAdjustment.daysOfWeek != null && rtvAdjustment.daysOfWeek.contains(driveWeekday);
    }

    private Map<Id, List<sked__Job__c>> getShiftIdJobsMap(List<sked__Job__c> jobs) {
        Map<Id, List<sked__Job__c>> shiftIdJobsMap = new Map<Id, List<sked__Job__c>>();
        for (sked__Job__c job : jobs) {
            if (!shiftIdJobsMap.containsKey(job.sked_Drive_Shift__c)) {
                shiftIdJobsMap.put(job.sked_Drive_Shift__c, new List<sked__Job__c>());
            }

            shiftIdJobsMap.get(job.sked_Drive_Shift__c).add(job);
        }

        return shiftIdJobsMap;
    }

    private Integer adjustAmountByCollectionOpThreshold(String affectedField, Integer amount, sked_Drive_Shift__c driveShift) {
        Integer breakdownTimeThreshold = driveShift.sked_Drive__r.sked_Collection_Operation__r.sked_Breakdown_Time_Threshold__c != NULL ?
                Integer.valueOf(driveShift.sked_Drive__r.sked_Collection_Operation__r.sked_Breakdown_Time_Threshold__c) : 0;
        Integer setupTimeThreshold = driveShift.sked_Drive__r.sked_Collection_Operation__r.sked_Setup_Time_Threshold__c != NULL ?
                 Integer.valueOf(driveShift.sked_Drive__r.sked_Collection_Operation__r.sked_Setup_Time_Threshold__c) : 0;
        switch on affectedField {
            when 'sked_Setup_Time__c' {
                if (driveShift.sked_Order__c > 1) {
                    return amount > setupTimeThreshold ?
                        setupTimeThreshold : amount;
                }
            }
            when 'sked_Breakdown_Time__c' {
                if (driveShift.sked_Order__c < driveShift.sked_Drive__r.sked_Drive_Shift_Count__c) {
                    return amount > breakdownTimeThreshold ?
                        breakdownTimeThreshold : amount;
                }
            }
        }

        return amount;
    }
}