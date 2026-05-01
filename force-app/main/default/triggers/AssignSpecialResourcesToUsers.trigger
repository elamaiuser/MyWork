/**
 * Description: Subscriber to AssignResourcesToUserEvent__e that triggers
 * the re-addition of special manual permissions via a Queueable job.
 */
trigger AssignSpecialResourcesToUsers on AssignResourcesToUserEvent__e (after insert) {
    Set<String> userIds = new Set<String>();

    for (AssignResourcesToUserEvent__e event : Trigger.new) {
        if (event.UserId__c != null) {
            System.debug(':::TPE::: ' + event.UserId__c);
            userIds.add(event.UserId__c);
        }
    }

    if (!userIds.isEmpty()) {
        System.enqueueJob(new UserSpecialPermissionQueueable(userIds));
    }
}