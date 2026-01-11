global class skedDriveDataUpdateOneTimeBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Date inputDate;
    
    public skedDriveDataUpdateOneTimeBatch(Date inputDate) {
        this.inputDate = inputDate;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Drive_Date__c, sked_Min_Shift_Start__c, sked_Min_Shift_Start_Date__c, sked_Min_Shift_Start_Time__c, 
            sked_Max_Shift_End__c, sked_Max_Shift_End_Date__c, sked_Max_Shift_End_Time__c, sked_Timezone__c
            FROM sked_Drive__c
            WHERE sked_Drive_Date__c >= :this.inputDate
            AND (sked_Min_Shift_Start_Date__c = NULL OR sked_Min_Shift_Start_Time__c = NULL
                 OR sked_Max_Shift_End_Date__c = NULL OR sked_Max_Shift_End_Time__c = NULL)
            LIMIT 50000
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        for (sked_Drive__c record : records) {
            skedDateTimeUtils.convertDateTimeToDateAndTime(record, 'sked_Min_Shift_Start__c', 'sked_Min_Shift_Start_Date__c', 'sked_Min_Shift_Start_Time__c', 'sked_Timezone__c', NULL);
            skedDateTimeUtils.convertDateTimeToDateAndTime(record, 'sked_Max_Shift_End__c', 'sked_Max_Shift_End_Date__c', 'sked_Max_Shift_End_Time__c', 'sked_Timezone__c', NULL);
        }
        update records;
    }
    
    public void finish(Database.BatchableContext BC) {}
    
}