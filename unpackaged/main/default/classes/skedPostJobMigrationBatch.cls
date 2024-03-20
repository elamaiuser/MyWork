global class skedPostJobMigrationBatch implements Database.Batchable<sked__Job__c>, Database.AllowsCallouts, Database.Stateful {

    global skedPostJobMigrationBatch() { }
    
    global List<sked__Job__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_MigrationID__c, sked__Location__c,
                sked_Travel_Time__c, sked_Travel_Time2__c, sked__Start__c, sked__Finish__c, sked__Timezone__c,
                sked_Asset_Type__c, sked_Resource_Role__c,
                sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Type_of_Drive__c,
                sked_Drive__r.sked_Start_Time__c, sked_Drive__r.sked_End_Time__c,
                sked_Drive__r.sked_Collection_Operation__c, 
                sked_Drive__r.sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c,
                sked_Drive__r.sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c
                FROM sked__Job__c
                WHERE sked__Location__c != NULL
                AND sked_Drive__c != NULL
                AND sked_Drive__r.sked_Collection_Operation__c != NULL
                AND sked_MigrationID__c != NULL
                AND sked_Post_Migration_Processed__c = FALSE
                AND sked_Resource_Role__c != NULL
                ORDER BY sked__Location__c ASC
                LIMIT 40000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job__c> records) {
        Map<Id, sked__Job__c> mapRecord = new Map<Id, sked__Job__c>(records);
        
        try {
            populateTravelTime(records);
            skedJobTagHandler.updateJobRoleCertifications(mapRecord.keySet());
        }
        catch (exception ex) {
            sked__Debug_Log__c debugLog = new sked__Debug_Log__c(
                sked__Message__c = ex.getStackTraceString(),
                sked__Summary__c = ex.getMessage(),
                sked__Type__c = 'Debug Log'
            );
            insert debugLog;
        }
        
        List<sked__Job__c> jobsToUpdate = new List<sked__Job__c>();
        for (sked__Job__c record : records) {
            sked__Job__c skedJob = new sked__Job__c(
                Id = record.Id,
                sked_Post_Migration_Processed__c = TRUE
            );
            jobsToUpdate.add(skedJob);
        }
        if (!jobsToUpdate.isEmpty()) {
            update jobsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked__Job__c> remainRecordQuery = [SELECT Id
                                                FROM sked__Job__c
                                                WHERE sked__Location__c != NULL
                                                AND sked_Drive__c != NULL
                                                AND sked_Drive__r.sked_Collection_Operation__c != NULL
                                                AND sked_MigrationID__c != NULL
                                                AND sked_Post_Migration_Processed__c = FALSE
                                                AND sked_Resource_Role__c != NULL
                                                ORDER BY sked__Location__c ASC
                                                LIMIT 1];
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedPostJobMigrationBatch(), 200);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void populateTravelTime(List<sked__Job__c> skedJobs) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Id> siteIds = new Set<Id>();
        Date minDate, maxDate;
        for (sked__Job__c skedJob : skedJobs) {
            siteIds.add(skedJob.sked__Location__c);
            if (skedJob.sked_Drive__r.sked_Collection_Operation__c != NULL) {
                collectionOperationIds.add(skedJob.sked_Drive__r.sked_Collection_Operation__c);
            }
            if (skedJob.sked_Drive__r.sked_Drive_Date__c != NULL) {
                if (minDate == NULL || minDate > skedJob.sked_Drive__r.sked_Drive_Date__c) {
                    minDate = skedJob.sked_Drive__r.sked_Drive_Date__c;
                }
                if (maxDate == NULL || maxDate < skedJob.sked_Drive__r.sked_Drive_Date__c) {
                    maxDate = skedJob.sked_Drive__r.sked_Drive_Date__c;
                }
            }
        }
        
        List<sked__Location__c> skedSites = [SELECT Id,
                                             (SELECT Id, sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c,
                                              sked_Start_Date__c, sked_End_Date__c
                                              FROM sked_Site_Collection_Operations__r)
                                             FROM sked__Location__c
                                             WHERE Id IN :siteIds];
        Map<Id, siteModel> mapSite = new Map<Id, siteModel>();
        for (sked__Location__c skedSite : skedSites) {
            siteModel site = new siteModel();
            site.id = skedSite.Id;
            site.siteCos = new List<siteCoModel>();
            for (sked_Site_Collection_Operation__c skedSiteCO : skedSite.sked_Site_Collection_Operations__r) {
                if (skedSiteCO.sked_Travel_Time_Breakdown_JSON__c != NULL && skedSiteCO.sked_Travel_Time_Breakdown_JSON_2__c != NULL) {
                    siteCoModel siteCO = new siteCoModel();
                    siteCO.id = skedSiteCO.Id;
                    siteCO.startDate = skedSiteCO.sked_Start_Date__c;
                    siteCO.endDate = skedSiteCO.sked_End_Date__c;
                    siteCO.coToSiteList = (List<travelTimeBreakdownModel>)JSON.deserialize(skedSiteCO.sked_Travel_Time_Breakdown_JSON__c, List<travelTimeBreakdownModel>.class);
                    siteCO.siteToCoList = (List<travelTimeBreakdownModel>)JSON.deserialize(skedSiteCO.sked_Travel_Time_Breakdown_JSON_2__c, List<travelTimeBreakdownModel>.class);
                    site.siteCos.add(siteCO);
                }
            }
            mapSite.put(skedSite.Id, site);
        }
        
        List<string> drivingRoles = new List<string>();
        drivingRoles.add('Competent Driver');
        drivingRoles.add('Driver');
        drivingRoles.add('Driver CDL B');
        drivingRoles.add('Driver - DOT');
        drivingRoles.add('Driver Support');
        drivingRoles.add('Driver Tech Trainee');
        drivingRoles.add('Staff Shuttle');
        
        Map<Id, sked__Job__c> mapRecordToUpdate = new Map<Id, sked__Job__c>();
        for (sked__Job__c skedJob : skedJobs) {
            string travelTimeIncluded = skedJob.sked_Drive__r.sked_Type_of_Drive__c == 'Mobile' 
                ? skedJob.sked_Drive__r.sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c
                : skedJob.sked_Drive__r.sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c;
            
            boolean isTravelTimeRoleExcluded = travelTimeIncluded == 'Drivers Only'
                && !drivingRoles.contains(skedJob.sked_Resource_Role__c);
                
            if (isTravelTimeRoleExcluded) {
                if (skedJob.sked_Travel_Time__c != 0) {
                    decimal currentTravelTime = skedJob.sked_Travel_Time__c != NULL ? skedJob.sked_Travel_Time__c : 0;
                    integer differentMinutes = integer.valueOf(currentTravelTime - 0);
                    skedJob.sked_Travel_Time__c = 0;
                    skedJob.sked__Start__c = skedJob.sked__Start__c.addMinutes(differentMinutes);
                    mapRecordToUpdate.put(skedJob.Id, skedJob);
                }
                if (skedJob.sked_Travel_Time2__c != 0) {
                    decimal currentTravelTime = skedJob.sked_Travel_Time2__c != NULL ? skedJob.sked_Travel_Time2__c : 0;
                    integer differentMinutes = integer.valueOf(0 - currentTravelTime);
                    skedJob.sked_Travel_Time2__c = 0;
                    skedJob.sked__Finish__c = skedJob.sked__Finish__c.addMinutes(differentMinutes);
                    mapRecordToUpdate.put(skedJob.Id, skedJob);
                }
            }
            else {
                if (mapSite.containsKey(skedJob.sked__Location__c)) {
                    siteModel site = mapSite.get(skedJob.sked__Location__c);
                    if (site.siteCos != NULL) {
                        siteCoModel siteCO;
                        for (siteCoModel item : site.siteCos) {
                            if (item.startDate <= skedJob.sked_Drive__r.sked_Drive_Date__c && skedJob.sked_Drive__r.sked_Drive_Date__c <= item.endDate) {
                                siteCO = item;
                                break;
                            }
                        }
                        if (siteCO != NULL) {
                            DateTime drawHourStart = DateTime.newInstance(skedJob.sked_Drive__r.sked_Drive_Date__c, skedJob.sked_Drive__r.sked_Start_Time__c);
                            drawHourStart = skedDateTimeUtils.toTimezone(drawHourStart, skedJob.sked__Timezone__c);
                            DateTime drawHourEnd = DateTime.newInstance(skedJob.sked_Drive__r.sked_Drive_Date__c, skedJob.sked_Drive__r.sked_End_Time__c);
                            drawHourEnd = skedDateTimeUtils.toTimezone(drawHourEnd, skedJob.sked__Timezone__c);
                            string driveWeekday = drawHourStart.format('EEEE');
                            
                            for (travelTimeBreakdownModel breakdown : siteCO.coToSiteList) {
                                if (breakdown.weekday == driveWeekday && breakdown.startOfWindow <= skedJob.sked_Drive__r.sked_Start_Time__c && skedJob.sked_Drive__r.sked_Start_Time__c <= breakdown.endOfWindow) {
                                    if (skedJob.sked_Travel_Time__c != breakdown.travelTime && breakdown.travelTime != NULL) {
                                        decimal currentTravelTime = skedJob.sked_Travel_Time__c != NULL ? skedJob.sked_Travel_Time__c : 0;
                                        integer differentMinutes = integer.valueOf(currentTravelTime - breakdown.travelTime);
                                        skedJob.sked_Travel_Time__c = breakdown.travelTime;
                                        skedJob.sked__Start__c = skedJob.sked__Start__c.addMinutes(differentMinutes);
                                        
                                        mapRecordToUpdate.put(skedJob.Id, skedJob);
                                    }
                                    break;
                                }
                            }
                            
                            for (travelTimeBreakdownModel breakdown : siteCO.siteToCoList) {
                                if (breakdown.weekday == driveWeekday && breakdown.startOfWindow <= skedJob.sked_Drive__r.sked_End_Time__c && skedJob.sked_Drive__r.sked_End_Time__c <= breakdown.endOfWindow) {
                                    if (skedJob.sked_Travel_Time2__c != breakdown.travelTime && breakdown.travelTime != NULL) {
                                        decimal currentTravelTime = skedJob.sked_Travel_Time2__c != NULL ? skedJob.sked_Travel_Time2__c : 0;
                                        integer differentMinutes = integer.valueOf(breakdown.travelTime - currentTravelTime);
                                        skedJob.sked_Travel_Time2__c = breakdown.travelTime;
                                        skedJob.sked__Finish__c = skedJob.sked__Finish__c.addMinutes(differentMinutes);
                                        mapRecordToUpdate.put(skedJob.Id, skedJob);
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        if (!mapRecordToUpdate.isEmpty()) {
            update mapRecordToUpdate.values();
        }
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class travelTimeBreakdownModel {
        public string siteId;
        public string weekday;
        public Time endOfWindow;
        public Time startOfWindow;
        public string direction;   
        public decimal travelTime;
        public decimal travelDistance;
    }
    
    public class siteModel {
        public Id id;
        public List<siteCoModel> siteCos;
    }
    
    public class siteCoModel {
        public Id id;
        public Date startDate;
        public Date endDate;
        public List<travelTimeBreakdownModel> coToSiteList;
        public List<travelTimeBreakdownModel> siteToCoList;
    }
    
}