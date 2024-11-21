global class skedSlotCleanupOneTimeBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String lastId = '';
    public skedSlotCleanupOneTimeBatch(String lastId) {
        this.lastId = lastId;
    }

    global List<sked_Drive_Shift__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, Name, sked_Drive__r.sked_Collection_Operation__c, sked_Finish__c
            FROM sked_Drive_Shift__c
            WHERE Id > :this.lastId
            ORDER BY Id ASC 
            LIMIT 50000
        ];
    }

    global void execute(Database.BatchableContext BC, List<sked_Drive_Shift__c> driveShiftsToProcess) {
        Set<Id> driveShiftIds = new Set<Id>();
        for(sked_Drive_Shift__c drive : driveShiftsToProcess){
            driveShiftIds.add(drive.Id);
        }

        List<sked__Slot__c> slots = [
            SELECT Id, sked_Start_Date__c, sked_Start_Time__c, sked_Drive_Shift__r.sked_Drive_Date__c, sked_Drive_Shift__r.sked_End_Time__c
            FROM sked__Slot__c 
            WHERE sked_Drive_Shift__c IN :driveShiftIds
            AND sked_Type__c = 'Whole Blood'
        ];

        List<sked__Slot__c> slotsToDelete = new List<sked__Slot__c>();

        for(sked__Slot__c slot : slots){
            if(slot.sked_Start_Date__c == slot.sked_Drive_Shift__r.sked_Drive_Date__c &&
                slot.sked_Start_Time__c >= slot.sked_Drive_Shift__r.sked_End_Time__c){
                slotsToDelete.add(slot);
            }
        }

        delete slotsToDelete;
        this.lastId = driveShiftsToProcess.get(driveShiftsToProcess.size()-1).Id;
    }   
     
    global void finish(Database.BatchableContext BC) {
        List<sked_Drive_Shift__c> remainingDriveShifts = [
            SELECT Id
            FROM sked_Drive_Shift__c
            WHERE Id > :this.lastId
            LIMIT 1
        ];

        if (!remainingDriveShifts.isEmpty()) {
            Database.executeBatch(new skedSlotCleanupOneTimeBatch(this.lastId), 200);
        }
    }
}