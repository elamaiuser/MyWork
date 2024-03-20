global class skedResourceHoursRecordBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    private Set<Id> recordIds;
    private boolean isJobAllocation;
    private boolean isActivity;
    private boolean isActivityResource;
    private boolean isAvailability;
    
    global skedResourceHoursRecordBatch(Set<Id> recordIds) {
        Id rootRecordId = new List<Id>(recordIds).get(0);
        string rootRecordObjApiName = rootRecordId.getSobjectType().getDescribe().getName();
        system.debug('rootRecordObjApiName');
        if (rootRecordObjApiName == 'sked__Job_Allocation__c') {
            this.isJobAllocation = TRUE;
        }
        else if (rootRecordObjApiName == 'sked__Activity__c') {
            this.isActivity = TRUE;
        }
        else if (rootRecordObjApiName == 'sked__Availability__c') {
            this.isAvailability = TRUE;
        }
        else if (rootRecordObjApiName == 'sked__Activity_Resource__c') {
            this.isActivityResource = TRUE;
        }
        
        this.recordIds = recordIds;
    }
    
    global List<sObject> start(Database.BatchableContext BC) {
        if (isJobAllocation == TRUE) {
            List<sked__Job_Allocation__c> skedJobAllocations = [SELECT Id, sked_Duration_with_Travel_Time__c, sked__Start__c, sked_Job_Timezone__c, sked__Status__c,
                                                                sked__Resource__c, sked__Job__c
                                                                FROM sked__Job_Allocation__c
                                                                WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
                                                                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                AND Id IN :recordIds];
            return skedJobAllocations;
        }
        else if (isAvailability == TRUE) {
            List<sked__Availability__c> skedAvailabilities = [SELECT Id, sked_Duration__c, sked__Start__c, sked__Timezone__c, sked_Custom_Status__c,
                                                              sked__Resource__c, sked__Is_Available__c, 
                                                              sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c
                                                              FROM sked__Availability__c
                                                              WHERE sked__Is_Available__c = FALSE
                                                              AND sked_Custom_Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                                              AND Id IN :recordIds];
            return skedAvailabilities;
        }
        else if (isActivity == TRUE) {
            List<sked__Activity__c> skedActivities = [SELECT Id, sked_Duration__c, sked__Start__c, sked__Timezone__c,sked_Is_Group_Activity__c,
                                                      sked__Resource__c, sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c
                                                      FROM sked__Activity__c
                                                      WHERE sked_Is_Group_Activity__c = FALSE
                                                      AND sked__Resource__c != NULL
                                                      AND Id IN :recordIds];
            return skedActivities;
        }
        else if (isActivityResource == TRUE) {
            List<sked__Activity_Resource__c> skedActivityResources = [SELECT Id, sked_Duration__c, sked_Start1__c, sked_Timezone__c, sked__Resource__c
                                                                      FROM sked__Activity_Resource__c
                                                                      WHERE Id IN :recordIds];
            return skedActivityResources;
        }
        return null;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> records) {
        if (isJobAllocation == TRUE) {
            List<sked__Job_Allocation__c> jobAllocations = (List<sked__Job_Allocation__c>)records;
            skedResourceHoursRecordUtils.syncToResourceHoursRecord(jobAllocations);
        }
        else if (isAvailability == TRUE) {
            List<sked__Availability__c> availabilities = (List<sked__Availability__c>)records;
            for (sked__Availability__c availability : availabilities) {
                if (string.isBlank(availability.sked__Timezone__c)) {
                    availability.sked__Timezone__c = availability.sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c;
                }
            }
            if (!availabilities.isEmpty()) {
                skedResourceHoursRecordUtils.syncToResourceHoursRecord(availabilities);
            }
        }
        else if (isActivity == TRUE) {
            List<sked__Activity__c> activities = (List<sked__Activity__c>)records;
            for (sked__Activity__c activity : activities) {
                if (string.isBlank(activity.sked__Timezone__c)) {
                    activity.sked__Timezone__c = activity.sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c;
                }
            }
            if (!activities.isEmpty()) {
                skedResourceHoursRecordUtils.syncToResourceHoursRecord(activities);
            }
        }
        else if (isActivityResource == TRUE) {
            List<sked__Activity_Resource__c> activityResources = (List<sked__Activity_Resource__c>)records;
            skedResourceHoursRecordUtils.syncToResourceHoursRecord(activityResources);
        }
    }
    
    global void finish(Database.BatchableContext BC) {}
}