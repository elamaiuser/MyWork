global class skedPostJobMigrationBatch1 implements Database.Batchable<sked__Job__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected string lastId = '';
    
    global skedPostJobMigrationBatch1(string lastId) {
        this.lastId = lastId;
    }
	
    global List<sked__Job__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_MigrationID__c, sked__Location__c,
                sked_Travel_Time__c, sked_Travel_Time2__c, sked__Start__c, sked__Finish__c, sked__Timezone__c,
                sked_Asset_Type__c, sked_Resource_Role__c,
                sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Start_Time__c, sked_Drive__r.sked_End_Time__c,
                sked_Drive__r.sked_Collection_Operation__c, sked_Drive__r.sked_Travel_Time_Included__c
                FROM sked__Job__c
                WHERE Id > :this.lastId
                AND sked_Resource_Role__c != NULL
                ORDER BY Id ASC
                LIMIT 40000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job__c> records) {
        List<string> drivingRoles = new List<string>();
        drivingRoles.add('Competent Driver');
        drivingRoles.add('Driver');
        drivingRoles.add('Driver CDL B');
        drivingRoles.add('Driver - DOT');
        drivingRoles.add('Driver Support');
        drivingRoles.add('Driver Tech Trainee');
        drivingRoles.add('Staff Shuttle');
        
        Map<Id, sked__Job__c> mapRecordToUpdate = new Map<Id, sked__Job__c>();
        for (sked__Job__c skedJob : records) {
            
            system.debug('#skedJob.sked_Drive__r.sked_Travel_Time_Included__c#' + skedJob.sked_Drive__r.sked_Travel_Time_Included__c);
            system.debug('#skedJob.sked_Resource_Role__c#' + skedJob.sked_Resource_Role__c);
            system.debug('#skedJob.sked_Travel_Time__c#' + skedJob.sked_Travel_Time__c);
            system.debug('#skedJob.sked_Travel_Time2__c#' + skedJob.sked_Travel_Time2__c);
            
            if (skedJob.sked_Drive__r.sked_Travel_Time_Included__c != NULL && skedJob.sked_Drive__r.sked_Travel_Time_Included__c == 'Drivers Only') {
                system.debug('#here?#' + drivingRoles.contains(skedJob.sked_Resource_Role__c));
                if (!drivingRoles.contains(skedJob.sked_Resource_Role__c)) {
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
            }
        }
        if (!mapRecordToUpdate.isEmpty()) {
            update mapRecordToUpdate.values();
        }
        
        this.lastId = records.get(records.size() - 1).Id;
        system.debug('#this.lastId#' + this.lastId);
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked__Job__c> remainRecordQuery = [SELECT Id, sked_MigrationID__c, sked__Location__c,
                                                sked_Travel_Time__c, sked_Travel_Time2__c, sked__Start__c, sked__Finish__c, sked__Timezone__c,
                                                sked_Asset_Type__c, sked_Resource_Role__c,
                                                sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Start_Time__c, sked_Drive__r.sked_End_Time__c,
                                                sked_Drive__r.sked_Collection_Operation__c
                                                FROM sked__Job__c
                                                WHERE Id > :this.lastId
                                                AND sked_Resource_Role__c != NULL
                                                ORDER BY Id ASC
                                                LIMIT 1];
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedPostJobMigrationBatch1(this.lastId), 200);
        }
    }
    
}