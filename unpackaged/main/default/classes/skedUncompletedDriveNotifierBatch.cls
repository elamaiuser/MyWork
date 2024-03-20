global class skedUncompletedDriveNotifierBatch implements Schedulable, Database.Batchable<sked_Drive__c>, Database.Stateful {
    Set<Id> jobAllocationIds = new Set<Id>();
    Map<String, Set<String>> resourceRolesByGroup;
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new skedUncompletedDriveNotifierBatch(), 200);
    }

    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        this.resourceRolesByGroup = skedResourceUtils.getResourceRolesByGroup();
        DateTime twoHoursAgo = System.now().addHours(-2);
        return [
            SELECT Id, Name
            FROM sked_Drive__c
            WHERE sked_Max_Shift_End__c <= :twoHoursAgo
            AND sked_Drive_Date__c = :System.today()
            AND sked_Status__c = :skedConstants.DRIVE_STATUS_CONFIRMED
            AND sked_Is_Notified__c = false
        ];
    }
    
    // The batch job executes and operates on records of a max size of 200
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> scope) {
        Set<Id> driveIds = new Set<Id>();
        for (sked_Drive__c drive : scope) {
            driveIds.add(drive.Id);
            drive.sked_Is_Notified__c = true;
        }
        update scope;

        List<sked__Job_Allocation__c> jobAllocations = [
            SELECT Id, sked__Resource__c
            FROM sked__Job_Allocation__c 
            WHERE sked__Job__r.sked_Drive__c IN :driveIds
            AND sked__Resource__r.sked__Resource_Type__c = 'Person'
            AND sked_Resource_Role__c IN :this.resourceRolesByGroup.get(skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES)
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        ];

        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            this.jobAllocationIds.add(jobAllocation.Id);
        }
    }

    // Finish runs at the end
    global void finish(Database.BatchableContext BC) {
        sked_Notification_Setting__mdt uncompletedDriveNotifSettings = [
            SELECT Id
            FROM sked_Notification_Setting__mdt
            WHERE DeveloperName = 'sked_Drive_End_Notification'
            LIMIT 1
        ][0];

        Map<Id, Set<Id>> jobAllocationIdsByNotifId = new Map<Id, Set<Id>>();
        jobAllocationIdsByNotifId.put(uncompletedDriveNotifSettings.Id, this.jobAllocationIds);
        Database.executeBatch(new skedSendNotificationBatch(jobAllocationIdsByNotifId), 20);
        System.scheduleBatch(new skedUncompletedDriveNotifierBatch(), 'skedUncompletedDriveNotifierBatch_' + String.valueOf(Datetime.now()), 10);
    }
}