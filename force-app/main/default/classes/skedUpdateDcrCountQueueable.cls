public class skedUpdateDcrCountQueueable implements Queueable {

    private final Set<Id> driveIds;

    public skedUpdateDcrCountQueueable(Set<Id> driveIds) {
        this.driveIds = driveIds;
    }

    public void execute(QueueableContext qc) {
        if (driveIds == null || driveIds.isEmpty()) {
            return;
        }

        Set<String> nonPendingStatuses = new Set<String>{
            'Approved', 'Rejected', 'Cancelled', 'Approved by System'
        };

        List<sked_Drive__c> drives = [
            SELECT Id, sked_Num_Of_Pending_DCRs__c,
                (SELECT Id FROM sked_Drive_Change_Requests__r
                 WHERE sked_Status__c NOT IN :nonPendingStatuses)
            FROM sked_Drive__c
            WHERE Id IN :driveIds
            FOR UPDATE
        ];

        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        for (sked_Drive__c drive : drives) {
            Decimal newCount = drive.sked_Drive_Change_Requests__r.size();
            if (drive.sked_Num_Of_Pending_DCRs__c != newCount) {
                drive.sked_Num_Of_Pending_DCRs__c = newCount;
                drivesToUpdate.add(drive);
            }
        }

        if (drivesToUpdate.isEmpty()) {
            return;
        }

        skedHubBase.BypassUpdateTriggers = true;
        try {
            update drivesToUpdate;
        } finally {
            skedHubBase.BypassUpdateTriggers = false;
        }
    }
}