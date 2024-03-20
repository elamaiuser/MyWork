global class skedSyncResourceHoursOneTime_Batch implements Database.Batchable<sObject>, Database.Stateful {
    protected List<String> modes = new List<String>{'JobAllocation', 'Availability', 'Activity', 'ActivityResource'};
    protected String mode = '';
    protected Integer modeIndex;
    protected String lastId = '';

    global skedSyncResourceHoursOneTime_Batch() {
        this.modeIndex = 0;
        this.mode = modes.get(0);
        this.lastId = '';
    }

    global skedSyncResourceHoursOneTime_Batch(Integer modeIndex) {
        this.modeIndex = modeIndex;
        this.mode = modes.get(modeIndex);
        this.lastId = '';
    }

    global skedSyncResourceHoursOneTime_Batch(Integer modeIndex, String lastId) {
        this.modeIndex = modeIndex;
        this.mode = modes.get(modeIndex);
        this.lastId = lastId;
    }

    global List<sObject> start(Database.BatchableContext BC) {
        if (this.mode == 'JobAllocation') {
            return  getJobAllocations(false);
        } else if (this.mode == 'Availability') {
            return getAvailabilities(false);
        } else if (this.mode == 'Activity') { 
            return getActivities(false);
        } else {
            return getActivityResources(false);
        }
    }

    global void execute(Database.BatchableContext BC, List<sObject> records) {
        if (mode == 'JobAllocation') {
            List<sked__Job_Allocation__c> jobAllocations = (List<sked__Job_Allocation__c>)records;
            skedResourceHoursRecordUtils.syncToResourceHoursRecord(jobAllocations);
        }
        else if (mode == 'Availability') {
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
        else if (mode == 'Activity') {
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
        else if (mode == 'ActivityResource') {
            List<sked__Activity_Resource__c> activityResources = (List<sked__Activity_Resource__c>)records;
            skedResourceHoursRecordUtils.syncToResourceHoursRecord(activityResources);
        }

        this.lastId = records.get(records.size()-1).Id;
        System.debug('THIS LAST ID ::: ' + this.lastId);
    }
    
    global void finish(Database.BatchableContext BC) {
        List<SObject> remainingRecords;
        if (this.mode == 'JobAllocation') {
            System.debug('FINISH LAST ID :: ' + this.lastId);
            remainingRecords = getJobAllocations(true);
        } else if (this.mode == 'Availability') {
            remainingRecords = getAvailabilities(true);
        } else if (this.mode == 'Activity') { 
            remainingRecords = getActivities(true);
        } else {
            remainingRecords = getActivityResources(true);
        }

        if (!remainingRecords.isEmpty()) {
            Database.executeBatch(new skedSyncResourceHoursOneTime_Batch(this.modeIndex, this.lastId));
        } else if (this.modeIndex < (this.modes.size()-1)) {
            this.modeIndex++;
            Database.executeBatch(new skedSyncResourceHoursOneTime_Batch(this.modeIndex));
        }
    }

    // Utils
    private List<SObject> getJobAllocations(Boolean isLimitQuery) {
        String query = 'SELECT Id, sked_Duration_with_Travel_Time__c, sked__Start__c, sked_Job_Timezone__c, sked__Status__c, ' +
        ' sked__Resource__c, sked__Job__c' + 
        ' FROM sked__Job_Allocation__c' + 
        ' WHERE sked__Status__c != \'' + skedConstants.JOB_ALLOCATION_STATUS_DECLINED + '\'' +
        ' AND sked__Status__c != \'' + skedConstants.JOB_ALLOCATION_STATUS_DELETED + '\'';
                
        System.debug('GET JA :: LAST ID :: ' + this.lastId);
        query += this.lastId != '' ? ' AND Id > \'' + this.lastId + '\'' : '';
        query += ' ORDER BY Id ASC ';
        query += isLimitQuery ? 'LIMIT 1' : 'LIMIT 50000';

        System.debug('QUERY :: ' + query);
        return Database.query(query);
    }

    private List<SObject> getAvailabilities(Boolean isLimitQuery) {
        String query = 'SELECT Id, sked_Duration__c, sked__Start__c, sked__Timezone__c, sked_Custom_Status__c,' +
        ' sked__Resource__c, sked__Is_Available__c, sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c ' +        
        ' FROM sked__Availability__c' +
        ' WHERE sked__Is_Available__c = FALSE' + 
        ' AND sked_Custom_Status__c =  \'' + skedConstants.AVAILABILITY_STATUS_APPROVED + '\'';
                
        query += this.lastId != '' ? ' AND Id > \'' + this.lastId + '\'' : '';
        query += ' ORDER BY Id ASC ';
        query += isLimitQuery ? 'LIMIT 1' : 'LIMIT 50000';
        return Database.query(query);
    }

    private List<SObject> getActivities(Boolean isLimitQuery) {
        String query = 'SELECT Id, sked_Duration__c, sked__Start__c, sked__Timezone__c,sked_Is_Group_Activity__c,' +
        ' sked__Resource__c, sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c' +
        ' FROM sked__Activity__c' +
        ' WHERE sked_Is_Group_Activity__c = FALSE' + 
        ' AND sked__Resource__c != NULL';
        
        query += this.lastId != '' ? ' AND Id > \'' + this.lastId + '\'' : '';
        query += ' ORDER BY Id ASC ';
        query += isLimitQuery ? 'LIMIT 1' : 'LIMIT 50000';
        return Database.query(query);
    }

    private List<SObject> getActivityResources(Boolean isLimitQuery) {
        String query = 'SELECT Id, sked_Duration__c, sked_Start1__c, sked_Timezone__c, sked__Resource__c' +
        ' FROM sked__Activity_Resource__c';

        query += this.lastId != '' ? ' WHERE Id > \'' + this.lastId + '\'' : '';
        query += ' ORDER BY Id ASC ';
        query += isLimitQuery ? 'LIMIT 1' : 'LIMIT 50000';
        return Database.query(query);
    }
}