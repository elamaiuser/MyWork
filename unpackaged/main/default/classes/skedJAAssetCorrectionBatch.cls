global class skedJAAssetCorrectionBatch implements Database.Batchable<sked__Job_Allocation__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected string lastId = '';
    
    public skedJAAssetCorrectionBatch() { 
        this.lastId = '';
    }
    
    public skedJAAssetCorrectionBatch(string lastId) { 
        this.lastId = lastId;
    }
    
    global List<sked__Job_Allocation__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked__Start__c, sked__Set_End__c,
                sked__Job__r.sked_Drive__r.sked_Min_Shift_Start__c,
                sked__Job__r.sked_Drive__r.sked_Max_Shift_End__c
                FROM sked__Job_Allocation__c
                WHERE sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_ASSET
                AND sked__Job__r.sked__Job_Allocation_Time_Source__c = FALSE
                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                AND sked__Job__r.sked_Drive__c != NULL
                AND sked__Job__r.sked_Drive__r.sked_Min_Shift_Start__c != NULL
                AND sked__Job__r.sked_Drive__r.sked_Max_Shift_End__c != NULL
                AND Id > :this.lastId
                ORDER BY Id ASC
                LIMIT 50000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> records) {
        for (sked__Job_Allocation__c record : records) {
            record.sked__Start__c = record.sked__Job__r.sked_Drive__r.sked_Min_Shift_Start__c;
            record.sked__Set_End__c = record.sked__Job__r.sked_Drive__r.sked_Max_Shift_End__c;
            record.sked__Duration__c = skedDateTimeUtils.getDifferentMinutes(record.sked__Start__c, record.sked__Set_End__c);
        }
        
        skedSetting.instance.Admin.migrationMode = TRUE;
        update records;
        skedSetting.instance.Admin.migrationMode = FALSE;
        
        this.lastId = records.get(records.size() - 1).Id;
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked__Job_Allocation__c> remainRecordQuery = [
            SELECT Id
            FROM sked__Job_Allocation__c
            WHERE sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_ASSET
            AND sked__Job__r.sked__Job_Allocation_Time_Source__c = FALSE
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            AND sked__Job__r.sked_Drive__c != NULL
            AND sked__Job__r.sked_Drive__r.sked_Min_Shift_Start__c != NULL
            AND sked__Job__r.sked_Drive__r.sked_Max_Shift_End__c != NULL
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];
        
        if (!remainRecordQuery.isEmpty()) {
            if (!Test.isRunningTest()) {
                Database.executeBatch(new skedJAAssetCorrectionBatch(this.lastId), 200);
            }
        }
    }
    
}