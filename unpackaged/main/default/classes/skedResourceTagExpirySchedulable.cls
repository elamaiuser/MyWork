global class skedResourceTagExpirySchedulable implements System.Schedulable {

    global void execute(SchedulableContext SC) {
        List<sked_Notification_Setting__mdt> skedNotificationSettings = [SELECT Id
                                                                         FROM sked_Notification_Setting__mdt
                                                                         WHERE DeveloperName = 'sked_Resource_Tag_Expiry_Notification'
                                                                         AND sked_Trigger__c = 'Custom'
                                                                         AND sked_Active__c = TRUE];
        if (!skedNotificationSettings.isEmpty()) {
            sked_Notification_Setting__mdt skedNotificationSetting = skedNotificationSettings.get(0);
            integer tagExpiryAlertDays = skedSetting.instance.admin.tagExpiryAlertDays;
            Date dateToNotify = system.today().addDays(tagExpiryAlertDays);

            System.debug('TAG EXPIRY ALERT DAYS :: ' + tagExpiryAlertDays);
            
            List<sked__Resource_Tag__c> records = [SELECT Id
                                                   FROM sked__Resource_Tag__c
                                                   WHERE sked_Expiry_Date__c = :dateToNotify
                                                   AND sked__Resource__r.sked_Supervisor_Email__c != NULL];
            Set<Id> recordIds = new Set<Id>();
            for (sked__Resource_Tag__c record : records) {
                recordIds.add(record.Id);
            }
            if (!recordIds.isEmpty()) {
                Map<Id, Set<Id>> map_settingId_recordIds = new Map<Id, Set<Id>>();
                map_settingId_recordIds.put(skedNotificationSetting.Id, recordIds);
                if (!Test.isRunningTest() && !System.isBatch()) {
                    Database.executeBatch(new skedSendNotificationBatch(map_settingId_recordIds), 20);
                }
            }
        }
    }
    
}