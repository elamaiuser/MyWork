global class skedPopulateDriveShiftDate_Batch implements Database.Batchable<sked_Drive_Shift__c>, Database.Stateful {
    protected String lastId = '';

    global skedPopulateDriveShiftDate_Batch() {
        this.lastId = '';
    }

    global skedPopulateDriveShiftDate_Batch(String id) {
        this.lastId = id;
    }

    global List<sked_Drive_Shift__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked_Drive__r.sked_Drive_Date__c
            FROM sked_Drive_Shift__c
            WHERE Id > :this.lastId
            AND sked_Drive_Date__c = null
            LIMIT 50000
        ];
    }

    global void execute(Database.BatchableContext BC, List<sked_Drive_Shift__c> driveShifts) {
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            driveShift.sked_Drive_Date__c = driveShift.sked_Drive__r.sked_Drive_Date__c;
        }

        update driveShifts;
        this.lastId = driveShifts.get(driveShifts.size()-1).Id;
    }

    global void finish(Database.BatchableContext BC) {
        List<sked_Drive_Shift__c> remainingDriveShifts = [
            SELECT Id, sked_Drive__r.sked_Drive_Date__c
            FROM sked_Drive_Shift__c
            WHERE Id > :this.lastId
            AND sked_Drive_Date__c = null
            LIMIT 1
        ];

        if (!remainingDriveShifts.isEmpty()) {
            Database.executeBatch(new skedPopulateDriveShiftDate_Batch(this.lastId));
        }
    }
}