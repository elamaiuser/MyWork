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
    private List<sked_Role_Time_Variance__c> rtvs;

    private List<sked_Drive_Shift__c> driveShiftsToUpdate;
    private List<sked__Job__c> jobsToUpdate;

    global skedUpdateJobTimeVarianceBatch(List<sked_Role_Time_Variance__c> updated) {
        this.rtvs = updated;
        this.resourceRoleByGroup = skedResourceUtils.getResourceRolesByGroup();

        this.driveShiftsToUpdate = new List<sked_Drive_Shift__c>();
        this.jobsToUpdate = new List<sked__Job__c>();
    }

    global List<sked_Role_Time_Variance__c> start(Database.BatchableContext BC) {
        return this.rtvs;
    }

    global void execute(Database.BatchableContext BC, List<sked_Role_Time_Variance__c> records) {
        // Run with context of 1 so this is only ever 1 record at a time
        for (sked_Role_Time_Variance__c rtv : records) {
            Set<String> affectedResourceRoles = new Set<String>();

            if (rtv.sked_Resource_Role_Group__c != null && rtv.sked_Resource_Role_Group__c != '') {
                List<String> affectedResourceRoleGroups = rtv.sked_Resource_Role_Group__c.split(';');
                for (String affectedResourceRoleGroup : affectedResourceRoleGroups) {
                    affectedResourceRoles.addAll(this.resourceRoleByGroup.get(affectedResourceRoleGroup));
                }
            }

            List<sked__Job__c> jobs = [
                SELECT Id, Name, sked_Setup_Time__c, sked_Lead_Time__c, sked_Travel_Time__c, sked_Site_Logistics_To__c,
                sked_Wrap_Up_Time__c, sked_Breakdown_Time__c, sked_Travel_Time2__c, sked_Site_Logistics_Back__c,
                sked__Start__c, sked_Start_Time__c, sked__Finish__c, sked_Finish_Time__c,
                sked_Drive_Shift__c, sked_Drive_Shift__r.sked_Start__c, sked_Drive_Shift__r.sked_Finish__c
                FROM sked__Job__c
                WHERE sked_Start_Date__c >= :rtv.sked_Effective_Start_Date__c
                AND sked_Finish_Date__c <= :rtv.sked_Effective_End_Date__c
                AND sked__Location__c = :rtv.sked_Location__c
                AND sked_Resource_Role__c IN :affectedResourceRoles
            ];

            Map<Id, DateTime> minStartDateByDriveShift = new Map<Id, DateTime>();
            Map<Id, DateTime> maxFinishDateByDriveShift = new Map<Id, DateTime>();

            for (sked__Job__c job : jobs) {
                List<String> affectedFields = getAffectedFields(rtv.sked_Variance_Applies_to__c);
                Integer numAffectedStartFields = getNumAffectedFields(rtv.sked_Variance_Applies_to__c, false);
                Integer numAffectedFinishFields = getNumAffectedFields(rtv.sked_Variance_Applies_to__c, true);
                Integer variationAmount = Integer.valueOf(rtv.sked_Variation_Amount__c);
                
                for (String affectedField : affectedFields) {
                    Object jobFieldValue = job.get(affectedField);
                    Integer originalFieldValue = 0;
                    if (jobFieldValue != NULL) {
                        originalFieldValue = ((Decimal)jobFieldValue).intValue();
                    }

                    if (rtv.sked_Buffer_Type__c == skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD) {
                        job.put(affectedField, originalFieldValue + variationAmount);
                    } else {
                        job.put(affectedField, originalFieldValue - variationAmount);
                    }
                }

                if (numAffectedStartFields > 0) {
                    Integer totalStartTimeVariation = variationAmount * numAffectedStartFields;
                    if (rtv.sked_Buffer_Type__c == skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD) {
                        // We're Adding to the time it takes to start the job, so they should start earlier.
                        job.sked__Start__c = job.sked__Start__c.addMinutes(totalStartTimeVariation * -1);
                    } else {
                        job.sked__Start__c = job.sked__Start__c.addMinutes(totalStartTimeVariation);
                    }
                }

                if (numAffectedFinishFields > 0) { 
                    Integer totalFinishTimeVariation = variationAmount * numAffectedFinishFields;
                    if (rtv.sked_Buffer_Type__c == skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD) {
                        // We're Adding to the time it takes to finish up, so they should end later.
                        job.sked__Finish__c = job.sked__Finish__c.addMinutes(totalFinishTimeVariation);
                    } else {
                        job.sked__Finish__c = job.sked__Finish__c.addMinutes(totalFinishTimeVariation * -1);
                    }
                }

                DateTime minStartDateForDriveShift = minStartDateByDriveShift.get(job.sked_Drive_Shift__c);
                if (null == minStartDateForDriveShift || job.sked__Start__c < minStartDateForDriveShift) {
                    minStartDateByDriveShift.put(job.sked_Drive_Shift__c, job.sked__Start__c);
                }

                DateTime maxFinishDateForDriveShift = maxFinishDateByDriveShift.get(job.sked_Drive_Shift__c);
                if (null == maxFinishDateForDriveShift || job.sked__Finish__c > maxFinishDateForDriveShift) {
                    maxFinishDateByDriveShift.put(job.sked_Drive_Shift__c, job.sked__Finish__c);
                }

                this.jobsToUpdate.add(job);
            }

            for (Id driveShiftId : minStartDateByDriveShift.keySet()) {
                this.driveShiftsToUpdate.add(new sked_Drive_Shift__c(
                    Id = driveShiftId,
                    sked_Start__c = minStartDateByDriveShift.get(driveShiftId),
                    sked_Finish__c = maxFinishDateByDriveShift.get(driveShiftId)
                ));
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        Integer numJobsUpdated = 0;
        List<Database.SaveResult> jobsSaveResults = Database.update(jobsToUpdate, false);
        for (Database.SaveResult jsr : jobsSaveResults) {
            if (jsr.isSuccess()) {
                numJobsUpdated++;
            }

        }

        Integer numDriveShiftsUpdated = 0;
        List<Database.SaveResult> driveShiftsSaveResults = Database.update(driveShiftsToUpdate, false);
        for (Database.SaveResult dssr : driveShiftsSaveResults) {
            if (dssr.isSuccess()) {
                numDriveShiftsUpdated++;
            }
        }

        System.debug('Finished a Job Time Variance batch process that updated: ' + numJobsUpdated + ' Jobs, and: ' + numDriveShiftsUpdated + ' Drive Shifts');
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
}