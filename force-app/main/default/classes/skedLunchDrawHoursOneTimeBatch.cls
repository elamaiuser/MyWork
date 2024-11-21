public class skedLunchDrawHoursOneTimeBatch implements Database.Batchable<sked__Job__c>, Database.Stateful {
    protected String lastId;
    Set<Id> affectedDriveIds;

    public skedLunchDrawHoursOneTimeBatch() {
        this.lastId = '';
        this.affectedDriveIds = new Set<Id>();
    }
    
    public skedLunchDrawHoursOneTimeBatch(string lastId) { 
        this.lastId = lastId;
        this.affectedDriveIds = new Set<Id>();
    }

    public List<sked__Job__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked__Start__c, sked__Finish__c, sked_Start_Date__c, sked_Finish_Date__c,
            sked_Start_Time__c, sked_Finish_Time__c, sked_Drive__r.sked_Drive_Date__c,
            sked_Drive_Shift__r.sked_Lunch_Break_Duration__c, sked_Drive_Shift__r.sked_Start__c,
            sked_Drive_Shift__r.sked_Start_Time__c, sked_Drive_Shift__r.sked_Finish__c,
            sked_Drive_Shift__r.sked_End_Time__c, sked_Lead_Time__c, sked_Setup_Time__c, 
            sked_Travel_Time__c, sked__Timezone__c,sked_Breakdown_Time__c, sked_Wrap_Up_Time__c, 
            sked_Travel_Time2__c
            FROM sked__Job__c
            WHERE sked_MigrationId__c != NULL 
            AND sked_Drive_Shift__r.sked_Lunch_Break__c = TRUE 
            AND sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c = TRUE
            AND sked_Resource_Role__c != NULL
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 50000
        ];
    }

    public void execute(Database.BatchableContext BC, List<sked__Job__c> jobs) {
        Map<Id, sked__Job__c> mapJob = new Map<Id, sked__Job__c>();
        Map<Id, sked_Drive_Shift__c> mapDriveShift = new Map<Id, sked_Drive_Shift__c>();
        for (sked__Job__c job : jobs) {
            Integer leadTime = job.sked_Lead_Time__c != NULL ? Integer.valueOf(job.sked_Lead_Time__c) : 0;
            Integer setupTime = job.sked_Setup_Time__c != NULL ? Integer.valueOf(job.sked_Setup_Time__c) : 0;
            Integer travelTime = job.sked_Travel_Time__c != NULL ? Integer.valueOf(job.sked_Travel_Time__c) : 0;
            Integer lunchBreakDuration = Integer.valueOf(job.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c);
            Integer totalMinutesBeforeDrawHours = leadTime + setupTime + travelTime + lunchBreakDuration;

            Integer breakdownTime = job.sked_Breakdown_Time__c != NULL ? Integer.valueOf(job.sked_Breakdown_Time__c) : 0;
            Integer wrapUpTime = job.sked_Wrap_Up_Time__c != NULL ? Integer.valueOf(job.sked_Wrap_Up_Time__c) : 0;
            Integer travelTime2 = job.sked_Travel_Time2__c != NULL ? Integer.valueOf(job.sked_Travel_Time2__c) : 0;
            Integer totalMinutesAfterDrawHours = breakdownTime + wrapUpTime + travelTime2;

            DateTime driveShiftDrawHoursStart = skedDateTimeUtils.getDateTimeFromDateAndTime(job.sked_Drive__r.sked_Drive_Date__c, job.sked_Drive_Shift__r.sked_Start_Time__c, job.sked__Timezone__c);
            DateTime driveShiftDrawHoursEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(job.sked_Drive__r.sked_Drive_Date__c, job.sked_Drive_Shift__r.sked_End_Time__c, job.sked__Timezone__c);

            job.sked__Start__c = driveShiftDrawHoursStart.addMinutes(-totalMinutesBeforeDrawHours);
            job.sked__Finish__c = driveShiftDrawHoursEnd.addMinutes(totalMinutesAfterDrawHours);
            job.sked__Duration__c = skedDateTimeUtils.getDifferentMinutes(job.sked__Start__c, job.sked__Finish__c);
            mapJob.put(job.Id, job);

            sked_Drive_Shift__c driveShift = mapDriveShift.containsKey(job.sked_Drive_Shift__c) ? 
                mapDriveShift.get(job.sked_Drive_Shift__c) : job.sked_Drive_Shift__r;
            
            if (job.sked__Start__c < driveShift.sked_Start__c) {
                driveShift.sked_Start__c = job.sked__Start__c;
                mapDriveShift.put(driveShift.Id, driveShift);
                affectedDriveIds.add(job.sked_Drive__c);
            }     
        }

        skedSetting.instance.Admin.migrationMode = TRUE;
        if (!mapJob.isEmpty()) {
            update mapJob.values();
        }
        if (!mapDriveShift.isEmpty()) {
            update mapDriveShift.values();
        }
        skedSetting.instance.Admin.migrationMode = FALSE;
        
        this.lastId = jobs.get(jobs.size() - 1).Id;
    }

    public void finish(Database.BatchableContext BC) {
        List<sked__Job__c> remainRecordQuery = [
            SELECT Id
            FROM sked__Job__c
            WHERE sked_MigrationId__c != NULL 
            AND sked_Drive_Shift__r.sked_Lunch_Break__c = TRUE 
            AND sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c = TRUE
            AND sked_Resource_Role__c != NULL
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedLunchDrawHoursOneTimeBatch(this.lastId), 200);
        }
        if (this.affectedDriveIds != null && !this.affectedDriveIds.isEmpty()) {
            Database.executeBatch(new skedDriveProductivityOneTimeBatch(this.affectedDriveIds));
        }
    }
}