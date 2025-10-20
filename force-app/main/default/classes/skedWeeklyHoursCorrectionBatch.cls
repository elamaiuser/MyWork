global class skedWeeklyHoursCorrectionBatch implements Database.Batchable<sked__Job_Allocation__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected string lastId = '';
    protected Set<Id> idsToProcess;
    
    global skedWeeklyHoursCorrectionBatch() {
        this.lastId = '';
        this.idsToProcess = new Set<Id>();
    }
    
    global skedWeeklyHoursCorrectionBatch(string lastId) {
        this.lastId = lastId;
        this.idsToProcess = new Set<Id>();
    }
    
    global List<sked__Job_Allocation__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Completed_Post_Processes__c,
                (SELECT Id
                 FROM sked_Resource_Hours_Record_Details__r
                 LIMIT 1)
                FROM sked__Job_Allocation__c
                WHERE sked__Resource__r.sked__Resource_Type__c = 'Person'
                AND sked__Status__c != 'Deleted'
                AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
                AND Id > :this.lastId
                ORDER BY Id ASC
                LIMIT 25000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> records) {
        List<sked__Job_Allocation__c> recordsToUpdate = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c record : records) {
            if (record.sked_Resource_Hours_Record_Details__r == NULL || record.sked_Resource_Hours_Record_Details__r.isEmpty()) {
                recordsToUpdate.add(record);
                this.idsToProcess.add(record.Id);
            }            
        }
        
        skedTriggerUtils.removePostProcessFromJobAllocations(recordsToUpdate, skedConstants.JOB_ALLOCATION_POST_PROCESS_MAIN_PROCESS);
        this.lastId = records.get(records.size() - 1).Id;
    }
    
    global void finish(Database.BatchableContext BC) { 
        if (!this.idsToProcess.isEmpty()) {
            skedJobAllocationPostProcessBatch.schedule();
        }
        
        List<sked__Job_Allocation__c> remainRecordQuery = [
            SELECT Id
            FROM sked__Job_Allocation__c
            WHERE sked__Resource__r.sked__Resource_Type__c = 'Person'
            AND sked__Status__c != 'Deleted'
            AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];
        
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedWeeklyHoursCorrectionBatch(this.lastId), 200);
        }
    }
    
}